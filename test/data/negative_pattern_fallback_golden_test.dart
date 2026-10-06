import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/domain/model_runtime/deterministic_explanation_runtime.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

import '../support/emulator_semantic_fixture.dart';

void main() {
  for (final spec in semanticFamilies) {
    test(
      'actual analytical pipeline preserves ${spec.name} fallback meaning',
      () async {
        final fixture = await SemanticFixture.build(spec);
        addTearDown(fixture.close);
        final result = fixture.result;
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
        for (final intent in semanticIntents) {
          final projection = await fixture.project(intent);
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
