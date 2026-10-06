import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:vueniverse/domain/model_runtime/output_guard.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

const semanticReplayInputPath =
    '/data/user/0/com.vueniverse.vueniverse/files/'
    'emulator-semantic-v1-app-projections.jsonl';
const replayFamilies = [
  'supported_negative',
  'supported_positive',
  'scarce_complete',
  'context_blocked',
  'mixed_direction',
];
const replayIntents = ['why_promoted', 'disagreement', 'observe_next'];

/// Test-only sealed synthetic input. Never opens a Live database or connector.
final class SemanticReplayCase {
  const SemanticReplayCase({
    required this.id,
    required this.family,
    required this.request,
    required this.requestWireSha256,
    required this.guardContext,
  });

  final String id;
  final String family;
  final ExplainerRequest request;
  final String requestWireSha256;
  final EvidenceGuardContext guardContext;
}

Future<List<SemanticReplayCase>> loadSemanticReplayFile(
  String path,
  String expectedSha256,
) async {
  if (path != semanticReplayInputPath ||
      await FileSystemEntity.type(path, followLinks: false) !=
          FileSystemEntityType.file) {
    throw ArgumentError(
      'Only the staged app-private synthetic fixture is allowed',
    );
  }
  final file = File(path);
  if (await file.length() > 1024 * 1024) {
    throw FormatException('Semantic fixture exceeds its bound');
  }
  return parseSemanticReplayBytes(await file.readAsBytes(), expectedSha256);
}

List<SemanticReplayCase> parseSemanticReplayBytes(
  List<int> bytes,
  String expectedSha256,
) {
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(expectedSha256) ||
      bytes.isEmpty ||
      bytes.length > 1024 * 1024 ||
      sha256.convert(bytes).toString() != expectedSha256) {
    throw FormatException('Semantic fixture SHA-256 or size mismatch');
  }
  final lines = const LineSplitter().convert(utf8.decode(bytes));
  if (lines.length != 15 || lines.any((line) => line.trim().isEmpty)) {
    throw FormatException('Exactly fifteen sealed rows are required');
  }
  final cases = <SemanticReplayCase>[];
  for (var index = 0; index < lines.length; index++) {
    final row = _object(jsonDecode(lines[index]));
    final family = replayFamilies[index ~/ 3];
    final intent = replayIntents[index % 3];
    final caseId = '${family}__$intent';
    if (row['case_id'] != caseId ||
        row['family_id'] != family ||
        row['cluster_id'] != family ||
        row['intent'] != intent ||
        row['split'] != 'inspected_development') {
      throw FormatException('Sealed case matrix or split changed');
    }
    final wire = row['request_wire_json'] as String;
    final wireHash = row['request_wire_sha256'] as String;
    if (sha256.convert(utf8.encode(wire)).toString() != wireHash) {
      throw FormatException('Request wire hash mismatch');
    }
    final requestJson = _object(jsonDecode(wire));
    const requestKeys = {
      'schemaVersion',
      'evidenceVersion',
      'findingState',
      'metricsJson',
      'promotionGatesJson',
      'exclusionsJson',
      'counterevidenceJson',
      'unresolvedInfluencesJson',
      'approvedNextObservations',
      'askIntent',
    };
    if (requestJson.length != requestKeys.length ||
        !requestKeys.every(requestJson.containsKey) ||
        jsonEncode(requestJson) != jsonEncode(row['pigeon_request']) ||
        requestJson['schemaVersion'] != 'explainer-v8' ||
        requestJson['askIntent'] != intent ||
        !RegExp(
          r'^[a-f0-9]{64}$',
        ).hasMatch(requestJson['evidenceVersion'] as String)) {
      throw FormatException('Request identity or Pigeon fields changed');
    }
    for (final key in [
      'metricsJson',
      'promotionGatesJson',
      'exclusionsJson',
      'counterevidenceJson',
      'unresolvedInfluencesJson',
    ]) {
      _object(jsonDecode(requestJson[key] as String));
    }
    final request = ExplainerRequest(
      schemaVersion: requestJson['schemaVersion'] as String,
      evidenceVersion: requestJson['evidenceVersion'] as String,
      findingState: requestJson['findingState'] as String,
      metricsJson: requestJson['metricsJson'] as String,
      promotionGatesJson: requestJson['promotionGatesJson'] as String,
      exclusionsJson: requestJson['exclusionsJson'] as String,
      counterevidenceJson: requestJson['counterevidenceJson'] as String,
      unresolvedInfluencesJson:
          requestJson['unresolvedInfluencesJson'] as String,
      approvedNextObservations:
          (requestJson['approvedNextObservations'] as List).cast<String>(),
      askIntent: intent,
    );
    final context = _object(row['guard_context']);
    if (context['liveStore'] != false ||
        context['evidenceVersion'] != request.evidenceVersion) {
      throw FormatException(
        'Only matching non-Live guard contexts are allowed',
      );
    }
    final citationNumbers = _object(context['allowedNumbersByCitation']);
    final primary = _object(context['primaryMetricValues']);
    cases.add(
      SemanticReplayCase(
        id: caseId,
        family: family,
        request: request,
        requestWireSha256: wireHash,
        guardContext: EvidenceGuardContext(
          evidenceVersion: request.evidenceVersion,
          allowedCitations: (context['allowedCitations'] as List)
              .cast<String>()
              .toSet(),
          allowedInfluenceIds: (context['allowedInfluenceIds'] as List)
              .cast<String>()
              .toSet(),
          allowedNumbers: (context['allowedNumbers'] as List)
              .cast<num>()
              .toSet(),
          allowedNumbersByCitation: {
            for (final entry in citationNumbers.entries)
              entry.key: (entry.value as List).cast<num>().toSet(),
          },
          primaryMetricValues: {
            for (final entry in primary.entries) entry.key: entry.value as num,
          },
          allowedNextObservations: (context['allowedNextObservations'] as List)
              .cast<String>()
              .toSet(),
        ),
      ),
    );
  }
  return List.unmodifiable(cases);
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('Expected a sealed JSON object');
  }
  return value;
}

Map<String, Object?> semanticResultJson(ModelExplainerResult result) => {
  'evidenceVersion': result.evidenceVersion,
  'output': result.output == null
      ? null
      : {
          'summary': result.output!.summary,
          'citedParagraphsJson': result.output!.citedParagraphsJson,
          'uncertainty': result.output!.uncertainty,
          'citedUnresolvedInfluences': result.output!.citedUnresolvedInfluences,
          'approvedNextObservation': result.output!.approvedNextObservation,
        },
  'metadata': {
    'runtime': result.metadata.runtime.name,
    'modelName': result.metadata.modelName,
    'promptVersion': result.metadata.promptVersion,
    'outputGuardVersion': result.metadata.outputGuardVersion,
    'latencyMillis': result.metadata.latencyMillis,
    'schemaValid': result.metadata.schemaValid,
  },
  'safety': semanticSafetyJson(result.safety),
  'failure': result.failure,
};

Map<String, Object?> semanticSafetyJson(SafetyResult safety) => {
  'accepted': safety.accepted,
  'failures': safety.failures,
};
