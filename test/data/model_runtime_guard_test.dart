import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/domain/model_runtime/deterministic_explanation_runtime.dart';
import 'package:vueniverse/domain/model_runtime/output_guard.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

void main() {
  const context = EvidenceGuardContext(
    evidenceVersion: 'evidence-v1',
    allowedCitations: {
      'finding_state',
      'median_difference_bpm',
      'included_count',
      'candidate_count',
      'exclusions',
      'unresolved_influences',
    },
    allowedInfluenceIds: {'unresolved_influences'},
    allowedNumbers: {12, 8, 6, 11, 14},
    allowedNumbersByCitation: {
      'finding_state': {1},
      'median_difference_bpm': {8, 11, 14},
      'included_count': {8},
      'candidate_count': {12},
      'exclusions': {6},
      'unresolved_influences': {6},
    },
    allowedNextObservations: {'Log caffeine before the next similar meeting.'},
  );

  test('deterministic fallback produces cited, bounded output', () {
    final result = DeterministicExplanationRuntime().explain(
      ExplainerRequest(
        schemaVersion: 'explainer-v3',
        evidenceVersion: 'evidence-v1',
        findingState: 'supported',
        metricsJson:
            '{"median_difference_bpm":11,"included_count":8,"candidate_count":12}',
        promotionGatesJson: '{}',
        exclusionsJson: '{}',
        counterevidenceJson: '{}',
        unresolvedInfluencesJson: '{}',
        approvedNextObservations: const [
          'Log caffeine before the next similar meeting.',
        ],
        askIntent: 'why_promoted',
      ),
      guardContext: context,
    );

    expect(result.safety.accepted, isTrue);
    expect(result.output, isNotNull);
    expect(
      result.output!.summary,
      'Across 8 meetings we could fairly compare, the usual heart-rate difference was +11 beats per minute.',
    );
    expect(result.output!.summary, isNot(contains('evidence bundle')));
    expect(result.metadata.runtime, InferenceRuntime.deterministic);
    expect(result.metadata.promptVersion, 5);
  });

  test('guard rejects internal jargon in model-written answers', () {
    final output = ExplainerOutput(
      summary: 'This evidence bundle has strong counterevidence.',
      citedParagraphsJson:
          '[{"text":"The evidence bundle was promoted.","citations":["finding_state"]}]',
      uncertainty: 'The inference remains bounded.',
      citedUnresolvedInfluences: const [],
    );

    final result = const OutputGuard().validate(output, context);

    expect(result.accepted, isFalse);
    expect(result.failures, contains('technical_language'));
  });

  test('guard rejects unsafe model claims and invented numbers', () {
    final output = ExplainerOutput(
      summary: 'This diagnosis was caused by 99 bpm.',
      citedParagraphsJson:
          '[{"text":"Take medication because this is unsafe.","citations":["finding_state"]}]',
      uncertainty: 'none',
      citedUnresolvedInfluences: const [],
    );
    final result = const OutputGuard().validate(output, context);
    expect(result.accepted, isFalse);
    expect(result.failures, contains('diagnosis'));
    expect(result.failures, contains('invented_number'));
  });

  test('guard checks unsafe and invented claims in uncertainty text', () {
    final output = ExplainerOutput(
      summary: 'The comparison remains supported.',
      citedParagraphsJson:
          '[{"text":"The comparison remains supported.","citations":["finding_state"]}]',
      uncertainty:
          'There is a 97% chance of an anxiety disorder, so you should take aspirin.',
      citedUnresolvedInfluences: const [],
    );

    final result = const OutputGuard().validate(output, context);

    expect(result.accepted, isFalse);
    expect(result.failures, contains('invented_number'));
    expect(result.failures, contains('diagnosis'));
    expect(result.failures, contains('medication_advice'));
    expect(result.failures, contains('generic_advice'));
  });

  test('guard allows supplied evidence numbers in uncertainty text', () {
    final output = ExplainerOutput(
      summary: 'The usual difference was +11 beats per minute.',
      citedParagraphsJson:
          '[{"text":"The usual difference was +11 beats per minute.","citations":["median_difference_bpm"]}]',
      uncertainty:
          'The observed +11 beat difference does not prove why the pattern happened.',
      citedUnresolvedInfluences: const [],
    );

    final result = const OutputGuard().validate(output, context);

    expect(result.accepted, isTrue);
  });

  test('guard rejects a globally valid number bound to another citation', () {
    final output = ExplainerOutput(
      summary: 'The comparison remains supported.',
      citedParagraphsJson:
          '[{"text":"The usual difference was +12 beats per minute.","citations":["median_difference_bpm"]}]',
      uncertainty: 'More similar meetings may change this result.',
      citedUnresolvedInfluences: const [],
    );

    final result = const OutputGuard().validate(output, context);

    expect(result.accepted, isFalse);
    expect(result.failures, contains('citation_number_mismatch'));
    expect(result.failures, isNot(contains('invented_number')));
  });

  test('guard rejects a summary number missing from bound paragraphs', () {
    final output = ExplainerOutput(
      summary: 'The usual difference was +12 beats per minute.',
      citedParagraphsJson:
          '[{"text":"The usual difference was +11 beats per minute.","citations":["median_difference_bpm"]}]',
      uncertainty: 'More similar meetings may change this result.',
      citedUnresolvedInfluences: const [],
    );

    final result = const OutputGuard().validate(output, context);

    expect(result.accepted, isFalse);
    expect(result.failures, contains('unbound_numeric_claim'));
    expect(result.failures, isNot(contains('citation_number_mismatch')));
    expect(result.failures, isNot(contains('invented_number')));
  });

  test('guard allows metric bounds when cited to their metric', () {
    final output = ExplainerOutput(
      summary: 'The comparison remains supported.',
      citedParagraphsJson:
          '[{"text":"The observed range was +8 to +14 beats per minute.","citations":["median_difference_bpm"]}]',
      uncertainty: 'More similar meetings may change this result.',
      citedUnresolvedInfluences: const [],
    );

    final result = const OutputGuard().validate(output, context);

    expect(result.accepted, isTrue);
  });

  test('guard still allows prose-only nonnumeric citations', () {
    final output = ExplainerOutput(
      summary: 'The comparison remains supported.',
      citedParagraphsJson:
          '[{"text":"The repeated pattern remains supported.","citations":["finding_state"]}]',
      uncertainty: 'More similar meetings may change this result.',
      citedUnresolvedInfluences: const [],
    );

    final result = const OutputGuard().validate(output, context);

    expect(result.accepted, isTrue);
  });

  test('guard rejects evidence mismatches and unknown observations', () {
    final output = ExplainerOutput(
      summary: 'The comparison remains supported.',
      citedParagraphsJson:
          '[{"text":"The comparison remains supported.","citations":["finding_state"]}]',
      uncertainty: 'The association remains uncertain.',
      citedUnresolvedInfluences: const [],
      approvedNextObservation: 'Change medication before the next meeting.',
    );
    final result = const OutputGuard().validateResult(
      ModelExplainerResult(
        evidenceVersion: 'other-evidence',
        output: output,
        metadata: ModelRuntimeMetadata(
          runtime: InferenceRuntime.phoneMedGemma,
          modelName: 'test',
          promptVersion: 1,
          outputGuardVersion: 0,
          latencyMillis: 1,
          schemaValid: true,
        ),
        safety: SafetyResult(accepted: true, failures: const []),
      ),
      ExplainerRequest(
        schemaVersion: 'explainer-v2',
        evidenceVersion: 'evidence-v1',
        findingState: 'supported',
        metricsJson: '{}',
        promotionGatesJson: '{}',
        exclusionsJson: '{}',
        counterevidenceJson: '{}',
        unresolvedInfluencesJson: '{}',
        approvedNextObservations: const [
          'Log caffeine before the next similar meeting.',
        ],
        askIntent: 'why_promoted',
      ),
      context,
    );

    expect(result.accepted, isFalse);
    expect(result.failures, contains('evidence_version_mismatch'));
    expect(result.failures, contains('unknown_next_observation'));
    expect(result.failures, contains('medication_advice'));
  });
}
