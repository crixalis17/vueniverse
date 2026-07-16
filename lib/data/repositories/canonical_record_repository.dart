import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:why_pulse/data/database/schema_versions.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/normalization/record_normalizer.dart';
import 'package:why_pulse/domain/models/canonical_domain_models.dart';

final class CanonicalRecordRepository {
  CanonicalRecordRepository(this.database);

  final WhyPulseDatabase database;

  Future<IngestionReport> importRecords({
    required String sourceConnectionId,
    required SourceKind sourceKind,
    required Iterable<SourceRecordEnvelope> records,
    required RecordNormalizer normalizer,
    required String syncRunId,
  }) async {
    final input = records.toList(growable: false);
    final normalized = normalizer.normalizeAll(input);
    var inserted = 0;
    var duplicates = 0;
    var changed = 0;
    DateTime? dirtyStart;
    DateTime? dirtyEnd;

    await database.transaction(() async {
      final now = DateTime.now().toUtc();
      await database
          .into(database.sourceConnections)
          .insertOnConflictUpdate(
            SourceConnectionsCompanion.insert(
              id: sourceConnectionId,
              sourceType: sourceKind.name,
              status: 'connected',
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await database
          .into(database.syncRuns)
          .insertOnConflictUpdate(
            SyncRunsCompanion.insert(
              id: syncRunId,
              sourceConnectionId: sourceConnectionId,
              status: 'running',
              startedAt: now,
              recordsSeen: Value(input.length),
              recordsRejected: Value(normalized.rejectedCount),
            ),
          );

      Future<void> persist({
        required String id,
        required String kind,
        required DateTime start,
        required DateTime end,
        required String payloadHash,
        required SourceProvenance provenance,
        required Future<void> Function() writeCanonical,
      }) async {
        final indexId = _rawIndexId(
          sourceKind,
          provenance.sourceRecordIdentity,
        );
        final existing = await (database.select(
          database.rawRecordIndex,
        )..where((row) => row.id.equals(indexId))).getSingleOrNull();
        if (existing?.canonicalPayloadHash == payloadHash) {
          duplicates++;
          return;
        }

        await writeCanonical();
        await database
            .into(database.rawRecordIndex)
            .insertOnConflictUpdate(
              RawRecordIndexCompanion.insert(
                id: indexId,
                sourceConnectionId: sourceConnectionId,
                sourceKind: sourceKind.name,
                sourceRecordHmac: Value(
                  provenance.sourceRecordIdentity.startsWith('hmac:')
                      ? provenance.sourceRecordIdentity.substring(5)
                      : null,
                ),
                canonicalPayloadHash: payloadHash,
                canonicalKind: kind,
                canonicalId: id,
                occurredAtUtc: start,
                updatedAt: Value(now),
              ),
            );

        final parentIdentity = provenance.parentSourceRecordIdentity;
        if (parentIdentity != null && parentIdentity.startsWith('hmac:')) {
          await database
              .into(database.syncSeenRecords)
              .insertOnConflictUpdate(
                SyncSeenRecordsCompanion.insert(
                  id: id,
                  syncRunId: syncRunId,
                  sourceRecordHmac: parentIdentity.substring(5),
                  seenAt: Value(now),
                ),
              );
        }

        if (existing == null) {
          inserted++;
        } else {
          changed++;
          await _markEvidenceStale(existing.canonicalId, now);
        }
        dirtyStart = dirtyStart == null || start.isBefore(dirtyStart!)
            ? start
            : dirtyStart;
        dirtyEnd = dirtyEnd == null || end.isAfter(dirtyEnd!) ? end : dirtyEnd;
      }

      for (final sample in normalized.signalSamples) {
        await persist(
          id: sample.id,
          kind: 'signal_sample',
          start: sample.occurredAtUtc,
          end: sample.occurredAtUtc.add(const Duration(seconds: 1)),
          payloadHash: sample.canonicalPayloadHash,
          provenance: sample.provenance,
          writeCanonical: () => database
              .into(database.signalSamples)
              .insertOnConflictUpdate(
                SignalSamplesCompanion.insert(
                  id: sample.id,
                  signalType: sample.kind.name,
                  occurredAtUtc: sample.occurredAtUtc,
                  value: sample.value,
                  unit: sample.unit,
                  originalOffsetMinutes: sample.originalOffsetMinutes,
                  originalLocalDate: sample.originalLocalDate,
                  provenanceJson: canonicalJsonEncode(
                    sample.provenance.toJson(),
                  ),
                  canonicalPayloadHash: sample.canonicalPayloadHash,
                ),
              ),
        );
      }
      for (final interval in normalized.healthIntervals) {
        await persist(
          id: interval.id,
          kind: 'health_interval',
          start: interval.startAtUtc,
          end: interval.endAtUtc,
          payloadHash: interval.canonicalPayloadHash,
          provenance: interval.provenance,
          writeCanonical: () => database
              .into(database.healthIntervals)
              .insertOnConflictUpdate(
                HealthIntervalsCompanion.insert(
                  id: interval.id,
                  intervalType: interval.kind.name,
                  category: interval.category,
                  startAtUtc: interval.startAtUtc,
                  endAtUtc: interval.endAtUtc,
                  originalOffsetMinutes: interval.originalOffsetMinutes,
                  originalLocalDate: interval.originalLocalDate,
                  provenanceJson: canonicalJsonEncode(
                    interval.provenance.toJson(),
                  ),
                  canonicalPayloadHash: interval.canonicalPayloadHash,
                ),
              ),
        );
      }
      for (final event in normalized.contextEvents) {
        await persist(
          id: event.id,
          kind: 'context_event',
          start: event.startAtUtc,
          end: event.endAtUtc,
          payloadHash: event.canonicalPayloadHash,
          provenance: event.provenance,
          writeCanonical: () => database
              .into(database.contextEvents)
              .insertOnConflictUpdate(
                ContextEventsCompanion.insert(
                  id: event.id,
                  category: event.category.name,
                  startAtUtc: event.startAtUtc,
                  endAtUtc: event.endAtUtc,
                  recurrenceKeyHmac: Value(event.recurrenceKeyHmac),
                  originalOffsetMinutes: event.originalOffsetMinutes,
                  originalLocalDate: event.originalLocalDate,
                  provenanceJson: canonicalJsonEncode(
                    event.provenance.toJson(),
                  ),
                  canonicalPayloadHash: event.canonicalPayloadHash,
                ),
              ),
        );
      }
      for (final checkin in normalized.manualCheckins) {
        await persist(
          id: checkin.id,
          kind: 'manual_checkin',
          start: checkin.occurredAtUtc,
          end: checkin.occurredAtUtc.add(const Duration(seconds: 1)),
          payloadHash: checkin.canonicalPayloadHash,
          provenance: checkin.provenance,
          writeCanonical: () => database
              .into(database.manualCheckins)
              .insertOnConflictUpdate(
                ManualCheckinsCompanion.insert(
                  id: checkin.id,
                  category: checkin.category.name,
                  occurredAtUtc: checkin.occurredAtUtc,
                  valueJson: canonicalJsonEncode(checkin.value),
                  originalOffsetMinutes: checkin.originalOffsetMinutes,
                  originalLocalDate: checkin.originalLocalDate,
                  provenanceJson: canonicalJsonEncode(
                    checkin.provenance.toJson(),
                  ),
                  canonicalPayloadHash: checkin.canonicalPayloadHash,
                  updatedAt: Value(now),
                ),
              ),
        );
      }

      await (database.update(
        database.syncRuns,
      )..where((run) => run.id.equals(syncRunId))).write(
        SyncRunsCompanion(
          status: const Value('completed'),
          finishedAt: Value(now),
          recordsAccepted: Value(normalized.acceptedCount),
          recordsRejected: Value(normalized.rejectedCount),
          errorDetails: Value(
            normalized.rejectedCounts.isEmpty
                ? null
                : jsonEncode(normalized.rejectedCounts),
          ),
        ),
      );
    });

    if (dirtyStart != null && dirtyEnd != null) {
      await database.enqueueRecompute(
        dirtyStartUtc: dirtyStart!.subtract(const Duration(days: 1)),
        dirtyEndUtc: dirtyEnd!.add(const Duration(days: 1)),
        reason: changed > 0 ? 'source_record_changed' : 'source_import',
        sourceId: sourceConnectionId,
        analysisVersion: SchemaVersions.meetingAnalysis,
      );
    }

    return IngestionReport(
      seen: input.length,
      inserted: inserted,
      duplicates: duplicates,
      changed: changed,
      rejectedCounts: normalized.rejectedCounts,
    );
  }

  Future<void> _markEvidenceStale(String canonicalId, DateTime now) async {
    final dependencies =
        await (database.select(database.evidenceDependencies)..where(
              (dependency) => dependency.dependencyId.equals(canonicalId),
            ))
            .get();
    for (final dependency in dependencies) {
      await (database.update(database.evidenceBundles)
            ..where((bundle) => bundle.id.equals(dependency.evidenceBundleId)))
          .write(
            EvidenceBundlesCompanion(
              status: const Value('stale'),
              staleAt: Value(now),
              staleReason: const Value('source_record_changed'),
            ),
          );
    }
  }

  Future<DeletionReport> deleteParentRecords({
    required String sourceConnectionId,
    required Iterable<String> stableParentIds,
    required RecordNormalizer normalizer,
    String reason = 'source_record_deleted',
  }) async {
    final parentHashes = stableParentIds
        .map(normalizer.sourceRecordIdentity)
        .map((identity) => identity.substring(5))
        .toSet();
    if (parentHashes.isEmpty) return const DeletionReport(0, null, null);
    final mappings = await (database.select(
      database.syncSeenRecords,
    )..where((row) => row.sourceRecordHmac.isIn(parentHashes))).get();
    return deleteCanonicalIds(
      sourceConnectionId: sourceConnectionId,
      canonicalIds: mappings.map((row) => row.id),
      reason: reason,
    );
  }

  Future<DeletionReport> deleteAbsentSnapshotRecords({
    required String sourceConnectionId,
    required Iterable<String> seenStableIds,
    required RecordNormalizer normalizer,
  }) async {
    final seenHashes = seenStableIds
        .map(normalizer.sourceRecordIdentity)
        .map((identity) => identity.substring(5))
        .toSet();
    final existing = await (database.select(
      database.rawRecordIndex,
    )..where((row) => row.sourceConnectionId.equals(sourceConnectionId))).get();
    final absentIds = existing
        .where(
          (row) =>
              row.sourceRecordHmac != null &&
              !seenHashes.contains(row.sourceRecordHmac),
        )
        .map((row) => row.canonicalId);
    return deleteCanonicalIds(
      sourceConnectionId: sourceConnectionId,
      canonicalIds: absentIds,
      reason: 'calendar_snapshot_absent',
    );
  }

  Future<DeletionReport> deleteAllForSource({
    required String sourceConnectionId,
    String reason = 'source_data_deleted',
  }) async {
    final existing = await (database.select(
      database.rawRecordIndex,
    )..where((row) => row.sourceConnectionId.equals(sourceConnectionId))).get();
    final report = await deleteCanonicalIds(
      sourceConnectionId: sourceConnectionId,
      canonicalIds: existing.map((row) => row.canonicalId),
      reason: reason,
    );
    await _invalidateDependentArtifacts(
      existing.map((row) => row.canonicalId),
      reason: reason,
    );
    return report;
  }

  Future<void> _invalidateDependentArtifacts(
    Iterable<String> canonicalIds, {
    required String reason,
  }) async {
    final ids = canonicalIds.toSet();
    if (ids.isEmpty) return;
    final dependencies = await (database.select(
      database.evidenceDependencies,
    )..where((row) => row.dependencyId.isIn(ids))).get();
    final evidenceIds = dependencies.map((row) => row.evidenceBundleId).toSet();
    if (evidenceIds.isEmpty) return;
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      await (database.update(
        database.evidenceBundles,
      )..where((row) => row.id.isIn(evidenceIds))).write(
        EvidenceBundlesCompanion(
          status: const Value('invalidated'),
          staleAt: Value(now),
          staleReason: Value(reason),
        ),
      );
      await (database.update(
        database.findingVersions,
      )..where((row) => row.evidenceBundleId.isIn(evidenceIds))).write(
        FindingVersionsCompanion(
          status: const Value('invalidated'),
          validUntil: Value(now),
        ),
      );
      final sessions = await (database.select(
        database.chatSessions,
      )..where((row) => row.evidenceBundleId.isIn(evidenceIds))).get();
      await (database.delete(database.chatMessages)..where(
            (row) => row.chatSessionId.isIn(sessions.map((row) => row.id)),
          ))
          .go();
      await (database.delete(
        database.chatSessions,
      )..where((row) => row.id.isIn(sessions.map((row) => row.id)))).go();
      await (database.delete(
        database.explanations,
      )..where((row) => row.evidenceBundleId.isIn(evidenceIds))).go();
      final protocols = await (database.select(
        database.experimentProtocols,
      )..where((row) => row.evidenceBundleId.isIn(evidenceIds))).get();
      final protocolIds = protocols.map((row) => row.id).toSet();
      if (protocolIds.isNotEmpty) {
        await (database.update(
          database.experimentProtocols,
        )..where((row) => row.id.isIn(protocolIds))).write(
          ExperimentProtocolsCompanion(
            status: const Value('invalidated'),
            updatedAt: Value(now),
          ),
        );
        await (database.update(database.experimentResults)
              ..where((row) => row.experimentProtocolId.isIn(protocolIds)))
            .write(ExperimentResultsCompanion(invalidatedAt: Value(now)));
      }
      final exports = await database.select(database.exportRecords).get();
      for (final export in exports.where((item) => item.deletedAt == null)) {
        try {
          final file = File(export.filePath);
          if (await file.exists()) await file.delete();
        } on FileSystemException {
          // The database tombstone remains authoritative if cleanup is unavailable.
        }
        await (database.update(
          database.exportRecords,
        )..where((row) => row.id.equals(export.id))).write(
          ExportRecordsCompanion(
            status: const Value('invalidated'),
            deletedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<DeletionReport> deleteCanonicalIds({
    required String sourceConnectionId,
    required Iterable<String> canonicalIds,
    required String reason,
  }) async {
    final ids = canonicalIds.toSet();
    if (ids.isEmpty) return const DeletionReport(0, null, null);
    final indexes =
        await (database.select(database.rawRecordIndex)..where(
              (row) =>
                  row.sourceConnectionId.equals(sourceConnectionId) &
                  row.canonicalId.isIn(ids),
            ))
            .get();
    if (indexes.isEmpty) return const DeletionReport(0, null, null);
    final actualIds = indexes.map((row) => row.canonicalId).toSet();
    final dirtyStart = indexes
        .map((row) => row.occurredAtUtc)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final dirtyEnd = indexes
        .map((row) => row.occurredAtUtc)
        .reduce((a, b) => a.isAfter(b) ? a : b)
        .add(const Duration(seconds: 1));
    final now = DateTime.now().toUtc();

    await database.transaction(() async {
      for (final id in actualIds) {
        await _markEvidenceStale(id, now);
      }
      await (database.delete(
        database.signalSamples,
      )..where((row) => row.id.isIn(actualIds))).go();
      await (database.delete(
        database.healthIntervals,
      )..where((row) => row.id.isIn(actualIds))).go();
      await (database.delete(
        database.contextEvents,
      )..where((row) => row.id.isIn(actualIds))).go();
      await (database.delete(
        database.manualCheckins,
      )..where((row) => row.id.isIn(actualIds))).go();
      await (database.delete(
        database.syncSeenRecords,
      )..where((row) => row.id.isIn(actualIds))).go();
      await (database.delete(
        database.rawRecordIndex,
      )..where((row) => row.canonicalId.isIn(actualIds))).go();
      await database
          .into(database.deletionAudit)
          .insert(
            DeletionAuditCompanion.insert(
              id: canonicalPayloadHash(
                '$sourceConnectionId|$reason|${now.toIso8601String()}',
              ),
              scope: reason,
              sourceId: Value(sourceConnectionId),
              recordsDeleted: actualIds.length,
              invalidatedJson: canonicalJsonEncode(actualIds.toList()..sort()),
              createdAt: Value(now),
            ),
          );
    });
    await database.enqueueRecompute(
      dirtyStartUtc: dirtyStart.subtract(const Duration(days: 1)),
      dirtyEndUtc: dirtyEnd.add(const Duration(days: 1)),
      reason: reason,
      sourceId: sourceConnectionId,
      analysisVersion: SchemaVersions.meetingAnalysis,
    );
    return DeletionReport(actualIds.length, dirtyStart, dirtyEnd);
  }

  String _rawIndexId(SourceKind source, String identity) =>
      canonicalPayloadHash('${source.name}|$identity');
}

final class DeletionReport {
  const DeletionReport(this.deleted, this.dirtyStartUtc, this.dirtyEndUtc);

  final int deleted;
  final DateTime? dirtyStartUtc;
  final DateTime? dirtyEndUtc;
}

final class IngestionReport {
  const IngestionReport({
    required this.seen,
    required this.inserted,
    required this.duplicates,
    required this.changed,
    required this.rejectedCounts,
  });

  final int seen;
  final int inserted;
  final int duplicates;
  final int changed;
  final Map<String, int> rejectedCounts;

  int get rejected =>
      rejectedCounts.values.fold(0, (sum, count) => sum + count);
}
