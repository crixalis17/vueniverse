import 'package:flutter/services.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/platform_security_api.g.dart';

abstract interface class StoreSecurityGateway {
  Future<StoreMaterial> open(StoreKind kind);

  Future<void> delete(StoreKind kind);
}

final class PigeonStoreSecurityGateway implements StoreSecurityGateway {
  PigeonStoreSecurityGateway({PlatformSecurityApi? api})
    : _api = api ?? PlatformSecurityApi();

  final PlatformSecurityApi _api;

  @override
  Future<StoreMaterial> open(StoreKind kind) async {
    try {
      final material = await _api.openStore(
        kind == StoreKind.live ? SecureStoreKind.live : SecureStoreKind.demo,
      );
      return StoreMaterial(
        databasePath: material.databasePath,
        passphrase: material.passphrase,
        databaseIsNew: material.created,
      );
    } on PlatformException catch (error) {
      throw StoreSecurityException.fromPlatform(error, kind);
    }
  }

  @override
  Future<void> delete(StoreKind kind) async {
    try {
      await _api.deleteStore(
        kind == StoreKind.live ? SecureStoreKind.live : SecureStoreKind.demo,
      );
    } on PlatformException catch (error) {
      throw StoreSecurityException.fromPlatform(error, kind);
    }
  }
}

final class StoreMaterial {
  const StoreMaterial({
    required this.databasePath,
    required this.passphrase,
    required this.databaseIsNew,
  });

  final String databasePath;
  final String passphrase;
  final bool databaseIsNew;
}

enum StoreSecurityFailure {
  keyMissing,
  keyUnavailable,
  keyRecordsUnreadable,
  deleteFailed,
  unknown,
}

final class StoreSecurityException implements Exception {
  const StoreSecurityException({
    required this.kind,
    required this.failure,
    required this.message,
  });

  factory StoreSecurityException.fromPlatform(
    PlatformException error,
    StoreKind kind,
  ) => StoreSecurityException(
    kind: kind,
    failure: switch (error.code) {
      'STORE_KEY_MISSING' => StoreSecurityFailure.keyMissing,
      'STORE_KEY_UNAVAILABLE' ||
      'STORE_KEY_CREATE_FAILED' => StoreSecurityFailure.keyUnavailable,
      'STORE_KEY_RECORDS_UNREADABLE' || 'STORE_KEY_RECORDS_WRITE_FAILED' =>
        StoreSecurityFailure.keyRecordsUnreadable,
      'STORE_DELETE_FAILED' => StoreSecurityFailure.deleteFailed,
      _ => StoreSecurityFailure.unknown,
    },
    message: error.message ?? 'The encrypted store could not be opened.',
  );

  final StoreKind kind;
  final StoreSecurityFailure failure;
  final String message;

  @override
  String toString() =>
      'StoreSecurityException(${kind.name}, ${failure.name}): $message';
}
