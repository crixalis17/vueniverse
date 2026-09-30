import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/features/vueniverse_screens.dart';

void main() {
  testWidgets('editing preserves explicit coverage and saves zero intake', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final end = DateTime.utc(2026, 7, 16, 10);
    final existing = CheckInData(
      id: 'existing',
      when: end,
      context: 'Caffeine',
      detail: 'Completed period',
      icon: Icons.coffee,
      category: 'caffeine',
      caffeineServings: 1,
      coverageStart: end.subtract(const Duration(hours: 4)),
      coverageEnd: end,
    );
    CheckInData? saved;
    final state = VueniverseState(
      initialOnboarded: true,
      initialCheckIns: [existing],
      onCheckInSaved: (value) async {
        saved = value;
      },
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: VueniverseScope(
          state: state,
          child: CheckInScreen(existing: existing),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('caffeine-servings')), '0');
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.text('Save changes'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(saved!.caffeineServings, 0);
    expect(saved!.coverageStart, existing.coverageStart);
    expect(saved!.coverageEnd, existing.coverageEnd);
    expect(saved!.id, existing.id);
    expect(state.checkIns, hasLength(1));
  });

  for (final failingSave in [false, true]) {
    testWidgets(
      failingSave
          ? 'save failure keeps the form and does not add a check-in'
          : 'negative intake cannot be saved',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final state = VueniverseState(
          initialOnboarded: true,
          initialCheckIns: [],
          onCheckInSaved: failingSave
              ? (_) async {
                  throw StateError('storage failure');
                }
              : null,
        );
        addTearDown(state.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: VueniverseScope(state: state, child: const CheckInScreen()),
          ),
        );
        await tester.enterText(
          find.byKey(const Key('caffeine-servings')),
          failingSave ? '1' : '-1',
        );
        tester.testTextInput.hide();
        await tester.scrollUntilVisible(
          find.text('Save check-in'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Save check-in'));
        await tester.pumpAndSettle();
        expect(state.checkIns, isEmpty);
        expect(find.byType(CheckInScreen), findsOneWidget);
        expect(
          find.text(
            failingSave
                ? 'The check-in could not be saved. Your entries are still here.'
                : 'Enter a finite amount of zero or more servings.',
          ),
          findsOneWidget,
        );
      },
    );
  }
}
