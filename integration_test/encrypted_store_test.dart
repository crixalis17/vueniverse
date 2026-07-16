import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/domain/store_kind.dart';
import 'package:why_pulse/platform/generated/platform_security_api.g.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android Keystore keeps Live and Demo encrypted and isolated', (
    tester,
  ) async {
    final security = PlatformSecurityApi();
    await security.deleteStore(SecureStoreKind.live);
    await security.deleteStore(SecureStoreKind.demo);
    addTearDown(() async {
      await security.deleteStore(SecureStoreKind.live);
      await security.deleteStore(SecureStoreKind.demo);
    });

    final liveMaterial = await security.openStore(SecureStoreKind.live);
    final demoMaterial = await security.openStore(SecureStoreKind.demo);
    expect(liveMaterial.databasePath, endsWith('whypulse_live.db'));
    expect(demoMaterial.databasePath, endsWith('whypulse_demo.db'));
    expect(liveMaterial.databasePath, isNot(demoMaterial.databasePath));
    expect(liveMaterial.passphrase, isNot(demoMaterial.passphrase));

    final live = WhyPulseDatabase.encrypted(
      path: liveMaterial.databasePath,
      passphrase: liveMaterial.passphrase,
    );
    await live.initialize(kind: StoreKind.live);
    await live
        .into(live.storeMetadata)
        .insertOnConflictUpdate(
          StoreMetadataCompanion.insert(key: 'isolation_marker', value: 'live'),
        );
    await live.close();

    final demo = WhyPulseDatabase.encrypted(
      path: demoMaterial.databasePath,
      passphrase: demoMaterial.passphrase,
    );
    await demo.initialize(kind: StoreKind.demo);
    await demo
        .into(demo.storeMetadata)
        .insertOnConflictUpdate(
          StoreMetadataCompanion.insert(key: 'isolation_marker', value: 'demo'),
        );
    await demo.close();

    for (final path in [liveMaterial.databasePath, demoMaterial.databasePath]) {
      final header = await File(path)
          .openRead(0, 16)
          .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
      expect(String.fromCharCodes(header), isNot('SQLite format 3\u0000'));
    }

    final reopenedLiveMaterial = await security.openStore(SecureStoreKind.live);
    expect(reopenedLiveMaterial.passphrase, liveMaterial.passphrase);
    final reopenedLive = WhyPulseDatabase.encrypted(
      path: reopenedLiveMaterial.databasePath,
      passphrase: reopenedLiveMaterial.passphrase,
    );
    await reopenedLive.initialize(kind: StoreKind.live);
    expect(
      (await (reopenedLive.select(
        reopenedLive.storeMetadata,
      )..where((row) => row.key.equals('isolation_marker'))).getSingle()).value,
      'live',
    );
    await reopenedLive.close();

    await security.deleteStore(SecureStoreKind.demo);
    final resetDemoMaterial = await security.openStore(SecureStoreKind.demo);
    expect(resetDemoMaterial.passphrase, isNot(demoMaterial.passphrase));
    final resetDemo = WhyPulseDatabase.encrypted(
      path: resetDemoMaterial.databasePath,
      passphrase: resetDemoMaterial.passphrase,
    );
    await resetDemo.initialize(kind: StoreKind.demo);
    expect(
      await (resetDemo.select(
        resetDemo.storeMetadata,
      )..where((row) => row.key.equals('isolation_marker'))).getSingleOrNull(),
      isNull,
    );
    await resetDemo.close();

    final finalLiveMaterial = await security.openStore(SecureStoreKind.live);
    final finalLive = WhyPulseDatabase.encrypted(
      path: finalLiveMaterial.databasePath,
      passphrase: finalLiveMaterial.passphrase,
    );
    await finalLive.initialize(kind: StoreKind.live);
    expect(
      (await (finalLive.select(
        finalLive.storeMetadata,
      )..where((row) => row.key.equals('isolation_marker'))).getSingle()).value,
      'live',
    );
    await finalLive.close();
  });
}
