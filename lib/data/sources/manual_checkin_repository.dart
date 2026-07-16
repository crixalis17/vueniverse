import 'dart:convert';

import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/normalization/record_normalizer.dart';
import 'package:why_pulse/data/repositories/canonical_record_repository.dart';
import 'package:why_pulse/data/sources/source_repository.dart';
import 'package:why_pulse/domain/models/canonical_domain_models.dart';

final class ManualCheckinRecord {
  const ManualCheckinRecord({
    required this.id,
    required this.category,
    required this.occurredAt,
    required this.detail,
    this.customLabel,
  });

  final String id;
  final CheckinCategory category;
  final DateTime occurredAt;
  final String detail;
  final String? customLabel;
}

final class ManualCheckinRepository {
  ManualCheckinRepository({
    required this.database,
    required this.canonicalRecords,
    required this.normalizer,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final WhyPulseDatabase database;
  final CanonicalRecordRepository canonicalRecords;
  final RecordNormalizer normalizer;
  final DateTime Function() _clock;

  Future<List<ManualCheckinRecord>> load() async {
    final rows = await database.select(database.manualCheckins).get();
    final result = <ManualCheckinRecord>[];
    for (final row in rows) {
      try {
        final value = jsonDecode(row.valueJson);
        if (value is! Map) continue;
        final id = value['manual_id'];
        final detail = value['detail'];
        final category = CheckinCategory.values
            .where((item) => item.name == row.category)
            .firstOrNull;
        if (id is! String || detail is! String || category == null) continue;
        result.add(
          ManualCheckinRecord(
            id: id,
            category: category,
            occurredAt: row.occurredAtUtc.toLocal(),
            detail: detail,
            customLabel: value['custom_label'] as String?,
          ),
        );
      } on FormatException {
        // Malformed rows remain excluded and are never surfaced as valid context.
      }
    }
    result.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List.unmodifiable(result);
  }

  Future<void> save(ManualCheckinRecord checkin) async {
    final occurredAt = checkin.occurredAt;
    final value = <String, Object?>{
      'manual_id': checkin.id,
      'detail': checkin.detail.trim().isEmpty
          ? 'No extra detail'
          : checkin.detail.trim(),
      if (checkin.customLabel != null)
        'custom_label': checkin.customLabel!.trim(),
      if (checkin.category == CheckinCategory.custom) 'reviewed': true,
    };
    await canonicalRecords.importRecords(
      sourceConnectionId: SourceIds.manual,
      sourceKind: SourceKind.manual,
      records: [
        SourceRecordEnvelope(
          source: SourceKind.manual,
          recordType: 'manual_checkin',
          payload: {
            'timestamp': occurredAt.toUtc().toIso8601String(),
            'offset_minutes': occurredAt.timeZoneOffset.inMinutes,
            'category': checkin.category.name,
            'value': value,
          },
          observedAt: _clock().toUtc(),
          stableSourceId: checkin.id,
        ),
      ],
      normalizer: normalizer,
      syncRunId: 'manual-${_clock().toUtc().microsecondsSinceEpoch}',
    );
  }

  Future<bool> delete(String manualId) async {
    final rows = await database.select(database.manualCheckins).get();
    String? canonicalId;
    for (final row in rows) {
      try {
        final value = jsonDecode(row.valueJson);
        if (value is Map && value['manual_id'] == manualId) {
          canonicalId = row.id;
          break;
        }
      } on FormatException {
        // Skip malformed records while looking for the explicit manual ID.
      }
    }
    if (canonicalId == null) return false;
    final report = await canonicalRecords.deleteCanonicalIds(
      sourceConnectionId: SourceIds.manual,
      canonicalIds: [canonicalId],
      reason: 'manual_checkin_deleted',
    );
    return report.deleted == 1;
  }
}
