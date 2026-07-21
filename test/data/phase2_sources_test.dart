import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/sources/manual_checkin_repository.dart';
import 'package:vueniverse/data/sources/source_platform_gateway.dart';
import 'package:vueniverse/data/sources/source_repository.dart';
import 'package:vueniverse/data/sources/source_sync_service.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/source_api.g.dart';

void main() {
  late VueniverseDatabase database;
  late RecordNormalizer normalizer;
  late CanonicalRecordRepository canonical;
  late SourceRepository sourceRepository;
  late _FakeSourcePlatform platform;
  late SourceSyncService sync;

  setUp(() async {
    database = VueniverseDatabase.forTesting(NativeDatabase.memory());
    await database.initialize(kind: StoreKind.live);
    normalizer = RecordNormalizer(
      identityKey: List<int>.generate(32, (i) => i),
    );
    canonical = CanonicalRecordRepository(database);
    sourceRepository = SourceRepository(database);
    platform = _FakeSourcePlatform();
    sync = SourceSyncService(
      platform: platform,
      sources: sourceRepository,
      canonicalRecords: canonical,
      normalizer: normalizer,
      clock: () => DateTime.utc(2026, 7, 16, 12),
    );
    await sync.initialize();
  });

  tearDown(() => database.close());

  test(
    'Health pages commit before cursor advancement and changes replace children',
    () async {
      platform.healthRecords = [
        _heartRecord('heart-parent', [70, 72]),
      ];
      await sync.syncHealth(ignoreBackoff: true);

      expect(await database.select(database.signalSamples).get(), hasLength(2));
      final cursor = await sourceRepository.getCursor(
        SourceIds.health,
        'health_heartRate',
      );
      expect(cursor, contains('changes-token-1'));

      platform.healthChanges = NativeHealthChanges(
        upserts: [
          _heartRecord('heart-parent', [74]),
        ],
        deletedRecordIds: const [],
        nextChangesToken: 'changes-token-2',
        hasMore: false,
        tokenExpired: false,
      );
      await sync.syncHealth(ignoreBackoff: true);
      final samples = await database.select(database.signalSamples).get();
      expect(samples, hasLength(1));
      expect(samples.single.value, 74);
      expect(
        await sourceRepository.getCursor(SourceIds.health, 'health_heartRate'),
        contains('changes-token-2'),
      );

      platform.healthChanges = NativeHealthChanges(
        upserts: const [],
        deletedRecordIds: const ['heart-parent'],
        nextChangesToken: 'changes-token-3',
        hasMore: false,
        tokenExpired: false,
      );
      await sync.syncHealth(ignoreBackoff: true);
      expect(await database.select(database.signalSamples).get(), isEmpty);
      expect(await database.select(database.deletionAudit).get(), isNotEmpty);
    },
  );

  test('a failed initial Health page never creates a cursor', () async {
    platform.healthPageFailure = NativeSourceFailure(
      code: 'rate_limited',
      message: 'The Android provider is temporarily unavailable.',
      retryable: true,
      openSettingsRecommended: false,
      retryAfterMillis: 30000,
    );
    await sourceRepository.deleteCursor(SourceIds.health, 'health_heartRate');
    await sync.syncHealth(ignoreBackoff: true);

    expect(
      await sourceRepository.getCursor(SourceIds.health, 'health_heartRate'),
      isNull,
    );
    final state = await sourceRepository.loadState(SourceIds.health);
    expect(state!.status, 'error');
    expect(state.configuration['retryAfterUtc'], isNotNull);
  });

  test(
    'Calendar titles are transient and incomplete snapshots keep prior data',
    () async {
      platform.calendarSeries = [
        NativeCalendarSeries(
          id: 'raw-series-1',
          title: 'Private Weekly Title',
          recurrenceRule: 'FREQ=WEEKLY',
          timeZone: 'Asia/Kolkata',
        ),
      ];
      platform.calendarSnapshot = NativeCalendarSnapshotResult(
        instances: [
          NativeCalendarInstance(
            instanceId: 'raw-instance-1',
            seriesId: 'raw-series-1',
            startEpochMillis: DateTime.utc(
              2026,
              7,
              15,
              5,
            ).millisecondsSinceEpoch,
            endEpochMillis: DateTime.utc(2026, 7, 15, 6).millisecondsSinceEpoch,
            offsetMinutes: 330,
          ),
        ],
        complete: true,
      );

      final discovered = await sync.connectCalendar();
      expect(discovered.single.title, 'Private Weekly Title');
      await sync.saveCalendarReview({
        'raw-series-1': ContextCategory.recurringOneToOne,
      });

      final events = await database.select(database.contextEvents).get();
      expect(events, hasLength(1));
      final connection = await (database.select(
        database.sourceConnections,
      )..where((row) => row.id.equals(SourceIds.calendar))).getSingle();
      expect(connection.configurationJson, isNot(contains('raw-series-1')));
      expect(
        connection.configurationJson,
        isNot(contains('Private Weekly Title')),
      );
      expect(events.single.provenanceJson, isNot(contains('raw-series-1')));

      platform.calendarSnapshot = NativeCalendarSnapshotResult(
        instances: const [],
        complete: false,
      );
      await sync.syncCalendar(ignoreBackoff: true);
      expect(await database.select(database.contextEvents).get(), hasLength(1));
      expect(
        (await sourceRepository.loadState(SourceIds.calendar))!.status,
        'stale',
      );

      platform.calendarSnapshot = NativeCalendarSnapshotResult(
        instances: const [],
        complete: true,
      );
      await sync.syncCalendar(ignoreBackoff: true);
      expect(await database.select(database.contextEvents).get(), isEmpty);
    },
  );

  test(
    'Manual Check-ins add edit and delete through encrypted repositories',
    () async {
      final repository = ManualCheckinRepository(
        database: database,
        canonicalRecords: canonical,
        normalizer: normalizer,
        clock: () => DateTime.utc(2026, 7, 16, 12),
      );
      const id = 'manual-checkin-1';
      await repository.save(
        ManualCheckinRecord(
          id: id,
          category: CheckinCategory.caffeine,
          occurredAt: DateTime.utc(2026, 7, 16, 8),
          detail: 'One coffee',
        ),
      );
      expect((await repository.load()).single.detail, 'One coffee');

      await repository.save(
        ManualCheckinRecord(
          id: id,
          category: CheckinCategory.caffeine,
          occurredAt: DateTime.utc(2026, 7, 16, 8),
          detail: 'Two coffees',
        ),
      );
      final edited = await repository.load();
      expect(edited, hasLength(1));
      expect(edited.single.detail, 'Two coffees');

      expect(await repository.delete(id), isTrue);
      expect(await repository.load(), isEmpty);
      final reasons = (await database.select(database.recomputeJobs).get())
          .map((job) => job.reason)
          .join(',');
      expect(reasons, contains('manual_checkin_deleted'));
    },
  );
}

