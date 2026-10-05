import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/observe/observe_dashboard_repository.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/sources/manual_checkin_repository.dart';
import 'package:vueniverse/data/sources/source_platform_gateway.dart';
import 'package:vueniverse/data/sources/source_repository.dart';
import 'package:vueniverse/data/sources/source_sync_service.dart';
import 'package:vueniverse/data/sources/ultrahuman_client.dart';
import 'package:vueniverse/data/sources/ultrahuman_import_service.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 4, 12);
  late VueniverseDatabase database;
  late CanonicalRecordRepository canonical;
  late SourceRepository sources;
  late ManualCheckinRepository manual;
  late SourceSyncService sync;
  setUp(() async {
    database = VueniverseDatabase.forTesting(NativeDatabase.memory());
    await database.initialize(kind: StoreKind.live);
    final normalizer = RecordNormalizer(
      identityKey: await database.getOrCreateSourceIdentityKey(),
    );
    canonical = CanonicalRecordRepository(database);
    sources = SourceRepository(database);
    await sources.initializeLiveSources();
    manual = ManualCheckinRepository(
      database: database,
      canonicalRecords: canonical,
      normalizer: normalizer,
      clock: () => now,
    );
    sync = SourceSyncService(
      platform: PigeonSourcePlatformGateway(),
      sources: sources,
      canonicalRecords: canonical,
      normalizer: normalizer,
      clock: () => now,
    );
  });
  tearDown(() => database.close());
  Future<void> seed() async {
    await manual.save(
      ManualCheckinRecord(
        id: 'fixture-manual',
        category: CheckinCategory.mood,
        occurredAt: now.subtract(const Duration(hours: 2)),
        detail: 'Protocol fixture',
      ),
    );
    await canonical.importRecords(
      sourceConnectionId: SourceIds.ultrahuman,
      sourceKind: SourceKind.ultrahuman,
      normalizer: RecordNormalizer(
        identityKey: await database.getOrCreateSourceIdentityKey(),
      ),
      syncRunId: 'fixture-health',
      records: [
        SourceRecordEnvelope(
          source: SourceKind.ultrahuman,
          recordType: 'heart_rate',
          observedAt: now,
          stableSourceId: 'fixture-heart',
          payload: {
            'timestamp': now
                .subtract(const Duration(hours: 1))
                .toIso8601String(),
            'offset_minutes': 0,
            'value': 72,
            'unit': 'bpm',
          },
        ),
      ],
    );
  }

  Future<List<CheckInData>> loadCheckins() async => [
    for (final row in await manual.load())
      CheckInData(
        id: row.id,
        when: row.occurredAt,
        context: 'Mood',
        detail: row.detail,
        category: row.category.name,
        icon: Icons.mood,
      ),
  ];
  Future<ObserveDashboardData> loadObserve() =>
      ObserveDashboardRepository(database).load(asOf: now, isDemo: false);
  Future<List<SourceData>> loadSources() async => [
    for (final row in await sources.loadStates())
      SourceData(
        id: row.id,
        name: row.sourceType,
        description: 'Protocol source',
        contribution: 'Protocol source',
        icon: Icons.device_hub,
        status: SourceStatus.connectedData,
        tier: FeatureTier.core,
        recordCount: row.recordCount,
      ),
  ];

  for (final target in ['checkins', SourceIds.ultrahuman]) {
    test(
      'committed $target deletion is acknowledged when analysis fails',
      () async {
        await seed();
        var fail = true;
        var reminderReconciliations = 0;
        final state = VueniverseState(
          initialMode: AppMode.live,
          initialCheckIns: await loadCheckins(),
          initialObserveDashboard: await loadObserve(),
          initialFinding: _finding(now),
          initialReplay: _replay,
          onSourceAction: (id, action) async {
            expect(action, SourceAction.deleteData);
            await sync.deleteSourceData(
              id == 'checkins' ? SourceIds.manual : id,
            );
          },
          onSourcesReload: loadSources,
          onCheckInsReload: loadCheckins,
          onEvidenceRecompute: () async {
            try {
              if (fail) throw StateError('private analysis diagnostic');
              await MeetingAnalysisRepository(database).runPending();
            } finally {
              reminderReconciliations++;
            }
          },
          onObserveReload: loadObserve,
          onFindingReload: () async => null,
        );
        addTearDown(state.dispose);
        state.currentExplanation = ExplanationData(
          summary: 'Old fixture',
          paragraphs: [],
          uncertainty: 'Fixture',
          runtimeLabel: 'Fixture',
          deterministicFallback: true,
          fromCache: true,
          createdAt: now,
        );
        state.chatMessages.add(
          const ChatMessageData(text: 'Old fixture', fromUser: false),
        );
        expect(state.observeDashboard.totalRecordCount, 2);
        expect(
          await state.performSourceAction(target, SourceAction.deleteData),
          isTrue,
        );
        expect(
          (await sources.loadState(
            target == 'checkins' ? SourceIds.manual : target,
          ))!.recordCount,
          0,
        );
        expect((await manual.load()).length, target == 'checkins' ? 0 : 1);
        expect(state.checkIns.length, target == 'checkins' ? 0 : 1);
        expect(state.finding, isNull);
        expect(state.replay, isNull);
        expect(state.currentExplanation, isNull);
        expect(state.chatMessages, isEmpty);
        expect(state.observeDashboard.totalRecordCount, 0);
        expect(
          state.sourceOperationMessage,
          startsWith('Source data deleted.'),
        );
        expect(state.sourceOperationMessage, isNot(contains('private')));
        expect(state.checkInRefreshMessage, contains('saved'));
        expect(reminderReconciliations, 1);
        fail = false;
        await state.retryCheckInRefresh();
        expect(state.observeDashboard.totalRecordCount, 1);
        expect(state.checkInRefreshMessage, isNull);
        expect(reminderReconciliations, 2);
        expect(state.sourceOperationInProgress, isFalse);
      },
    );
  }
  test('source storage failure never claims committed deletion', () async {
    await seed();
    final state = VueniverseState(
      initialMode: AppMode.live,
      initialCheckIns: await loadCheckins(),
      initialObserveDashboard: await loadObserve(),
      initialFinding: _finding(now),
      onSourceAction: (_, _) async {
        throw StateError('storage failure');
      },
      onSourcesReload: loadSources,
      onCheckInsReload: loadCheckins,
    );
    addTearDown(state.dispose);
    expect(
      await state.performSourceAction('checkins', SourceAction.deleteData),
      isFalse,
    );
    expect((await manual.load()), hasLength(1));
    expect(state.checkIns, hasLength(1));
    expect(state.sourceOperationMessage, contains('did not finish'));
    expect(state.sourceOperationMessage, isNot(contains('deleted')));
    expect(state.finding, isNull);
    expect(state.observeDashboard.totalRecordCount, 0);
  });
  test(
    'pause during real pending import prevents late persistence and keeps honest UI state',
    () async {
      final transport = _BlockedTransport();
      final importer = UltrahumanImportService(
        database,
        client: UltrahumanClient(transport: transport),
        clock: () => now,
      );
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialCheckIns: [],
        onUltrahumanImport: (token, days, endDate) => importer.importRecentDays(
          token: token,
          days: days,
          endDate: endDate,
        ),
        onSourceAction: (id, action) async {
          expect(action, SourceAction.pause);
          await sync.pause(id);
        },
        onSourcesReload: loadSources,
        onCheckInsReload: loadCheckins,
        onEvidenceRecompute: () async {},
        onObserveReload: loadObserve,
        onFindingReload: () async => null,
      );
      addTearDown(state.dispose);
      final pending = state.importUltrahuman(
        'private-test-token',
        1,
        '2026-10-04',
      );
      await transport.started.future;
      expect(state.ultrahumanImportInProgress, isTrue);
      expect(state.canPerformSourceAction(SourceAction.pause), isTrue);
      expect(state.canPerformSourceAction(SourceAction.disconnect), isTrue);
      expect(state.canPerformSourceAction(SourceAction.deleteData), isTrue);
      expect(state.canPerformSourceAction(SourceAction.refresh), isFalse);
      expect(
        await state.performSourceAction(
          SourceIds.ultrahuman,
          SourceAction.pause,
        ),
        isTrue,
      );
      expect(state.sourceOperationInProgress, isTrue);
      expect(state.canPerformSourceAction(SourceAction.resume), isFalse);
      transport.release.complete();
      expect(await pending, isFalse);
      expect(await database.select(database.signalSamples).get(), isEmpty);
      expect((await sources.loadState(SourceIds.ultrahuman))!.status, 'paused');
      expect(state.sourceOperationMessage, startsWith('Source paused.'));
      expect(state.sourceOperationInProgress, isFalse);
    },
  );
  test(
    'a source action and manual mutation cannot overlap another source action',
    () async {
      final release = Completer<void>();
      var actions = 0;
      var writes = 0;
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialCheckIns: [],
        onSourceAction: (_, _) {
          actions++;
          return release.future;
        },
        onCheckInSaved: (_) async {
          writes++;
        },
      );
      addTearDown(state.dispose);
      final pending = state.performSourceAction(
        SourceIds.ultrahuman,
        SourceAction.pause,
      );
      expect(
        await state.performSourceAction(
          SourceIds.ultrahuman,
          SourceAction.deleteData,
        ),
        isFalse,
      );
      await expectLater(
        state.addCheckIn(
          CheckInData(
            id: 'blocked',
            when: now,
            context: 'Mood',
            detail: 'Protocol',
            icon: Icons.mood,
            category: 'mood',
          ),
        ),
        throwsStateError,
      );
      expect(actions, 1);
      expect(writes, 0);
      release.complete();
      expect(await pending, isTrue);
    },
  );
  for (final dashboardFails in [false, true]) {
    test(
      'partial import hides prior answers; dashboard failure=$dashboardFails',
      () async {
        await seed();
        final release = Completer<void>();
        var reconciliations = 0;
        final state = VueniverseState(
          initialMode: AppMode.live,
          initialCheckIns: await loadCheckins(),
          initialObserveDashboard: await loadObserve(),
          initialFinding: _finding(now),
          initialReplay: _replay,
          onUltrahumanImport: (_, _, _) async {
            await release.future;
            await canonical.importRecords(
              sourceConnectionId: SourceIds.ultrahuman,
              sourceKind: SourceKind.ultrahuman,
              normalizer: RecordNormalizer(
                identityKey: await database.getOrCreateSourceIdentityKey(),
              ),
              syncRunId: 'partial-day',
              records: [
                SourceRecordEnvelope(
                  source: SourceKind.ultrahuman,
                  recordType: 'heart_rate',
                  observedAt: now,
                  stableSourceId: 'partial-heart',
                  payload: {
                    'timestamp': now.toIso8601String(),
                    'offset_minutes': 0,
                    'value': 75,
                    'unit': 'bpm',
                  },
                ),
              ],
            );
            throw StateError('next provider day failed');
          },
          onEvidenceRecompute: () async {
            reconciliations++;
          },
          onSourcesReload: loadSources,
          onCheckInsReload: loadCheckins,
          onObserveReload: () async {
            if (dashboardFails) throw StateError('read failed');
            return loadObserve();
          },
          onFindingReload: () async => _finding(now),
        );
        addTearDown(state.dispose);
        state.currentExplanation = ExplanationData(
          summary: 'Old answer',
          paragraphs: [],
          uncertainty: 'Fixture',
          runtimeLabel: 'Fixture',
          deterministicFallback: true,
          fromCache: true,
          createdAt: now,
        );
        state.chatMessages.add(
          const ChatMessageData(text: 'Old answer', fromUser: false),
        );
        final pending = state.importUltrahuman(
          'private-test-token',
          7,
          '2026-10-04',
        );
        expect(state.finding, isNull);
        expect(state.currentExplanation, isNull);
        release.complete();
        expect(await pending, isFalse);
        expect(
          await database.select(database.signalSamples).get(),
          hasLength(2),
        );
        expect(state.finding, isNull);
        expect(state.replay, isNull);
        expect(state.currentExplanation, isNull);
        expect(state.chatMessages, isEmpty);
        expect(state.observeDashboard.totalRecordCount, dashboardFails ? 0 : 3);
        expect(
          state.sourceOperationMessage,
          startsWith('Import did not complete.'),
        );
        expect(reconciliations, 1);
      },
    );
  }
  test(
    'committed source action reconciles reminders before a collection read failure',
    () async {
      await seed();
      var reconciliations = 0;
      final state = VueniverseState(
        initialMode: AppMode.live,
        onSourceAction: (id, _) => sync.deleteSourceData(id),
        onSourcesReload: () async {
          throw StateError('read failed');
        },
        onEvidenceRecompute: () async {
          reconciliations++;
        },
      );
      addTearDown(state.dispose);
      expect(
        await state.performSourceAction(
          SourceIds.ultrahuman,
          SourceAction.deleteData,
        ),
        isTrue,
      );
      expect(reconciliations, 1);
      expect(await database.select(database.signalSamples).get(), isEmpty);
      expect(state.sourceOperationMessage, startsWith('Source data deleted.'));
    },
  );
  test(
    'an older finding reload cannot restore evidence after import begins',
    () async {
      final oldFinding = Completer<FindingData?>();
      final importRelease = Completer<void>();
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialFinding: _finding(now),
        onFindingReload: () => oldFinding.future,
        onUltrahumanImport: (_, _, _) async {
          await importRelease.future;
          throw StateError('collection failed');
        },
      );
      addTearDown(state.dispose);
      final oldRefresh = state.refreshFinding();
      final importing = state.importUltrahuman(
        'private-test-token',
        1,
        '2026-10-04',
      );
      oldFinding.complete(_finding(now));
      await oldRefresh;
      expect(state.finding, isNull);
      importRelease.complete();
      expect(await importing, isFalse);
      expect(state.finding, isNull);
    },
  );
  test(
    'partial manual source deletion never restores cached text after failed reads',
    () async {
      await seed();
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialCheckIns: await loadCheckins(),
        initialObserveDashboard: await loadObserve(),
        onSourceAction: (_, _) async {
          await sources.advanceCollectionGeneration(
            SourceIds.manual,
            'deleting',
          );
          await canonical.deleteAllForSource(
            sourceConnectionId: SourceIds.manual,
            reason: 'source_data_deleted',
          );
          throw StateError('clear source state failed');
        },
        onCheckInsReload: () async {
          throw StateError('read failed');
        },
      );
      addTearDown(state.dispose);
      expect(
        await state.performSourceAction('checkins', SourceAction.deleteData),
        isFalse,
      );
      expect(await manual.load(), isEmpty);
      expect(state.checkIns, isEmpty);
      expect(state.observeDashboard.totalRecordCount, 0);
      expect(state.sourceOperationMessage, contains('did not finish'));
      expect(
        state.sourceOperationMessage,
        isNot(contains('Source data deleted.')),
      );
    },
  );
  test(
    'Ultrahuman resume lifts pause without keyless refresh or newer data claim',
    () async {
      await seed();
      await sources.markSyncComplete(SourceIds.ultrahuman);
      await sync.pause(SourceIds.ultrahuman);
      final before = (await sources.loadState(SourceIds.ultrahuman))!;
      final state = VueniverseState(
        initialMode: AppMode.live,
        onSourceAction: (id, action) async {
          expect(action, SourceAction.resume);
          await sync.resume(id);
        },
        onSourcesReload: loadSources,
      );
      addTearDown(state.dispose);
      expect(
        await state.performSourceAction(
          SourceIds.ultrahuman,
          SourceAction.resume,
        ),
        isTrue,
      );
      final after = (await sources.loadState(SourceIds.ultrahuman))!;
      expect(after.status, 'stale');
      expect(after.recordCount, before.recordCount);
      expect(
        after.configuration['lastSyncUtc'],
        before.configuration['lastSyncUtc'],
      );
      expect(
        after.configuration['collectionGeneration'],
        (before.configuration['collectionGeneration'] as int) + 1,
      );
      expect(
        state.sourceOperationMessage,
        contains('Enter your API key to import'),
      );
      expect(state.sourceOperationMessage, isNot(contains('could not')));
    },
  );
  for (final operation in ['edit', 'delete']) {
    test(
      'committed manual $operation removes obsolete Observe aggregates when recompute fails',
      () async {
        await seed();
        final entries = await loadCheckins();
        final state = VueniverseState(
          initialMode: AppMode.live,
          initialCheckIns: entries,
          initialObserveDashboard: await loadObserve(),
          onCheckInSaved: (entry) => manual.save(
            ManualCheckinRecord(
              id: entry.id,
              category: CheckinCategory.mood,
              occurredAt: entry.when,
              detail: entry.detail,
            ),
          ),
          onCheckInDeleted: (id) async {
            await manual.delete(id);
          },
          onEvidenceRecompute: () async {
            throw StateError('analysis failed');
          },
        );
        addTearDown(state.dispose);
        expect(state.observeDashboard.checkInRecords, 1);
        expect(state.observeDashboard.recentActivity, isNotEmpty);
        if (operation == 'delete') {
          await state.deleteCheckIn(entries.single.id);
          expect(await manual.load(), isEmpty);
        } else {
          final original = entries.single;
          await state.editCheckIn(
            CheckInData(
              id: original.id,
              when: original.when,
              context: original.context,
              detail: 'Updated fixture',
              icon: original.icon,
              category: original.category,
            ),
          );
          expect((await manual.load()).single.detail, 'Updated fixture');
        }
        expect(state.observeDashboard.totalRecordCount, 0);
        expect(state.observeDashboard.recentActivity, isEmpty);
        expect(
          state.observeDashboard.days.every(
            (day) => day.checkInCount == 0 && day.eventCount == 0,
          ),
          isTrue,
        );
        expect(state.checkInRefreshMessage, contains('saved'));
      },
    );
  }
}

