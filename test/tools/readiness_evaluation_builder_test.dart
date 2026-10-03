import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/schema_versions.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/model_runtime/evidence_projection_repository.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/domain/analytics/evidence_uncertainty.dart';
import 'package:vueniverse/domain/model_runtime/deterministic_explanation_runtime.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';

const _cases = <(String, String)>[
  ('null', 'nullFinding'),
  ('repeated', 'supported'),
  ('unknown_context', 'developing'),
  ('mixed_direction', 'contradictory'),
  ('sparse', 'insufficientData'),
  ('workout', 'insufficientData'),
  ('illness_control', 'insufficientData'),
  ('distinct_series', 'developing'),
  ('missing_identity', 'insufficientData'),
  ('offset_mismatch', 'insufficientData'),
];
const _outputPath = String.fromEnvironment('READINESS_EXPORT_DIR');

void main() {
  test(
    'raw development timelines traverse actual normalization, analytics and projection',
    () async {
      final now = DateTime.utc(2026, 9, 20, 12);
      final rows = <Map<String, Object?>>[];
      final raw = <Map<String, Object?>>[];
      for (final spec in _cases) {
        final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
        try {
          await database.initialize(kind: StoreKind.demo);
          final records = _records(spec.$1, now);
          final rawObject = {
            'case_id': spec.$1,
            'records': [
              for (final record in records)
                {
                  'source': record.source.name,
                  'type': record.recordType,
                  'id': record.stableSourceId,
                  'observed_at': record.observedAt.toIso8601String(),
                  'payload': record.payload,
                },
            ],
          };
          raw.add(rawObject);
          final inputHash = sha256
              .convert(utf8.encode(jsonEncode(rawObject)))
              .toString();
          for (final source in records.map((row) => row.source).toSet()) {
            final report = await CanonicalRecordRepository(database)
                .importRecords(
                  sourceConnectionId: '${spec.$1}:${source.name}',
                  sourceKind: source,
                  records: records.where((row) => row.source == source),
                  normalizer: RecordNormalizer(
                    identityKey: 'readiness-v1:${spec.$1}'.codeUnits,
                  ),
                  syncRunId: 'sync:${spec.$1}:${source.name}',
                );
            expect(report.rejected, 0, reason: spec.$1);
          }
          final analysis = MeetingAnalysisRepository(
            database,
            clock: () => now,
          );
          final result = await analysis.evaluate();
          expect(result.state.name, spec.$2, reason: spec.$1);
          if (spec.$1 == 'null') expect(result.medianDifferenceBpm, 0);
          if (spec.$1 == 'repeated') expect(result.includedCount, 4);
          if (spec.$1 == 'distinct_series') expect(result.candidateCount, 2);
          if (spec.$1 == 'missing_identity') expect(result.includedCount, 0);
          await analysis.runPending(ensureEvidence: true);
          for (final intent in [
            'why_promoted',
            'disagreement',
            'observe_next',
          ]) {
            final projection = (await EvidenceProjectionRepository(
              database,
            ).build(storeKind: StoreKind.demo, intent: intent))!;
            final request = projection.request;
            final response = DeterministicExplanationRuntime().explain(
              request,
              guardContext: projection.guardContext,
            );
            expect(
              response.safety.accepted,
              isTrue,
              reason: '${spec.$1}:$intent ${response.safety.failures}',
            );
            final differences = [
              for (final row in result.occurrences)
                if (row.included && row.differenceBpm != null)
                  row.differenceBpm!,
            ];
            final sign = pairedSignTest(differences);
            rows.add({
              'case_id': '${spec.$1}:$intent',
              'cluster_id': spec.$1,
              'split': 'development',
              'raw_input_sha256': inputHash,
              'independent_review_status': 'pending',
              'expected_analytical_state': spec.$2,
              'evidence_hash': projection.evidenceHash,
              'projection_request_hash': projection.requestHash,
              'schema_versions': SchemaVersions.values,
              'request': {
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
              },
              'research_diagnostic': {
                'sign_p_value': sign.pValue,
                'positive': sign.positive,
                'negative': sign.negative,
                'ties': sign.ties,
                'independence_assumed': true,
                'inferential_claim_allowed': false,
              },
              'deterministic_baseline': {
                'guard_accepted': response.safety.accepted,
                'guard_failures': response.safety.failures,
                'summary': response.output?.summary,
                'citedParagraphsJson': response.output?.citedParagraphsJson,
                'uncertainty': response.output?.uncertainty,
                'citedUnresolvedInfluences':
                    response.output?.citedUnresolvedInfluences,
                'approvedNextObservation':
                    response.output?.approvedNextObservation,
              },
            });
          }
        } finally {
          await database.close();
        }
      }
      expect(rows, hasLength(30));
      if (_outputPath.isNotEmpty) {
        final directory = Directory(_outputPath);
        await directory.create(recursive: true);
        final projectionBytes = utf8.encode(
          '${rows.map(jsonEncode).join('\n')}\n',
        );
        final rawBytes = utf8.encode('${raw.map(jsonEncode).join('\n')}\n');
        await File(
          '${directory.path}/app-projections.jsonl',
        ).writeAsBytes(projectionBytes);
        await File(
          '${directory.path}/raw-timelines.jsonl',
        ).writeAsBytes(rawBytes);
        final contract = File(
          'docs/finetuning/readiness-evaluation-contract-v1.md',
        );
        await File('${directory.path}/manifest.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'contract': 'readiness-evaluation-v1',
            'split': 'development',
            'final_evaluation': false,
            'independent_review_status': 'pending',
            'case_count': rows.length,
            'cluster_count': _cases.length,
            'clock_utc': now.toIso8601String(),
            'schema_versions': SchemaVersions.values,
            'projection_sha256': sha256.convert(projectionBytes).toString(),
            'raw_timelines_sha256': sha256.convert(rawBytes).toString(),
            'contract_sha256': sha256
                .convert(await contract.readAsBytes())
                .toString(),
            'generation': 'test/tools/readiness_evaluation_builder_test.dart',
            'prior_training_artifacts_modified': false,
          }),
        );
        await File('${directory.path}/review-template.jsonl').writeAsString(
          '${rows.map((row) => jsonEncode({'case_id': row['case_id'], 'blinded_output_id': null, 'reviewer_id': null, 'grounding': null, 'uncertainty': null, 'safety': null, 'usefulness': null, 'verdict': null, 'evidence_references': [], 'error_codes': [], 'rationale': null})).join('\n')}\n',
        );
      }
    },
  );
}

