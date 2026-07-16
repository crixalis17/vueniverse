import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/main.dart';

Future<void> enterDemo(WidgetTester tester) async {
  await tester.pumpWidget(const WhyPulseApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('See how it works'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Explore Demo Data'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {});

  testWidgets('onboarding enters the four-destination evidence experience', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await enterDemo(tester);

    expect(find.text('Today'), findsWidgets);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Experiments'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(
      find.text(
        'Your heart rate was usually higher before your recurring 1:1.',
      ),
      findsOneWidget,
    );
    expect(find.text('DEMO'), findsWidgets);
  });

  testWidgets('live onboarding includes source preparation as a product step', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const WhyPulseApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('See how it works'));
    await tester.pumpAndSettle();
    final liveSetup = find.text('Continue to Sources');
    await tester.drag(find.byType(ListView).first, const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(liveSetup);
    await tester.pumpAndSettle();

    expect(find.text('Choose what WhyPulse can use.'), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.text('Android Calendar'), findsOneWidget);
    expect(find.text('Manual check-ins'), findsOneWidget);
    expect(find.text('Demo Data'), findsOneWidget);

    final continueButton = find.text('Continue with selected sources');
    await tester.scrollUntilVisible(
      continueButton,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('Sources is a standalone screen in the Observe journey', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.textContaining('Manage sources'));
    await tester.pumpAndSettle();

    expect(find.text('Sources'), findsOneWidget);
    expect(find.text('Control what evidence WhyPulse can use'), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.text('Android Calendar'), findsOneWidget);
    expect(find.text('Manual check-ins'), findsOneWidget);
    expect(find.text('Demo Data'), findsOneWidget);
  });

  testWidgets('core evidence journey reaches bounded Ask WhyPulse', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(
      find.text(
        'Your heart rate was usually higher before your recurring 1:1.',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Moment Fingerprint'), findsOneWidget);

    final challenge = find.text('Challenge the evidence');
    await tester.scrollUntilVisible(
      challenge,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(challenge);
    await tester.pumpAndSettle();
    expect(find.text('Challenge the recurring 1:1 finding'), findsOneWidget);

    final explain = find.text('Explain this evidence');
    await tester.scrollUntilVisible(
      explain,
      420,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(explain);
    await tester.pumpAndSettle();
    expect(find.text('Bounded to this evidence bundle'), findsOneWidget);

    final ask = find.text('Ask about this evidence');
    await tester.scrollUntilVisible(
      ask,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(ask);
    await tester.pumpAndSettle();
    expect(find.text('Ask WhyPulse'), findsOneWidget);

    await tester.tap(find.text('What evidence is missing?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('largest gap is caffeine'), findsOneWidget);
  });

  testWidgets('Ask WhyPulse is directly discoverable from Today', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    final askEntry = find.bySemanticsLabel(
      'Ask WhyPulse about the recurring 1:1 evidence',
    );
    await tester.scrollUntilVisible(
      askEntry,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(askEntry);
    await tester.pumpAndSettle();

    expect(find.text('Recurring 1:1 evidence only'), findsOneWidget);
    await tester.tap(find.text('What evidence is missing?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('largest gap is caffeine'), findsOneWidget);
  });

  testWidgets('history exposes lifecycle and deterministic evidence cases', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(-380, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weakened'));
    await tester.pumpAndSettle();
    expect(find.text('Late meetings and sleep duration'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(-420, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expired'));
    await tester.pumpAndSettle();
    expect(find.text('Travel-day recovery pattern'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await enterDemo(tester);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -480));
      await tester.pumpAndSettle();
    }

    final demoCases = find.text('Demo evidence cases');
    expect(demoCases, findsOneWidget);
    await tester.ensureVisible(demoCases);
    await tester.pumpAndSettle();
    await tester.tap(demoCases);
    await tester.pumpAndSettle();

    expect(find.text('Supported repeated pattern'), findsOneWidget);
    expect(find.text('Null finding'), findsOneWidget);
    expect(find.text('Contradictory evidence'), findsOneWidget);
    expect(find.text('Missing-data result'), findsOneWidget);

    await tester.tap(find.text('Contradictory evidence'));
    await tester.pumpAndSettle();
    expect(find.text('Promotion stopped'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final missing = find.text('Missing-data result');
    await tester.scrollUntilVisible(
      missing,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(missing);
    await tester.pumpAndSettle();
    expect(find.text('Evidence gate not reached'), findsOneWidget);
  });

  testWidgets('experiment result gallery covers all four outcome states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    final resultCases = find.text('Deterministic result cases');
    await tester.scrollUntilVisible(
      resultCases,
      360,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(resultCases);
    await tester.pumpAndSettle();

    expect(find.text('Strengthened'), findsOneWidget);
    expect(find.text('Weakened'), findsOneWidget);
    expect(find.text('Unchanged'), findsOneWidget);
    expect(find.text('Inconclusive'), findsOneWidget);

    final inconclusive = find.text('Inconclusive');
    await tester.scrollUntilVisible(
      inconclusive,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(inconclusive);
    await tester.pumpAndSettle();
    expect(
      find.text('There is not enough complete evidence to resolve the test.'),
      findsOneWidget,
    );
    expect(find.text('Evidence gate not reached'), findsOneWidget);
  });

  testWidgets('experiment can start and record an eligible occurrence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.text('Experiments'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Review proposed test'));
    await tester.pumpAndSettle();

    final consent = find.text(
      'I understand this is a personal test, not treatment.',
    );
    await tester.scrollUntilVisible(
      consent,
      360,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(consent);
    await tester.pumpAndSettle();
    final start = find.text('Start 3-meeting experiment');
    await tester.scrollUntilVisible(
      start,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(start);
    await tester.pumpAndSettle();

    expect(find.text('0/3 eligible meetings'), findsOneWidget);
    await tester.tap(find.text('Complete occurrence check-in'));
    await tester.pumpAndSettle();
    expect(find.text('1/3 eligible meetings'), findsOneWidget);
  });

  testWidgets('proof, previews and expansion remain honestly labelled', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await enterDemo(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proof & exports'));
    await tester.pumpAndSettle();
    expect(find.text('Proof & Export'), findsOneWidget);
    final integrity = find.text('INTEGRITY HASH');
    await tester.scrollUntilVisible(
      integrity,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    expect(integrity, findsOneWidget);

    final clinician = find.text('Reviewed Clinician Report');
    await tester.scrollUntilVisible(
      clinician,
      360,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(clinician);
    await tester.pumpAndSettle();
    expect(find.text('PREVIEW · SAMPLE DATA'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final expansion = find.text('Expansion');
    await tester.scrollUntilVisible(
      expansion,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(expansion);
    await tester.pumpAndSettle();
    expect(
      find.text('Future capabilities · no unfinished integrations'),
      findsOneWidget,
    );
    expect(find.text('LATER'), findsWidgets);
    expect(find.text('Connect'), findsNothing);
  });
}
