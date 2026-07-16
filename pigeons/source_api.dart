import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/generated/source_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/whypulse/why_pulse/sources/SourceApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.whypulse.why_pulse.sources'),
    dartPackageName: 'why_pulse',
  ),
)
enum SourcePlatformKind { healthConnect, calendar }

enum HealthDataType { heartRate, sleep, steps, exercise, activity, hrvRmssd }

enum HealthAvailabilityStatus { available, updateRequired, unavailable }

enum NativePermissionState { granted, denied, unavailable }

class NativeFeatureState {
  NativeFeatureState({required this.name, required this.available});

  String name;
  bool available;
}

class NativeHealthAvailability {
  NativeHealthAvailability({
    required this.status,
    required this.features,
    this.providerPackage,
  });

  HealthAvailabilityStatus status;
  List<NativeFeatureState> features;
  String? providerPackage;
}

class NativeHealthPermission {
  NativeHealthPermission({required this.type, required this.state});

  HealthDataType type;
  NativePermissionState state;
}

class NativeHealthPermissionSnapshot {
  NativeHealthPermissionSnapshot({required this.permissions});

  List<NativeHealthPermission> permissions;
}

class NativeSourceFailure {
  NativeSourceFailure({
    required this.code,
    required this.message,
    required this.retryable,
    required this.openSettingsRecommended,
    this.retryAfterMillis,
  });

  String code;
  String message;
  bool retryable;
  bool openSettingsRecommended;
  int? retryAfterMillis;
}

class NativeNumericSample {
  NativeNumericSample({
    required this.epochMillis,
    required this.offsetMinutes,
    required this.value,
  });

  int epochMillis;
  int offsetMinutes;
  double value;
}

class NativeIntervalSegment {
  NativeIntervalSegment({
    required this.startEpochMillis,
    required this.endEpochMillis,
    required this.category,
  });

  int startEpochMillis;
  int endEpochMillis;
  String category;
}

class NativeHealthRecord {
  NativeHealthRecord({
    required this.id,
    required this.type,
    required this.startEpochMillis,
    required this.endEpochMillis,
    required this.startOffsetMinutes,
    required this.endOffsetMinutes,
    required this.lastModifiedEpochMillis,
    required this.samples,
    required this.segments,
    this.value,
    this.unit,
    this.category,
  });

  String id;
  HealthDataType type;
  int startEpochMillis;
  int endEpochMillis;
  int startOffsetMinutes;
  int endOffsetMinutes;
  int lastModifiedEpochMillis;
  List<NativeNumericSample> samples;
  List<NativeIntervalSegment> segments;
  double? value;
  String? unit;
  String? category;
}

class NativeHealthPage {
  NativeHealthPage({required this.records, this.nextPageToken});

  List<NativeHealthRecord> records;
  String? nextPageToken;
}

class NativeHealthPageResult {
  NativeHealthPageResult({this.page, this.failure});

  NativeHealthPage? page;
  NativeSourceFailure? failure;
}

class NativeHealthChanges {
  NativeHealthChanges({
    required this.upserts,
    required this.deletedRecordIds,
    required this.nextChangesToken,
    required this.hasMore,
    required this.tokenExpired,
  });

  List<NativeHealthRecord> upserts;
  List<String> deletedRecordIds;
  String nextChangesToken;
  bool hasMore;
  bool tokenExpired;
}

class NativeHealthChangesResult {
  NativeHealthChangesResult({this.changes, this.failure});

  NativeHealthChanges? changes;
  NativeSourceFailure? failure;
}

class NativeHealthTokenResult {
  NativeHealthTokenResult({this.token, this.failure});

  String? token;
  NativeSourceFailure? failure;
}

class NativeCalendarPermissionSnapshot {
  NativeCalendarPermissionSnapshot({
    required this.state,
    required this.shouldShowRationale,
  });

  NativePermissionState state;
  bool shouldShowRationale;
}

class NativeCalendarSeries {
  NativeCalendarSeries({
    required this.id,
    required this.title,
    required this.recurrenceRule,
    required this.timeZone,
  });

  String id;
  String title;
  String recurrenceRule;
  String timeZone;
}

class NativeCalendarDiscoveryResult {
  NativeCalendarDiscoveryResult({required this.series, this.failure});

  List<NativeCalendarSeries> series;
  NativeSourceFailure? failure;
}

class NativeCalendarInstance {
  NativeCalendarInstance({
    required this.instanceId,
    required this.seriesId,
    required this.startEpochMillis,
    required this.endEpochMillis,
    required this.offsetMinutes,
  });

  String instanceId;
  String seriesId;
  int startEpochMillis;
  int endEpochMillis;
  int offsetMinutes;
}

class NativeCalendarSnapshotResult {
  NativeCalendarSnapshotResult({
    required this.instances,
    required this.complete,
    this.failure,
  });

  List<NativeCalendarInstance> instances;
  bool complete;
  NativeSourceFailure? failure;
}

@HostApi()
abstract class SourceApi {
  @async
  NativeHealthAvailability getHealthAvailability();

  @async
  NativeHealthPermissionSnapshot getHealthPermissionSnapshot();

  @async
  NativeHealthPermissionSnapshot requestHealthPermissions(
    List<HealthDataType> types,
  );

  @async
  NativeHealthPageResult readHealthPage(
    HealthDataType type,
    int startEpochMillis,
    int endEpochMillis,
    String? pageToken,
    int pageSize,
  );

  @async
  NativeHealthTokenResult createHealthChangesToken(HealthDataType type);

  @async
  NativeHealthChangesResult readHealthChanges(
    HealthDataType type,
    String changesToken,
  );

  NativeCalendarPermissionSnapshot getCalendarPermissionSnapshot();

  @async
  NativeCalendarPermissionSnapshot requestCalendarPermission();

  @async
  NativeCalendarDiscoveryResult discoverRecurringCalendarSeries();

  @async
  NativeCalendarSnapshotResult readRecurringCalendarSnapshot(
    int startEpochMillis,
    int endEpochMillis,
  );

  void openSourceSettings(SourcePlatformKind kind);
}
