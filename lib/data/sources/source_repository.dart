import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';

abstract final class SourceIds {
  static const ultrahuman = 'ultrahuman';
  static const health = 'health-connect';
  static const calendar = 'android-calendar';
  static const manual = 'manual-checkins';
}

final class PersistedSourceState {
  const PersistedSourceState({
    required this.id,
    required this.sourceType,
    required this.status,
    required this.configuration,
    required this.recordCount,
    required this.updatedAtUtc,
  });

  final String id;
  final String sourceType;
  final String status;
  final Map<String, Object?> configuration;
  final int recordCount;
  final DateTime updatedAtUtc;
}

final class SourceRepository {
  SourceRepository(this.database);

  final VueniverseDatabase database;

  Future<void> initializeLiveSources() async {
    final now = DateTime.now().toUtc();
    for (final source in const [
      (SourceIds.ultrahuman, 'ultrahuman', 'disconnected'),
      (SourceIds.health, 'health_connect', 'disconnected'),
      (SourceIds.calendar, 'calendar', 'disconnected'),
      (SourceIds.manual, 'manual', 'connected_empty'),
    ]) {
      await database
          .into(database.sourceConnections)
          .insert(
            SourceConnectionsCompanion.insert(
              id: source.$1,
              sourceType: source.$2,
              status: source.$3,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  Future<List<PersistedSourceState>> loadStates() async {
    final connections = await database.select(database.sourceConnections).get();
    final result = <PersistedSourceState>[];
    for (final connection in connections.where(
      (row) => const {
        SourceIds.ultrahuman,
        SourceIds.health,
        SourceIds.calendar,
        SourceIds.manual,
      }.contains(row.id),
    )) {
      final indexes = await (database.select(
        database.rawRecordIndex,
      )..where((row) => row.sourceConnectionId.equals(connection.id))).get();
      result.add(
        PersistedSourceState(
          id: connection.id,
          sourceType: connection.sourceType,
          // Older local writes used generic `connected`, and a saved manual
          // report must not reopen as disconnected or empty. Derive only the
          // manual connected/empty read model; never erase an operational state.
          status:
              connection.id == SourceIds.manual &&
                  const {
                    'connected',
                    'connected_empty',
                    'connected_data',
                  }.contains(connection.status)
              ? indexes.isEmpty
                    ? 'connected_empty'
                    : 'connected_data'
              : connection.status,
          configuration: _decodeConfiguration(connection.configurationJson),
          recordCount: indexes.length,
          updatedAtUtc: connection.updatedAt,
        ),
      );
    }
    result.sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  Future<PersistedSourceState?> loadState(String id) async {
    final states = await loadStates();
    return states.where((state) => state.id == id).firstOrNull;
  }

  Future<void> setStatus(
    String sourceId,
    String status, {
    Map<String, Object?> configurationPatch = const {},
  }) async {
    final existing = await (database.select(
      database.sourceConnections,
    )..where((row) => row.id.equals(sourceId))).getSingleOrNull();
    if (existing == null) {
      throw StateError('Source $sourceId has not been initialized.');
    }
    final configuration = {
      ..._decodeConfiguration(existing.configurationJson),
      ...configurationPatch,
    };
    await (database.update(
      database.sourceConnections,
    )..where((row) => row.id.equals(sourceId))).write(
      SourceConnectionsCompanion(
        status: Value(status),
        configurationJson: Value(canonicalJsonEncode(configuration)),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> advanceCollectionGeneration(
    String sourceId,
    String status,
  ) async {
    await database.transaction(() async {
      final source = await loadState(sourceId);
      if (source == null) throw StateError('Source is unavailable');
      final generation = source.configuration['collectionGeneration'];
      await setStatus(
        sourceId,
        status,
        configurationPatch: {
          'collectionGeneration': (generation is int ? generation : 0) + 1,
        },
      );
    });
  }

  Future<void> storePermissions(
    String sourceId,
    Map<String, String> permissions,
  ) async {
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      for (final entry in permissions.entries) {
        await database
            .into(database.sourcePermissions)
            .insertOnConflictUpdate(
              SourcePermissionsCompanion.insert(
                id: '$sourceId:${entry.key}',
                sourceConnectionId: sourceId,
                recordType: entry.key,
                status: entry.value,
                updatedAt: Value(now),
              ),
            );
      }
    });
  }

  Future<Map<String, String>> loadPermissions(String sourceId) async {
    final rows = await (database.select(
      database.sourcePermissions,
    )..where((row) => row.sourceConnectionId.equals(sourceId))).get();
    return {for (final row in rows) row.recordType: row.status};
  }

  Future<String?> getCursor(String sourceId, String recordType) async {
    final row =
        await (database.select(database.syncCursors)..where(
              (row) =>
                  row.sourceConnectionId.equals(sourceId) &
                  row.recordType.equals(recordType),
            ))
            .getSingleOrNull();
    return row?.cursor;
  }

  Future<void> setCursor(
    String sourceId,
    String recordType,
    String cursor,
  ) async {
    await database
        .into(database.syncCursors)
        .insertOnConflictUpdate(
          SyncCursorsCompanion.insert(
            id: '$sourceId:$recordType',
            sourceConnectionId: sourceId,
            recordType: recordType,
            cursor: cursor,
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  Future<void> deleteCursor(String sourceId, String recordType) =>
      (database.delete(database.syncCursors)..where(
            (row) =>
                row.sourceConnectionId.equals(sourceId) &
                row.recordType.equals(recordType),
          ))
          .go();

  Future<void> clearCursors(String sourceId) => (database.delete(
    database.syncCursors,
  )..where((row) => row.sourceConnectionId.equals(sourceId))).go();

  Future<void> markSyncComplete(String sourceId) async {
    final indexes = await (database.select(
      database.rawRecordIndex,
    )..where((row) => row.sourceConnectionId.equals(sourceId))).get();
    await setStatus(
      sourceId,
      indexes.isEmpty ? 'connected_empty' : 'connected_data',
      configurationPatch: {
        'lastSyncUtc': DateTime.now().toUtc().toIso8601String(),
        'failureCount': 0,
        'retryAfterUtc': null,
        'lastErrorCode': null,
        'lastErrorMessage': null,
      },
    );
  }

  Future<void> markFailure(
    String sourceId, {
    required String code,
    required String message,
    required bool retryable,
    int? nativeRetryAfterMillis,
  }) async {
    final state = await loadState(sourceId);
    final previous = state?.configuration['failureCount'];
    final failureCount = (previous is num ? previous.toInt() : 0) + 1;
    final exponentialSeconds = 15 * (1 << (failureCount - 1).clamp(0, 6));
    final delay = Duration(
      milliseconds:
          nativeRetryAfterMillis ?? exponentialSeconds.clamp(15, 900) * 1000,
    );
    await setStatus(
      sourceId,
      'error',
      configurationPatch: {
        'lastErrorCode': code,
        'lastErrorMessage': message,
        'failureCount': failureCount,
        'retryable': retryable,
        'retryAfterUtc': retryable
            ? DateTime.now().toUtc().add(delay).toIso8601String()
            : null,
      },
    );
  }

  Future<bool> canRetryNow(String sourceId) async {
    final state = await loadState(sourceId);
    final raw = state?.configuration['retryAfterUtc'];
    if (raw is! String) return true;
    final retryAt = DateTime.tryParse(raw)?.toUtc();
    return retryAt == null || !retryAt.isAfter(DateTime.now().toUtc());
  }

  Future<void> saveCalendarSelections(Map<String, String> selections) =>
      setStatus(
        SourceIds.calendar,
        'syncing',
        configurationPatch: {'reviewedSeries': selections},
      );

  Future<Map<String, String>> loadCalendarSelections() async {
    final state = await loadState(SourceIds.calendar);
    final raw = state?.configuration['reviewedSeries'];
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  Future<void> clearSourceState(String sourceId) async {
    await database.transaction(() async {
      await (database.delete(
        database.syncCursors,
      )..where((row) => row.sourceConnectionId.equals(sourceId))).go();
      await (database.delete(
        database.sourcePermissions,
      )..where((row) => row.sourceConnectionId.equals(sourceId))).go();
      await setStatus(
        sourceId,
        sourceId == SourceIds.manual ? 'connected_empty' : 'disconnected',
        configurationPatch: {
          'reviewedSeries': <String, String>{},
          'lastSyncUtc': null,
          'lastErrorCode': null,
          'lastErrorMessage': null,
          'failureCount': 0,
          'retryAfterUtc': null,
          if (sourceId == SourceIds.ultrahuman) 'credentialBinding': null,
          if (sourceId == SourceIds.ultrahuman) 'reportedTimezone': null,
          if (sourceId == SourceIds.ultrahuman) 'unsupportedMetricTypes': null,
        },
      );
    });
  }

  Map<String, Object?> _decodeConfiguration(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return decoded;
      if (decoded is Map) {
        return {
          for (final entry in decoded.entries) '${entry.key}': entry.value,
        };
      }
    } on FormatException {
      // Treat a corrupt non-sensitive status blob as empty and overwrite it.
    }
    return <String, Object?>{};
  }
}
