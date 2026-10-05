import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/sources/manual_checkin_repository.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/platform_security_api.g.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('ALLOW_DESTRUCTIVE_STORE_TESTS')) {
    testWidgets(
      'store-erasure tests require an explicitly disposable device',
      (_) async {},
      skip: true,
    );
    return;
  }

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
    expect(liveMaterial.databasePath, endsWith('vueniverse_live.db'));
    expect(demoMaterial.databasePath, endsWith('vueniverse_demo.db'));
    expect(liveMaterial.databasePath, isNot(demoMaterial.databasePath));
    expect(liveMaterial.passphrase, isNot(demoMaterial.passphrase));

    final live = VueniverseDatabase.encrypted(
      path: liveMaterial.databasePath,
      passphrase: liveMaterial.passphrase,
    );
    await live.initialize(kind: StoreKind.live);
    await live
        .into(live.storeMetadata)
        .insertOnConflictUpdate(
          StoreMetadataCompanion.insert(key: 'isolation_marker', value: 'live'),
        );
    final checkins = await _checkins(live);
    await checkins.save(
      ManualCheckinRecord(
        id: 'emulator-only-journal',
        category: CheckinCategory.mood,
        occurredAt: DateTime.utc(2026, 10, 3),
        detail: 'Fixture check-in',
      ),
    );
    await checkins.save(
      ManualCheckinRecord(
        id: 'emulator-only-journal',
        category: CheckinCategory.mood,
        occurredAt: DateTime.utc(2026, 10, 3),
        detail: 'Edited fixture check-in',
      ),
    );
    expect((await checkins.load()).single.detail, 'Edited fixture check-in');
    await live.close();

    final demo = VueniverseDatabase.encrypted(
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
    final reopenedLive = VueniverseDatabase.encrypted(
      path: reopenedLiveMaterial.databasePath,
      passphrase: reopenedLiveMaterial.passphrase,
    );
    await reopenedLive.initialize(kind: StoreKind.live);
    final reopenedCheckins = await _checkins(reopenedLive);
    expect(
      (await reopenedCheckins.load()).single.detail,
      'Edited fixture check-in',
    );
    await reopenedCheckins.delete('emulator-only-journal');
    expect(await reopenedCheckins.load(), isEmpty);
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
    final resetDemo = VueniverseDatabase.encrypted(
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
    final finalLive = VueniverseDatabase.encrypted(
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

Future<ManualCheckinRepository> _checkins(VueniverseDatabase database) async =>
    ManualCheckinRepository(
      database: database,
      canonicalRecords: CanonicalRecordRepository(database),
      normalizer: RecordNormalizer(
        identityKey: await database.getOrCreateSourceIdentityKey(),
      ),
    );
