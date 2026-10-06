import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/first_person_flow_test.dart' as flow;
import '../test/collection_history_widget_test.dart' as ledger;
import '../test/data/ultrahuman_import_service_test.dart' as imports;
import '../test/manual_collection_review_test.dart' as manual_review;
import '../test/finding_direction_widgets_test.dart' as finding_direction;
import 'encrypted_store_test.dart' as encrypted;
import 'prototype_mocked_collection_persistence_test.dart'
    as mocked_persistence;

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
  setUpAll(() async {
    expect(Platform.isAndroid, isTrue);
    final qemu = await Process.run('/system/bin/getprop', ['ro.kernel.qemu']);
    expect(qemu.exitCode, 0);
    expect(
      '${qemu.stdout}'.trim(),
      '1',
      reason: 'Refuse store-erasure tests on a physical device.',
    );
  });
  // These reused widget regressions inject fabricated text. Keep the native
  // emulator IME from restoring stale composing text during fixture scrolling.
  // This scoped harness does not certify native keyboard behavior.
  setUp(() {
    final binding = IntegrationTestWidgetsFlutterBinding.instance;
    final alreadyRegistered = binding.testTextInput.isRegistered;
    if (!alreadyRegistered) binding.testTextInput.register();
    addTearDown(() {
      if (!alreadyRegistered && binding.testTextInput.isRegistered) {
        binding.testTextInput.unregister();
      }
    });
  });
  flow.main();
  ledger.main();
  manual_review.main();
  finding_direction.main();
  group('mocked provider import lifecycle', imports.main);
  mocked_persistence.main();
  encrypted.main();
}
