import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/domain/models/app_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  CheckInData entry() => CheckInData(
    id: 'boundary-entry',
    when: DateTime.utc(2026, 10, 4),
    context: 'Mood',
    detail: 'Protocol fixture',
    category: 'mood',
    icon: Icons.mood,
  );
  test(
    'successful later import clears a previous postcommit analysis warning',
    () async {
      var fail = true;
      var imports = 0;
      final state = VueniverseState(
        initialMode: AppMode.live,
        onUltrahumanImport: (_, _, _) async {
          imports++;
        },
        onEvidenceRecompute: () async {
          if (fail) throw StateError('test failure');
        },
      );
      addTearDown(state.dispose);
      expect(
        await state.importUltrahuman('private-test-token', 1, '2026-10-03'),
        isTrue,
      );
      expect(state.checkInRefreshMessage, isNotNull);
      expect(state.sourceOperationMessage, contains('analysis'));
      fail = false;
      expect(
        await state.importUltrahuman('private-test-token', 1, '2026-10-04'),
        isTrue,
      );
      expect(state.checkInRefreshMessage, isNull);
      expect(state.sourceOperationMessage, isNull);
      expect(imports, 2);
    },
  );
  test(
    'active import refuses add edit delete and analytical retry before callbacks',
    () async {
      final release = Completer<void>();
      var saves = 0;
      var deletes = 0;
      var recomputes = 0;
      final checkIn = entry();
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialCheckIns: [checkIn],
        onUltrahumanImport: (_, _, _) => release.future,
        onCheckInSaved: (_) async {
          saves++;
        },
        onCheckInDeleted: (_) async {
          deletes++;
        },
        onEvidenceRecompute: () async {
          recomputes++;
        },
      );
      addTearDown(state.dispose);
      final pending = state.importUltrahuman(
        'private-test-token',
        1,
        '2026-10-04',
      );
      expect(state.sourceOperationInProgress, isTrue);
      await expectLater(state.addCheckIn(checkIn), throwsStateError);
      await expectLater(state.editCheckIn(checkIn), throwsStateError);
      await expectLater(state.deleteCheckIn(checkIn.id), throwsStateError);
      await state.retryCheckInRefresh();
      expect(saves, 0);
      expect(deletes, 0);
      expect(recomputes, 0);
      expect(state.checkIns.single.id, checkIn.id);
      release.complete();
      expect(await pending, isTrue);
      expect(recomputes, 1);
    },
  );
  test(
    'active manual commit refuses import and retry before callbacks',
    () async {
      final release = Completer<void>();
      var imports = 0;
      var recomputes = 0;
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialCheckIns: [],
        onCheckInSaved: (_) => release.future,
        onUltrahumanImport: (_, _, _) async {
          imports++;
        },
        onEvidenceRecompute: () async {
          recomputes++;
        },
      );
      addTearDown(state.dispose);
      final pending = state.addCheckIn(entry());
      expect(state.checkInOperationInProgress, isTrue);
      expect(
        await state.importUltrahuman('private-test-token', 1, '2026-10-04'),
        isFalse,
      );
      await state.retryCheckInRefresh();
      expect(imports, 0);
      expect(recomputes, 0);
      release.complete();
      await pending;
      expect(recomputes, 1);
      expect(state.checkIns, hasLength(1));
    },
  );
  test(
    'active analytical retry refuses import and new manual persistence',
    () async {
      final release = Completer<void>();
      var imports = 0;
      var saves = 0;
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialCheckIns: [],
        onEvidenceRecompute: () => release.future,
        onUltrahumanImport: (_, _, _) async {
          imports++;
        },
        onCheckInSaved: (_) async {
          saves++;
        },
      );
      addTearDown(state.dispose);
      final pending = state.retryCheckInRefresh();
      expect(state.checkInOperationInProgress, isTrue);
      expect(
        await state.importUltrahuman('private-test-token', 1, '2026-10-04'),
        isFalse,
      );
      await expectLater(state.addCheckIn(entry()), throwsStateError);
      expect(imports, 0);
      expect(saves, 0);
      release.complete();
      await pending;
      expect(state.checkInOperationInProgress, isFalse);
    },
  );
  test('completed import is acknowledged when only analysis fails', () async {
    var imports = 0;
    var fail = true;
    final state = VueniverseState(
      initialMode: AppMode.live,
      initialCheckIns: [],
      onUltrahumanImport: (_, _, _) async => imports++,
      onEvidenceRecompute: () async {
        if (fail) throw StateError('private analytical diagnostic');
      },
    );
    addTearDown(state.dispose);
    expect(
      await state.importUltrahuman('private-token', 1, '2026-10-03'),
      isTrue,
    );
    expect(state.sourceOperationMessage, startsWith('Import complete.'));
    expect(state.sourceOperationMessage, isNot(contains('private')));
    expect(state.checkInRefreshMessage, contains('imported data is saved'));
    expect(state.finding, isNull);
    fail = false;
    await state.retryCheckInRefresh();
    expect(state.checkInRefreshMessage, isNull);
    expect(imports, 1);
  });
  test('store switch is refused while a foreground import is active', () async {
    final release = Completer<void>();
    var switches = 0;
    final state = VueniverseState(
      initialMode: AppMode.live,
      onUltrahumanImport: (_, _, _) => release.future,
      onModeChanged: (_) async {
        switches++;
      },
    );
    addTearDown(state.dispose);
    final pending = state.importUltrahuman(
      'private-test-token',
      1,
      '2026-10-03',
    );
    expect(state.sourceOperationInProgress, isTrue);
    state.setMode(AppMode.demo);
    expect(state.mode, AppMode.live);
    expect(switches, 0);
    release.complete();
    expect(await pending, isTrue);
    state.setMode(AppMode.demo);
    expect(state.mode, AppMode.demo);
    expect(switches, 1);
  });
  test(
    'handled import failure does not escape when source refresh also fails',
    () async {
      final state = VueniverseState(
        initialMode: AppMode.live,
        onUltrahumanImport: (_, _, _) async {
          throw StateError('private request detail');
        },
        onSourcesReload: () async {
          throw StateError('closed database');
        },
      );
      addTearDown(state.dispose);
      expect(
        await state.importUltrahuman('private-test-token', 1, '2026-10-03'),
        isFalse,
      );
      expect(state.sourceOperationInProgress, isFalse);
      expect(state.sourceOperationMessage, isNotNull);
      expect(state.sourceOperationMessage, isNot(contains('private')));
    },
  );
  for (final fail in [false, true]) {
    test(
      'disposed state does not reload after import finishes (failure=$fail)',
      () async {
        final release = Completer<void>();
        var reloads = 0;
        final state = VueniverseState(
          initialMode: AppMode.live,
          onUltrahumanImport: (_, _, _) => release.future,
          onSourcesReload: () async {
            reloads++;
            return <SourceData>[];
          },
        );
        final pending = state.importUltrahuman(
          'private-test-token',
          1,
          '2026-10-03',
        );
        state.dispose();
        if (fail) {
          release.completeError(StateError('private detail'));
        } else {
          release.complete();
        }
        expect(await pending, isFalse);
        expect(reloads, 0);
        expect(state.sourceOperationMessage, isNull);
        state.setMode(AppMode.demo);
        expect(state.mode, AppMode.live);
      },
    );
  }
  test(
    'disposal during source reload does not replace mode-scoped records',
    () async {
      final release = Completer<List<SourceData>>();
      final started = Completer<void>();
      final state = VueniverseState(
        initialMode: AppMode.live,
        onUltrahumanImport: (_, _, _) async {},
        onSourcesReload: () {
          started.complete();
          return release.future;
        },
      );
      final prior = state.sources;
      final pending = state.importUltrahuman(
        'private-test-token',
        1,
        '2026-10-03',
      );
      await started.future;
      state.dispose();
      release.complete(<SourceData>[]);
      expect(await pending, isFalse);
      expect(identical(state.sources, prior), isTrue);
    },
  );
}
