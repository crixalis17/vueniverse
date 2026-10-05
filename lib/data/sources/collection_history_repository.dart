import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/domain/models/collection_history.dart';
import 'package:vueniverse/domain/store_kind.dart';

/// Read-only, store-scoped collection accounting. No effect/causality claims.
final class CollectionHistoryRepository {
  CollectionHistoryRepository(this.database);
  final VueniverseDatabase database;

  Future<StoreKind> _storeKind() async {
    final row = await (database.select(
      database.storeMetadata,
    )..where((row) => row.key.equals('store_kind'))).getSingleOrNull();
    final kind = StoreKind.values
        .where((kind) => kind.name == row?.value)
        .firstOrNull;
    if (kind == null) {
      throw StateError('Collection store identity is unavailable.');
    }
    return kind;
  }

  Future<CollectionCoverage> loadCoverage() async {
    final kind = await _storeKind();
    // Aggregate in SQLite; never load raw measurements or check-in text. Inner
    // joins exclude dangling index entries from retained canonical counts.
    final rows = await database.customSelect('''
      SELECT source_connection_id, source_kind, canonical_kind, record_type,
        COUNT(*) AS record_count, MIN(observed_at) AS first_observed,
        MAX(observed_at) AS last_observed, MAX(indexed_at) AS last_indexed
      FROM (
        SELECT r.source_connection_id, r.source_kind, r.canonical_kind,
          s.signal_type AS record_type, r.occurred_at_utc AS observed_at,
          r.updated_at AS indexed_at
        FROM raw_record_index r JOIN signal_samples s ON s.id = r.canonical_id
        WHERE r.canonical_kind = 'signal_sample'
        UNION ALL
        SELECT r.source_connection_id, r.source_kind, r.canonical_kind,
          h.interval_type, r.occurred_at_utc, r.updated_at
        FROM raw_record_index r JOIN health_intervals h ON h.id = r.canonical_id
        WHERE r.canonical_kind = 'health_interval'
        UNION ALL
        SELECT r.source_connection_id, r.source_kind, r.canonical_kind,
          m.category, r.occurred_at_utc, r.updated_at
        FROM raw_record_index r JOIN manual_checkins m ON m.id = r.canonical_id
        WHERE r.canonical_kind = 'manual_checkin'
        UNION ALL
        SELECT r.source_connection_id, r.source_kind, r.canonical_kind,
          c.category, r.occurred_at_utc, r.updated_at
        FROM raw_record_index r JOIN context_events c ON c.id = r.canonical_id
        WHERE r.canonical_kind = 'context_event'
      ) GROUP BY source_connection_id, source_kind, canonical_kind, record_type
      ORDER BY source_connection_id, canonical_kind, record_type
    ''').get();
    return CollectionCoverage(
      storeKind: kind,
      groups: List.unmodifiable(
        rows.map(
          (row) => CollectionCoverageGroup(
            sourceConnectionId: row.read<String>('source_connection_id'),
            sourceKind: row.read<String>('source_kind'),
            canonicalKind: row.read<String>('canonical_kind'),
            recordType: row.read<String>('record_type'),
            count: row.read<int>('record_count'),
            firstObservedAtUtc: row.read<DateTime>('first_observed').toUtc(),
            lastObservedAtUtc: row.read<DateTime>('last_observed').toUtc(),
            lastIndexedAtUtc: row.read<DateTime>('last_indexed').toUtc(),
          ),
        ),
      ),
    );
  }

