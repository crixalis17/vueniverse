import 'dart:convert';
import 'dart:math' as math;

import 'package:why_pulse/platform/generated/model_runtime_api.g.dart';

const outputGuardVersion = 5;

final class EvidenceGuardContext {
  const EvidenceGuardContext({
    required this.evidenceVersion,
    required this.allowedCitations,
    required this.allowedInfluenceIds,
    required this.allowedNumbers,
    required this.allowedNumbersByCitation,
    required this.allowedNextObservations,
    this.liveStore = false,
  });

  final String evidenceVersion;
  final Set<String> allowedCitations;
  final Set<String> allowedInfluenceIds;
  final Set<num> allowedNumbers;
  final Map<String, Set<num>> allowedNumbersByCitation;
  final Set<String> allowedNextObservations;
  final bool liveStore;
}

final class OutputGuard {
  const OutputGuard();

  SafetyResult validateResult(
    ModelExplainerResult result,
    ExplainerRequest request,
    EvidenceGuardContext context,
  ) {
    final failures = <String>[];
    if (result.evidenceVersion != request.evidenceVersion ||
        request.evidenceVersion != context.evidenceVersion) {
      failures.add('evidence_version_mismatch');
    }
    if (!result.metadata.schemaValid) failures.add('invalid_schema');
    if (result.failure != null) failures.add(result.failure!);
    if (!result.safety.accepted) failures.addAll(result.safety.failures);
    final output = result.output;
    if (output == null) {
      failures.add(result.failure ?? 'missing_output');
    } else {
      failures.addAll(validate(output, context).failures);
    }
    return SafetyResult(
      accepted: failures.isEmpty,
      failures: failures.toSet().toList()..sort(),
    );
  }

  SafetyResult validate(ExplainerOutput output, EvidenceGuardContext context) {
    final failures = <String>[];
    if (output.summary.trim().isEmpty) failures.add('empty_summary');
    if (output.uncertainty.trim().isEmpty) failures.add('missing_uncertainty');
    final boundParagraphNumbers = <num>{};
    final paragraphs = _decodeParagraphs(output.citedParagraphsJson);
    if (paragraphs == null || paragraphs.isEmpty) {
      failures.add('invalid_cited_paragraphs');
    } else {
      for (final paragraph in paragraphs) {
        final text = paragraph['text'];
        final citations = paragraph['citations'];
        if (text is! String || text.trim().isEmpty) {
          failures.add('empty_cited_paragraph');
          continue;
        }
        if (citations is! List || citations.isEmpty) {
          failures.add('uncited_claim');
        } else {
          for (final citation in citations) {
            if (citation is! String ||
                !context.allowedCitations.contains(citation)) {
              failures.add('unknown_citation');
            }
          }
        }
        failures.addAll(_unsafeTextFailures(text));
        failures.addAll(_hardToReadTextFailures(text));
        failures.addAll(_inventedNumberFailures(text, context.allowedNumbers));
        if (citations is List && citations.isNotEmpty) {
          final citationNumbers = _allowedNumbersForCitations(
            citations.whereType<String>(),
            context,
          );
          failures.addAll(
            _citationNumberFailures(text, citationNumbers, context),
          );
          boundParagraphNumbers.addAll(
            _successfullyBoundNumbers(text, citationNumbers, context),
          );
        }
      }
    }
    failures.addAll(_unsafeTextFailures(output.summary));
    failures.addAll(_hardToReadTextFailures(output.summary));
    failures.addAll(
      _inventedNumberFailures(output.summary, context.allowedNumbers),
    );
    failures.addAll(
      _inventedNumberFailures(output.uncertainty, context.allowedNumbers),
    );
    failures.addAll(
      _unboundNumberFailures(
        output.summary,
        boundParagraphNumbers,
        context.allowedNumbers,
      ),
    );
    failures.addAll(
      _unboundNumberFailures(
        output.uncertainty,
        boundParagraphNumbers,
        context.allowedNumbers,
      ),
    );
    for (final influence in output.citedUnresolvedInfluences) {
      if (!context.allowedInfluenceIds.contains(influence)) {
        failures.add('unknown_influence');
      }
    }
    final nextObservation = output.approvedNextObservation;
    if (nextObservation != null) {
      if (nextObservation.trim().isEmpty) {
        failures.add('empty_next_observation');
      } else if (!context.allowedNextObservations.contains(nextObservation)) {
        failures.add('unknown_next_observation');
      }
    }
    final prose = <String>[
      output.summary,
      output.uncertainty,
      ?nextObservation,
      ...?_decodeParagraphs(
        output.citedParagraphsJson,
      )?.map((paragraph) => paragraph['text']).whereType<String>(),
    ];
    failures.addAll(prose.expand(_unsafeTextFailures));
    failures.addAll(prose.expand(_hardToReadTextFailures));
    if (context.liveStore &&
        prose.any(
          (text) =>
              _containsAny(text, const ['demo', 'fictional', 'sample data']),
        )) {
      failures.add('cross_store_reference');
    }
    return SafetyResult(
      accepted: failures.isEmpty,
      failures: failures.toSet().toList()..sort(),
    );
  }

