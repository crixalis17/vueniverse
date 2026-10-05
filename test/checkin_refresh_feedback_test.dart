import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/app/app_state.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/features/vueniverse_screens.dart';

void main() {
  for (final delete in [false, true]) {
    testWidgets(
      delete
          ? 'committed deletion closes editor and offers analysis-only retry'
          : 'committed save closes editor and offers analysis-only retry',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final existing = CheckInData(
          id: 'fixture-check-in',
          when: DateTime.utc(2026, 10, 4, 9),
          context: 'Mood check-in',
          detail: 'Synthetic mood report',
          icon: Icons.mood,
          category: 'mood',
        );
        var writes = 0;
        var deletions = 0;
        var fail = true;
        final state = VueniverseState(
          initialMode: AppMode.live,
          initialOnboarded: true,
          initialCheckIns: delete ? [existing] : [],
          onCheckInSaved: (_) async => writes++,
          onCheckInDeleted: (_) async => deletions++,
          onEvidenceRecompute: () async {
            if (fail) throw StateError('private analytical diagnostic');
          },
        );
        addTearDown(state.dispose);
        await tester.pumpWidget(
          VueniverseScope(
            state: state,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: const TodayScreen(),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => openPulsePage(
                      context,
                      CheckInScreen(existing: delete ? existing : null),
                    ),
                    child: const Icon(Icons.edit),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        if (delete) {
          await tester.scrollUntilVisible(
            find.widgetWithText(TextButton, 'Delete check-in'),
            250,
            scrollable: find
                .descendant(
                  of: find.byType(CheckInScreen),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.tap(find.widgetWithText(TextButton, 'Delete check-in'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(FilledButton, 'Delete check-in'),
          );
        } else {
          await tester.tap(find.widgetWithText(ChoiceChip, 'Mood'));
          await tester.enterText(
            find.byKey(const Key('checkin-detail')),
            'Synthetic new mood report',
          );
          tester.testTextInput.hide();
          await tester.scrollUntilVisible(
            find.text('Save check-in'),
            250,
            scrollable: find
                .descendant(
                  of: find.byType(CheckInScreen),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.tap(find.text('Save check-in'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(CheckInScreen), findsNothing);
        expect(find.textContaining('could not be saved'), findsNothing);
        expect(find.textContaining('could not be deleted'), findsNothing);
        expect(state.checkIns.length, delete ? 0 : 1);
        expect(state.checkInRefreshMessage, contains('saved'));
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        final retry = find.widgetWithText(TextButton, 'Retry analysis update');
        await tester.scrollUntilVisible(
          retry,
          250,
          scrollable: find
              .descendant(
                of: find.byType(TodayScreen),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        fail = false;
        await tester.tap(retry);
        await tester.pumpAndSettle();
        expect(state.checkInRefreshMessage, isNull);
        expect(writes, delete ? 0 : 1);
        expect(deletions, delete ? 1 : 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
