import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/domain/model_runtime/deterministic_explanation_runtime.dart';
import 'package:why_pulse/domain/model_runtime/output_guard.dart';
import 'package:why_pulse/platform/generated/model_runtime_api.g.dart';

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
    allowedNumbers: {12, 8, 6, 11},
  );

  test('deterministic fallback produces cited, bounded output', () {
    final result = DeterministicExplanationRuntime().explain(
      ExplainerRequest(
        schemaVersion: 'explainer-v1',
        evidenceVersion: 'evidence-v1',
        findingState: 'supported',
        metricsJson:
            '{"median_difference_bpm":11,"included_count":8,"candidate_count":12}',
        promotionGatesJson: '{}',
        exclusionsJson: '{}',
        counterevidenceJson: '{}',
        unresolvedInfluencesJson: '{}',
        approvedNextObservations: const [
          'Log caffeine before the next meeting.',
        ],
        askIntent: 'why_promoted',
      ),
      guardContext: context,
    );

    expect(result.safety.accepted, isTrue);
    expect(result.output, isNotNull);
    expect(result.metadata.runtime, InferenceRuntime.deterministic);
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
}
