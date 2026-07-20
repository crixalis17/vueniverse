import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/generated/platform_security_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/vueniverse/vueniverse/platform/PlatformSecurityApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.vueniverse.vueniverse.platform'),
    dartPackageName: 'vueniverse',
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
