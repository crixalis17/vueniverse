import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/model_runtime/evidence_projection_repository.dart';
import 'package:why_pulse/domain/model_runtime/output_guard.dart';
import 'package:why_pulse/platform/generated/model_runtime_api.g.dart';

final class PersistedExplanation {
  const PersistedExplanation({
    required this.output,
    required this.metadata,
    required this.createdAt,
  });

  final ExplainerOutput output;
  final ModelRuntimeMetadata metadata;
  final DateTime createdAt;
}

final class ExplanationRepository {
  const ExplanationRepository(this.database);

  final WhyPulseDatabase database;

  Future<PersistedExplanation?> loadAccepted(
    EvidenceProjection projection,
  ) async {
    final row =
        await (database.select(database.explanations)
              ..where(
                (row) =>
                    row.evidenceBundleId.equals(projection.evidenceBundleId) &
                    row.evidenceHash.equals(projection.evidenceHash) &
                    row.intent.equals(projection.request.askIntent) &
                    row.requestHash.equals(projection.requestHash) &
                    row.safetyState.equals('accepted') &
                    row.schemaValid.equals(true) &
                    row.outputGuardVersion.equals(outputGuardVersion),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    final output = _decodeOutput(row.content);
    if (output == null) return null;
    return PersistedExplanation(
      output: output,
      metadata: ModelRuntimeMetadata(
        runtime: _runtime(row.runtime),
        modelName: row.modelName,
        promptVersion: row.promptVersion,
        outputGuardVersion: row.outputGuardVersion,
        latencyMillis: row.latencyMillis,
        schemaValid: row.schemaValid,
      ),
      createdAt: row.createdAt,
    );
  }

  Future<void> saveAttempt({
    required EvidenceProjection projection,
    required ModelExplainerResult result,
    required SafetyResult safety,
  }) async {
    final accepted = safety.accepted && result.output != null;
    final createdAt = DateTime.now().toUtc();
    final identity = sha256.convert(
      utf8.encode(
        '${projection.requestHash}|${result.metadata.runtime.name}|${createdAt.microsecondsSinceEpoch}',
      ),
    );
    await database
        .into(database.explanations)
        .insert(
          ExplanationsCompanion.insert(
            id: identity.toString(),
            evidenceBundleId: projection.evidenceBundleId,
            evidenceHash: Value(projection.evidenceHash),
            intent: Value(projection.request.askIntent),
            requestHash: Value(projection.requestHash),
            runtime: result.metadata.runtime.name,
            modelName: Value(result.metadata.modelName),
            content: accepted ? _encodeOutput(result.output!) : '{}',
            safetyState: accepted ? 'accepted' : 'rejected',
            safetyFailuresJson: Value(jsonEncode(safety.failures)),
            failureCode: Value(
              accepted ? null : result.failure ?? safety.failures.firstOrNull,
            ),
            promptVersion: result.metadata.promptVersion,
            outputGuardVersion: outputGuardVersion,
            latencyMillis: Value(result.metadata.latencyMillis),
            schemaValid: Value(result.metadata.schemaValid),
            createdAt: Value(createdAt),
          ),
        );
  }

  Future<void> appendChatExchange({
    required EvidenceProjection projection,
    required String question,
    required PersistedExplanation explanation,
  }) async {
    final sessionId = sha256
        .convert(utf8.encode('chat|${projection.evidenceBundleId}'))
        .toString();
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      await database
          .into(database.chatSessions)
          .insertOnConflictUpdate(
            ChatSessionsCompanion.insert(
              id: sessionId,
              evidenceBundleId: projection.evidenceBundleId,
              createdAt: Value(now),
            ),
          );
      await database
          .into(database.chatMessages)
          .insert(
            ChatMessagesCompanion.insert(
              id: _messageId(sessionId, 'user', now),
              chatSessionId: sessionId,
              role: 'user',
              content: jsonEncode({'text': question}),
              safetyState: 'accepted',
              createdAt: Value(now),
            ),
          );
      await database
          .into(database.chatMessages)
          .insert(
            ChatMessagesCompanion.insert(
              id: _messageId(
                sessionId,
                'assistant',
                now.add(const Duration(microseconds: 1)),
              ),
              chatSessionId: sessionId,
              role: 'assistant',
              content: jsonEncode({
                'output': jsonDecode(_encodeOutput(explanation.output)),
                'runtime': explanation.metadata.runtime.name,
                'modelName': explanation.metadata.modelName,
              }),
              safetyState: 'accepted',
              createdAt: Value(now.add(const Duration(microseconds: 1))),
            ),
          );
    });
  }

  String _messageId(String sessionId, String role, DateTime createdAt) => sha256
      .convert(
        utf8.encode('$sessionId|$role|${createdAt.microsecondsSinceEpoch}'),
      )
      .toString();

  String _encodeOutput(ExplainerOutput output) => jsonEncode({
    'summary': output.summary,
    'citedParagraphsJson': output.citedParagraphsJson,
    'uncertainty': output.uncertainty,
    'citedUnresolvedInfluences': output.citedUnresolvedInfluences,
    'approvedNextObservation': output.approvedNextObservation,
  });

  ExplainerOutput? _decodeOutput(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      final map = {
        for (final entry in value.entries) '${entry.key}': entry.value,
      };
      final influences = map['citedUnresolvedInfluences'];
      if (map['summary'] is! String ||
          map['citedParagraphsJson'] is! String ||
          map['uncertainty'] is! String ||
          influences is! List) {
        return null;
      }
      return ExplainerOutput(
        summary: map['summary']! as String,
        citedParagraphsJson: map['citedParagraphsJson']! as String,
        uncertainty: map['uncertainty']! as String,
        citedUnresolvedInfluences: influences.cast<String>(),
        approvedNextObservation: map['approvedNextObservation'] as String?,
      );
    } on Object {
      return null;
    }
  }

  InferenceRuntime _runtime(String value) => InferenceRuntime.values.firstWhere(
    (runtime) => runtime.name == value,
    orElse: () => InferenceRuntime.deterministic,
  );
}
