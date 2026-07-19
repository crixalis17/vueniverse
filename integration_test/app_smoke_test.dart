import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:why_pulse/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WhyPulse data-to-action smoke journey', (tester) async {
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
    expect(find.text('Pattern detail'), findsOneWidget);

    final evidence = find.text('Review the data');
    await tester.scrollUntilVisible(
      evidence,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(evidence);
    await tester.pumpAndSettle();
    expect(find.text('Data behind the pattern'), findsOneWidget);
    expect(find.text('NUMBERS BEHIND THIS PATTERN'), findsOneWidget);

    final explain = find.text('Explain this pattern');
    await tester.scrollUntilVisible(
      explain,
      320,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(explain);
    await tester.pumpAndSettle();
    expect(find.text('USES ONLY THIS PATTERN’S DATA'), findsOneWidget);
    expect(find.text('Data used for this answer'), findsOneWidget);

    final askEntry = find.text('Ask about this pattern');
    await tester.scrollUntilVisible(
      askEntry,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.tap(askEntry);
    await tester.pumpAndSettle();
    expect(find.text('THIS PATTERN ONLY'), findsOneWidget);
    await tester.tap(find.text('Which meetings do not match?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 of 8 meetings'), findsOneWidget);
  });
}
