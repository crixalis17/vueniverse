import 'package:why_pulse/platform/generated/source_api.g.dart';

abstract interface class SourcePlatformGateway {
  Future<NativeHealthAvailability> getHealthAvailability();

  Future<NativeHealthPermissionSnapshot> getHealthPermissionSnapshot();

  Future<NativeHealthPermissionSnapshot> requestHealthPermissions(
    List<HealthDataType> types,
  );

  Future<NativeHealthPageResult> readHealthPage(
    HealthDataType type,
    int startEpochMillis,
    int endEpochMillis,
    String? pageToken,
    int pageSize,
  );

  Future<NativeHealthTokenResult> createHealthChangesToken(HealthDataType type);

  Future<NativeHealthChangesResult> readHealthChanges(
    HealthDataType type,
    String changesToken,
  );

  Future<NativeCalendarPermissionSnapshot> getCalendarPermissionSnapshot();

  Future<NativeCalendarPermissionSnapshot> requestCalendarPermission();

  Future<NativeCalendarDiscoveryResult> discoverRecurringCalendarSeries();

  Future<NativeCalendarSnapshotResult> readRecurringCalendarSnapshot(
    int startEpochMillis,
    int endEpochMillis,
  );

  Future<void> openSourceSettings(SourcePlatformKind kind);
}

final class PigeonSourcePlatformGateway implements SourcePlatformGateway {
  PigeonSourcePlatformGateway({SourceApi? api}) : _api = api ?? SourceApi();

  final SourceApi _api;

  @override
  Future<NativeHealthAvailability> getHealthAvailability() =>
      _api.getHealthAvailability();

  @override
  Future<NativeHealthPermissionSnapshot> getHealthPermissionSnapshot() =>
      _api.getHealthPermissionSnapshot();

  @override
  Future<NativeHealthPermissionSnapshot> requestHealthPermissions(
    List<HealthDataType> types,
  ) => _api.requestHealthPermissions(types);

  @override
  Future<NativeHealthPageResult> readHealthPage(
    HealthDataType type,
    int startEpochMillis,
    int endEpochMillis,
    String? pageToken,
    int pageSize,
  ) => _api.readHealthPage(
    type,
    startEpochMillis,
    endEpochMillis,
    pageToken,
    pageSize,
  );

  @override
  Future<NativeHealthTokenResult> createHealthChangesToken(
    HealthDataType type,
  ) => _api.createHealthChangesToken(type);

  @override
  Future<NativeHealthChangesResult> readHealthChanges(
    HealthDataType type,
    String changesToken,
  ) => _api.readHealthChanges(type, changesToken);

  @override
  Future<NativeCalendarPermissionSnapshot> getCalendarPermissionSnapshot() =>
      _api.getCalendarPermissionSnapshot();

  @override
  Future<NativeCalendarPermissionSnapshot> requestCalendarPermission() =>
      _api.requestCalendarPermission();

  @override
  Future<NativeCalendarDiscoveryResult> discoverRecurringCalendarSeries() =>
      _api.discoverRecurringCalendarSeries();

  @override
  Future<NativeCalendarSnapshotResult> readRecurringCalendarSnapshot(
    int startEpochMillis,
    int endEpochMillis,
  ) => _api.readRecurringCalendarSnapshot(startEpochMillis, endEpochMillis);

  @override
  Future<void> openSourceSettings(SourcePlatformKind kind) =>
      _api.openSourceSettings(kind);
}
