import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/first_person_flow_test.dart' as flow;
import '../test/collection_history_widget_test.dart' as ledger;
import '../test/data/ultrahuman_import_service_test.dart' as imports;
import 'encrypted_store_test.dart' as encrypted;

/// Reuses the production UI regressions on Android, plus real Keystore/SQLCipher.
/// Only run on an explicitly disposable emulator copy, never an owner's phone.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('VUENIVERSE_DISPOSABLE_EMULATOR')) {
    testWidgets(
      'emulator suite requires disposable-copy opt-in',
      (_) async {},
      skip: true,
    );
    return;
  }
  flow.main();
  ledger.main();
  group('mocked provider import lifecycle', imports.main);
  encrypted.main();
}