  List<Map<String, Object?>>? _decodeParagraphs(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is! List) return null;
      final paragraphs = <Map<String, Object?>>[];
      for (final item in value) {
        if (item is! Map) return null;
        paragraphs.add({
          for (final entry in item.entries) '${entry.key}': entry.value,
        });
      }
      return paragraphs;
    } on FormatException {
      return null;
    }
  }

  List<String> _unsafeTextFailures(String text) {
    final lower = text.toLowerCase();
    const unsafe = {
      'diagnos': 'diagnosis',
      'treat': 'treatment',
      'prescri': 'prescription',
      'medication': 'medication_advice',
      'medicine': 'medication_advice',
      'aspirin': 'medication_advice',
      'ibuprofen': 'medication_advice',
      'paracetamol': 'medication_advice',
      'acetaminophen': 'medication_advice',
      'dosage': 'medication_advice',
      'dose ': 'medication_advice',
      'disorder': 'diagnosis',
      'causes': 'causal_claim',
      'caused by': 'causal_claim',
      'because of': 'causal_claim',
      'healthy': 'health_verdict',
      'unhealthy': 'health_verdict',
      'safe': 'safety_verdict',
      'unsafe': 'safety_verdict',
      'ignore previous': 'prompt_injection',
      'system prompt': 'prompt_leakage',
      'calendar account': 'calendar_identity',
      'calendar title': 'calendar_identity',
      'event title': 'calendar_identity',
      'email address': 'personal_identity',
      'phone number': 'personal_identity',
      'you should': 'generic_advice',
      'i recommend': 'generic_advice',
      'try to': 'generic_advice',
      'avoid ': 'generic_advice',
      'increase ': 'generic_advice',
      'decrease ': 'generic_advice',
      'seek medical': 'medical_advice',
      'see a doctor': 'medical_advice',
      'consult a doctor': 'medical_advice',
      'consult a clinician': 'medical_advice',
    };
    return [
      for (final entry in unsafe.entries)
        if (lower.contains(entry.key)) entry.value,
    ];
  }

  List<String> _hardToReadTextFailures(String text) {
    const internalTerms = [
      'evidence bundle',
      'counterevidence',
      'promoted direction',
      'evidence completeness',
      'unresolved influence',
      'association',
      'deterministic',
      'inference',
      'causality',
      'confidence interval',
      'statistically significant',
    ];
    return _containsAny(text, internalTerms)
        ? const ['technical_language']
        : const [];
  }

  List<String> _inventedNumberFailures(String text, Set<num> allowed) {
    return [
      for (final value in _numbersIn(text))
        if (!_matchesAllowedNumber(value, allowed)) 'invented_number',
    ];
  }

  List<String> _citationNumberFailures(
    String text,
    Set<num> citationNumbers,
    EvidenceGuardContext context,
  ) {
    return [
      for (final value in _numbersIn(text))
        if (_matchesAllowedNumber(value, context.allowedNumbers) &&
            !_matchesAllowedNumber(value, citationNumbers))
          'citation_number_mismatch',
    ];
  }

  Set<num> _allowedNumbersForCitations(
    Iterable<String> citations,
    EvidenceGuardContext context,
  ) => {
    for (final citation in citations)
      if (context.allowedCitations.contains(citation))
        ...(context.allowedNumbersByCitation[citation] ?? const <num>{}),
  };

  Iterable<num> _successfullyBoundNumbers(
    String text,
    Set<num> citationNumbers,
    EvidenceGuardContext context,
  ) => _numbersIn(text).where(
    (value) =>
        _matchesAllowedNumber(value, context.allowedNumbers) &&
        _matchesAllowedNumber(value, citationNumbers),
  );

  List<String> _unboundNumberFailures(
    String text,
    Set<num> boundParagraphNumbers,
    Set<num> allowedNumbers,
  ) => [
    for (final value in _numbersIn(text))
      if (_matchesAllowedNumber(value, allowedNumbers) &&
          !_matchesAllowedNumber(value, boundParagraphNumbers))
        'unbound_numeric_claim',
  ];

  Iterable<num> _numbersIn(String text) sync* {
    final numberPattern = RegExp(r'(?<![A-Za-z])[-+]?\d+(?:\.\d+)?');
    for (final match in numberPattern.allMatches(text)) {
      final raw = match.group(0)!;
      final value = num.tryParse(raw.replaceFirst('+', ''));
      if (value == null) continue;
      yield value;
    }
  }

  bool _matchesAllowedNumber(num value, Iterable<num> allowed) => allowed.any(
    (candidate) =>
        (candidate - value).abs() < math.max(0.01, value.abs() * 0.001),
  );

  bool _containsAny(String text, Iterable<String> values) {
    final lower = text.toLowerCase();
    return values.any(lower.contains);
  }
}
