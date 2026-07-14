import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/main.dart';

void main() {
  testWidgets('minimal setup app launches', (tester) async {
    await tester.pumpWidget(const WhyPulseApp());

    expect(find.text('WhyPulse'), findsOneWidget);
    expect(find.text('Android project setup ready'), findsOneWidget);
  });
}
