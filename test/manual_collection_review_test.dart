import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/features/vueniverse_screens.dart';

void main() {
  final originalTime = DateTime.utc(2026, 10, 3, 9);
  final entries = List.generate(
    3,
    (index) => CheckInData(
      id: 'fixture-$index',
      when: originalTime.subtract(Duration(hours: index)),
      context: 'Mood check-in',
      detail: 'Fixture report $index',
      icon: Icons.mood,
      category: 'mood',
    ),
  );
  for (final count in [1, 2]) {
    testWidgets('manual collection labels agree with count $count', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialOnboarded: true,
        initialCheckIns: entries.take(count).toList(),
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(
        VueniverseScope(
          state: state,
          child: const MaterialApp(home: TodayScreen()),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Recent context'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          count == 1
              ? '1 check-in helps explain what sensors cannot see.'
              : '2 check-ins help explain what sensors cannot see.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('1 check-ins help explain what sensors cannot see.'),
        findsNothing,
      );
      await _tap(tester, find.text('Review all check-ins'));
      expect(
        find.text(count == 1 ? '1 saved check-in' : '2 saved check-ins'),
        findsOneWidget,
      );
      expect(find.text('1 saved check-ins'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  for (final fromSource in [false, true]) {
    testWidgets(
      'all manual reports remain editable without finding from ${fromSource ? 'source' : 'Today'}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        CheckInData? saved;
        String? deleted;
        final state = VueniverseState(
          initialMode: AppMode.live,
          initialOnboarded: true,
          initialCheckIns: entries,
          onCheckInSaved: (row) async => saved = row,
          onCheckInDeleted: (id) async => deleted = id,
        );
        addTearDown(state.dispose);
        const source = SourceData(
          id: 'checkins',
          name: 'Manual check-ins',
          description: 'Your reported context',
          contribution: 'Locally saved reports',
          icon: Icons.edit_note,
          status: SourceStatus.connectedData,
          tier: FeatureTier.core,
        );
        await tester.pumpWidget(
          VueniverseScope(
            state: state,
            child: MaterialApp(
              home: fromSource
                  ? const SourceDetailScreen(source: source)
                  : const TodayScreen(),
            ),
          ),
        );
        await _tap(tester, find.text('Review all check-ins'));
        expect(find.text('Saved check-ins'), findsOneWidget);
        expect(find.text('3 saved check-ins'), findsOneWidget);
        expect(
          find.textContaining('not proof of a health pattern'),
          findsOneWidget,
        );
        expect(
          find.text('Check the details used in this pattern'),
          findsNothing,
        );
        expect(state.hasDisplayableCurrentFinding, isFalse);
        await _tap(
          tester,
          find.byKey(const ValueKey('saved-check-in-fixture-2')),
        );
        expect(
          find.textContaining('Editing preserves that report time'),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const Key('checkin-detail')),
          'Edited older fixture report',
        );
        await _tap(tester, find.widgetWithText(FilledButton, 'Save changes'));
        expect(saved?.id, 'fixture-2');
        expect(saved?.when, entries[2].when);
        expect(saved?.detail, 'Edited older fixture report');
        expect(find.text('3 saved check-ins'), findsOneWidget);
        await _tap(
          tester,
          find.byKey(const ValueKey('saved-check-in-fixture-2')),
        );
        await _tap(tester, find.widgetWithText(TextButton, 'Delete check-in'));
        expect(find.text('Delete this check-in?'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Delete check-in'));
        await tester.pumpAndSettle();
        expect(deleted, 'fixture-2');
        expect(find.text('2 saved check-ins'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('saved-check-in-fixture-2')),
          findsNothing,
        );
        expect(state.hasDisplayableCurrentFinding, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'new mood report uses save time, not an inferred past event time',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      CheckInData? saved;
      final state = VueniverseState(
        initialMode: AppMode.live,
        initialOnboarded: true,
        onCheckInSaved: (row) async => saved = row,
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(
        VueniverseScope(
          state: state,
          child: const MaterialApp(home: CheckInScreen()),
        ),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Mood'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Recorded when you save.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('checkin-detail')),
        'Fixture report',
      );
      final before = DateTime.now();
      await _tap(tester, find.widgetWithText(FilledButton, 'Save check-in'));
      final after = DateTime.now();
      expect(saved, isNotNull);
      expect(saved!.when.isBefore(before), isFalse);
      expect(saved!.when.isAfter(after), isFalse);
      expect(state.hasDisplayableCurrentFinding, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder.hitTestable());
  await tester.pumpAndSettle();
}
