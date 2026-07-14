import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:why_pulse/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('minimal WhyPulse app launches on Android', (tester) async {
    await tester.pumpWidget(const WhyPulseApp());
    await tester.pumpAndSettle();

    expect(find.text('Android project setup ready'), findsOneWidget);
  });
}
