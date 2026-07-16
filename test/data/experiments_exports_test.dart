import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/experiments/experiment_repository.dart';
import 'package:why_pulse/data/exports/evidence_export_service.dart';
import 'package:why_pulse/domain/models/experiment_models.dart';
import 'package:why_pulse/domain/store_kind.dart';

void main() {
  late WhyPulseDatabase database;
  late Directory exportDirectory;

  setUp(() async {
    database = WhyPulseDatabase.forTesting(NativeDatabase.memory());
    await database.initialize(kind: StoreKind.live);
    exportDirectory = await Directory.systemTemp.createTemp('whypulse-export-');
  });

  tearDown(() async {
    await database.close();
    if (await exportDirectory.exists()) {
      await exportDirectory.delete(recursive: true);
    }
  });

  test('experiment protocol and occurrence survive reload', () async {
    await database
        .into(database.analysisRuns)
        .insert(
          AnalysisRunsCompanion.insert(
            id: 'analysis-1',
            status: 'completed',
            rangeStartUtc: DateTime.utc(2026, 6, 1),
            rangeEndUtc: DateTime.utc(2026, 7, 16),
            analysisVersion: 1,
            startedAt: DateTime.utc(2026, 7, 16),
            inputHash: 'input',
          ),
        );
    await database
        .into(database.evidenceBundles)
        .insert(
          EvidenceBundlesCompanion.insert(
            id: 'evidence-1',
            analysisRunId: 'analysis-1',
            status: 'supported',
            title: 'Test evidence',
            claimType: 'test',
            evidenceHash: 'hash',
            promotionPolicyVersion: 1,
          ),
        );
    final repository = ExperimentRepository(database);
    final created = await repository.start(
      evidenceBundleId: 'evidence-1',
      findingVersionId: 'finding:v1',
      recurrenceKeyHmac: 'recurrence-hmac',
      createdAtUtc: DateTime.utc(2026, 7, 16),
    );
    expect(created.occurrences, hasLength(3));
    await repository.recordAdherence(
      occurrenceId: created.occurrences.first.id,
      adhered: true,
      recordedAtUtc: DateTime.utc(2026, 7, 23),
    );
    final restored = await repository.loadProtocols();
    expect(restored.single.status, ExperimentProtocolStatus.active);
    expect(
      restored.single.occurrences.first.status,
      ExperimentOccurrenceStatus.adhered,
    );
  });

  test('PDF and canonical JSON exports share one integrity hash', () async {
    final result =
        await EvidenceExportService(
          database,
          directoryPath: exportDirectory.path,
        ).export(
          const EvidenceExportDocument(
            storeKind: 'live',
            evidenceVersion: 'finding:v1',
            status: 'supported',
            title: 'Recurring 1:1 and heart rate',
            metrics: {'median_difference_bpm': 11},
            sources: [
              {'id': 'health-connect', 'last_sync': '2026-07-16T12:00:00Z'},
            ],
            exclusions: {'workout_overlap': 2},
            counterevidence: {'count': 2},
            influences: ['unresolved_influences'],
            runtime: 'deterministic',
            safetyState: 'accepted',
          ),
        );
    final json = await File(result.jsonPath).readAsString();
    final pdf = await File(result.pdfPath).readAsBytes();
    expect(jsonDecode(json), isA<Map>());
    expect(result.hash, hasLength(64));
    expect(pdf.take(8), orderedEquals(utf8.encode('%PDF-1.4')));
    expect(String.fromCharCodes(pdf), contains(result.hash));
  });
}
