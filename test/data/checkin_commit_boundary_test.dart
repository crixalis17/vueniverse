import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/sources/manual_checkin_repository.dart';
import 'package:vueniverse/data/sources/source_repository.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';

CheckInData _entry(String detail) => CheckInData(
  id: 'fixture-stable-entry',
  when: DateTime.utc(2026, 10, 4, 9),
  context: 'Mood check-in',
  detail: detail,
  icon: Icons.mood,
  category: 'mood',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final operation in ['add', 'edit', 'delete']) {
    for (final failurePhase in ['analysis', 'finding reload']) {
      test('$operation remains committed when $failurePhase fails', () async {
        final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
        addTearDown(database.close);
        await database.initialize(kind: StoreKind.live);
        await SourceRepository(database).initializeLiveSources();
        final manual = ManualCheckinRepository(
          database: database,
          canonicalRecords: CanonicalRecordRepository(database),
          normalizer: RecordNormalizer(identityKey: List.filled(32, 29)),
        );
        Future<void> persist(CheckInData entry) => manual.save(
          ManualCheckinRecord(
            id: entry.id,
            category: CheckinCategory.mood,
            occurredAt: entry.when,
            detail: entry.detail,
          ),
        );
        final original = _entry('Synthetic before');
        if (operation != 'add') await persist(original);
        var fail = true;
        final state = VueniverseState(
          initialMode: AppMode.live,
          initialCheckIns: operation == 'add' ? [] : [original],
          onCheckInSaved: persist,
          onCheckInDeleted: (id) async {
            expect(await manual.delete(id), isTrue);
          },
          onEvidenceRecompute: () async {
            if (fail && failurePhase == 'analysis') {
              throw StateError('private analytical diagnostic');
            }
            await MeetingAnalysisRepository(database).runPending();
          },
          onFindingReload: () async {
            if (fail && failurePhase == 'finding reload') {
              throw StateError('private read diagnostic');
            }
            return null;
          },
        );
        addTearDown(state.dispose);
        final changed = _entry('Synthetic after');
        switch (operation) {
          case 'add':
            await state.addCheckIn(changed);
          case 'edit':
            await state.editCheckIn(changed);
          case 'delete':
            await state.deleteCheckIn(original.id);
        }
        final retained = await manual.load();
        if (operation == 'delete') {
          expect(retained, isEmpty);
          expect(state.checkIns, isEmpty);
        } else {
          expect(retained.single.id, changed.id);
          expect(retained.single.detail, changed.detail);
          expect(state.checkIns.single.detail, changed.detail);
        }
        expect(state.checkInRefreshMessage, contains('saved'));
        expect(state.checkInRefreshMessage, isNot(contains('private')));
        expect(state.finding, isNull);
        expect(state.replay, isNull);
        expect(state.currentExplanation, isNull);
        expect(state.checkInOperationInProgress, isFalse);
        final receiptCount =
            (await database.select(database.syncRuns).get()).length;
        fail = false;
        await state.retryCheckInRefresh();
        expect(state.checkInRefreshMessage, isNull);
        expect(
          (await database.select(database.syncRuns).get()).length,
          receiptCount,
        );
        expect((await manual.load()).length, operation == 'delete' ? 0 : 1);
        expect(
          (await database.select(database.recomputeJobs).get()).every(
            (job) => job.status == 'completed',
          ),
          isTrue,
        );
      });
    }
  }

  test(
    'storage failure never acknowledges or refreshes a new check-in',
    () async {
      var refreshes = 0;
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialCheckIns: [],
        onCheckInSaved: (_) async => throw StateError('storage failure'),
        onEvidenceRecompute: () async => refreshes++,
      );
      addTearDown(state.dispose);
      await expectLater(
        state.addCheckIn(_entry('Synthetic')),
        throwsStateError,
      );
      expect(state.checkIns, isEmpty);
      expect(refreshes, 0);
      expect(state.checkInRefreshMessage, isNull);
      expect(state.checkInOperationInProgress, isFalse);
    },
  );

  test(
    'store switch and a second mutation are refused while a write is active',
    () async {
      final release = Completer<void>();
      var writes = 0;
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialCheckIns: [],
        onCheckInSaved: (_) {
          writes++;
          return release.future;
        },
      );
      addTearDown(state.dispose);
      final pending = state.addCheckIn(_entry('Synthetic'));
      expect(state.checkInOperationInProgress, isTrue);
      state.setMode(AppMode.demo);
      expect(state.mode, AppMode.live);
      await expectLater(state.addCheckIn(_entry('Second')), throwsStateError);
      expect(writes, 1);
      release.complete();
      await pending;
      expect(state.checkIns, hasLength(1));
      state.setMode(AppMode.demo);
      expect(state.mode, AppMode.demo);
    },
  );

  test(
    'disposed state never refreshes after a storage acknowledgment',
    () async {
      final release = Completer<void>();
      var refreshes = 0;
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialCheckIns: [],
        onCheckInSaved: (_) => release.future,
        onEvidenceRecompute: () async => refreshes++,
      );
      final pending = state.addCheckIn(_entry('Synthetic'));
      state.dispose();
      release.complete();
      await pending;
      expect(refreshes, 0);
      expect(state.checkIns, isEmpty);
    },
  );
}
