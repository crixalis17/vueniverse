import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/sources/collection_history_repository.dart';
import 'package:vueniverse/data/sources/manual_checkin_repository.dart';
import 'package:vueniverse/data/sources/source_platform_gateway.dart';
import 'package:vueniverse/data/sources/source_repository.dart';
import 'package:vueniverse/data/sources/source_sync_service.dart';
import 'package:vueniverse/data/sources/ultrahuman_client.dart';
import 'package:vueniverse/data/sources/ultrahuman_import_service.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/platform_security_api.g.dart';

/// Service-level Android persistence, not live API, keyboard or cold-start proof.
/// Deletes only the disposable emulator's Live store before and after this test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('VUENIVERSE_DISPOSABLE_EMULATOR') ||
      !const bool.fromEnvironment('ALLOW_DESTRUCTIVE_STORE_TESTS')) {
    testWidgets(
      'mocked encrypted collection requires both disposable-copy opt-ins',
      (_) async {},
      skip: true,
    );
    return;
  }

  testWidgets(
    'encrypted mocked HR and sleep survive explicit resume and source deletion preserves manual data',
    (_) async {
      expect(Platform.isAndroid, isTrue);
      final qemu = await Process.run('/system/bin/getprop', ['ro.kernel.qemu']);
      expect(qemu.exitCode, 0);
      expect(
        '${qemu.stdout}'.trim(),
        '1',
        reason: 'Refuse destructive collection tests on a physical phone.',
      );
      final security = PlatformSecurityApi();
      VueniverseDatabase? activeDatabase;
      addTearDown(() async {
        await activeDatabase?.close();
        await security.deleteStore(SecureStoreKind.live);
      });
      await security.deleteStore(SecureStoreKind.live);
      final material = await security.openStore(SecureStoreKind.live);
      var database = VueniverseDatabase.encrypted(
        path: material.databasePath,
        passphrase: material.passphrase,
      );
      activeDatabase = database;
      await database.initialize(kind: StoreKind.live);
      final now = DateTime.utc(2026, 10, 5, 18);
      final normalizer = RecordNormalizer(
        identityKey: await database.getOrCreateSourceIdentityKey(),
      );
      final manual = ManualCheckinRepository(
        database: database,
        canonicalRecords: CanonicalRecordRepository(database),
        normalizer: normalizer,
        clock: () => now,
      );
      await manual.save(
        ManualCheckinRecord(
          id: 'disposable-collection-mood',
          category: CheckinCategory.mood,
          occurredAt: now,
          detail: 'Bundled fixture report, not owner data',
        ),
      );

      final transport = _FixtureTransport();
      final importer = UltrahumanImportService(
        database,
        client: UltrahumanClient(transport: transport),
        clock: () => now,
      );
      Future<void> explicitImport() => importer.importRecentDays(
        token: 'fixture-only-token',
        days: 1,
        endDate: '2026-10-03',
      );
      await explicitImport();
      await explicitImport();
      var history = CollectionHistoryRepository(database);
      var receipts = (await history.loadReceipts()).receipts
          .where((row) => row.sourceConnectionId == SourceIds.ultrahuman)
          .toList();
      expect(receipts, hasLength(2));
      expect(receipts.map((row) => row.recordsSeen), everyElement(3));
      expect(receipts.map((row) => row.recordsAccepted), everyElement(3));
      expect(receipts.map((row) => row.recordsRejected), everyElement(0));
      expect(receipts.map((row) => row.recordsInserted), containsAll([3, 0]));
      expect(receipts.map((row) => row.recordsDuplicate), containsAll([0, 3]));
      expect((await history.loadCoverage()).retainedRecords, 4);
      expect(
        (await database.select(database.signalSamples).get()).single.value,
        72,
      );
      expect(
        await database.select(database.healthIntervals).get(),
        hasLength(2),
      );
      expect(await database.select(database.contextEvents).get(), isEmpty);

      final platform = _RejectNativeSourceCalls();
      final sync = SourceSyncService(
        platform: platform,
        sources: SourceRepository(database),
        canonicalRecords: CanonicalRecordRepository(database),
        normalizer: normalizer,
        clock: () => now,
      );
      await sync.pause(SourceIds.ultrahuman);
      await expectLater(explicitImport(), throwsA(isA<UltrahumanException>()));
      expect(
        transport.calls,
        2,
        reason: 'Pause rejects before mocked transport.',
      );
      await sync.resume(SourceIds.ultrahuman);
      expect(
        transport.calls,
        2,
        reason: 'Resume must not perform keyless import.',
      );
      expect(platform.calls, 0);
      expect(
        (await SourceRepository(
          database,
        ).loadState(SourceIds.ultrahuman))!.status,
        'stale',
      );
      await explicitImport();
      expect(transport.calls, 3);
      expect((await history.loadCoverage()).retainedRecords, 4);
      expect(
        (await SourceRepository(
          database,
        ).loadState(SourceIds.ultrahuman))!.status,
        'connected_data',
      );
      expect(
        jsonEncode(
          (await SourceRepository(
            database,
          ).loadState(SourceIds.ultrahuman))!.configuration,
        ),
        isNot(contains('fixture-only-token')),
      );

      // A successful empty mocked day cannot invent or replace measurements.
      transport.empty = true;
      await explicitImport();
      expect(transport.calls, 4);
      expect((await history.loadCoverage()).retainedRecords, 4);
      receipts = (await history.loadReceipts()).receipts
          .where((row) => row.sourceConnectionId == SourceIds.ultrahuman)
          .toList();
      expect(receipts, hasLength(4));
      expect(receipts.where((row) => row.recordsAccepted == 0), hasLength(1));

      await database.close();
      activeDatabase = null;
      final header = await File(material.databasePath)
          .openRead(0, 16)
          .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
      expect(String.fromCharCodes(header), isNot('SQLite format 3\u0000'));
      final reopened = await security.openStore(SecureStoreKind.live);
      expect(
        reopened.passphrase == material.passphrase,
        isTrue,
        reason: 'Reopening must retain the disposable Live store key.',
      );
      database = VueniverseDatabase.encrypted(
        path: reopened.databasePath,
        passphrase: reopened.passphrase,
      );
      activeDatabase = database;
      await database.initialize(kind: StoreKind.live);
      history = CollectionHistoryRepository(database);
      expect((await history.loadCoverage()).retainedRecords, 4);
      expect(await database.select(database.signalSamples).get(), hasLength(1));
      expect(
        await database.select(database.healthIntervals).get(),
        hasLength(2),
      );
      final reopenedNormalizer = RecordNormalizer(
        identityKey: await database.getOrCreateSourceIdentityKey(),
      );
      final reopenedManual = ManualCheckinRepository(
        database: database,
        canonicalRecords: CanonicalRecordRepository(database),
        normalizer: reopenedNormalizer,
      );
      expect(
        (await reopenedManual.load()).single.id,
        'disposable-collection-mood',
      );
      final reopenedSync = SourceSyncService(
        platform: platform,
        sources: SourceRepository(database),
        canonicalRecords: CanonicalRecordRepository(database),
        normalizer: reopenedNormalizer,
      );
      await reopenedSync.deleteSourceData(SourceIds.ultrahuman);
      expect((await history.loadCoverage()).retainedRecords, 1);
      expect(await database.select(database.signalSamples).get(), isEmpty);
      expect(await database.select(database.healthIntervals).get(), isEmpty);
      expect(
        (await reopenedManual.load()).single.id,
        'disposable-collection-mood',
      );
      final deletion = (await history.loadReceipts()).receipts.singleWhere(
        (row) =>
            row.kind == 'deletion' &&
            row.sourceConnectionId == SourceIds.ultrahuman,
      );
      expect(deletion.recordsDeleted, 3);
      expect(
        (await SourceRepository(
          database,
        ).loadState(SourceIds.ultrahuman))!.status,
        'disconnected',
      );
      expect(
        (await SourceRepository(
          database,
        ).loadState(SourceIds.ultrahuman))!.configuration['credentialBinding'],
        isNull,
      );
      expect(platform.calls, 0);
    },
  );
}

