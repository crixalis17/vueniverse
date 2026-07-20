import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:vueniverse/data/database/schema_versions.dart';
import 'package:vueniverse/data/database/tables.dart';
import 'package:vueniverse/domain/store_kind.dart';

part 'vueniverse_database.g.dart';

@DriftDatabase(
  tables: [
    StoreMetadata,
    SourceConnections,
    SourcePermissions,
    SyncRuns,
    SyncCursors,
    SyncSeenRecords,
    RawRecordIndex,
    SignalSamples,
    HealthIntervals,
    ContextEvents,
    ManualCheckins,
    RecomputeJobs,
    AnalysisRuns,
    EventWindows,
    ControlMatches,
    WindowMetrics,
    EvidenceBundles,
    EvidenceMetrics,
    EvidenceDependencies,
    FindingVersions,
    Explanations,
    ChatSessions,
    ChatMessages,
    ExperimentProtocols,
    ExperimentOccurrences,
    AdherenceCheckins,
    ExperimentResults,
    ExperimentDependencies,
    ExportRecords,
    DeletionAudit,
  ],
)
class VueniverseDatabase extends _$VueniverseDatabase {
  VueniverseDatabase(super.executor);

  factory VueniverseDatabase.encrypted({
    required String path,
    required String passphrase,
  }) {
    if (passphrase.isEmpty) {
      throw const StoreOpenException(
        'An empty database passphrase is forbidden.',
      );
    }
    final escapedPassphrase = passphrase.replaceAll("'", "''");
    return VueniverseDatabase(
      NativeDatabase.createInBackground(
        File(path),
        setup: (database) {
          database.execute("PRAGMA key = '$escapedPassphrase';");
          database.execute('PRAGMA cipher_memory_security = ON;');
          database.execute('PRAGMA foreign_keys = ON;');
          database.execute('PRAGMA journal_mode = WAL;');
          database.execute('PRAGMA synchronous = FULL;');
        },
      ),
    );
  }

  factory VueniverseDatabase.forTesting(QueryExecutor executor) =>
      VueniverseDatabase(executor);

