import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/generated/platform_security_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/whypulse/why_pulse/platform/PlatformSecurityApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.whypulse.why_pulse.platform'),
    dartPackageName: 'why_pulse',
  ),
)
enum SecureStoreKind { live, demo }

class SecureStoreMaterial {
  SecureStoreMaterial({
    required this.databasePath,
    required this.passphrase,
    required this.created,
  });

  String databasePath;
  String passphrase;
  bool created;
}

@HostApi()
abstract class PlatformSecurityApi {
  SecureStoreMaterial openStore(SecureStoreKind kind);

  void deleteStore(SecureStoreKind kind);
}