final class _RejectNativeSourceCalls implements SourcePlatformGateway {
  int calls = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError(
      'No native health/calendar source access in fixture test.',
    );
  }
}

final class _FixtureTransport implements UltrahumanTransport {
  int calls = 0;
  bool empty = false;
  @override
  Future<UltrahumanHttpResponse> get({
    required Uri uri,
    required String authorization,
    required Duration timeout,
    required int maxResponseBytes,
  }) async {
    calls++;
    final date = uri.queryParameters['date']!;
    final sleepStart =
        DateTime.parse('${date}T00:00:00Z').millisecondsSinceEpoch ~/ 1000;
    final hrTime =
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
              date: empty
                  ? <Object?>[]
                  : [
                      {
                        'type': 'hr',
                        'object': {
                          'unit': 'BPM',
                          'values': [
                            {'timestamp': hrTime, 'value': 72},
                          ],
                        },
                      },
                      {
                        'type': 'sleep',
                        'object': {
                          'sleep_graph': {
                            'data': [
                              {
                                'start': sleepStart,
                                'end': sleepStart + 3600,
                                'type': 'deep_sleep',
                              },
                              {
                                'start': sleepStart + 3600,
                                'end': sleepStart + 7200,
                                'type': 'light_sleep',
                              },
                            ],
                          },
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