  @override
  int get schemaVersion => SchemaVersions.database;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 1) await migrator.createAll();
      if (from < 2) {
        await migrator.addColumn(explanations, explanations.evidenceHash);
        await migrator.addColumn(explanations, explanations.intent);
        await migrator.addColumn(explanations, explanations.requestHash);
        await migrator.addColumn(explanations, explanations.modelName);
        await migrator.addColumn(explanations, explanations.safetyFailuresJson);
        await migrator.addColumn(explanations, explanations.failureCode);
        await migrator.addColumn(explanations, explanations.latencyMillis);
        await migrator.addColumn(explanations, explanations.schemaValid);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  Future<void> initialize({required StoreKind kind}) async {
    await _assertEncryptionAvailable();
    await transaction(() async {
      final existingKind = await (select(
        storeMetadata,
      )..where((row) => row.key.equals('store_kind'))).getSingleOrNull();
      if (existingKind != null && existingKind.value != kind.wireName) {
        throw StoreOpenException(
          'A ${existingKind.value} database was opened as ${kind.wireName}.',
        );
      }

      final now = DateTime.now().toUtc();
      await into(storeMetadata).insertOnConflictUpdate(
        StoreMetadataCompanion.insert(
          key: 'store_kind',
          value: kind.wireName,
          updatedAt: Value(now),
        ),
      );
      for (final version in SchemaVersions.values.entries) {
        await into(storeMetadata).insertOnConflictUpdate(
          StoreMetadataCompanion.insert(
            key: version.key,
            value: version.value.toString(),
            updatedAt: Value(now),
          ),
        );
      }
    });
    await recoverRecomputeJobs();
  }

  Future<void> _assertEncryptionAvailable() async {
    final result = await customSelect('PRAGMA cipher_version;').get();
    if (result.isEmpty || result.first.data.values.firstOrNull == null) {
      throw const StoreOpenException(
        'SQLCipher is unavailable; refusing to open a plaintext fallback.',
      );
    }
  }

  Future<void> recoverRecomputeJobs() async {
    await transaction(() async {
      await (update(
        recomputeJobs,
      )..where((job) => job.status.equals('running'))).write(
        RecomputeJobsCompanion(
          status: const Value('pending'),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      await _coalescePendingJobs();
    });
  }

  Future<List<int>> getOrCreateSourceIdentityKey() async {
    const keyName = 'source_identity_key_v1';
    final existing = await (select(
      storeMetadata,
    )..where((row) => row.key.equals(keyName))).getSingleOrNull();
    if (existing != null) return base64Decode(existing.value);

    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(256));
    final now = DateTime.now().toUtc();
    await into(storeMetadata).insertOnConflictUpdate(
      StoreMetadataCompanion.insert(
        key: keyName,
        value: base64Encode(key),
        updatedAt: Value(now),
      ),
    );
    return List<int>.unmodifiable(key);
  }

  Future<void> enqueueRecompute({
    required DateTime dirtyStartUtc,
    required DateTime dirtyEndUtc,
    required String reason,
    String? sourceId,
    int analysisVersion = SchemaVersions.meetingAnalysis,
  }) async {
    if (!dirtyEndUtc.isAfter(dirtyStartUtc)) {
      throw ArgumentError.value(
        dirtyEndUtc,
        'dirtyEndUtc',
        'must follow start',
      );
    }
    final normalizedStart = dirtyStartUtc.toUtc();
    final normalizedEnd = dirtyEndUtc.toUtc();
    final identity = sha256.convert(
      utf8.encode(
        '${normalizedStart.toIso8601String()}|${normalizedEnd.toIso8601String()}|$reason|$sourceId|$analysisVersion',
      ),
    );
    await into(recomputeJobs).insertOnConflictUpdate(
      RecomputeJobsCompanion.insert(
        id: identity.toString(),
        dirtyStartUtc: normalizedStart,
        dirtyEndUtc: normalizedEnd,
        reason: reason,
        sourceId: Value(sourceId),
        status: 'pending',
        analysisVersion: analysisVersion,
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await transaction(_coalescePendingJobs);
  }

  Future<void> _coalescePendingJobs() async {
    final jobs =
        await (select(recomputeJobs)
              ..where((job) => job.status.equals('pending'))
              ..orderBy([(job) => OrderingTerm.asc(job.dirtyStartUtc)]))
            .get();
    if (jobs.length < 2) return;

    var current = jobs.first;
    for (final next in jobs.skip(1)) {
      final overlaps = !next.dirtyStartUtc.isAfter(current.dirtyEndUtc);
      if (!overlaps) {
        current = next;
        continue;
      }

      final mergedEnd = next.dirtyEndUtc.isAfter(current.dirtyEndUtc)
          ? next.dirtyEndUtc
          : current.dirtyEndUtc;
      final mergedReasons = <String>{
        ...current.reason.split(','),
        ...next.reason.split(','),
      }.toList()..sort();
      final mergedSource = current.sourceId == next.sourceId
          ? current.sourceId
          : null;
      final mergedVersion = current.analysisVersion > next.analysisVersion
          ? current.analysisVersion
          : next.analysisVersion;
      await (update(
        recomputeJobs,
      )..where((job) => job.id.equals(current.id))).write(
        RecomputeJobsCompanion(
          dirtyEndUtc: Value(mergedEnd),
          reason: Value(mergedReasons.join(',')),
          sourceId: Value(mergedSource),
          analysisVersion: Value(mergedVersion),
          retryCount: Value(
            current.retryCount > next.retryCount
                ? current.retryCount
                : next.retryCount,
          ),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      await (delete(
        recomputeJobs,
      )..where((job) => job.id.equals(next.id))).go();
      current = current.copyWith(
        dirtyEndUtc: mergedEnd,
        reason: mergedReasons.join(','),
        sourceId: Value(mergedSource),
        analysisVersion: mergedVersion,
      );
    }
  }

  Future<String> canonicalDataHash() async {
    final parts = <Object?>[
      for (final row in await (select(
        signalSamples,
      )..orderBy([(row) => OrderingTerm.asc(row.id)])).get())
        [row.id, row.canonicalPayloadHash],
      for (final row in await (select(
        healthIntervals,
      )..orderBy([(row) => OrderingTerm.asc(row.id)])).get())
        [row.id, row.canonicalPayloadHash],
      for (final row in await (select(
        contextEvents,
      )..orderBy([(row) => OrderingTerm.asc(row.id)])).get())
        [row.id, row.canonicalPayloadHash],
      for (final row in await (select(
        manualCheckins,
      )..orderBy([(row) => OrderingTerm.asc(row.id)])).get())
        [row.id, row.canonicalPayloadHash],
    ];
    return sha256.convert(utf8.encode(jsonEncode(parts))).toString();
  }
}

class StoreOpenException implements Exception {
  const StoreOpenException(this.message);

  final String message;

  @override
  String toString() => 'StoreOpenException: $message';
}
