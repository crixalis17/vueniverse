import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/domain/models/collection_history.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/features/source_collection_screens.dart';
import 'package:vueniverse/main.dart';
import 'package:vueniverse/platform/generated/model_download_api.g.dart';

void main() {
  setUp(() async {});
  testWidgets(
    'collection-first onboarding does not require Calendar or a model download',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      AppMode? selected;
      var downloads = 0;
      var calendars = 0;
      await tester.pumpWidget(
        VueniverseApp(
          onModeChanged: (mode) async {
            selected = mode;
          },
          onCalendarDiscovery: () async {
            calendars++;
            return [];
          },
          initialModelDownloadStatus: ModelDownloadStatus(
            state: ModelDownloadState.notConfigured,
            downloadedBytes: 0,
            totalBytes: 0,
            progress: 0,
            retryable: false,
          ),
          onModelDownloadAcceptAndStart: () async {
            downloads++;
            throw StateError('must not download');
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('See how it works'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Continue to Sources'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Continue to Sources'));
      await tester.pumpAndSettle();
      expect(find.text('Ultrahuman'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Start collecting without AI'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Start collecting without AI'));
      await tester.pumpAndSettle();
      expect(selected, AppMode.live);
      expect(find.text('Today'), findsWidgets);
      expect(downloads, 0);
      expect(calendars, 0);
    },
  );

  testWidgets(
    'import requires owner confirmation and clears the credential field',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? received;
      int? period;
      String? providerEndDate;
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialOnboarded: true,
        onUltrahumanImport: (token, days, endDate) async {
          received = token;
          period = days;
          providerEndDate = endDate;
        },
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: VueniverseScope(
            state: state,
            child: const UltrahumanImportScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Import to this device');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      final tokenField = find.widgetWithText(TextField, 'Personal API key');
      final dateField = find.widgetWithText(
        TextField,
        'Last provider date (YYYY-MM-DD)',
      );
      await tester.enterText(tokenField, 'test-private-key');
      await tester.enterText(dateField, '2026-09-30');
      expect(tester.widget<TextField>(tokenField).obscureText, isTrue);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(received, 'test-private-key');
      expect(period, 7);
      expect(providerEndDate, '2026-09-30');
      expect(tester.widget<TextField>(tokenField).controller!.text, isEmpty);
      expect(find.textContaining('Import complete.'), findsOneWidget);
      expect(find.text('test-private-key'), findsNothing);
    },
  );

  testWidgets('empty collection history is an honest Live empty state', (
    tester,
  ) async {
    final state = VueniverseState(
      initialMode: AppMode.live,
      initialOnboarded: true,
      onCollectionRequested: (_) async => (
        coverage: const CollectionCoverage(
          storeKind: StoreKind.live,
          groups: [],
        ),
        history: const CollectionHistoryPage(
          storeKind: StoreKind.live,
          receipts: [],
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
    expect(find.text('LIVE · 0 retained records'), findsOneWidget);
    expect(
      find.textContaining('No health or context records saved yet.'),
      findsOneWidget,
    );
    expect(find.text('Load older activity'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed check-in deletion retains the saved entry', (
    tester,
  ) async {
    final checkIn = CheckInData(
      id: 'saved',
      when: DateTime(2026, 10, 3),
      context: 'Mood',
      detail: 'Private',
      icon: Icons.mood,
      category: 'mood',
    );
    final state = VueniverseState(
      initialMode: AppMode.live,
      initialOnboarded: true,
      initialCheckIns: [checkIn],
      onCheckInDeleted: (_) async {
        throw StateError('storage failure');
      },
    );
    addTearDown(state.dispose);
    await expectLater(state.deleteCheckIn('saved'), throwsStateError);
    expect(state.checkIns.single.id, 'saved');
  });
  testWidgets(
    'invalid provider date stays on screen without sending or clearing credential',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var calls = 0;
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialOnboarded: true,
        onUltrahumanImport: (_, _, _) async {
          calls++;
        },
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: VueniverseScope(
            state: state,
            child: const UltrahumanImportScreen(),
          ),
        ),
      );
      final tokenField = find.widgetWithText(TextField, 'Personal API key');
      final dateField = find.widgetWithText(
        TextField,
        'Last provider date (YYYY-MM-DD)',
      );
      await tester.enterText(tokenField, 'test-private-key');
      await tester.enterText(dateField, '2026-02-30');
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Import to this device');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(
        tester.widget<TextField>(tokenField).controller!.text,
        'test-private-key',
      );
      expect(
        find.text('Enter a valid last provider date as YYYY-MM-DD.'),
        findsOneWidget,
      );
    },
  );
}