  Future<CollectionHistoryPage> loadReceipts({
    int limit = 30,
    CollectionHistoryCursor? before,
  }) async {
    if (limit < 1 || limit > 100) throw ArgumentError.value(limit, 'limit');
    final kind = await _storeKind();
    final cursorClause = before == null
        ? ''
        : '''
      WHERE receipt_time < ? OR (receipt_time = ? AND receipt_kind < ?)
        OR (receipt_time = ? AND receipt_kind = ? AND receipt_id < ?)
    ''';
    final rows = await database
        .customSelect(
          '''
      SELECT * FROM (
        SELECT id AS receipt_id, 'sync' AS receipt_kind,
          source_connection_id AS source_id, status, started_at AS receipt_time,
          finished_at, records_seen, records_accepted, records_rejected,
          NULL AS records_deleted,
          (error_code IS NOT NULL OR status = 'failed') AS has_error,
          CASE WHEN LENGTH(error_details) <= 4096 THEN error_details
            ELSE NULL END AS rejection_details, NULL AS deletion_reason
        FROM sync_runs
        UNION ALL
        SELECT id, 'deletion', source_id, 'deleted', created_at, created_at,
          NULL, NULL, NULL, records_deleted, 0, NULL, scope
        FROM deletion_audit
      ) $cursorClause
      ORDER BY receipt_time DESC, receipt_kind DESC, receipt_id DESC LIMIT ?
    ''',
          variables: [
            if (before != null) ...[
              Variable<DateTime>(before.recordedAtUtc.toUtc()),
              Variable<DateTime>(before.recordedAtUtc.toUtc()),
              Variable<String>(before.kind),
              Variable<DateTime>(before.recordedAtUtc.toUtc()),
              Variable<String>(before.kind),
              Variable<String>(before.id),
            ],
            Variable<int>(limit + 1),
          ],
        )
        .get();
    final receipts = rows
        .take(limit)
        .map((row) {
          final details = _details(
            row.readNullable<String>('rejection_details'),
          );
          return CollectionReceipt(
            id: row.read<String>('receipt_id'),
            kind: row.read<String>('receipt_kind'),
            sourceConnectionId: row.readNullable<String>('source_id'),
            status: row.read<String>('status'),
            recordedAtUtc: row.read<DateTime>('receipt_time').toUtc(),
            finishedAtUtc: row.readNullable<DateTime>('finished_at')?.toUtc(),
            recordsSeen: row.readNullable<int>('records_seen'),
            recordsAccepted: row.readNullable<int>('records_accepted'),
            recordsRejected: row.readNullable<int>('records_rejected'),
            recordsDeleted: row.readNullable<int>('records_deleted'),
            rejectionReasons: details.rejections,
            receiptSchema: details.schema,
            recordsInserted: details.inserted,
            recordsChanged: details.changed,
            recordsDuplicate: details.duplicates,
            reportedTimezone: details.timezone,
            requestedLocalDate: details.localDate,
            hasError: row.read<int>('has_error') != 0,
            deletionReason: _safeDeletionReason(
              row.readNullable<String>('deletion_reason'),
            ),
          );
        })
        .toList(growable: false);
    return CollectionHistoryPage(
      storeKind: kind,
      receipts: List.unmodifiable(receipts),
      nextCursor: rows.length > limit ? receipts.last.cursor : null,
    );
  }

  static const _safeReasons = {
    'unsupported_record_type',
    'unsupported_unit',
    'impossible_value',
    'impossible_duration',
    'unsupported_category',
    'malformed_value',
    'unreviewed_custom_category',
    'malformed_time',
    'malformed_record',
  };

  _ReceiptDetails _details(String? text) {
    if (text == null || text.length > 4096) return const _ReceiptDetails();
    try {
      final value = jsonDecode(text);
      if (value is! Map) return const _ReceiptDetails();
      if (!value.containsKey('receipt_schema')) {
        return _ReceiptDetails(rejections: _rejections(value));
      }
      if (value['receipt_schema'] is! int || value['receipt_schema'] != 1) {
        return const _ReceiptDetails();
      }
      return _ReceiptDetails(
        schema: 1,
        rejections: value['rejections'] is Map
            ? _rejections(value['rejections'] as Map)
            : const {},
        inserted: _counter(value['inserted']),
        changed: _counter(value['changed']),
        duplicates: _counter(value['duplicates']),
        timezone: _timezone(value['reportedTimezone']),
        localDate: _localDate(value['requestedLocalDate']),
      );
    } on FormatException {
      return const _ReceiptDetails();
    }
  }

  int? _counter(Object? value) =>
      value is int && value >= 0 && value <= 9007199254740991 ? value : null;

  Map<String, int> _rejections(Map value) {
    final result = <String, int>{};
    for (final entry in value.entries) {
      final count = _counter(entry.value);
      if (count == null) continue;
      final key = _safeReasons.contains(entry.key)
          ? entry.key as String
          : 'other_rejection';
      final combined = (result[key] ?? 0) + count;
      if (combined <= 9007199254740991) result[key] = combined;
    }
    return Map.unmodifiable(result);
  }

  String? _timezone(Object? value) {
    if (value is! String || value.length > 100) return null;
    if (value == 'UTC' || value == 'GMT') return value;
    return RegExp(
          r'^(Africa|America|Antarctica|Arctic|Asia|Atlantic|Australia|Europe|Indian|Pacific|Etc)/[A-Za-z0-9_+-]{1,32}(/[A-Za-z0-9_+-]{1,32}){0,2}$',
        ).hasMatch(value)
        ? value
        : null;
  }

  String? _localDate(Object? value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final parsed = DateTime.tryParse('${value}T00:00:00Z');
    return parsed != null && parsed.toIso8601String().startsWith('${value}T')
        ? value
        : null;
  }

  String? _safeDeletionReason(String? reason) {
    if (reason == null) return null;
    return const {
          'manual_checkin_deleted',
          'manual_checkin_replaced',
          'source_record_deleted',
          'source_data_deleted',
          'source_snapshot_missing',
        }.contains(reason)
        ? reason
        : 'records_deleted';
  }
}

final class _ReceiptDetails {
  const _ReceiptDetails({
    this.schema,
    this.rejections = const {},
    this.inserted,
    this.changed,
    this.duplicates,
    this.timezone,
    this.localDate,
  });
  final int? schema;
  final Map<String, int> rejections;
  final int? inserted;
  final int? changed;
  final int? duplicates;
  final String? timezone;
  final String? localDate;
}
