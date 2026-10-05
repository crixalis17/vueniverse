import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/sources/collection_history_repository.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/domain/models/collection_history.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/features/source_collection_screens.dart';

void main() {
  testWidgets(
    'populated ledger renders safe counts/date metadata and paginates',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final db = VueniverseDatabase.forTesting(NativeDatabase.memory());
      await db.initialize(kind: StoreKind.live);
      addTearDown(db.close);
      final now = DateTime.utc(2026, 10, 3, 10);
      await db
          .into(db.sourceConnections)
          .insert(
            SourceConnectionsCompanion.insert(
              id: 'ultrahuman',
              sourceType: 'ultrahuman',
              status: 'connected_data',
            ),
          );
      await db
          .into(db.signalSamples)
          .insert(
            SignalSamplesCompanion.insert(
              id: 'synthetic-sample',
              signalType: 'heartRate',
              occurredAtUtc: now,
              value: 70,
              unit: 'bpm',
              originalOffsetMinutes: 330,
              originalLocalDate: '2026-10-03',
              provenanceJson: '{}',
              canonicalPayloadHash: 'synthetic-hash',
            ),
          );
      await db
          .into(db.rawRecordIndex)
          .insert(
            RawRecordIndexCompanion.insert(
              id: 'synthetic-index',
              sourceConnectionId: 'ultrahuman',
              sourceKind: 'ultrahuman',
              canonicalPayloadHash: 'synthetic-hash',
              canonicalKind: 'signal_sample',
              canonicalId: 'synthetic-sample',
              occurredAtUtc: now,
            ),
          );
      for (var i = 0; i < 3; i++) {
        await db
            .into(db.syncRuns)
            .insert(
              SyncRunsCompanion.insert(
                id: 'receipt-$i',
                sourceConnectionId: 'ultrahuman',
                status: 'completed',
                startedAt: now.subtract(Duration(days: i)),
                recordsSeen: const Value(13),
                recordsAccepted: const Value(10),
                recordsRejected: const Value(3),
                errorDetails: Value(
                  jsonEncode({
                    'receipt_schema': 1,
                    'inserted': 6,
                    'changed': 1,
                    'duplicates': 3,
                    'reportedTimezone': 'Asia/Kolkata',
                    'requestedLocalDate': '2026-10-03',
                    'rejections': {
                      'malformed_time': 1,
                      'impossible_value': 1,
                      'PRIVATE JOURNAL AND TOKEN SHOULD NEVER RENDER': 1,
                    },
                  }),
                ),
              ),
            );
      }
      final repository = CollectionHistoryRepository(db);
      final cursors = <CollectionHistoryCursor?>[];
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialOnboarded: true,
        onCollectionRequested: (cursor) async {
          cursors.add(cursor);
          return (
            coverage: await repository.loadCoverage(),
            history: await repository.loadReceipts(limit: 2, before: cursor),
          );
        },
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: VueniverseScope(
            state: state,
            child: const CollectionHistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('LIVE · 1 retained records'), findsOneWidget);
      expect(find.text('ultrahuman · heartRate'), findsOneWidget);
      expect(
        find.textContaining('6 new · 1 updated · 3 repeats'),
        findsNWidgets(2),
      );
      expect(
        find.textContaining('API day 2026-10-03 · Asia/Kolkata'),
        findsNWidgets(2),
      );
      expect(find.textContaining('other_rejection: 1'), findsNWidgets(2));
      expect(find.textContaining('PRIVATE JOURNAL'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Load older activity'), 250);
      await tester.tap(find.text('Load older activity'));
      await tester.pumpAndSettle();
      expect(cursors, hasLength(2));
      expect(cursors.last?.id, 'receipt-1');
      expect(
        find.textContaining('6 new · 1 updated · 3 repeats'),
        findsNWidgets(3),
      );
      expect(find.text('Load older activity'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'malformed and absent ledger counters render unknown, never null or invented zero',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 920));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final db = VueniverseDatabase.forTesting(NativeDatabase.memory());
      await db.initialize(kind: StoreKind.live);
      addTearDown(db.close);
      final now = DateTime.utc(2026, 10, 3, 10);
      await db
          .into(db.sourceConnections)
          .insert(
            SourceConnectionsCompanion.insert(
              id: 'ultrahuman',
              sourceType: 'ultrahuman',
              status: 'connected_data',
            ),
          );
      await db
          .into(db.syncRuns)
          .insert(
            SyncRunsCompanion.insert(
              id: 'malformed-counters',
              sourceConnectionId: 'ultrahuman',
              status: 'completed',
              startedAt: now,
              recordsSeen: const Value(5),
              recordsAccepted: const Value(5),
              errorDetails: Value(
                jsonEncode({
                  'receipt_schema': 1,
                  'inserted': 5,
                  'changed': 'private error text',
                  'duplicates': -1,
                  'rejections': {},
                }),
              ),
            ),
          );
      final repository = CollectionHistoryRepository(db);
      final parsed = (await repository.loadReceipts()).receipts.single;
      final unknown = CollectionReceipt(
        id: 'unknown',
        kind: 'sync',
        sourceConnectionId: 'local',
        status: 'failed',
        recordedAtUtc: now,
        finishedAtUtc: null,
        recordsSeen: null,
        recordsAccepted: null,
        recordsRejected: null,
        recordsDeleted: null,
        rejectionReasons: const {},
        hasError: true,
        deletionReason: null,
      );
      final state = VueniverseState(
        initialMode: AppMode.live,
        onCollectionRequested: (_) async => (
          coverage: await repository.loadCoverage(),
          history: CollectionHistoryPage(
            storeKind: StoreKind.live,
            receipts: [parsed, unknown],
            nextCursor: null,
          ),
        ),
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: VueniverseScope(
            state: state,
            child: const CollectionHistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('5 new · unknown updated · unknown repeats'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'unknown seen · unknown accepted · unknown rejected',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('null updated'), findsNothing);
      expect(find.textContaining('null repeats'), findsNothing);
      expect(find.textContaining('0 seen · 0 accepted'), findsNothing);
      expect(find.textContaining('private error text'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'refresh never claims a new keyless Ultrahuman or manual import',
    (tester) async {
      final sources = [
        for (final id in ['ultrahuman', 'checkins', 'health'])
          SourceData(
            id: id,
            name: id,
            description: 'Synthetic source',
            contribution: 'Local',
            icon: Icons.favorite,
            status: SourceStatus.connected,
            tier: FeatureTier.core,
            lastSync: 'Yesterday',
          ),
      ];
      final fallback = VueniverseState(
        initialMode: AppMode.live,
        initialSources: sources,
      );
      addTearDown(fallback.dispose);
      await fallback.refreshSources();
      expect(
        fallback.sources.every((source) => source.lastSync == 'Yesterday'),
        isTrue,
      );
      expect(
        fallback.sourceOperationMessage,
        contains('has not been refreshed'),
      );
      final actions = <String>[];
      final connected = VueniverseState(
        initialMode: AppMode.live,
        initialSources: sources,
        onSourceAction: (id, action) async => actions.add(id),
      );
      addTearDown(connected.dispose);
      await connected.refreshSources();
      expect(actions, ['health']);
      expect(
        connected.sourceOperationMessage,
        contains('has not been refreshed'),
      );
    },
  );
}
