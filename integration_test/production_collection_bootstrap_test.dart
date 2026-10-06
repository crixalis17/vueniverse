import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vueniverse/app/app_preferences.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/app/store_providers.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/sources/collection_history_repository.dart';
import 'package:vueniverse/data/store/store_coordinator.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/features/vueniverse_screens.dart';
import 'package:vueniverse/main.dart' as app;
import 'package:vueniverse/platform/generated/model_download_api.g.dart';
import 'package:vueniverse/platform/generated/platform_security_api.g.dart';

/// Actual production bootstrap: no ProviderScope or VueniverseApp callbacks
/// are injected. Only run on an explicitly disposable emulator, never a phone.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('VUENIVERSE_DISPOSABLE_EMULATOR')) {
    testWidgets(
      'production bootstrap requires disposable emulator opt-in',
      (_) async {},
      skip: true,
    );
    return;
  }

  testWidgets(
    'production collection onboarding persists an encrypted manual edit across restart',
    (tester) async {
      expect(Platform.isAndroid, isTrue, reason: 'Android emulator only.');
      final qemu = await Process.run('/system/bin/getprop', ['ro.kernel.qemu']);
      expect(qemu.exitCode, 0);
      expect(
        '${qemu.stdout}'.trim(),
        '1',
        reason: 'Refuse preference changes on a physical owner phone.',
      );
      final material = await PlatformSecurityApi().openStore(
        SecureStoreKind.live,
      );
      final preflight = VueniverseDatabase.encrypted(
        path: material.databasePath,
        passphrase: material.passphrase,
      );
      await preflight.initialize(kind: StoreKind.live);
      try {
        // Fail safely rather than erase a previous test or personal collection.
        final count = await preflight
            .customSelect(
              'SELECT (SELECT COUNT(*) FROM raw_record_index) + '
              '(SELECT COUNT(*) FROM manual_checkins) + '
              '(SELECT COUNT(*) FROM signal_samples) + '
              '(SELECT COUNT(*) FROM health_intervals) + '
              '(SELECT COUNT(*) FROM context_events) AS total',
            )
            .getSingle();
        expect(
          count.read<int>('total'),
          0,
          reason:
              'Production bootstrap test requires an empty disposable Live store.',
        );
      } finally {
        await preflight.close();
      }

      final preferences = await SharedPreferences.getInstance();
      const ownedPreferenceKeys = [
        'onboarding_complete',
        'active_mode',
        'reduced_motion',
        'last_navigation_destination',
      ];
      final originalPreferences = {
        for (final key in ownedPreferenceKeys) key: preferences.get(key),
      };
      StoreCoordinator? coordinator;
      String? createdManualId;
      addTearDown(() async {
        final active = coordinator?.active;
        if (active != null && createdManualId != null) {
          await active.manualCheckins.delete(createdManualId);
        }
        await coordinator?.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        for (final entry in originalPreferences.entries) {
          switch (entry.value) {
            case final bool value:
              await preferences.setBool(entry.key, value);
            case final String value:
              await preferences.setString(entry.key, value);
            case null:
              await preferences.remove(entry.key);
            default:
              throw StateError('Unexpected preference type.');
          }
        }
      });
      final productionPreferences = SharedAppPreferences(preferences);
      await productionPreferences.setOnboardingComplete(false);
      await productionPreferences.setActiveMode(StoreKind.live);
      await productionPreferences.setReducedMotion(true);
      await productionPreferences.setLastNavigationDestination(null);
      final downloadBefore = await ModelDownloadApi().inspectDownload();
      expect(
        downloadBefore.state,
        isNot(
          anyOf(
            ModelDownloadState.queued,
            ModelDownloadState.downloading,
            ModelDownloadState.verifying,
          ),
        ),
        reason: 'Do not share the emulator with an active model download.',
      );

      await app.main();
      await _waitFor(tester, find.text('See how it works'));
      var container = ProviderScope.containerOf(
        tester.element(find.byType(app.StoreRoot)),
      );
      coordinator = container.read(storeCoordinatorProvider);
      await tester.tap(find.text('See how it works'));
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Continue to Sources'));
      expect(find.text('Ultrahuman'), findsOneWidget);
      await _tapVisible(tester, find.text('Start collecting without AI'));
      await _waitFor(tester, find.text('Today'));

      var state = VueniverseScope.of(tester.element(find.text('Today').first));
      var graph = await container.read(storeSessionProvider.future);
      expect(graph.kind, StoreKind.live);
      expect(state.mode, AppMode.live);
      _expectNoSupportedFinding(state);
      expect(state.checkIns, isEmpty);
      for (final id in ['health', 'calendar', 'checkins', 'ultrahuman']) {
        final source = state.sources.singleWhere((row) => row.id == id);
        expect(source.recordCount, 0, reason: 'Fresh Live $id has no records.');
        expect(
          source.lastSync,
          isNull,
          reason: 'Fresh Live $id must not inherit Snapshot sync labels.',
        );
        expect(
          source.completeness,
          0,
          reason: 'Fresh Live $id has no verified coverage.',
        );
      }
      expect(state.observeDashboard.heartRateRecords, 0);
      expect(state.observeDashboard.sleepRecords, 0);
      expect(await graph.sourceRepository.loadCalendarSelections(), isEmpty);
      expect(find.text('Download on-device AI'), findsNothing);

      await _tapVisible(tester, find.text('Add a check-in'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Mood'));
      await tester.pumpAndSettle();
      // IntegrationTest leaves the real IME enabled. Injecting fixture text
      // through WidgetTester while that IME owns the client can restore stale
      // composing text during scroll. Mock only this fixture typing/save phase;
      // production controllers, commit callbacks and encrypted store stay real.
      // This test does not certify the owner's physical keyboard behavior.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      final originallyRegistered = tester.testTextInput.isRegistered;
      if (!originallyRegistered) tester.testTextInput.register();
      addTearDown(() {
        if (!originallyRegistered && tester.testTextInput.isRegistered) {
          tester.testTextInput.unregister();
        }
      });
      await tester.enterText(
        find.byKey(const Key('checkin-detail')),
        'Disposable emulator mood entry',
      );
      await _tapVisible(tester, find.text('Save check-in'));
      await _waitFor(tester, find.text('Today'));
      expect(state.checkIns, hasLength(1));
      _expectManualSource(state, retained: 1);
      createdManualId = state.checkIns.single.id;
      await _tapVisible(tester, find.text('Disposable emulator mood entry'));
      await _waitFor(tester, find.text('Edit check-in'));
      expect(
        tester.widget<CheckInScreen>(find.byType(CheckInScreen)).existing?.id,
        createdManualId,
      );
      expect(
        identical(
          VueniverseScope.of(tester.element(find.text('Edit check-in'))),
          state,
        ),
        isTrue,
      );
      await tester.enterText(
        find.byKey(const Key('checkin-detail')),
        'Edited disposable emulator mood entry',
      );
      final editedField = tester.widget<TextField>(
        find.byKey(const Key('checkin-detail')),
      );
      final editor = tester.widget<EditableText>(find.byType(EditableText));
      debugPrint(
        'Fixture edit input: registered=${tester.testTextInput.isRegistered}, '
        'client=${tester.testTextInput.isRegistered ? tester.testTextInput.hasAnyClients : 'unavailable'}, '
        'focused=${editor.focusNode.hasFocus}, '
        'controllerShared=${identical(editedField.controller, editor.controller)}, '
        'expectedFixtureText=${editedField.controller?.text == 'Edited disposable emulator mood entry'}',
      );
      expect(
        editedField.controller?.text,
        'Edited disposable emulator mood entry',
        reason:
            'Fixture edit must reach the production controller before scrolling.',
      );
      await _tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Save changes'),
        beforeTap: () {
          expect(
            tester
                .widget<TextField>(find.byKey(const Key('checkin-detail')))
                .controller
                ?.text,
            'Edited disposable emulator mood entry',
          );
        },
      );
      await tester.pump(const Duration(seconds: 1));
      final editReceipts = await CollectionHistoryRepository(
        graph.database,
      ).loadReceipts();
      debugPrint(
        'Fixture edit probe: receipts=${editReceipts.receipts.length}, inserted=${editReceipts.receipts.map((row) => row.recordsInserted).toList()}, changed=${editReceipts.receipts.map((row) => row.recordsChanged).toList()}, duplicates=${editReceipts.receipts.map((row) => row.recordsDuplicate).toList()}, editorStillVisible=${find.byType(CheckInScreen).evaluate().isNotEmpty}',
      );
      await _waitForCondition(
        tester,
        () =>
            state.checkIns.length == 1 &&
            state.checkIns.single.detail ==
                'Edited disposable emulator mood entry',
      );
      await _waitFor(tester, find.text('Today'));
      expect(
        (await graph.manualCheckins.load()).single.detail,
        'Edited disposable emulator mood entry',
      );
      _expectNoSupportedFinding(state);

      _expectManualSource(state, retained: 1);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      if (!originallyRegistered) tester.testTextInput.unregister();

      // Release the production provider graph before bootstrapping it again.
      await coordinator?.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await app.main();
      await _waitFor(tester, find.text('Today'));
      expect(find.text('See how it works'), findsNothing);
      container = ProviderScope.containerOf(
        tester.element(find.byType(app.StoreRoot)),
      );
      coordinator = container.read(storeCoordinatorProvider);
      graph = await container.read(storeSessionProvider.future);
      state = VueniverseScope.of(tester.element(find.text('Today').first));
      expect(state.mode, AppMode.live);
      expect(
        state.checkIns.single.detail,
        'Edited disposable emulator mood entry',
      );
      expect((await graph.manualCheckins.load()).single.id, createdManualId);
      _expectManualSource(state, retained: 1);
      _expectNoSupportedFinding(state);
      expect(state.observeDashboard.heartRateRecords, 0);
      expect(state.observeDashboard.sleepRecords, 0);
      expect(await graph.sourceRepository.loadCalendarSelections(), isEmpty);
      final receipts = await CollectionHistoryRepository(
        graph.database,
      ).loadReceipts();
      expect(
        receipts.receipts.where((row) => row.kind == 'sync'),
        hasLength(2),
      );
      expect(receipts.receipts.map((row) => row.recordsInserted), contains(1));
      expect(receipts.receipts.map((row) => row.recordsChanged), contains(1));
      final header = await File(graph.databasePath)
          .openRead(0, 16)
          .fold<List<int>>([], (bytes, chunk) => bytes..addAll(chunk));
      expect(String.fromCharCodes(header), isNot('SQLite format 3\u0000'));

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Sources'));
      await _tapVisible(tester, find.text('View collection history'));
      await _waitFor(tester, find.text('LIVE · 1 retained records'));
      expect(find.text('manual-checkins · mood'), findsOneWidget);
      expect(
        find.textContaining('1 new · 0 updated · 0 repeats'),
        findsOneWidget,
      );
      expect(
        find.textContaining('0 new · 1 updated · 0 repeats'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Edited disposable emulator mood entry'),
        findsNothing,
      );
      final downloadAfter = await ModelDownloadApi().inspectDownload();
      expect(downloadAfter.state, downloadBefore.state);
      expect(downloadAfter.downloadedBytes, downloadBefore.downloadedBytes);
      // The actual committed deletion must refresh the source read model,
      // not merely remove the row from Today while retaining a stale status.
      await state.deleteCheckIn(createdManualId);
      createdManualId = null;
      expect(state.checkIns, isEmpty);
      expect(await graph.manualCheckins.load(), isEmpty);
      _expectManualSource(state, retained: 0);
      final historyAfterDeletion = CollectionHistoryRepository(graph.database);
      expect((await historyAfterDeletion.loadCoverage()).retainedRecords, 0);
      final deletionReceipts = (await historyAfterDeletion.loadReceipts())
          .receipts
          .where((row) => row.kind == 'deletion');
      expect(deletionReceipts, hasLength(1));
      expect(deletionReceipts.single.recordsDeleted, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

void _expectManualSource(VueniverseState state, {required int retained}) {
  final source = state.sources.singleWhere((row) => row.id == 'checkins');
  expect(source.recordCount, retained);
  expect(
    source.status,
    retained == 0 ? SourceStatus.connectedEmpty : SourceStatus.connectedData,
  );
  expect(source.lastSync, isNotNull);
  expect(source.lastSync, isNot('Today, 8:05 AM'));
}

void _expectNoSupportedFinding(VueniverseState state) {
  expect(state.hasDisplayableCurrentFinding, isFalse);
  expect(state.finding?.status, 'insufficientData');
  expect(state.finding?.candidateCount, 0);
  expect(state.finding?.includedCount, 0);
  expect(state.finding?.controlsCount, 0);
  expect(find.text('What stands out'), findsNothing);
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var step = 0; step < 300; step++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(
    finder,
    findsWidgets,
    reason: 'Production UI did not become ready in 30 seconds.',
  );
}

Future<void> _waitForCondition(
  WidgetTester tester,
  bool Function() condition,
) async {
  for (var step = 0; step < 300; step++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  expect(
    condition(),
    isTrue,
    reason: 'Production edit did not commit in 30 seconds.',
  );
}

Future<void> _tapVisible(
  WidgetTester tester,
  Finder finder, {
  void Function()? beforeTap,
}) async {
  await tester.pumpAndSettle();
  for (var attempt = 0; attempt < 3; attempt++) {
    await tester.scrollUntilVisible(
      finder,
      220,
      scrollable: find.byType(Scrollable).last,
    );
    // ensureVisible schedules layout. A live device can draw between pointer
    // down/up, so never tap coordinates from the pre-scroll layout.
    await tester.pump();
    final target = finder.hitTestable();
    if (target.evaluate().isNotEmpty) {
      beforeTap?.call();
      await tester.tap(target);
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Production control did not become hit-testable: $finder');
}
