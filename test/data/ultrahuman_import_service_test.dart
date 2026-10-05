import 'dart:async';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/sources/collection_history_repository.dart';
import 'package:vueniverse/data/sources/source_repository.dart';
import 'package:vueniverse/data/sources/ultrahuman_client.dart';
import 'package:vueniverse/data/sources/ultrahuman_import_service.dart';
import 'package:vueniverse/domain/store_kind.dart';

void main() {
  late VueniverseDatabase database;
  late _Transport transport;
  late UltrahumanImportService importer;
  setUp(() async {
    database = VueniverseDatabase.forTesting(NativeDatabase.memory());
    await database.initialize(kind: StoreKind.live);
    transport = _Transport();
    importer = UltrahumanImportService(
      database,
      client: UltrahumanClient(transport: transport),
      clock: () => DateTime.utc(2026, 10, 3, 18),
    );
  });
  tearDown(() => database.close());
  test(
    'repeat import retains one actual observation and separate receipts, no credential',
    () async {
      await importer.importRecentDays(token: 'private-test-token', days: 1);
      await importer.importRecentDays(token: 'private-test-token', days: 1);
      final coverage = await CollectionHistoryRepository(
        database,
      ).loadCoverage();
      expect(coverage.retainedRecords, 1);
      expect(coverage.groups.single.sourceConnectionId, SourceIds.ultrahuman);
      final history = await CollectionHistoryRepository(
        database,
      ).loadReceipts();
      expect(history.receipts, hasLength(2));
      expect(
        history.receipts.map((row) => row.recordsAccepted),
        everyElement(1),
      );
      final source = (await SourceRepository(
        database,
      ).loadState(SourceIds.ultrahuman))!;
      expect(
        jsonEncode(source.configuration),
        isNot(contains('private-test-token')),
      );
      expect(source.configuration['credentialBinding'], isNotNull);
      expect(source.status, 'connected_data');
      final sample =
          (await database.select(database.signalSamples).get()).single;
      expect(sample.value, 72);
      expect(sample.originalOffsetMinutes, 330);
    },
  );
  test(
    'failure preserves successful days and records a redacted failed receipt',
    () async {
      transport.failAt = 3;
      await expectLater(
        importer.importRecentDays(token: 'private-test-token', days: 7),
        throwsA(isA<UltrahumanException>()),
      );
      final history = await CollectionHistoryRepository(
        database,
      ).loadReceipts();
      expect(history.receipts, hasLength(3));
      expect(history.receipts.where((row) => row.hasError), hasLength(1));
      expect(
        (await CollectionHistoryRepository(
          database,
        ).loadCoverage()).retainedRecords,
        2,
      );
      final runs = await database.select(database.syncRuns).get();
      expect(
        runs.where((row) => row.status == 'failed').single.errorCode,
        'authorization_failed',
      );
      expect(
        runs.map((row) => row.errorDetails).join(),
        isNot(contains('secret-body')),
      );
    },
  );
  test('different credential cannot silently merge users', () async {
    await importer.importRecentDays(token: 'private-test-token', days: 1);
    await expectLater(
      importer.importRecentDays(token: 'other-token', days: 1),
      throwsA(isA<UltrahumanException>()),
    );
    expect(transport.calls, 1);
    expect((await database.select(database.signalSamples).get()).length, 1);
    final state = (await SourceRepository(
      database,
    ).loadState(SourceIds.ultrahuman))!;
    expect(state.status, 'error');
    expect(state.configuration['lastErrorCode'], 'credential_changed');
  });
  for (final status in ['paused', 'disconnected', 'deleting']) {
    test(
      '$status before initial claim cannot be overwritten by syncing',
      () async {
        final barrier = _BarrierDatabase();
        addTearDown(barrier.close);
        await barrier.initialize(kind: StoreKind.live);
        barrier.blockIdentity = true;
        final pending = UltrahumanImportService(
          barrier,
          client: UltrahumanClient(transport: transport),
          clock: () => DateTime.utc(2026, 10, 3, 18),
        ).importRecentDays(token: 'private-test-token', days: 1);
        final rejected = expectLater(
          pending,
          throwsA(isA<UltrahumanException>()),
        );
        await barrier.identityStarted.future;
        await SourceRepository(
          barrier,
        ).advanceCollectionGeneration(SourceIds.ultrahuman, status);
        barrier.identityRelease.complete();
        await rejected;
        expect(
          (await SourceRepository(
            barrier,
          ).loadState(SourceIds.ultrahuman))!.status,
          status,
        );
        expect(transport.calls, 0);
        expect(await barrier.select(barrier.signalSamples).get(), isEmpty);
      },
    );
  }
  test(
    'network failure after pause preserves pause rather than setting error',
    () async {
      transport.failAt = 1;
      transport.beforeResponse = () => transport.release.future;
      final pending = importer.importRecentDays(
        token: 'private-test-token',
        days: 1,
      );
      final rejected = expectLater(
        pending,
        throwsA(isA<UltrahumanException>()),
      );
      await transport.started.future;
      await SourceRepository(
        database,
      ).advanceCollectionGeneration(SourceIds.ultrahuman, 'paused');
      transport.release.complete();
      await rejected;
      expect(
        (await SourceRepository(
          database,
        ).loadState(SourceIds.ultrahuman))!.status,
        'paused',
      );
      expect(await database.select(database.signalSamples).get(), isEmpty);
    },
  );
  test(
    'concurrent import is refused before it can mix credential owners',
    () async {
      transport.beforeResponse = () => transport.release.future;
      final first = importer.importRecentDays(
        token: 'private-test-token',
        days: 1,
      );
      await transport.started.future;
      await expectLater(
        UltrahumanImportService(
          database,
          client: UltrahumanClient(transport: transport),
        ).importRecentDays(token: 'other-token', days: 1),
        throwsA(isA<UltrahumanException>()),
      );
      transport.release.complete();
      await first;
      expect(transport.calls, 1);
    },
  );
  for (final status in ['paused', 'disconnected', 'deleting']) {
    test('$status during request prevents later repopulation', () async {
      transport.beforeResponse = () => transport.release.future;
      final first = importer.importRecentDays(
        token: 'private-test-token',
        days: 1,
      );
      final rejected = expectLater(first, throwsA(isA<UltrahumanException>()));
      await transport.started.future;
      await SourceRepository(
        database,
      ).advanceCollectionGeneration(SourceIds.ultrahuman, status);
      transport.release.complete();
      await rejected;
      expect(await database.select(database.signalSamples).get(), isEmpty);
      expect(
        (await SourceRepository(
          database,
        ).loadState(SourceIds.ultrahuman))!.status,
        status,
      );
    });
  }
  test(
    'explicit data deletion allows a new credential without merging history',
    () async {
      await importer.importRecentDays(token: 'private-test-token', days: 1);
      final sources = SourceRepository(database);
      await sources.advanceCollectionGeneration(
        SourceIds.ultrahuman,
        'deleting',
      );
      // The user explicitly chose source deletion; production uses this same path.
      await CanonicalRecordRepository(database).deleteAllForSource(
        sourceConnectionId: SourceIds.ultrahuman,
        reason: 'source_data_deleted',
      );
      await sources.clearSourceState(SourceIds.ultrahuman);
      await importer.importRecentDays(token: 'new-owner-token', days: 1);
      expect(
        (await database.select(database.signalSamples).get()),
        hasLength(1),
      );
      expect(
        (await CollectionHistoryRepository(
          database,
        ).loadReceipts()).receipts.where((row) => row.kind == 'deletion'),
        hasLength(1),
      );
    },
  );
  test(
    'invalid first authentication does not poison credential binding',
    () async {
      transport.failAt = 1;
      await expectLater(
        importer.importRecentDays(token: 'bad-token', days: 1),
        throwsA(isA<UltrahumanException>()),
      );
      expect(
        (await SourceRepository(
          database,
        ).loadState(SourceIds.ultrahuman))!.configuration['credentialBinding'],
        isNull,
      );
      transport.failAt = null;
      await importer.importRecentDays(token: 'correct-token', days: 1);
      expect(
        (await CollectionHistoryRepository(
          database,
        ).loadCoverage()).retainedRecords,
        1,
      );
    },
  );
  test(
    'mapping rejections remain visible alongside accepted records',
    () async {
      transport.includeBadRow = true;
      await importer.importRecentDays(token: 'private-test-token', days: 1);
      final receipt = (await CollectionHistoryRepository(
        database,
      ).loadReceipts()).receipts.single;
      expect(receipt.recordsSeen, 2);
      expect(receipt.recordsAccepted, 1);
      expect(receipt.recordsRejected, 1);
    },
  );
  test(
    'bounded import period and Demo isolation fail before transport',
    () async {
      await expectLater(
        importer.importRecentDays(token: 'private-test-token', days: 90),
        throwsArgumentError,
      );
      final demo = VueniverseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(demo.close);
      await demo.initialize(kind: StoreKind.demo);
      await expectLater(
        UltrahumanImportService(
          demo,
          client: UltrahumanClient(transport: transport),
        ).importRecentDays(token: 'private-test-token', days: 1),
        throwsStateError,
      );
      expect(transport.calls, 0);
    },
  );
  test(
    'explicit provider end date anchors each requested day and receipt',
    () async {
      await importer.importRecentDays(
        token: 'private-test-token',
        days: 7,
        endDate: '2026-09-30',
      );
      expect(transport.requestedDates, [
        '2026-09-24',
        '2026-09-25',
        '2026-09-26',
        '2026-09-27',
        '2026-09-28',
        '2026-09-29',
        '2026-09-30',
      ]);
      final source = (await SourceRepository(
        database,
      ).loadState(SourceIds.ultrahuman))!;
      expect(
        source.configuration['requestedDatePolicy'],
        'explicit_provider_daily_dates',
      );
      expect(source.configuration['requestedStartDate'], '2026-09-24');
      expect(source.configuration['requestedEndDate'], '2026-09-30');
      final runs = await database.select(database.syncRuns).get();
      expect(
        runs.map(
          (r) => (jsonDecode(r.errorDetails!) as Map)['requestedLocalDate'],
        ),
        unorderedEquals(transport.requestedDates),
      );
    },
  );
  test(
    'invalid and impossible provider ranges fail before any request',
    () async {
      for (final endDate in [
        '2026-02-30',
        '2026-10-05',
        '2026-10-03&email=someone',
        '2000-01-01',
      ]) {
        await expectLater(
          importer.importRecentDays(
            token: 'private-test-token',
            days: 7,
            endDate: endDate,
          ),
          throwsA(isA<UltrahumanException>()),
        );
      }
      expect(transport.calls, 0);
      expect(await database.select(database.syncRuns).get(), isEmpty);
    },
  );
  test(
    'legacy device date default is labeled unconfirmed, never provider-inferred',
    () async {
      await importer.importRecentDays(token: 'private-test-token', days: 1);
      final source = (await SourceRepository(
        database,
      ).loadState(SourceIds.ultrahuman))!;
      expect(
        source.configuration['requestedDatePolicy'],
        'device_date_default_provider_timezone_unconfirmed',
      );
    },
  );
}

