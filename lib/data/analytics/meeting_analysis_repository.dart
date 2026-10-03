import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:vueniverse/data/database/schema_versions.dart';
import 'package:vueniverse/data/analytics/evidence_validity_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/domain/analytics/meeting_analysis_models.dart';
import 'package:vueniverse/domain/analytics/meeting_analytics_engine.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

final class MeetingAnalysisRepository {
  MeetingAnalysisRepository(
    this.database, {
    this.engine = const MeetingAnalyticsEngine(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final VueniverseDatabase database;
  final MeetingAnalyticsEngine engine;
  final DateTime Function() _clock;

  Future<MeetingAnalysisResult> evaluate({
    Set<String>? eventIds,
    String? recurrenceKeyHmac,
  }) async => engine.analyze(
    await _loadDataset(),
    eventIds: eventIds,
    recurrenceKeyHmac: recurrenceKeyHmac,
  );

  Future<EvidenceBundleRow?> runPending({bool ensureEvidence = false}) async {
    final pending =
        await (database.select(database.recomputeJobs)
              ..where((job) => job.status.equals('pending'))
              ..orderBy([(job) => OrderingTerm.asc(job.createdAt)]))
            .get();
    final current = await _currentEvidenceUnchecked();
    final currentRun = current == null
        ? null
        : await (database.select(database.analysisRuns)
                ..where((row) => row.id.equals(current.analysisRunId)))
              .getSingleOrNull();
    final versionChanged =
        current != null &&
        (currentRun?.analysisVersion != SchemaVersions.meetingAnalysis ||
            current.promotionPolicyVersion != SchemaVersions.promotionPolicy ||
            !await EvidenceValidityRepository(database).isCurrent(current));
    if (pending.isEmpty &&
        !versionChanged &&
        (!ensureEvidence || current != null)) {
      return current;
    }
    return recompute(
      pendingJobIds: pending.map((job) => job.id).toList(growable: false),
    );
  }

  Future<EvidenceBundleRow> recompute({
    List<String> pendingJobIds = const [],
  }) async {
    final now = _clock().toUtc();
    final dataset = await _loadDataset();
    final inputHash = await database.canonicalDataHash();
    final result = engine.analyze(dataset);
    final payload = {
      ..._evidencePayload(result),
      'canonical_input_hash': inputHash,
    };
    final evidenceHash = sha256
        .convert(utf8.encode(canonicalJsonEncode(payload)))
        .toString();
    // Reuse only the active finding, never reactivate a superseded cohort.
    final existing = await _currentEvidenceUnchecked();
    final existingRun = existing == null
        ? null
        : await (database.select(database.analysisRuns)
                ..where((row) => row.id.equals(existing.analysisRunId)))
              .getSingleOrNull();
    if (existing != null &&
        existing.evidenceHash == evidenceHash &&
        existing.status != EvidenceState.invalidated.name &&
        existing.promotionPolicyVersion == SchemaVersions.promotionPolicy &&
        existingRun?.analysisVersion == SchemaVersions.meetingAnalysis &&
        existingRun?.inputHash == inputHash &&
        existingRun?.status == 'completed') {
      if (existing.status == EvidenceState.stale.name) {
        await (database.update(
          database.evidenceBundles,
        )..where((row) => row.id.equals(existing.id))).write(
          EvidenceBundlesCompanion(
            status: Value(result.state.name),
            staleAt: const Value(null),
            staleReason: const Value(null),
          ),
        );
      }
      await _completeJobs(pendingJobIds, 'unchanged:$evidenceHash');
      return (database.select(
        database.evidenceBundles,
      )..where((row) => row.id.equals(existing.id))).getSingle();
    }

    final runId = sha256
        .convert(
          utf8.encode(
            '$inputHash|${SchemaVersions.meetingAnalysis}|${now.microsecondsSinceEpoch}|${DateTime.now().microsecondsSinceEpoch}',
          ),
        )
        .toString();
    await database.transaction(() async {
      await database
          .into(database.analysisRuns)
          .insert(
            AnalysisRunsCompanion.insert(
              id: runId,
              status: AnalysisStatus.running.name,
              rangeStartUtc: result.rangeStartUtc,
              rangeEndUtc: result.rangeEndUtc,
              analysisVersion: SchemaVersions.meetingAnalysis,
              startedAt: now,
              inputHash: inputHash,
            ),
          );
      await (database.update(database.evidenceBundles)..where(
            (row) => row.status.isNotIn([
              EvidenceState.invalidated.name,
              EvidenceState.stale.name,
            ]),
          ))
          .write(
            EvidenceBundlesCompanion(
              status: Value(EvidenceState.stale.name),
              staleAt: Value(now),
              staleReason: const Value('recomputing'),
            ),
          );
    });

    try {
      final evidenceId = sha256
          .convert(
            utf8.encode(
              '$evidenceHash|${SchemaVersions.promotionPolicy}|$runId',
            ),
          )
          .toString();
      await database.transaction(() async {
        for (final occurrence in result.occurrences) {
          final windowId = '$runId:${occurrence.event.id}';
          await database
              .into(database.eventWindows)
              .insert(
                EventWindowsCompanion.insert(
                  id: windowId,
                  analysisRunId: runId,
                  contextEventId: occurrence.event.id,
                  startAtUtc: occurrence.event.startAtUtc.subtract(
                    MeetingAnalyticsEngine.preEvent,
                  ),
                  endAtUtc: occurrence.event.endAtUtc.add(
                    MeetingAnalyticsEngine.recoveryHorizon,
                  ),
                  status: occurrence.included ? 'included' : 'excluded',
                  exclusionReason: Value(occurrence.exclusionReason),
                ),
              );
          String? controlId;
          if (occurrence.control.medianBpm != null) {
            controlId = '$windowId:control';
            await database
                .into(database.controlMatches)
                .insert(
                  ControlMatchesCompanion.insert(
                    id: controlId,
                    eventWindowId: windowId,
                    startAtUtc: occurrence.controlStartUtc,
                    endAtUtc: occurrence.controlEndUtc,
                    score: occurrence.controlScore,
                    factorsJson: canonicalJsonEncode(occurrence.controlFactors),
                  ),
                );
          }
          final metrics = <(String, double?, String)>[
            ('pre_event_median', occurrence.pre.medianBpm, 'bpm'),
            ('during_event_median', occurrence.during.medianBpm, 'bpm'),
            ('recovery_median', occurrence.recovery.medianBpm, 'bpm'),
            ('control_median', occurrence.control.medianBpm, 'bpm'),
            ('difference', occurrence.differenceBpm, 'bpm'),
            (
              'completeness',
              occurrence.included ? occurrence.pre.completeness : null,
              'ratio',
            ),
            (
              'recovery_duration',
              occurrence.recoveryDurationMinutes?.toDouble(),
              'minutes',
            ),
          ];
          for (final metric in metrics.where((item) => item.$2 != null)) {
            await database
                .into(database.windowMetrics)
                .insert(
                  WindowMetricsCompanion.insert(
                    id: '$windowId:${metric.$1}',
                    eventWindowId: windowId,
                    controlMatchId: Value(controlId),
                    metric: metric.$1,
                    value: metric.$2!,
                    unit: metric.$3,
                    qualityState: occurrence.included ? 'usable' : 'excluded',
                  ),
                );
          }
        }

        await database
            .into(database.evidenceBundles)
            .insert(
              EvidenceBundlesCompanion.insert(
                id: evidenceId,
                analysisRunId: runId,
                status: result.state.name,
                title: result.title,
                claimType: result.claimType,
                evidenceHash: evidenceHash,
                promotionPolicyVersion: SchemaVersions.promotionPolicy,
                createdAt: Value(now),
              ),
            );
        for (final metric in _aggregateMetrics(result)) {
          await database
              .into(database.evidenceMetrics)
              .insert(
                EvidenceMetricsCompanion.insert(
                  id: '$evidenceId:${metric.name}',
                  evidenceBundleId: evidenceId,
                  metric: metric.name,
                  value: metric.value,
                  lowerBound: Value(metric.lowerBound),
                  upperBound: Value(metric.upperBound),
                  unit: metric.unit,
                ),
              );
        }
        final dependencyHashes = await _dependencyHashes(result.dependencyIds);
        for (final entry in dependencyHashes.entries) {
          await database
              .into(database.evidenceDependencies)
              .insert(
                EvidenceDependenciesCompanion.insert(
                  id: '$evidenceId:${entry.key}',
                  evidenceBundleId: evidenceId,
                  dependencyKind: 'canonical_record',
                  dependencyId: entry.key,
                  dependencyHash: entry.value,
                ),
              );
        }

        const findingId = 'recurring-one-to-one-heart-rate';
        final prior =
            await (database.select(database.findingVersions)
                  ..where((row) => row.findingId.equals(findingId))
                  ..orderBy([(row) => OrderingTerm.desc(row.version)]))
                .getSingleOrNull();
        if (prior != null) {
          await (database.update(database.findingVersions)
                ..where((row) => row.id.equals(prior.id)))
              .write(FindingVersionsCompanion(validUntil: Value(now)));
        }
        final findingVersion = (prior?.version ?? 0) + 1;
        final findingVersionId = '$findingId:v$findingVersion';
        await database
            .into(database.findingVersions)
            .insert(
              FindingVersionsCompanion.insert(
                id: findingVersionId,
                findingId: findingId,
                evidenceBundleId: evidenceId,
                version: findingVersion,
                status: result.state.name,
                validFrom: now,
                supersedesId: Value(prior?.id),
              ),
            );
        await (database.update(
          database.analysisRuns,
        )..where((row) => row.id.equals(runId))).write(
          AnalysisRunsCompanion(
            status: Value(AnalysisStatus.completed.name),
            finishedAt: Value(now),
            outputHash: Value(evidenceHash),
          ),
        );
        await _completeJobs(
          pendingJobIds,
          'evidence:$evidenceId',
          insideTransaction: true,
        );
      });
      return (await (database.select(
        database.evidenceBundles,
      )..where((row) => row.id.equals(evidenceId))).getSingle());
    } on Object {
      await database.transaction(() async {
        await (database.update(
          database.analysisRuns,
        )..where((row) => row.id.equals(runId))).write(
          AnalysisRunsCompanion(
            status: Value(AnalysisStatus.failed.name),
            finishedAt: Value(DateTime.now().toUtc()),
          ),
        );
        if (pendingJobIds.isNotEmpty) {
          await (database.update(
            database.recomputeJobs,
          )..where((row) => row.id.isIn(pendingJobIds))).write(
            RecomputeJobsCompanion(
              status: const Value('pending'),
              lastCheckpoint: const Value('analysis_failed'),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );
        }
      });
      rethrow;
    }
  }

  Future<EvidenceBundleRow?> currentEvidence() async {
    final row = await _currentEvidenceUnchecked();
    return row != null &&
            await EvidenceValidityRepository(database).isCurrent(row)
        ? row
        : null;
  }

  Future<EvidenceBundleRow?> _currentEvidenceUnchecked() async {
    final finding =
        await (database.select(database.findingVersions)
              ..where((row) => row.validUntil.isNull())
              ..orderBy([(row) => OrderingTerm.desc(row.version)]))
            .getSingleOrNull();
    if (finding == null) return null;
    return (database.select(database.evidenceBundles)
          ..where((row) => row.id.equals(finding.evidenceBundleId)))
        .getSingleOrNull();
  }

  Future<MeetingAnalysisDataset> _loadDataset() async {
    final now = await _analysisClock();
    final signals = await (database.select(
      database.signalSamples,
    )..where((row) => row.signalType.equals(SignalKind.heartRate.name))).get();
    final events = await database.select(database.contextEvents).get();
    final intervals = await database.select(database.healthIntervals).get();
    final checkins = await database.select(database.manualCheckins).get();
    return MeetingAnalysisDataset(
      nowUtc: now,
      heartRate: [
        for (final row in signals)
          AnalysisHeartRate(
            id: row.id,
            occurredAtUtc: row.occurredAtUtc,
            valueBpm: row.value,
            offsetMinutes: row.originalOffsetMinutes,
            provenanceHash: row.canonicalPayloadHash,
          ),
      ],
      events: [
        for (final row in events)
          AnalysisContextEvent(
            id: row.id,
            category: ContextCategory.values.firstWhere(
              (item) => item.name == row.category,
            ),
            startAtUtc: row.startAtUtc,
            endAtUtc: row.endAtUtc,
            offsetMinutes: row.originalOffsetMinutes,
            provenanceHash: row.canonicalPayloadHash,
            recurrenceKeyHmac: row.recurrenceKeyHmac,
          ),
      ],
      healthIntervals: [
        for (final row in intervals)
          AnalysisHealthInterval(
            id: row.id,
            kind: HealthIntervalKind.values.firstWhere(
              (item) => item.name == row.intervalType,
            ),
            startAtUtc: row.startAtUtc,
            endAtUtc: row.endAtUtc,
            provenanceHash: row.canonicalPayloadHash,
          ),
      ],
      influences: [for (final row in checkins) _analysisInfluence(row)],
    );
  }

  AnalysisInfluence _analysisInfluence(ManualCheckinRow row) {
    final values = _caffeineValues(row.valueJson);
    return AnalysisInfluence(
      id: row.id,
      category: CheckinCategory.values.firstWhere(
        (item) => item.name == row.category,
      ),
      occurredAtUtc: row.occurredAtUtc,
      provenanceHash: row.canonicalPayloadHash,
      caffeineServings: values.servings,
      coverageStartUtc: values.start,
      coverageEndUtc: values.end,
    );
  }

  ({double? servings, DateTime? start, DateTime? end}) _caffeineValues(
    String raw,
  ) {
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return (servings: null, start: null, end: null);
      final amount = value['servings'];
      DateTime? timestamp(Object? text) {
        if (text is! String ||
            !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(text)) {
          return null;
        }
        return DateTime.tryParse(text)?.toUtc();
      }

      return (
        servings: amount is num && amount.isFinite && amount >= 0
            ? amount.toDouble()
            : null,
        start: timestamp(value['coverage_start_utc']),
        end: timestamp(value['coverage_end_utc']),
      );
    } on FormatException {
      return (servings: null, start: null, end: null);
    }
  }

  Future<DateTime> _analysisClock() async {
    final row =
        await (database.select(database.storeMetadata)
              ..where((item) => item.key.equals('demo_virtual_clock')))
            .getSingleOrNull();
    return (row == null ? _clock() : DateTime.parse(row.value)).toUtc();
  }

  Map<String, Object?> _evidencePayload(MeetingAnalysisResult result) => {
    'schema': SchemaVersions.meetingAnalysis,
    'promotion_policy': SchemaVersions.promotionPolicy,
    'state': result.state.name,
    'claim_type': result.claimType,
    'recurrence_key_hmac':
        result.occurrences.firstOrNull?.event.recurrenceKeyHmac,
    'range_start': result.rangeStartUtc.toIso8601String(),
    'range_end': result.rangeEndUtc.toIso8601String(),
    'candidate_count': result.candidateCount,
    'included_count': result.includedCount,
    'controls_count': result.controlsCount,
    'positive_count': result.positiveCount,
    'counterevidence_count': result.counterevidenceCount,
    'excluded': result.excludedByReason,
    'median_difference_bpm': result.medianDifferenceBpm,
    'effect_lower_bpm': result.effectLowerBpm,
    'effect_upper_bpm': result.effectUpperBpm,
    'consistency': result.consistency,
    'completeness': result.completeness,
    'recovery_minutes': result.recoveryDurationMinutes,
    'unresolved_influences': result.unresolvedInfluenceCount,
    'caffeine_unknown_pair_count': result.caffeineUnknownPairCount,
    'caffeine_exposure_pair_count': result.caffeineExposurePairCount,
    'promotion_gates': result.promotionGates,
    'dependencies': result.dependencyIds,
  };

  List<EvidenceMetric> _aggregateMetrics(MeetingAnalysisResult result) => [
    EvidenceMetric(
      name: 'median_difference_bpm',
      value: result.medianDifferenceBpm,
      unit: 'bpm',
      lowerBound: result.effectLowerBpm,
      upperBound: result.effectUpperBpm,
    ),
    EvidenceMetric(
      name: 'candidate_count',
      value: result.candidateCount.toDouble(),
      unit: 'count',
    ),
    EvidenceMetric(
      name: 'included_count',
      value: result.includedCount.toDouble(),
      unit: 'count',
    ),
    EvidenceMetric(
      name: 'excluded_count',
      value: result.excludedByReason.values.fold(0, (a, b) => a + b).toDouble(),
      unit: 'count',
    ),
    EvidenceMetric(
      name: 'control_count',
      value: result.controlsCount.toDouble(),
      unit: 'count',
    ),
    EvidenceMetric(
      name: 'positive_count',
      value: result.positiveCount.toDouble(),
      unit: 'count',
    ),
    EvidenceMetric(
      name: 'counterevidence_count',
      value: result.counterevidenceCount.toDouble(),
      unit: 'count',
    ),
    EvidenceMetric(
      name: 'consistency',
      value: result.consistency,
      unit: 'ratio',
    ),
    EvidenceMetric(
      name: 'completeness',
      value: result.completeness,
      unit: 'ratio',
    ),
    EvidenceMetric(
      name: 'recovery_duration_minutes',
      value: result.recoveryDurationMinutes,
      unit: 'minutes',
    ),
    EvidenceMetric(
      name: 'unresolved_influence_count',
      value: result.unresolvedInfluenceCount.toDouble(),
      unit: 'count',
    ),
    for (final entry in result.excludedByReason.entries)
      EvidenceMetric(
        name: 'excluded_${entry.key}',
        value: entry.value.toDouble(),
        unit: 'count',
      ),
    EvidenceMetric(
      name: 'caffeine_unknown_pair_count',
      value: result.caffeineUnknownPairCount.toDouble(),
      unit: 'count',
    ),
    EvidenceMetric(
      name: 'caffeine_exposure_pair_count',
      value: result.caffeineExposurePairCount.toDouble(),
      unit: 'count',
    ),
    for (final entry in result.promotionGates.entries)
      EvidenceMetric(
        name: 'gate_${entry.key}',
        value: entry.value ? 1 : 0,
        unit: 'boolean',
      ),
  ];

  Future<Map<String, String>> _dependencyHashes(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await (database.select(
      database.rawRecordIndex,
    )..where((row) => row.canonicalId.isIn(ids))).get();
    return {for (final row in rows) row.canonicalId: row.canonicalPayloadHash};
  }

  Future<void> _completeJobs(
    List<String> ids,
    String checkpoint, {
    bool insideTransaction = false,
  }) async {
    if (ids.isEmpty) return;
    Future<void> write() async {
      await (database.update(
        database.recomputeJobs,
      )..where((row) => row.id.isIn(ids))).write(
        RecomputeJobsCompanion(
          status: const Value('completed'),
          lastCheckpoint: Value(checkpoint),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
    }

    if (insideTransaction) {
      await write();
    } else {
      await database.transaction(write);
    }
  }
}
