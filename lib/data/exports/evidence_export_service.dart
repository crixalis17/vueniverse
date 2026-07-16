import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:why_pulse/data/database/schema_versions.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/normalization/record_normalizer.dart';

final class EvidenceExportDocument {
  const EvidenceExportDocument({
    required this.storeKind,
    required this.evidenceVersion,
    required this.status,
    required this.title,
    required this.metrics,
    required this.sources,
    required this.exclusions,
    required this.counterevidence,
    required this.influences,
    required this.runtime,
    required this.safetyState,
  });

  final String storeKind;
  final String evidenceVersion;
  final String status;
  final String title;
  final Map<String, Object?> metrics;
  final List<Map<String, Object?>> sources;
  final Map<String, Object?> exclusions;
  final Map<String, Object?> counterevidence;
  final List<String> influences;
  final String runtime;
  final String safetyState;
}

final class EvidenceExportResult {
  const EvidenceExportResult({
    required this.hash,
    required this.jsonPath,
    required this.pdfPath,
  });

  final String hash;
  final String jsonPath;
  final String pdfPath;
}

final class EvidenceExportService {
  EvidenceExportService(this.database, {this._directoryPath});

  final WhyPulseDatabase database;
  final String? _directoryPath;

  Future<EvidenceExportResult> export(EvidenceExportDocument document) async {
    final directory = Directory(
      _directoryPath ?? '${database.executor.hashCode}-whypulse-exports',
    );
    await directory.create(recursive: true);
    final body = <String, Object?>{
      'schema': SchemaVersions.exportSchema,
      'store': document.storeKind,
      'evidence_version': document.evidenceVersion,
      'status': document.status,
      'title': document.title,
      'metrics': document.metrics,
      'sources': document.sources,
      'exclusions': document.exclusions,
      'counterevidence': document.counterevidence,
      'influences': document.influences,
      'runtime': document.runtime,
      'safety_state': document.safetyState,
    };
    final json = canonicalJsonEncode(body);
    final hash = sha256.convert(utf8.encode(json)).toString();
    final prefix = 'evidence-${document.evidenceVersion}-$hash';
    final jsonFile = File('${directory.path}/$prefix.json');
    final pdfFile = File('${directory.path}/$prefix.pdf');
    await jsonFile.writeAsString(json, flush: true);
    await pdfFile.writeAsBytes(_pdfBytes(document, hash), flush: true);
    final now = DateTime.now().toUtc();
    await database
        .into(database.exportRecords)
        .insert(
          ExportRecordsCompanion.insert(
            id: '$prefix:json',
            exportType: 'json',
            status: 'valid',
            filePath: jsonFile.path,
            contentHash: Value(hash),
            exportSchemaVersion: SchemaVersions.exportSchema,
            createdAt: Value(now),
          ),
        );
    await database
        .into(database.exportRecords)
        .insert(
          ExportRecordsCompanion.insert(
            id: '$prefix:pdf',
            exportType: 'pdf',
            status: 'valid',
            filePath: pdfFile.path,
            contentHash: Value(hash),
            exportSchemaVersion: SchemaVersions.exportSchema,
            createdAt: Value(now),
          ),
        );
    return EvidenceExportResult(
      hash: hash,
      jsonPath: jsonFile.path,
      pdfPath: pdfFile.path,
    );
  }

  Future<void> deleteAll() async {
    final rows = await database.select(database.exportRecords).get();
    for (final row in rows) {
      try {
        final file = File(row.filePath);
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // Keep the tombstone if the file is already unavailable.
      }
      await (database.update(
        database.exportRecords,
      )..where((item) => item.id.equals(row.id))).write(
        ExportRecordsCompanion(
          status: const Value('deleted'),
          deletedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }
  }

  List<int> _pdfBytes(EvidenceExportDocument document, String hash) {
    final lines = [
      'WhyPulse evidence export',
      'Store: ${document.storeKind}',
      'Title: ${document.title}',
      'Status: ${document.status}',
      'Evidence version: ${document.evidenceVersion}',
      'Integrity hash: $hash',
      'Runtime: ${document.runtime}',
      'Safety: ${document.safetyState}',
      '',
      'This report describes a personal association. It is not a diagnosis or treatment recommendation.',
    ];
    final stream = StringBuffer('BT\n/F1 11 Tf\n50 760 Td\n');
    for (final line in lines) {
      stream.write('(${_pdfEscape(line)}) Tj\n0 -16 Td\n');
    }
    stream.write('ET');
    final content = utf8.encode(stream.toString());
    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      '<< /Length ${content.length} >>\nstream\n$stream\nendstream',
    ];
    final output = BytesBuilder();
    output.add(utf8.encode('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n'));
    final offsets = <int>[];
    for (var index = 0; index < objects.length; index++) {
      offsets.add(output.length);
      output.add(
        utf8.encode('${index + 1} 0 obj\n${objects[index]}\nendobj\n'),
      );
    }
    final xref = output.length;
    output.add(
      utf8.encode('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n'),
    );
    for (final offset in offsets) {
      output.add(
        utf8.encode('${offset.toString().padLeft(10, '0')} 00000 n \n'),
      );
    }
    output.add(
      utf8.encode(
        'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n',
      ),
    );
    return output.takeBytes();
  }

  String _pdfEscape(String value) => value
      .replaceAll('\\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
}
