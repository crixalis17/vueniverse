import 'dart:convert';

import 'package:vueniverse/domain/model_runtime/output_guard.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

final class DeterministicExplanationRuntime {
  DeterministicExplanationRuntime({this._guard = const OutputGuard()});

  final OutputGuard _guard;

  ModelExplainerResult explain(
    ExplainerRequest request, {
    required EvidenceGuardContext guardContext,
  }) {
    final metrics = _decode(request.metricsJson);
    final median = _number(metrics['median_difference_bpm']);
    final included = _number(metrics['included_count']);
    final positive = _number(metrics['positive_count']);
    final candidate = _number(metrics['candidate_count']);
    final counterevidence = _number(metrics['counterevidence_count']);
    final completeness = _number(metrics['completeness']);
    final unresolved = _number(metrics['unresolved_influence_count']);
    final contributorIds = _objectKeys(request.unresolvedInfluencesJson);
    final findingSummary = switch (request.findingState) {
      'supported' when median != null && included != null && positive != null =>
        'Heart rate followed the same pattern in ${_format(positive)} of the ${_format(included)} meetings we could fairly compare. The usual difference was ${_signed(median)} beats per minute.',
      'supported' when median != null && included != null =>
        'Across ${_format(included)} meetings we could fairly compare, the usual heart-rate difference was ${_signed(median)} beats per minute.',
      'nullFinding' || 'null_finding' when included != null =>
        'The ${_format(included)} meetings we could fairly compare did not show a clear, repeated heart-rate difference.',
      'nullFinding' || 'null_finding' =>
        'The meetings we could fairly compare did not show a clear, repeated heart-rate difference.',
      'contradictory' when counterevidence != null && included != null =>
        '${_format(counterevidence)} of ${_format(included)} meetings did not show the same pattern, so there is no clear result yet.',
      'contradictory' =>
        'Some meetings showed the pattern and others did not, so there is no clear result yet.',
      'insufficientData' || 'insufficient_data' =>
        'There is not enough complete data to make a fair comparison yet.',
      'developing' when metrics['gate_caffeine_context_reported_zero'] == 0 =>
        'The meeting comparison remains tentative because caffeine context in the meeting or comparison periods is unresolved.',
      'developing' =>
        'The pattern has appeared more than once, but more similar meetings are needed to understand it.',
      _ => 'There is not enough complete data to make a clear comparison yet.',
    };
    final summary = switch (request.askIntent) {
      'disagreement' when counterevidence != null && included != null =>
        '${_format(counterevidence)} of ${_format(included)} meetings we could compare did not show the same pattern.',
      'disagreement' when counterevidence != null =>
        '${_format(counterevidence)} meetings did not show the same pattern.',
      'missing_evidence' when completeness != null && unresolved != null =>
        '${_format(completeness * 100)}% of the needed data is available. ${_format(unresolved)} context ${unresolved == 1 ? 'detail still needs' : 'details still need'} review.',
      'observe_next' when request.approvedNextObservations.isNotEmpty =>
        'The approved next observation is shown below. It can help check whether the pattern repeats.',
      _ => findingSummary,
    };
    final primaryCitations = switch (request.askIntent) {
      'disagreement' => [
        'counterevidence_count',
        if (included != null) 'included_count',
      ],
      'missing_evidence' => ['completeness', 'unresolved_influence_count'],
      'observe_next' => ['unresolved_influences'],
      _ => [
        if (median == null && included == null && positive == null)
          'finding_state',
        if (median != null) 'median_difference_bpm',
        if (included != null) 'included_count',
        if (positive != null) 'positive_count',
      ],
    };
    final paragraphs = [
      {'text': summary, 'citations': primaryCitations},
      {
        'text': candidate == null
            ? 'Meetings with missing or unreliable data were left out of this comparison.'
            : included == null
            ? 'Vueniverse found ${_format(candidate)} meetings to check and left out any with missing or unreliable data.'
            : 'Vueniverse found ${_format(candidate)} meetings to check and used ${_format(included)} after leaving out meetings with missing or unreliable data.',
        'citations': [
          if (candidate != null) 'candidate_count',
          if (included != null) 'included_count',
          'exclusions',
        ],
      },
    ];
    final output = ExplainerOutput(
      summary: summary,
      citedParagraphsJson: jsonEncode(paragraphs),
      uncertainty:
          'This is a pattern in your data. It does not prove that the meeting was the reason for the heart-rate change.',
      citedUnresolvedInfluences: unresolved != null && unresolved > 0
          ? contributorIds.take(3).toList(growable: false)
          : const [],
      approvedNextObservation: request.approvedNextObservations.isEmpty
          ? null
          : request.approvedNextObservations.first,
    );
    final safety = _guard.validate(output, guardContext);
    return ModelExplainerResult(
      evidenceVersion: request.evidenceVersion,
      output: safety.accepted ? output : null,
      metadata: ModelRuntimeMetadata(
        runtime: InferenceRuntime.deterministic,
        modelName: 'deterministic-fallback',
        promptVersion: 5,
        outputGuardVersion: outputGuardVersion,
        latencyMillis: 0,
        schemaValid: safety.accepted,
      ),
      safety: safety,
      failure: safety.accepted ? null : safety.failures.join(','),
    );
  }

  Map<String, Object?> _decode(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is Map) {
        return {for (final entry in value.entries) '${entry.key}': entry.value};
      }
    } on FormatException {
      // Fallback text remains safe when a model request has malformed metrics.
    }
    return const {};
  }

  num? _number(Object? value) => value is num ? value : null;

  List<String> _objectKeys(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is Map) {
        return value.keys.map((key) => '$key').toList(growable: false);
      }
    } on FormatException {
      // A malformed optional context list simply produces no contributors.
    }
    return const [];
  }

  String _format(num value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  String _signed(num value) => '${value >= 0 ? '+' : ''}${_format(value)}';
}
