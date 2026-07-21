import 'dart:convert';

import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/sources/health_record_mapper.dart';
import 'package:vueniverse/data/sources/source_platform_gateway.dart';
import 'package:vueniverse/data/sources/source_repository.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/platform/generated/source_api.g.dart';

final class CalendarReviewSeries {
  const CalendarReviewSeries({
    required this.transientId,
    required this.title,
    required this.recurrenceRule,
    required this.timeZone,
    this.category,
  });

  final String transientId;
  final String title;
  final String recurrenceRule;
  final String timeZone;
  final String? category;
}

final class SourceSyncService {
  SourceSyncService({
    required this.platform,
    required this.sources,
    required this.canonicalRecords,
    required this.normalizer,
    this.healthMapper = const HealthRecordMapper(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SourcePlatformGateway platform;
  final SourceRepository sources;
  final CanonicalRecordRepository canonicalRecords;
  final RecordNormalizer normalizer;
  final HealthRecordMapper healthMapper;
  final DateTime Function() _clock;

  static const _healthTypes = HealthDataType.values;

  Future<void> initialize() async {
    await sources.initializeLiveSources();
    await refreshNativeStates();
  }

  Future<List<PersistedSourceState>> loadStates() => sources.loadStates();

  Future<void> refreshNativeStates() async {
    final healthState = await sources.loadState(SourceIds.health);
    if (healthState?.status != 'paused') {
      final availability = await platform.getHealthAvailability();
      if (availability.status != HealthAvailabilityStatus.available) {
        await sources.setStatus(SourceIds.health, 'unavailable');
      } else {
        final snapshot = await platform.getHealthPermissionSnapshot();
        await _persistHealthPermissions(snapshot);
        final granted = snapshot.permissions
            .where(
              (permission) => permission.state == NativePermissionState.granted,
            )
            .length;
        if (granted == 0) {
          await sources.setStatus(SourceIds.health, 'permission_required');
        } else if (granted < _healthTypes.length) {
          await sources.setStatus(SourceIds.health, 'partially_permitted');
        } else if (healthState == null ||
            const {
              'disconnected',
              'unavailable',
              'permission_required',
            }.contains(healthState.status)) {
          await sources.setStatus(
            SourceIds.health,
            healthState?.recordCount == 0
                ? 'connected_empty'
                : 'connected_data',
          );
        }
      }
    }

    final calendarState = await sources.loadState(SourceIds.calendar);
    if (calendarState?.status != 'paused') {
      final permission = await platform.getCalendarPermissionSnapshot();
      await sources.storePermissions(SourceIds.calendar, {
        'read_calendar': permission.state.name,
      });
      if (permission.state != NativePermissionState.granted) {
        await sources.setStatus(SourceIds.calendar, 'permission_required');
      } else if (calendarState == null ||
          const {
            'disconnected',
            'permission_required',
          }.contains(calendarState.status)) {
        await sources.setStatus(
          SourceIds.calendar,
          calendarState?.recordCount == 0
              ? 'connected_empty'
              : 'connected_data',
        );
      }
    }
  }

  Future<void> onAppResumed() async {
    await refreshNativeStates();
    final states = await sources.loadStates();
    final health = states
        .where((state) => state.id == SourceIds.health)
        .firstOrNull;
    if (health != null &&
        const {
          'connected_empty',
          'connected_data',
          'partially_permitted',
          'error',
          'stale',
        }.contains(health.status) &&
        await sources.canRetryNow(SourceIds.health)) {
      await syncHealth();
    }
    final calendar = states
        .where((state) => state.id == SourceIds.calendar)
        .firstOrNull;
    if (calendar != null &&
        const {
          'connected_empty',
          'connected_data',
          'error',
          'stale',
        }.contains(calendar.status) &&
        (await sources.loadCalendarSelections()).isNotEmpty &&
        await sources.canRetryNow(SourceIds.calendar)) {
      await syncCalendar();
    }
  }

  Future<void> connectHealth() async {
    final availability = await platform.getHealthAvailability();
    if (availability.status != HealthAvailabilityStatus.available) {
      await sources.setStatus(SourceIds.health, 'unavailable');
      return;
    }
    final permissions = await platform.requestHealthPermissions(_healthTypes);
    await _persistHealthPermissions(permissions);
    if (!permissions.permissions.any(
      (permission) => permission.state == NativePermissionState.granted,
    )) {
      await sources.setStatus(SourceIds.health, 'permission_required');
      return;
    }
    await syncHealth(ignoreBackoff: true);
  }

  Future<List<CalendarReviewSeries>> connectCalendar() async {
    final permission = await platform.requestCalendarPermission();
    await sources.storePermissions(SourceIds.calendar, {
      'read_calendar': permission.state.name,
    });
    if (permission.state != NativePermissionState.granted) {
      await sources.setStatus(SourceIds.calendar, 'permission_required');
      return const [];
    }
    await sources.setStatus(SourceIds.calendar, 'syncing');
    final result = await platform.discoverRecurringCalendarSeries();
    if (result.failure case final failure?) {
      await _recordFailure(SourceIds.calendar, failure);
      return const [];
    }
    if (result.series.isEmpty) {
      await sources.setStatus(SourceIds.calendar, 'connected_empty');
    }
    final selections = await sources.loadCalendarSelections();
    final current = await sources.loadState(SourceIds.calendar);
    if (result.series.isNotEmpty) {
      await sources.setStatus(
        SourceIds.calendar,
        (current?.recordCount ?? 0) == 0 ? 'connected_empty' : 'connected_data',
      );
    }
    return result.series
        .map(
          (series) => CalendarReviewSeries(
            transientId: series.id,
            title: series.title,
            recurrenceRule: series.recurrenceRule,
            timeZone: series.timeZone,
            category:
                selections[normalizer
                    .sourceRecordIdentity(series.id)
                    .substring('hmac:'.length)],
          ),
        )
        .toList(growable: false);
  }

  Future<void> saveCalendarReview(
    Map<String, ContextCategory> reviewedSeries,
  ) async {
    final persisted = <String, String>{};
    for (final entry in reviewedSeries.entries) {
      final hmac = normalizer
          .sourceRecordIdentity(entry.key)
          .substring('hmac:'.length);
      persisted[hmac] = switch (entry.value) {
        ContextCategory.recurringOneToOne => 'recurring_one_to_one',
        ContextCategory.teamMeeting => 'team_meeting',
        ContextCategory.otherRecurringMeeting => 'other_recurring_meeting',
      };
    }
    await sources.saveCalendarSelections(persisted);
    await syncCalendar(ignoreBackoff: true);
  }

  Future<void> refresh(String sourceId) async {
    switch (sourceId) {
      case SourceIds.health:
        await syncHealth(ignoreBackoff: true);
      case SourceIds.calendar:
        await syncCalendar(ignoreBackoff: true);
      case SourceIds.manual:
        await sources.markSyncComplete(SourceIds.manual);
    }
  }

  Future<void> syncHealth({bool ignoreBackoff = false}) async {
    if (!ignoreBackoff && !await sources.canRetryNow(SourceIds.health)) return;
    final state = await sources.loadState(SourceIds.health);
    if (state?.status == 'paused' || state?.status == 'disconnected') return;
    final permissions = await platform.getHealthPermissionSnapshot();
    await _persistHealthPermissions(permissions);
    final grantedTypes = permissions.permissions
        .where(
          (permission) => permission.state == NativePermissionState.granted,
        )
        .map((permission) => permission.type)
        .toList(growable: false);
    if (grantedTypes.isEmpty) {
      await sources.setStatus(SourceIds.health, 'permission_required');
      return;
    }

    await sources.setStatus(SourceIds.health, 'syncing');
    try {
      for (final type in grantedTypes) {
        await _syncHealthType(type);
      }
      await sources.markSyncComplete(SourceIds.health);
      if (grantedTypes.length < _healthTypes.length) {
        await sources.setStatus(SourceIds.health, 'partially_permitted');
      }
    } on SourceOperationException catch (error) {
      await _recordFailure(SourceIds.health, error.failure);
    }
  }

  Future<void> _syncHealthType(HealthDataType type) async {
    final cursorKey = 'health_${type.name}';
    final rawCursor = await sources.getCursor(SourceIds.health, cursorKey);
    if (rawCursor == null) {
      await _runInitialHealthRead(type, cursorKey);
      return;
    }
    final cursor = _decodeCursor(rawCursor);
    if (cursor['mode'] == 'initial') {
      await _runInitialHealthRead(type, cursorKey, existingCursor: cursor);
      return;
    }
    final token = cursor['token'];
    if (cursor['mode'] != 'changes' || token is! String || token.isEmpty) {
      await sources.deleteCursor(SourceIds.health, cursorKey);
      await _runInitialHealthRead(type, cursorKey);
      return;
    }
    await _runHealthChanges(type, cursorKey, token);
  }

  Future<void> _runInitialHealthRead(
    HealthDataType type,
    String cursorKey, {
    Map<String, Object?>? existingCursor,
  }) async {
    final now = _clock().toUtc();
    final startMillis =
        existingCursor?['startEpochMillis'] as int? ??
        now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final endMillis =
        existingCursor?['endEpochMillis'] as int? ?? now.millisecondsSinceEpoch;
    var pageToken = existingCursor?['pageToken'] as String?;
    while (true) {
      final result = await platform.readHealthPage(
        type,
        startMillis,
        endMillis,
        pageToken,
        500,
      );
      if (result.failure case final failure?) {
        throw SourceOperationException(failure);
      }
      final page = result.page;
      if (page == null) {
        throw SourceOperationException(
          _invalidNativeResult('health_page_missing'),
        );
      }
      final envelopes = page.records
          .expand(healthMapper.toEnvelopes)
          .toList(growable: false);
      await canonicalRecords.importRecords(
        sourceConnectionId: SourceIds.health,
        sourceKind: SourceKind.healthConnect,
        records: envelopes,
        normalizer: normalizer,
        syncRunId: _syncRunId('health_initial_${type.name}'),
      );
      pageToken = page.nextPageToken;
      if (pageToken == null || pageToken.isEmpty) break;
      await sources.setCursor(
        SourceIds.health,
        cursorKey,
        canonicalJsonEncode({
          'mode': 'initial',
          'startEpochMillis': startMillis,
          'endEpochMillis': endMillis,
          'pageToken': pageToken,
        }),
      );
    }

    final tokenResult = await platform.createHealthChangesToken(type);
    if (tokenResult.failure case final failure?) {
      throw SourceOperationException(failure);
    }
    final token = tokenResult.token;
    if (token == null || token.isEmpty) {
      throw SourceOperationException(
        _invalidNativeResult('health_token_missing'),
      );
    }
    await sources.setCursor(
      SourceIds.health,
      cursorKey,
      canonicalJsonEncode({'mode': 'changes', 'token': token}),
    );
  }

  Future<void> _runHealthChanges(
    HealthDataType type,
    String cursorKey,
    String initialToken,
  ) async {
    var token = initialToken;
    while (true) {
      final result = await platform.readHealthChanges(type, token);
      if (result.failure case final failure?) {
        throw SourceOperationException(failure);
      }
      final changes = result.changes;
      if (changes == null) {
        throw SourceOperationException(
          _invalidNativeResult('health_changes_missing'),
        );
      }
      if (changes.tokenExpired) {
        await sources.deleteCursor(SourceIds.health, cursorKey);
        await _runInitialHealthRead(type, cursorKey);
        return;
      }

      final replacedParents = changes.upserts
          .map((record) => record.id)
          .toSet();
      await canonicalRecords.deleteParentRecords(
        sourceConnectionId: SourceIds.health,
        stableParentIds: {...replacedParents, ...changes.deletedRecordIds},
        normalizer: normalizer,
      );
      final envelopes = changes.upserts
          .expand(healthMapper.toEnvelopes)
          .toList(growable: false);
      if (envelopes.isNotEmpty) {
        await canonicalRecords.importRecords(
          sourceConnectionId: SourceIds.health,
          sourceKind: SourceKind.healthConnect,
          records: envelopes,
          normalizer: normalizer,
          syncRunId: _syncRunId('health_changes_${type.name}'),
        );
      }

      token = changes.nextChangesToken;
      await sources.setCursor(
        SourceIds.health,
        cursorKey,
        canonicalJsonEncode({'mode': 'changes', 'token': token}),
      );
      if (!changes.hasMore) break;
    }
  }

  Future<void> syncCalendar({bool ignoreBackoff = false}) async {
    if (!ignoreBackoff && !await sources.canRetryNow(SourceIds.calendar)) {
      return;
    }
    final state = await sources.loadState(SourceIds.calendar);
    if (state?.status == 'paused' || state?.status == 'disconnected') return;
    final permission = await platform.getCalendarPermissionSnapshot();
    await sources.storePermissions(SourceIds.calendar, {
      'read_calendar': permission.state.name,
    });
    if (permission.state != NativePermissionState.granted) {
      await sources.setStatus(SourceIds.calendar, 'permission_required');
      return;
    }
    final selections = await sources.loadCalendarSelections();
    if (selections.isEmpty) {
      await sources.setStatus(SourceIds.calendar, 'connected_empty');
      return;
    }
    await sources.setStatus(SourceIds.calendar, 'syncing');
    final now = _clock().toUtc();
    final start = now.subtract(const Duration(days: 30));
    final end = now.add(const Duration(days: 30));
    final result = await platform.readRecurringCalendarSnapshot(
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    );
    if (result.failure case final failure?) {
      await _recordFailure(SourceIds.calendar, failure);
      return;
    }
    if (!result.complete) {
      await sources.setStatus(
        SourceIds.calendar,
        'stale',
        configurationPatch: {
          'lastErrorCode': 'calendar_snapshot_interrupted',
          'lastErrorMessage':
              'The previous complete Calendar snapshot was kept.',
        },
      );
      return;
    }

    final selectedInstances = <NativeCalendarInstance>[];
    final envelopes = <SourceRecordEnvelope>[];
    for (final instance in result.instances) {
      final seriesHmac = normalizer
          .sourceRecordIdentity(instance.seriesId)
          .substring('hmac:'.length);
      final category = selections[seriesHmac];
      if (category == null) continue;
      selectedInstances.add(instance);
      envelopes.add(
        SourceRecordEnvelope(
          source: SourceKind.calendar,
          recordType: 'calendar_event',
          payload: {
            'start': DateTime.fromMillisecondsSinceEpoch(
              instance.startEpochMillis,
              isUtc: true,
            ).toIso8601String(),
            'end': DateTime.fromMillisecondsSinceEpoch(
              instance.endEpochMillis,
              isUtc: true,
            ).toIso8601String(),
            'offset_minutes': instance.offsetMinutes,
            'category': category,
            'recurrence_id': instance.seriesId,
          },
          observedAt: now,
          stableSourceId: instance.instanceId,
        ),
      );
    }
    await canonicalRecords.importRecords(
      sourceConnectionId: SourceIds.calendar,
      sourceKind: SourceKind.calendar,
      records: envelopes,
      normalizer: normalizer,
      syncRunId: _syncRunId('calendar_snapshot'),
    );
    await canonicalRecords.deleteAbsentSnapshotRecords(
      sourceConnectionId: SourceIds.calendar,
      seenStableIds: selectedInstances.map((instance) => instance.instanceId),
      normalizer: normalizer,
    );
    await sources.markSyncComplete(SourceIds.calendar);
  }

  Future<void> pause(String sourceId) => sources.setStatus(sourceId, 'paused');

  Future<void> resume(String sourceId) async {
    await sources.setStatus(sourceId, 'stale');
    await refresh(sourceId);
  }

  Future<void> disconnect(String sourceId) =>
      sources.setStatus(sourceId, 'disconnected');

  Future<void> deleteSourceData(String sourceId) async {
    await sources.setStatus(sourceId, 'deleting');
    await canonicalRecords.deleteAllForSource(
      sourceConnectionId: sourceId,
      reason: 'source_data_deleted',
    );
    await sources.clearSourceState(sourceId);
  }

  Future<void> openSettings(String sourceId) => platform.openSourceSettings(
    sourceId == SourceIds.health
        ? SourcePlatformKind.healthConnect
        : SourcePlatformKind.calendar,
  );

  Future<void> _persistHealthPermissions(
    NativeHealthPermissionSnapshot snapshot,
  ) => sources.storePermissions(SourceIds.health, {
    for (final permission in snapshot.permissions)
      permission.type.name: permission.state.name,
  });

  Future<void> _recordFailure(String sourceId, NativeSourceFailure failure) =>
      sources.markFailure(
        sourceId,
        code: failure.code,
        message: failure.message,
        retryable: failure.retryable,
        nativeRetryAfterMillis: failure.retryAfterMillis,
      );

  NativeSourceFailure _invalidNativeResult(String code) => NativeSourceFailure(
    code: code,
    message: 'Android returned an incomplete source response.',
    retryable: true,
    openSettingsRecommended: false,
  );

  String _syncRunId(String prefix) =>
      '$prefix-${_clock().toUtc().microsecondsSinceEpoch}';

  Map<String, Object?> _decodeCursor(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return decoded;
      if (decoded is Map) {
        return {
          for (final entry in decoded.entries) '${entry.key}': entry.value,
        };
      }
    } on FormatException {
      // A malformed cursor is discarded and replaced by a safe full read.
    }
    return const {};
  }
}

final class SourceOperationException implements Exception {
  const SourceOperationException(this.failure);

  final NativeSourceFailure failure;
}
