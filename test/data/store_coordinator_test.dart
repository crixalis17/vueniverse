import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/app/app_preferences.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/demo/demo_fixtures.dart';
import 'package:why_pulse/data/demo/demo_import_service.dart';
import 'package:why_pulse/data/security/store_security_gateway.dart';
import 'package:why_pulse/data/store/store_coordinator.dart';
import 'package:why_pulse/domain/store_kind.dart';

void main() {
  test(
    'Live and Demo use isolated encrypted files, keys and repository graphs',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'whypulse-stores-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final security = _FakeSecurity(directory);
      final preferences = _FakePreferences();
      final coordinator = StoreCoordinator(
        security: security,
        preferences: preferences,
        demoImporter: DemoImportService(
          DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
        ),
      );
      addTearDown(coordinator.dispose);

      final demo = await coordinator.initialize();
      expect(demo.kind, StoreKind.demo);
      expect(demo.demoImport, isNotNull);
      final demoHash = await demo.database.canonicalDataHash();
      final demoPath = demo.databasePath;
      final initialDemoKey = security.passphrases[StoreKind.demo];

      final live = await coordinator.switchTo(StoreKind.live);
      expect(live.databasePath, isNot(demoPath));
      expect(security.passphrases[StoreKind.live], isNot(initialDemoKey));
      await live.database
          .into(live.database.storeMetadata)
          .insertOnConflictUpdate(
            StoreMetadataCompanion.insert(
              key: 'live_only_marker',
              value: 'preserved',
            ),
          );
      final livePath = live.databasePath;
      final liveKey = security.passphrases[StoreKind.live];

      final resetDemo = await coordinator.resetDemo();
      expect(resetDemo.kind, StoreKind.demo);
      expect(await resetDemo.database.canonicalDataHash(), demoHash);
      expect(security.passphrases[StoreKind.demo], isNot(initialDemoKey));
      expect(security.passphrases[StoreKind.live], liveKey);
      expect(
        await (resetDemo.database.select(resetDemo.database.storeMetadata)
              ..where((row) => row.key.equals('live_only_marker')))
            .getSingleOrNull(),
        isNull,
      );

      final reopenedLive = await coordinator.switchTo(StoreKind.live);
      expect(reopenedLive.databasePath, livePath);
      expect(
        (await (reopenedLive.database.select(
              reopenedLive.database.storeMetadata,
            )..where((row) => row.key.equals('live_only_marker'))).getSingle())
            .value,
        'preserved',
      );

      final demoBeforeLiveDeletion = await coordinator.switchTo(StoreKind.demo);
      final demoKeyBeforeLiveDeletion = security.passphrases[StoreKind.demo];
      await coordinator.deleteLive();
      expect(coordinator.active, same(demoBeforeLiveDeletion));
      expect(
        await demoBeforeLiveDeletion.database.canonicalDataHash(),
        demoHash,
      );
      expect(security.passphrases[StoreKind.demo], demoKeyBeforeLiveDeletion);

      final recreatedLive = await coordinator.switchTo(StoreKind.live);
      expect(security.passphrases[StoreKind.live], isNot(liveKey));
      expect(
        await (recreatedLive.database.select(
              recreatedLive.database.storeMetadata,
            )..where((row) => row.key.equals('live_only_marker')))
            .getSingleOrNull(),
        isNull,
      );
      await coordinator.switchTo(StoreKind.demo);
      await coordinator.switchTo(StoreKind.live);

      final header = await File(demoPath)
          .openRead(0, 16)
          .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
      expect(String.fromCharCodes(header), isNot('SQLite format 3\u0000'));

      await coordinator.dispose();
      final wrongKeyDatabase = WhyPulseDatabase.encrypted(
        path: demoPath,
        passphrase: 'this-is-the-wrong-passphrase',
      );
      await expectLater(
        wrongKeyDatabase.initialize(kind: StoreKind.demo),
        throwsA(anything),
      );
      await wrongKeyDatabase.close();
    },
  );
}

final class _FakeSecurity implements StoreSecurityGateway {
  _FakeSecurity(this.directory);

  final Directory directory;
  final passphrases = <StoreKind, String>{};
  final generations = <StoreKind, int>{};

  @override
  Future<StoreMaterial> open(StoreKind kind) async {
    final file = File('${directory.path}/whypulse_${kind.name}.db');
    final generation = generations.putIfAbsent(kind, () => 1);
    final passphrase = passphrases.putIfAbsent(
      kind,
      () => '${kind.name}-fake-256-bit-key-material-generation-$generation',
    );
    return StoreMaterial(
      databasePath: file.path,
      passphrase: passphrase,
      databaseIsNew: !file.existsSync(),
    );
  }

  @override
  Future<void> delete(StoreKind kind) async {
    final base = '${directory.path}/whypulse_${kind.name}.db';
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final file = File('$base$suffix');
      if (file.existsSync()) file.deleteSync();
    }
    generations[kind] = (generations[kind] ?? 1) + 1;
    passphrases.remove(kind);
  }
}

final class _FakePreferences implements AppPreferences {
  bool onboarded = false;
  StoreKind mode = StoreKind.demo;
  bool reducedMotion = false;
  String? destination;

  @override
  Future<StoreKind> getActiveMode() async => mode;

  @override
  Future<String?> getLastNavigationDestination() async => destination;

  @override
  Future<bool> getOnboardingComplete() async => onboarded;

  @override
  Future<bool> getReducedMotion() async => reducedMotion;

  @override
  Future<void> setActiveMode(StoreKind value) async => mode = value;

  @override
  Future<void> setLastNavigationDestination(String? value) async =>
      destination = value;

  @override
  Future<void> setOnboardingComplete(bool value) async => onboarded = value;

  @override
  Future<void> setReducedMotion(bool value) async => reducedMotion = value;
}
