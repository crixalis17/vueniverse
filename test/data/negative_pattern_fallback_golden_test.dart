import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/model_runtime/evidence_projection_repository.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/domain/model_runtime/deterministic_explanation_runtime.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';

void main() {
  for (final spec
      in <({String name, int delta, int pairs, bool reportContext})>[
        (name: 'supported_negative', delta: -10, pairs: 4, reportContext: true),
        (name: 'supported_positive', delta: 10, pairs: 4, reportContext: true),
        (name: 'scarce_complete', delta: 10, pairs: 2, reportContext: true),
        (name: 'context_blocked', delta: 10, pairs: 4, reportContext: false),
        (name: 'mixed_direction', delta: 7, pairs: 4, reportContext: true),
      ]) {
    test(
      'actual analytical pipeline preserves ${spec.name} fallback meaning',
      () async {
        final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
        addTearDown(database.close);
        await database.initialize(kind: StoreKind.demo);
        final now = DateTime.utc(2026, 9, 20, 12);
        final records = _records(
          spec.name,
          now,
          delta: spec.delta,
          pairs: spec.pairs,
          reportContext: spec.reportContext,
        );
        for (final source in records.map((row) => row.source).toSet()) {
          final import = await CanonicalRecordRepository(database)
              .importRecords(
                sourceConnectionId: '${spec.name}:${source.name}',
                sourceKind: source,
                records: records.where((row) => row.source == source),
                normalizer: RecordNormalizer(
                  identityKey: 'fallback-golden:${spec.name}'.codeUnits,
                ),
                syncRunId: 'sync:${spec.name}:${source.name}',
              );
          expect(import.rejected, 0);
        }
        final analysis = MeetingAnalysisRepository(database, clock: () => now);
        final result = await analysis.evaluate();
        final isMixed = spec.name == 'mixed_direction';
        final expectedPositive = isMixed
            ? 2
            : spec.delta < 0
            ? 0
            : spec.pairs;
        final expectedCounterevidence = isMixed ? 2 : 0;
        expect(result.includedCount, spec.pairs);
        expect(result.controlsCount, spec.pairs);
        expect(result.positiveCount, expectedPositive);
        expect(result.counterevidenceCount, expectedCounterevidence);
        expect(result.consistency, isMixed ? .5 : 1);
        expect(result.completeness, 1);
        expect(result.medianDifferenceBpm, spec.delta);
        expect(
          result.state,
          isMixed
              ? EvidenceState.contradictory
              : spec.pairs < 4 || !spec.reportContext
              ? EvidenceState.developing
              : EvidenceState.supported,
        );
        expect(result.promotionGates['four_usable_meetings'], spec.pairs >= 4);
        expect(
          result.promotionGates['caffeine_context_reported_zero'],
          spec.reportContext,
        );
        await analysis.runPending(ensureEvidence: true);
        for (final intent in ['why_promoted', 'disagreement', 'observe_next']) {
          final projection = (await EvidenceProjectionRepository(
            database,
          ).build(storeKind: StoreKind.demo, intent: intent))!;
          final metrics =
              jsonDecode(projection.request.metricsJson)
                  as Map<String, dynamic>;
          expect(metrics['positive_count'], expectedPositive);
          expect(metrics['consistency'], isMixed ? .5 : 1);
          final response = DeterministicExplanationRuntime().explain(
            projection.request,
            guardContext: projection.guardContext,
          );
          expect(
            response.safety.accepted,
            isTrue,
            reason: '$intent ${response.safety.failures}',
          );
          final output = response.output!;
          if (intent == 'why_promoted') {
            if (spec.name == 'supported_negative') {
              expect(
                output.summary,
                'Across 4 meetings we could fairly compare, the usual heart-rate difference was -10 beats per minute.',
              );
              expect(output.summary, isNot(contains('same pattern in 0')));
            } else if (spec.name == 'supported_positive') {
              expect(output.summary, contains('+10 beats per minute'));
            } else if (spec.name == 'scarce_complete') {
              expect(
                output.summary,
                contains('more similar meetings are needed'),
              );
              expect(output.summary, isNot(contains('caffeine context')));
            } else if (isMixed) {
              expect(
                output.summary,
                '2 of 4 meetings did not show the same pattern, so there is no clear result yet.',
              );
              final paragraphs =
                  jsonDecode(output.citedParagraphsJson) as List<dynamic>;
              expect(
                paragraphs.first['citations'],
                contains('counterevidence_count'),
              );
            } else {
              expect(output.summary, contains('caffeine context'));
              expect(
                output.summary,
                isNot(contains('more similar meetings are needed')),
              );
            }
          } else if (intent == 'disagreement') {
            expect(
              output.summary,
              '$expectedCounterevidence of ${spec.pairs} meetings we could compare did not show the same pattern.',
            );
          } else {
            expect(
              output.approvedNextObservation,
              projection.request.approvedNextObservations.first,
            );
          }
          expect(response.metadata.runtime.name, 'deterministic');
        }
      },
    );
  }
}

List<SourceRecordEnvelope> _records(
  String name,
  DateTime now, {
  required int delta,
  required int pairs,
  required bool reportContext,
}) {
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
        stableSourceId: '$name:$id',
        observedAt: now,
        payload: payload,
      ),
    );
  }

  for (final day in [4, 8, 12, 16].take(pairs)) {
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
                    (name == 'mixed_direction'
                        ? (day % 8 == 0 ? -4 : 18)
                        : delta)
              : 70,
          'offset_minutes': 0,
        });
      }
      if (reportContext) {
        final end = DateTime.utc(2026, 9, sampleDay, 10);
        add(SourceKind.demoManual, 'manual_checkin', 'caffeine-$sampleDay', {
          'timestamp': now.toIso8601String(),
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
