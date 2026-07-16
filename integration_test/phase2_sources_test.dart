import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/normalization/record_normalizer.dart';
import 'package:why_pulse/data/repositories/canonical_record_repository.dart';
import 'package:why_pulse/data/sources/manual_checkin_repository.dart';
import 'package:why_pulse/data/sources/source_repository.dart';
import 'package:why_pulse/domain/models/canonical_domain_models.dart';
import 'package:why_pulse/domain/store_kind.dart';
import 'package:why_pulse/platform/generated/platform_security_api.g.dart';
import 'package:why_pulse/platform/generated/source_api.g.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android exposes typed Health Connect and Calendar state', (
    tester,
  ) async {
    final sources = SourceApi();
    final availability = await sources.getHealthAvailability();
    expect(
      availability.features.map((feature) => feature.name),
      containsAll([
        'background_read',
        'history_read',
        'change_tokens',
        'hrv_rmssd',
      ]),
    );

    final healthPermissions = await sources.getHealthPermissionSnapshot();
    expect(
      healthPermissions.permissions,
      hasLength(HealthDataType.values.length),
    );
    expect(
      healthPermissions.permissions
          .map((permission) => permission.type)
          .toSet(),
      unorderedEquals(HealthDataType.values),
    );

    final calendarPermission = await sources.getCalendarPermissionSnapshot();
    expect(NativePermissionState.values, contains(calendarPermission.state));

    if (calendarPermission.state == NativePermissionState.granted) {
      final discovery = await sources.discoverRecurringCalendarSeries();
      expect(discovery.failure, isNull);
      final now = DateTime.now().toUtc();
      final snapshot = await sources.readRecurringCalendarSnapshot(
        now.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
        now.add(const Duration(days: 30)).millisecondsSinceEpoch,
      );
      expect(snapshot.failure, isNull);
      expect(snapshot.complete, isTrue);
    }
  });

  testWidgets('an actual Manual Check-in survives encrypted restart', (
    tester,
  ) async {
    final security = PlatformSecurityApi();
    await security.deleteStore(SecureStoreKind.live);
    addTearDown(() => security.deleteStore(SecureStoreKind.live));

    final firstMaterial = await security.openStore(SecureStoreKind.live);
    final firstDatabase = WhyPulseDatabase.encrypted(
      path: firstMaterial.databasePath,
      passphrase: firstMaterial.passphrase,
    );
    await firstDatabase.initialize(kind: StoreKind.live);
    final firstSources = SourceRepository(firstDatabase);
    await firstSources.initializeLiveSources();
    final firstManual = await _manualRepository(firstDatabase);
    final occurredAt = DateTime.now();
    await firstManual.save(
      ManualCheckinRecord(
        id: 'phase2-restart-checkin',
        category: CheckinCategory.caffeine,
        occurredAt: occurredAt,
        detail: 'One coffee',
      ),
    );
    expect((await firstManual.load()).single.id, 'phase2-restart-checkin');
    await firstDatabase.close();

    expect(File(firstMaterial.databasePath).existsSync(), isTrue);
    final secondMaterial = await security.openStore(SecureStoreKind.live);
    expect(secondMaterial.passphrase, firstMaterial.passphrase);
    final secondDatabase = WhyPulseDatabase.encrypted(
      path: secondMaterial.databasePath,
      passphrase: secondMaterial.passphrase,
    );
    await secondDatabase.initialize(kind: StoreKind.live);
    final secondManual = await _manualRepository(secondDatabase);
    final restored = await secondManual.load();
    expect(restored.single.id, 'phase2-restart-checkin');
    expect(restored.single.detail, 'One coffee');
    expect(await secondManual.delete('phase2-restart-checkin'), isTrue);
    expect(await secondManual.load(), isEmpty);
    await secondDatabase.close();
  });
}

Future<ManualCheckinRepository> _manualRepository(
  WhyPulseDatabase database,
) async {
  final normalizer = RecordNormalizer(
    identityKey: await database.getOrCreateSourceIdentityKey(),
  );
  return ManualCheckinRepository(
    database: database,
    canonicalRecords: CanonicalRecordRepository(database),
    normalizer: normalizer,
  );
}
