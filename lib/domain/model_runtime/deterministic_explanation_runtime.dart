import 'dart:convert';

import 'package:why_pulse/domain/model_runtime/output_guard.dart';
import 'package:why_pulse/platform/generated/model_runtime_api.g.dart';

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
    final candidate = _number(metrics['candidate_count']);
    final state = request.findingState.replaceAll('_', ' ');
    final summary = switch (request.findingState) {
      'supported' when median != null && included != null =>
        'The comparison is supported by ${_format(included)} included meetings: the median difference was ${_signed(median)} bpm.',
      'nullFinding' || 'null_finding' =>
        'The available comparisons did not show a repeatable difference.',
      'contradictory' =>
        'The comparison moved in mixed directions, so the evidence was not promoted.',
      _ =>
        'The current evidence is $state. More complete comparable observations are needed before drawing a stronger conclusion.',
    };
    final paragraphs = [
      {
        'text': summary,
        'citations': [
          'finding_state',
          if (median != null) 'median_difference_bpm',
          if (included != null) 'included_count',
        ],
      },
      {
        'text': candidate == null
            ? 'The result keeps its exclusions and unresolved influences visible.'
            : 'The comparison started with ${_format(candidate)} candidate events and keeps exclusions visible.',
        'citations': ['candidate_count', 'exclusions', 'unresolved_influences'],
      },
    ];
    final output = ExplainerOutput(
      summary: summary,
      citedParagraphsJson: jsonEncode(paragraphs),
      uncertainty:
          'This describes a repeated personal association, not a diagnosis, treatment, or causal conclusion.',
      citedUnresolvedInfluences: const ['unresolved_influences'],
      approvedNextObservation: request.approvedNextObservations.isEmpty
          ? null
          : request.approvedNextObservations.first,
    );
    final safety = _guard.validate(output, guardContext);
    return ModelExplainerResult(
      output: safety.accepted ? output : null,
      metadata: ModelRuntimeMetadata(
        runtime: InferenceRuntime.deterministic,
        modelName: 'deterministic-fallback',
        promptVersion: request.askIntent.isEmpty ? 1 : 2,
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

  String _format(num value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  String _signed(num value) => '${value >= 0 ? '+' : ''}${_format(value)}';
}