NativeHealthRecord _heartRecord(
  String id,
  List<int> values,
) => NativeHealthRecord(
  id: id,
  type: HealthDataType.heartRate,
  startEpochMillis: DateTime.utc(2026, 7, 16, 9).millisecondsSinceEpoch,
  endEpochMillis: DateTime.utc(2026, 7, 16, 9, 5).millisecondsSinceEpoch,
  startOffsetMinutes: 0,
  endOffsetMinutes: 0,
  lastModifiedEpochMillis: DateTime.utc(2026, 7, 16, 10).millisecondsSinceEpoch,
  samples: [
    for (var index = 0; index < values.length; index++)
      NativeNumericSample(
        epochMillis: DateTime.utc(2026, 7, 16, 9, index).millisecondsSinceEpoch,
        offsetMinutes: 0,
        value: values[index].toDouble(),
      ),
  ],
  segments: const [],
  unit: 'bpm',
);

final class _FakeSourcePlatform implements SourcePlatformGateway {
  List<NativeHealthRecord> healthRecords = [];
  NativeSourceFailure? healthPageFailure;
  NativeHealthChanges? healthChanges;
  List<NativeCalendarSeries> calendarSeries = [];
  NativeCalendarSnapshotResult calendarSnapshot = NativeCalendarSnapshotResult(
    instances: const [],
    complete: true,
  );

  NativeHealthPermissionSnapshot get permissions =>
      NativeHealthPermissionSnapshot(
        permissions: [
          for (final type in HealthDataType.values)
            NativeHealthPermission(
              type: type,
              state: type == HealthDataType.heartRate
                  ? NativePermissionState.granted
                  : NativePermissionState.denied,
            ),
        ],
      );

  @override
  Future<NativeHealthAvailability> getHealthAvailability() async =>
      NativeHealthAvailability(
        status: HealthAvailabilityStatus.available,
        features: [NativeFeatureState(name: 'change_tokens', available: true)],
      );

  @override
  Future<NativeHealthPermissionSnapshot> getHealthPermissionSnapshot() async =>
      permissions;

  @override
  Future<NativeHealthPermissionSnapshot> requestHealthPermissions(
    List<HealthDataType> types,
  ) async => permissions;

  @override
  Future<NativeHealthPageResult> readHealthPage(
    HealthDataType type,
    int startEpochMillis,
    int endEpochMillis,
    String? pageToken,
    int pageSize,
  ) async => NativeHealthPageResult(
    page: healthPageFailure == null
        ? NativeHealthPage(records: healthRecords)
        : null,
    failure: healthPageFailure,
  );

  @override
  Future<NativeHealthTokenResult> createHealthChangesToken(
    HealthDataType type,
  ) async => NativeHealthTokenResult(token: 'changes-token-1');

  @override
  Future<NativeHealthChangesResult> readHealthChanges(
    HealthDataType type,
    String changesToken,
  ) async => NativeHealthChangesResult(
    changes:
        healthChanges ??
        NativeHealthChanges(
          upserts: const [],
          deletedRecordIds: const [],
          nextChangesToken: changesToken,
          hasMore: false,
          tokenExpired: false,
        ),
  );

  @override
  Future<NativeCalendarPermissionSnapshot>
  getCalendarPermissionSnapshot() async => NativeCalendarPermissionSnapshot(
    state: NativePermissionState.granted,
    shouldShowRationale: false,
  );

  @override
  Future<NativeCalendarPermissionSnapshot> requestCalendarPermission() =>
      getCalendarPermissionSnapshot();

  @override
  Future<NativeCalendarDiscoveryResult>
  discoverRecurringCalendarSeries() async =>
      NativeCalendarDiscoveryResult(series: calendarSeries);

  @override
  Future<NativeCalendarSnapshotResult> readRecurringCalendarSnapshot(
    int startEpochMillis,
    int endEpochMillis,
  ) async => calendarSnapshot;

  @override
  Future<void> openSourceSettings(SourcePlatformKind kind) async {}
}
