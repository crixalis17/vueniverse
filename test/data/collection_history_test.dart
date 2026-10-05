import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/sources/collection_history_repository.dart';
import 'package:vueniverse/data/sources/manual_checkin_repository.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';

void main() {
  late VueniverseDatabase db;
  late CollectionHistoryRepository history;
  late CanonicalRecordRepository records;
  late RecordNormalizer normalizer;
  final time = DateTime.utc(2026, 10, 3, 8);

  setUp(() async {
    db = VueniverseDatabase.forTesting(NativeDatabase.memory());
    await db.initialize(kind: StoreKind.live);
    history = CollectionHistoryRepository(db);
    records = CanonicalRecordRepository(db);
    normalizer = RecordNormalizer(identityKey: List.filled(32, 17));
  });
  tearDown(() => db.close());

  SourceRecordEnvelope heart({double value = 70}) => SourceRecordEnvelope(
    source: SourceKind.healthConnect,
    recordType: 'heart_rate',
    payload: {
      'timestamp': time.toIso8601String(),
      'offset_minutes': 330,
      'value': value,
      'unit': 'bpm',
    },
    observedAt: time,
    stableSourceId: 'private-provider-id',
  );

  Future<void> import(String id, List<SourceRecordEnvelope> input) async {
    await records.importRecords(
      sourceConnectionId: 'health-connect',
      sourceKind: SourceKind.healthConnect,
      records: input,
      normalizer: normalizer,
      syncRunId: id,
    );
  }

  test('repeated accepted imports do not inflate retained coverage', () async {
    await import('first', [heart()]);
    await import('second', [heart()]);
    await import('changed', [heart(value: 75)]);
    final coverage = await history.loadCoverage();
    expect(coverage.storeKind, StoreKind.live);
    expect(coverage.retainedRecords, 1);
    expect(coverage.groups.single.recordType, 'heartRate');
    expect(coverage.groups.single.firstObservedAtUtc, time);
    expect(coverage.groups.single.lastObservedAtUtc, time);
    final page = await history.loadReceipts();
    expect(page.receipts, hasLength(3));
    expect(page.receipts.every((row) => row.recordsAccepted == 1), isTrue);
    final first = page.receipts.singleWhere((row) => row.id == 'first');
    final duplicate = page.receipts.singleWhere((row) => row.id == 'second');
    final changed = page.receipts.singleWhere((row) => row.id == 'changed');
    expect(first.recordsInserted, 1);
    expect(duplicate.recordsDuplicate, 1);
    expect(duplicate.recordsInserted, 0);
    expect(changed.recordsChanged, 1);
    expect(changed.recordsDuplicate, 0);
    // Legacy historical rows have no detailed counters: never backfill guesses.
    await db
        .update(db.syncRuns)
        .write(const SyncRunsCompanion(errorDetails: Value(null)));
    final legacy = await history.loadReceipts();
    expect(
      legacy.receipts.every((row) => row.recordsDuplicate == null),
      isTrue,
    );
    expect(legacy.receipts.every((row) => row.recordsChanged == null), isTrue);
    expect(legacy.receipts.every((row) => row.recordsInserted == null), isTrue);
  });

  test(
    'rejections expose bounded safe metadata, never exception details',
    () async {
      await import('rejected', [heart(value: -1)]);
      var receipt = (await history.loadReceipts()).receipts.single;
      expect(receipt.recordsRejected, 1);
      expect(receipt.rejectionReasons, {'impossible_value': 1});
      await (db.update(
        db.syncRuns,
      )..where((row) => row.id.equals('rejected'))).write(
        SyncRunsCompanion(
          status: const Value('failed'),
          errorCode: const Value('PRIVATE TOKEN AND REMOTE BODY'),
          errorDetails: Value(
            jsonEncode({
              'private journal text': 2,
              'malformed_time': 1,
              'invalid': -1,
            }),
          ),
        ),
      );
      receipt = (await history.loadReceipts()).receipts.single;
      expect(receipt.hasError, isTrue);
      expect(receipt.status, 'failed');
      expect(receipt.rejectionReasons, {
        'other_rejection': 2,
        'malformed_time': 1,
      });
      await (db.update(
        db.syncRuns,
      )..where((row) => row.id.equals('rejected'))).write(
        const SyncRunsCompanion(errorDetails: Value('private malformed text')),
      );
      expect(
        (await history.loadReceipts()).receipts.single.rejectionReasons,
        isEmpty,
      );
    },
  );

  test(
    'deletion removes coverage but leaves only its existing count receipt',
    () async {
      await import('first', [heart()]);
      await records.deleteAllForSource(sourceConnectionId: 'health-connect');
      expect((await history.loadCoverage()).retainedRecords, 0);
      final page = await history.loadReceipts();
      expect(page.receipts, hasLength(2));
      final deleted = page.receipts.singleWhere(
        (row) => row.kind == 'deletion',
      );
      expect(deleted.recordsDeleted, 1);
      expect(deleted.deletionReason, 'source_data_deleted');
      expect(deleted.recordsAccepted, isNull);
    },
  );

  test(
    'stable bounded pagination includes tie timestamps and receipt kinds',
    () async {
      await import('a', [heart()]);
      await import('b', [heart()]);
      await import('c', [heart()]);
      await db
          .update(db.syncRuns)
          .write(SyncRunsCompanion(startedAt: Value(time)));
      await db
          .into(db.deletionAudit)
          .insert(
            DeletionAuditCompanion.insert(
              id: 'deletion-tie',
              scope: 'private deletion text',
              recordsDeleted: 0,
              invalidatedJson: '[]',
              createdAt: Value(time),
            ),
          );
      final first = await history.loadReceipts(limit: 2);
      expect(first.receipts.map((row) => row.id), ['c', 'b']);
      final second = await history.loadReceipts(
        limit: 2,
        before: first.nextCursor,
      );
      expect(second.receipts.map((row) => row.id), ['a', 'deletion-tie']);
      expect(second.receipts.last.deletionReason, 'records_deleted');
      expect(second.nextCursor, isNull);
      await expectLater(history.loadReceipts(limit: 0), throwsArgumentError);
      await expectLater(history.loadReceipts(limit: 101), throwsArgumentError);
    },
  );

  test(
    'manual text is not read into coverage or receipt projections',
    () async {
      await records.importRecords(
        sourceConnectionId: 'manual-checkins',
        sourceKind: SourceKind.manual,
        records: [
          SourceRecordEnvelope(
            source: SourceKind.manual,
            recordType: 'manual_checkin',
            payload: {
              'timestamp': time.toIso8601String(),
              'offset_minutes': 330,
              'category': 'mood',
              'value': {
                'manual_id': 'private-user-id',
                'detail': 'private journal',
              },
            },
            observedAt: time,
            stableSourceId: 'private-user-id',
          ),
        ],
        normalizer: normalizer,
        syncRunId: 'manual-receipt',
      );
      final group = (await history.loadCoverage()).groups.single;
      expect(group.canonicalKind, 'manual_checkin');
      expect(group.recordType, 'mood');
      expect(group.count, 1);
      expect((await history.loadReceipts()).receipts.single.recordsAccepted, 1);
    },
  );

  test(
    'manual edits and deletion leave metadata without retaining revisions',
    () async {
      var clock = time;
      final manual = ManualCheckinRepository(
        database: db,
        canonicalRecords: records,
        normalizer: normalizer,
        clock: () => clock,
      );
      Future<void> save(String detail) => manual.save(
        ManualCheckinRecord(
          id: 'same-private-manual-id',
          category: CheckinCategory.mood,
          occurredAt: time,
          detail: detail,
        ),
      );
      await save('private first revision');
      clock = clock.add(const Duration(seconds: 1));
      await save('private replacement');
      expect((await history.loadCoverage()).retainedRecords, 1);
      expect((await history.loadReceipts()).receipts, hasLength(2));
      expect(await manual.delete('same-private-manual-id'), isTrue);
      expect((await history.loadCoverage()).retainedRecords, 0);
      final page = await history.loadReceipts();
      expect(page.receipts, hasLength(3));
      expect(
        page.receipts
            .singleWhere((row) => row.kind == 'deletion')
            .recordsDeleted,
        1,
      );
      expect(await db.select(db.manualCheckins).get(), isEmpty);
    },
  );

  test(
    'versioned counters and requested date metadata are persisted facts',
    () async {
      await import('v1', [heart()]);
      await (db.update(db.syncRuns)..where((row) => row.id.equals('v1'))).write(
        SyncRunsCompanion(
          errorDetails: Value(
            jsonEncode({
              'receipt_schema': 1,
              'inserted': 5,
              'changed': 2,
              'duplicates': 3,
              'rejections': {'malformed_time': 1, 'private text': 2},
              'reportedTimezone': 'Asia/Kolkata',
              'requestedLocalDate': '2026-10-03',
            }),
          ),
        ),
      );
      final row = (await history.loadReceipts()).receipts.single;
      expect(row.receiptSchema, 1);
      expect(row.recordsInserted, 5);
      expect(row.recordsChanged, 2);
      expect(row.recordsDuplicate, 3);
      expect(row.reportedTimezone, 'Asia/Kolkata');
      expect(row.requestedLocalDate, '2026-10-03');
      expect(row.rejectionReasons, {'malformed_time': 1, 'other_rejection': 2});
      // Coverage is deliberately not used to infer or "correct" historical counts.
      expect((await history.loadCoverage()).retainedRecords, 1);
    },
  );

  test(
    'invalid detail counters, unsafe strings and unknown schemas fail closed',
    () async {
      await import('invalid', [heart()]);
      Future<void> details(Map<String, Object?> value) async {
        await (db.update(db.syncRuns)..where((row) => row.id.equals('invalid')))
            .write(SyncRunsCompanion(errorDetails: Value(jsonEncode(value))));
      }

      await details({
        'receipt_schema': 1,
        'inserted': -1,
        'changed': 2.5,
        'duplicates': true,
        'rejections': {'malformed_time': 1.2, 'malformed_value': false},
        'reportedTimezone': 'Asia/Kolkata private notes',
        'requestedLocalDate': '2026-02-30',
      });
      var row = (await history.loadReceipts()).receipts.single;
      expect(row.recordsInserted, isNull);
      expect(row.recordsChanged, isNull);
      expect(row.recordsDuplicate, isNull);
      expect(row.reportedTimezone, isNull);
      expect(row.requestedLocalDate, isNull);
      expect(row.rejectionReasons, isEmpty);
      await details({
        'receipt_schema': 2,
        'inserted': 100,
        'rejections': {'malformed_time': 1},
      });
      row = (await history.loadReceipts()).receipts.single;
      expect(row.receiptSchema, isNull);
      expect(row.recordsInserted, isNull);
      expect(row.rejectionReasons, isEmpty);
      await details({'receipt_schema': 1.0, 'inserted': 100});
      expect(
        (await history.loadReceipts()).receipts.single.receiptSchema,
        isNull,
      );
      await details({
        'receipt_schema': 1,
        'inserted': 9007199254740992,
        'reportedTimezone': 'UTC',
        'requestedLocalDate': '2024-02-29',
      });
      row = (await history.loadReceipts()).receipts.single;
      expect(row.recordsInserted, isNull);
      expect(row.reportedTimezone, 'UTC');
      expect(row.requestedLocalDate, '2024-02-29');
    },
  );

  test(
    'Demo identity is explicit and unidentified stores fail closed',
    () async {
      final demo = VueniverseDatabase.forTesting(NativeDatabase.memory());
      final unknown = VueniverseDatabase.forTesting(NativeDatabase.memory());
      try {
        await demo.initialize(kind: StoreKind.demo);
        expect(
          (await CollectionHistoryRepository(demo).loadCoverage()).storeKind,
          StoreKind.demo,
        );
        expect(
          (await CollectionHistoryRepository(demo).loadReceipts()).storeKind,
          StoreKind.demo,
        );
        await expectLater(
          CollectionHistoryRepository(unknown).loadCoverage(),
          throwsStateError,
        );
      } finally {
        await demo.close();
        await unknown.close();
      }
    },
  );
}