FindingData _finding(DateTime now) => FindingData(
  status: 'supported',
  title: 'Fixture',
  evidenceHash: 'fixture',
  evidenceVersion: 'fixture',
  candidateCount: 4,
  includedCount: 4,
  controlsCount: 4,
  positiveCount: 4,
  counterevidenceCount: 0,
  medianDifferenceBpm: 10,
  effectLowerBpm: 10,
  effectUpperBpm: 10,
  completeness: 1,
  recoveryDurationMinutes: 1,
  unresolvedInfluenceCount: 0,
  createdAt: now,
);
const _replay = MomentReplayData(
  phases: ['Before', 'During'],
  traces: [],
  matchedBaselineBpm: [70, 80],
  sourceLabel: 'Fixture',
);

class _BlockedTransport implements UltrahumanTransport {
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<UltrahumanHttpResponse> get({
    required Uri uri,
    required String authorization,
    required Duration timeout,
    required int maxResponseBytes,
  }) async {
    started.complete();
    await release.future;
    final date = uri.queryParameters['date']!;
    return UltrahumanHttpResponse(
      statusCode: 200,
      bytes: utf8.encode(
        jsonEncode({
          'status': 200,
          'error': null,
          'data': {
            'latest_time_zone': 'UTC',
            'metrics': {
              date: [
                {
                  'type': 'hr',
                  'object': {
                    'unit': 'BPM',
                    'values': [
                      {
                        'value': 72,
                        'timestamp':
                            DateTime.parse(
                              '${date}T09:00:00Z',
                            ).millisecondsSinceEpoch ~/
                            1000,
                      },
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