class _BarrierDatabase extends VueniverseDatabase {
  _BarrierDatabase() : super(NativeDatabase.memory());
  bool blockIdentity = false;
  final identityStarted = Completer<void>();
  final identityRelease = Completer<void>();
  @override
  Future<List<int>> getOrCreateSourceIdentityKey() async {
    if (blockIdentity) {
      if (!identityStarted.isCompleted) identityStarted.complete();
      await identityRelease.future;
    }
    return super.getOrCreateSourceIdentityKey();
  }
}

class _Transport implements UltrahumanTransport {
  int calls = 0;
  int? failAt;
  bool includeBadRow = false;
  final requestedDates = <String>[];
  Future<void> Function()? beforeResponse;
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<UltrahumanHttpResponse> get({
    required Uri uri,
    required String authorization,
    required Duration timeout,
    required int maxResponseBytes,
  }) async {
    calls++;
    if (!started.isCompleted) started.complete();
    await beforeResponse?.call();
    if (calls == failAt) {
      return UltrahumanHttpResponse(
        statusCode: 401,
        bytes: utf8.encode('secret-body'),
      );
    }
    final date = uri.queryParameters['date']!;
    requestedDates.add(date);
    final timestamp =
        DateTime.parse('${date}T12:00:00Z').millisecondsSinceEpoch ~/ 1000;
    return UltrahumanHttpResponse(
      statusCode: 200,
      bytes: utf8.encode(
        jsonEncode({
          'status': 200,
          'error': null,
          'data': {
            'latest_time_zone': 'Asia/Kolkata',
            'metrics': {
              date: [
                {
                  'type': 'hr',
                  'object': {
                    'unit': 'BPM',
                    'values': [
                      {'timestamp': timestamp, 'value': 72},
                      if (includeBadRow)
                        {'timestamp': timestamp + 60, 'value': 'invalid'},
                    ],
                  },
                },
              ],
            },
          },
        }),
      ),
    );
  }
}
