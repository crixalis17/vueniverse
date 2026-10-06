import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/model_runtime/evidence_projection_repository.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/domain/analytics/meeting_analysis_models.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

typedef SemanticFamily = ({
  String name,
  int delta,
  int pairs,
  bool reportContext,
});

const semanticFamilies = <SemanticFamily>[
  (name: 'supported_negative', delta: -10, pairs: 4, reportContext: true),
  (name: 'supported_positive', delta: 10, pairs: 4, reportContext: true),
  (name: 'scarce_complete', delta: 10, pairs: 2, reportContext: true),
  (name: 'context_blocked', delta: 10, pairs: 4, reportContext: false),
  (name: 'mixed_direction', delta: 7, pairs: 4, reportContext: true),
];
const semanticIntents = ['why_promoted', 'disagreement', 'observe_next'];
final semanticClock = DateTime.utc(2026, 9, 20, 12);

/// The same raw normalization/analytics path used by the regression goldens.
/// Production run IDs intentionally remain real run-instance IDs, not remapped.
final class SemanticFixture {
  SemanticFixture._(this.spec, this.database, this.records, this.result);

  final SemanticFamily spec;
  final VueniverseDatabase database;
  final List<SourceRecordEnvelope> records;
  final MeetingAnalysisResult result;

  static Future<SemanticFixture> build(SemanticFamily spec) async {
    final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
    try {
      await database.initialize(kind: StoreKind.demo);
      final records = semanticRecords(spec);
      for (final source in records.map((row) => row.source).toSet()) {
        final receipt = await CanonicalRecordRepository(database).importRecords(
          sourceConnectionId: '${spec.name}:${source.name}',
          sourceKind: source,
          records: records.where((row) => row.source == source),
          normalizer: RecordNormalizer(
            identityKey: 'fallback-golden:${spec.name}'.codeUnits,
          ),
          syncRunId: 'sync:${spec.name}:${source.name}',
        );
        if (receipt.rejected != 0) {
          throw StateError(
            'Fixture import rejected ${receipt.rejected} records',
          );
        }
      }
      final analysis = MeetingAnalysisRepository(
        database,
        clock: () => semanticClock,
      );
      final result = await analysis.evaluate();
      validateSemanticAnalysis(spec, result);
      await analysis.runPending(ensureEvidence: true);
      return SemanticFixture._(spec, database, records, result);
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  Future<EvidenceProjection> project(String intent) async {
    if (!semanticIntents.contains(intent)) throw ArgumentError.value(intent);
    final projection = await EvidenceProjectionRepository(
      database,
    ).build(storeKind: StoreKind.demo, intent: intent);
    if (projection == null) throw StateError('Fixture projection is absent');
    return projection;
  }

  Future<void> close() => database.close();
}

void validateSemanticAnalysis(
  SemanticFamily spec,
  MeetingAnalysisResult result,
) {
  final mixed = spec.name == 'mixed_direction';
  final expected = <String, Object?>{
    'state': mixed
        ? 'contradictory'
        : spec.pairs < 4 || !spec.reportContext
        ? 'developing'
        : 'supported',
    'candidate_count': spec.pairs,
    'included_count': spec.pairs,
    'control_count': spec.pairs,
    'positive_count': mixed ? 2 : (spec.delta < 0 ? 0 : spec.pairs),
    'counterevidence_count': mixed ? 2 : 0,
    'consistency': mixed ? .5 : 1.0,
    'completeness': 1.0,
    'median_difference_bpm': spec.delta.toDouble(),
    'excluded_count': 0,
    'unresolved_influence_count': spec.reportContext ? 0 : spec.pairs,
    'caffeine_unknown_pair_count': spec.reportContext ? 0 : spec.pairs,
    'caffeine_exposure_pair_count': 0,
    'promotion_gates': {
      'four_usable_meetings': spec.pairs >= 4,
      'four_controls': spec.pairs >= 4,
      'completeness': true,
      'consistent_direction': !mixed,
      'material_difference': true,
      'complete_provenance': true,
      'caffeine_context_reported_zero': spec.reportContext,
    },
  };
  if (canonicalJsonEncode(semanticAnalyticalFacts(result)) !=
      canonicalJsonEncode(expected)) {
    throw StateError('Analytical expectations changed for ${spec.name}');
  }
}

Map<String, Object?> semanticAnalyticalFacts(MeetingAnalysisResult result) => {
  'state': result.state.name,
  'candidate_count': result.candidateCount,
  'included_count': result.includedCount,
  'control_count': result.controlsCount,
  'positive_count': result.positiveCount,
  'counterevidence_count': result.counterevidenceCount,
  'consistency': result.consistency,
  'completeness': result.completeness,
  'median_difference_bpm': result.medianDifferenceBpm,
  'excluded_count': result.excludedByReason.values.fold<int>(
    0,
    (a, b) => a + b,
  ),
  'unresolved_influence_count': result.unresolvedInfluenceCount,
  'caffeine_unknown_pair_count': result.caffeineUnknownPairCount,
  'caffeine_exposure_pair_count': result.caffeineExposurePairCount,
  'promotion_gates': result.promotionGates,
};

Map<String, Object?> semanticRequestJson(ExplainerRequest request) => {
  'schemaVersion': request.schemaVersion,
  'evidenceVersion': request.evidenceVersion,
  'findingState': request.findingState,
  'metricsJson': request.metricsJson,
  'promotionGatesJson': request.promotionGatesJson,
  'exclusionsJson': request.exclusionsJson,
  'counterevidenceJson': request.counterevidenceJson,
  'unresolvedInfluencesJson': request.unresolvedInfluencesJson,
  'approvedNextObservations': request.approvedNextObservations,
  'askIntent': request.askIntent,
};

String semanticSha256(String text) =>
    sha256.convert(utf8.encode(text)).toString();

String semanticRawTimelineJson(List<SourceRecordEnvelope> records) =>
    canonicalJsonEncode([
      for (final row in records)
        {
          'source': row.source.name,
          'recordType': row.recordType,
          'stableSourceId': row.stableSourceId,
          'parentStableSourceId': row.parentStableSourceId,
          'observedAt': row.observedAt.toUtc().toIso8601String(),
          'payload': row.payload,
        },
    ]);

List<SourceRecordEnvelope> semanticRecords(SemanticFamily spec) {
  final records = <SourceRecordEnvelope>[];
  void add(
    SourceKind source,
    String type,
    String id,
    Map<String, Object?> payload,
  ) {
    records.add(
      SourceRecordEnvelope(
        source: source,
        recordType: type,
        stableSourceId: '${spec.name}:$id',
        observedAt: semanticClock,
        payload: payload,
      ),
    );
  }

  for (final day in [4, 8, 12, 16].take(spec.pairs)) {
    final start = DateTime.utc(2026, 9, day, 10);
    add(SourceKind.demoCalendar, 'calendar_event', 'event-$day', {
      'start': start.toIso8601String(),
      'end': start.add(const Duration(minutes: 30)).toIso8601String(),
      'offset_minutes': 0,
      'category': 'recurring_one_to_one',
      'recurrence_id': 'series-a',
    });
    for (final sampleDay in [day - 1, day]) {
      final isEvent = sampleDay == day;
      for (var minute = 0; minute < (isEvent ? 60 : 15); minute++) {
        final time = DateTime.utc(
          2026,
          9,
          sampleDay,
          9,
          45,
        ).add(Duration(minutes: minute));
        add(SourceKind.demoHealth, 'heart_rate', 'hr-$sampleDay-$minute', {
          'timestamp': time.toIso8601String(),
          'unit': 'bpm',
          'value': isEvent && minute < 15
              ? 70 +
                    (spec.name == 'mixed_direction'
                        ? (day % 8 == 0 ? -4 : 18)
                        : spec.delta)
              : 70,
          'offset_minutes': 0,
        });
      }
      if (spec.reportContext) {
        final end = DateTime.utc(2026, 9, sampleDay, 10);
        add(SourceKind.demoManual, 'manual_checkin', 'caffeine-$sampleDay', {
          'timestamp': semanticClock.toIso8601String(),
          'offset_minutes': 0,
          'category': 'caffeine',
          'value': {
            'servings': 0,
            'coverage_start_utc': end
                .subtract(const Duration(hours: 4))
                .toIso8601String(),
            'coverage_end_utc': end.toIso8601String(),
          },
        });
      }
    }
  }
  return records;
}
