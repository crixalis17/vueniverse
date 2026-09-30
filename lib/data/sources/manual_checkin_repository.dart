import 'dart:convert';
import 'package:vueniverse/domain/models/caffeine_checkin.dart';

import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/sources/source_repository.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

final class ManualCheckinRecord {
  const ManualCheckinRecord({
    required this.id,
    required this.category,
    required this.occurredAt,
    required this.detail,
    this.customLabel,
    this.caffeineServings,
    this.coverageStart,
    this.coverageEnd,
  });

  final String id;
  final CheckinCategory category;
  final DateTime occurredAt;
  final String detail;
  final String? customLabel;
  final double? caffeineServings;
  final DateTime? coverageStart;
  final DateTime? coverageEnd;
}

final class ManualCheckinRepository {
  ManualCheckinRepository({
    required this.database,
    required this.canonicalRecords,
    required this.normalizer,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final VueniverseDatabase database;
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
            customLabel: value['custom_label'] is String
                ? value['custom_label'] as String
                : null,
            caffeineServings:
                category == CheckinCategory.caffeine && value['servings'] is num
                ? (value['servings'] as num).toDouble()
                : null,
            coverageStart: category == CheckinCategory.caffeine
                ? _time(value['coverage_start_utc'])
                : null,
            coverageEnd: category == CheckinCategory.caffeine
                ? _time(value['coverage_end_utc'])
                : null,
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
    if (checkin.category == CheckinCategory.caffeine) {
      final error = caffeineCheckinError(
        servings: checkin.caffeineServings,
        start: checkin.coverageStart,
        end: checkin.coverageEnd,
        reportedAt: occurredAt,
        now: _clock(),
      );
      if (error != null) throw ArgumentError(error);
    } else if (checkin.caffeineServings != null ||
        checkin.coverageStart != null ||
        checkin.coverageEnd != null) {
      throw ArgumentError(
        'Caffeine fields are only valid for caffeine check-ins.',
      );
    }
    final value = <String, Object?>{
      'manual_id': checkin.id,
      if (checkin.caffeineServings != null)
        'servings': checkin.caffeineServings,
      if (checkin.coverageStart != null)
        'coverage_start_utc': checkin.coverageStart!.toUtc().toIso8601String(),
      if (checkin.coverageEnd != null)
        'coverage_end_utc': checkin.coverageEnd!.toUtc().toIso8601String(),
      'detail': checkin.detail.trim().isEmpty
          ? 'No extra detail'
          : checkin.detail.trim(),
      if (checkin.customLabel != null)
        'custom_label': checkin.customLabel!.trim(),
      if (checkin.category == CheckinCategory.custom) 'reviewed': true,
    };
    await database.transaction(() async {
      // Imported demo identities use a different source/key. Replace those
      // records atomically when an explicit edit becomes a user-owned check-in.
      for (final row in await database.select(database.manualCheckins).get()) {
        Object? decoded;
        try {
          decoded = jsonDecode(row.valueJson);
        } on FormatException {
          continue;
        }
        if (decoded is! Map || decoded['manual_id'] != checkin.id) continue;
        final indexed = await (database.select(
          database.rawRecordIndex,
        )..where((entry) => entry.canonicalId.equals(row.id))).get();
        for (final source
            in indexed.map((entry) => entry.sourceConnectionId).toSet()) {
          if (source == SourceIds.manual) continue;
          await canonicalRecords.deleteCanonicalIds(
            sourceConnectionId: source,
            canonicalIds: [row.id],
            reason: 'manual_checkin_replaced',
          );
        }
      }
      final report = await canonicalRecords.importRecords(
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
      if (report.rejected > 0) {
        throw StateError('Check-in normalization rejected the record.');
      }
    });
  }

  DateTime? _time(Object? value) =>
      value is String && RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)
      ? DateTime.tryParse(value)?.toLocal()
      : null;

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
    final indexed = await (database.select(
      database.rawRecordIndex,
    )..where((row) => row.canonicalId.equals(canonicalId!))).get();
    if (indexed.isEmpty) return false;
    final report = await canonicalRecords.deleteCanonicalIds(
      sourceConnectionId: indexed.first.sourceConnectionId,
      canonicalIds: [canonicalId],
      reason: 'manual_checkin_deleted',
    );
    return report.deleted == 1;
  }
}