List<SourceRecordEnvelope> _records(String family, DateTime now) {
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
        stableSourceId: '$family:$id',
        observedAt: now,
        payload: payload,
      ),
    );
  }

  for (final day in [4, 8, 12, 16]) {
    final start = DateTime.utc(2026, 9, day, 10);
    final end = start.add(const Duration(minutes: 30));
    add(SourceKind.demoCalendar, 'calendar_event', 'event-$day', {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'offset_minutes': 0,
      'category': 'recurring_one_to_one',
      if (family != 'missing_identity')
        'recurrence_id': family == 'distinct_series' && day > 8
            ? 'series-b'
            : 'series-a',
    });
    final delta = family == 'null'
        ? 0
        : family == 'mixed_direction' && day % 8 == 0
        ? -4
        : family == 'mixed_direction'
        ? 18
        : 10;
    for (final sampleDay in [day - 1, day]) {
      final isEvent = sampleDay == day;
      for (var minute = 0; minute < (isEvent ? 60 : 15); minute++) {
        if (family == 'sparse' && minute.isOdd) continue;
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
          'value': isEvent && minute < 15 ? 70 + delta : 70,
          'offset_minutes': family == 'offset_mismatch' && !isEvent ? 60 : 0,
        });
      }
      if (family != 'unknown_context') {
        final coverageEnd = DateTime.utc(2026, 9, sampleDay, 10);
        add(SourceKind.demoManual, 'manual_checkin', 'caffeine-$sampleDay', {
          'timestamp': now.toIso8601String(),
          'offset_minutes': 0,
          'category': 'caffeine',
          'value': {
            'servings': 0,
            'coverage_start_utc': coverageEnd
                .subtract(const Duration(hours: 4))
                .toIso8601String(),
            'coverage_end_utc': coverageEnd.toIso8601String(),
          },
        });
      }
      if (family == 'illness_control' && !isEvent) {
        add(SourceKind.demoManual, 'manual_checkin', 'illness-$sampleDay', {
          'timestamp': DateTime.utc(2026, 9, sampleDay, 8).toIso8601String(),
          'offset_minutes': 0,
          'category': 'illness',
          'value': {'detail': 'Feeling unwell today'},
        });
      }
    }
    if (family == 'workout') {
      add(SourceKind.demoHealth, 'workout', 'workout-$day', {
        'start': start.subtract(const Duration(minutes: 20)).toIso8601String(),
        'end': start.add(const Duration(minutes: 10)).toIso8601String(),
        'offset_minutes': 0,
        'category': 'running',
      });
    }
  }
  return records;
}
