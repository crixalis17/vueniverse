import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/domain/model_runtime/output_guard.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

void main() {
  final context = EvidenceGuardContext(
    evidenceVersion: 'fixture-v1',
    allowedCitations: {
      'consistency',
      'completeness',
      'included_count',
      'candidate_count',
      'gate_caffeine_context_reported_zero',
    },
    allowedInfluenceIds: {},
    allowedNumbers: {0, 0.75, 1, 8, 12, 100},
    allowedNumbersByCitation: {
      'consistency': {0.75},
      'completeness': {1, 100},
      'included_count': {8},
      'candidate_count': {12},
      'gate_caffeine_context_reported_zero': {0},
    },
    allowedNextObservations: {},
    primaryMetricValues: {
      'consistency': 0.75,
      'completeness': 1,
      'included_count': 8,
    },
  );
  ExplainerOutput answer(String text) => ExplainerOutput(
    summary: text,
    citedParagraphsJson: jsonEncode([
      {
        'text': text,
        'citations': ['consistency', 'completeness', 'included_count'],
      },
    ]),
    uncertainty: 'The comparison cannot establish why this happened.',
    citedUnresolvedInfluences: [],
  );
  for (final text in [
    'The same-direction share is zero.',
    'The same-direction share is 0.',
    'The data completeness is 8.',
    'The share of data available is zero.',
    'The included count is 1.',
    'There were zero comparable windows.',
    'There were 1 comparable windows.',
  ]) {
    test('rejects explicit wrong metric role: $text', () {
      final result = const OutputGuard().validate(answer(text), context);
      expect(result.accepted, isFalse);
      expect(result.failures, contains('metric_role_numeric_mismatch'));
    });
  }
  test('unrelated cited gate zero cannot authorize consistency zero', () {
    final output = answer('The same-direction share is 0.');
    output.citedParagraphsJson = jsonEncode([
      {
        'text': output.summary,
        'citations': ['consistency', 'gate_caffeine_context_reported_zero'],
      },
    ]);
    expect(
      const OutputGuard().validate(output, context).failures,
      contains('metric_role_numeric_mismatch'),
    );
  });
  test('recovered accepted response contradicts its exact fixture metric role', () {
    final output = answer(
      'For developing windows, the comparison windows cannot be used for a fair comparison. The same-direction share is zero. The comparison pairs need context review.',
    );
    output.citedParagraphsJson = jsonEncode([
      {
        'text': output.summary,
        'citations': ['candidate_count', 'included_count', 'consistency'],
      },
      {
        'text':
            'The event windows checked are 12.0, and 8.0 were compared. The same-direction share is 0.75, which does not meet the usable data. The comparison pairs need context review.',
        'citations': ['candidate_count', 'included_count', 'consistency'],
      },
    ]);
    expect(
      const OutputGuard().validate(output, context).failures,
      contains('metric_role_numeric_mismatch'),
    );
  });
  for (final text in [
    'The same-direction share is 0.75.',
    'The same-direction share is zero point seven five.',
    'The same-direction share is ZERO POINT SEVEN FIVE.',
    'The included count is eight.',
    'There were eight comparable windows.',
    'The completeness is one.',
    // Unsupported compounds must remain unknown, not prefix-zero assertions.
    'The same-direction share is zero point seventy five.',
    'The same-direction share is zero point seven five six seven eight nine zero one two three.',
    'The completeness is one hundred.',
    'The completeness is one and a half.',
    'If the same-direction share is zero point seven four, more comparisons may help.',
    'The claim "the same-direction share is zero point seven four" is false.',
    'The completeness is 1.',
    'The completeness is 100%.',
    'There were 8 comparable windows.',
    'The same-direction share is not zero.',
    'Missing logs do not mean zero intake.',
    'These are one-to-one meetings.',
    'If the same-direction share is zero, more comparisons may help.',
    'We cannot conclude that the same-direction share is zero.',
    'Whether the same-direction share is zero remains unknown.',
    'The claim "the same-direction share is zero" is false.',
    'No comparison can prove why a change happened.',
    'More similar windows are needed.',
    'There were not zero comparable windows.',
    'There might be zero comparable windows.',
    'There could be zero comparable windows.',
    'We do not know whether there were zero comparable windows.',
  ]) {
    test('allows scoped positive/negative control: $text', () {
      expect(
        const OutputGuard().validate(answer(text), context).accepted,
        isTrue,
      );
    });
  }
  for (final text in [
    'The same-direction share is zero point seven four.',
    'The same-direction share is zero point seven five one.',
    'The included count is nine.',
    'There were nineteen comparable windows.',
    'The completeness is zero point nine nine nine.',
    'The same-direction share is 0.751.',
  ]) {
    test('rejects whole wrong cardinal or decimal: $text', () {
      expect(
        const OutputGuard().validate(answer(text), context).failures,
        contains('metric_role_numeric_mismatch'),
      );
    });
  }
  const cardinals = [
    'zero',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen',
  ];
  for (final entry in cardinals.indexed) {
    test('accepts exact finite cardinal ${entry.$2}', () {
      final scalarContext = EvidenceGuardContext(
        evidenceVersion: 'fixture-v1',
        allowedCitations: {'included_count'},
        allowedInfluenceIds: {},
        allowedNumbers: {entry.$1},
        allowedNumbersByCitation: {
          'included_count': {entry.$1},
        },
        allowedNextObservations: {},
        primaryMetricValues: {'included_count': entry.$1},
      );
      final text = 'The included count is ${entry.$2}.';
      final output = answer(text);
      output.citedParagraphsJson = jsonEncode([
        {
          'text': text,
          'citations': ['included_count'],
        },
      ]);
      expect(
        const OutputGuard().validate(output, scalarContext).accepted,
        isTrue,
      );
    });
  }
  test(
    'true zero consistency remains allowed independently of other metrics',
    () {
      const zeroContext = EvidenceGuardContext(
        evidenceVersion: 'fixture-v1',
        allowedCitations: {'consistency'},
        allowedInfluenceIds: {},
        allowedNumbers: {0},
        allowedNumbersByCitation: {
          'consistency': {0},
        },
        allowedNextObservations: {},
      );
      final output = answer('The same-direction share is zero.');
      output.citedParagraphsJson =
          '[{"text":"The same-direction share is zero.","citations":["consistency"]}]';
      expect(
        const OutputGuard().validate(output, zeroContext).accepted,
        isTrue,
      );
    },
  );
}
