import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:why_pulse/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WhyPulse deterministic evidence-to-action smoke journey', (
    tester,
  ) async {
    await tester.pumpWidget(const WhyPulseApp());
    await tester.pumpAndSettle();

    expect(
      find.text('Understand what repeated moments do to you.'),
      findsOneWidget,
    );
    await tester.tap(find.text('See how it works'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore Demo Data'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Your heart rate was usually higher before your recurring 1:1.',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.text(
        'Your heart rate was usually higher before your recurring 1:1.',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Moment Fingerprint'), findsOneWidget);

    final evidence = find.text('Challenge the evidence');
    await tester.scrollUntilVisible(
      evidence,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(evidence);
    await tester.pumpAndSettle();
    expect(find.text('Evidence'), findsOneWidget);
    expect(find.text('VERIFIED MEASURES'), findsOneWidget);

    final askEntry = find.bySemanticsLabel(
      'Ask WhyPulse about the recurring 1:1 evidence',
    );
    await tester.scrollUntilVisible(
      askEntry,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(askEntry);
    await tester.pumpAndSettle();
    expect(find.text('Recurring 1:1 evidence only'), findsOneWidget);
    await tester.tap(find.text('What disagrees with this pattern?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Two meetings did not show'), findsOneWidget);
  });
}
