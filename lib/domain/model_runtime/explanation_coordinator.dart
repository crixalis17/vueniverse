import 'package:why_pulse/data/model_runtime/evidence_projection_repository.dart';
import 'package:why_pulse/data/model_runtime/explanation_repository.dart';
import 'package:why_pulse/domain/model_runtime/explanation_runtime.dart';
import 'package:why_pulse/domain/model_runtime/output_guard.dart';
import 'package:why_pulse/domain/store_kind.dart';
import 'package:why_pulse/platform/generated/model_runtime_api.g.dart';

const developmentMedGemmaEnabled = bool.fromEnvironment(
  'WHYPULSE_DEVELOPMENT_MEDGEMMA',
);

final class ExplanationDelivery {
  const ExplanationDelivery({
    required this.projection,
    required this.explanation,
    required this.fromCache,
    required this.usedFallback,
  });

  final EvidenceProjection projection;
  final PersistedExplanation explanation;
  final bool fromCache;
  final bool usedFallback;
}

final class ExplanationCoordinator {
  ExplanationCoordinator({
    required this.storeKind,
    required this.projections,
    required this.repository,
    ExplanationRuntime? phoneRuntime,
    ExplanationRuntime? developmentRuntime,
    ExplanationRuntime? deterministicRuntime,
    this.guard = const OutputGuard(),
    this.enableDevelopmentRuntime = developmentMedGemmaEnabled,
    this.enablePhoneRuntime = true,
  }) : _phone = phoneRuntime ?? PhoneMedGemmaRuntimeAdapter(),
       _development =
           developmentRuntime ?? DevelopmentMachineMedGemmaRuntimeAdapter(),
       _deterministic =
           deterministicRuntime ?? DeterministicExplanationRuntimeAdapter();

  final StoreKind storeKind;
  final EvidenceProjectionRepository projections;
  final ExplanationRepository repository;
  final ExplanationRuntime _phone;
  final ExplanationRuntime _development;
  final ExplanationRuntime _deterministic;
  final OutputGuard guard;
  final bool enableDevelopmentRuntime;
  final bool enablePhoneRuntime;
  ExplanationRuntime? _activeRuntime;

  Future<ExplanationDelivery?> explain({
    required String intent,
    String? chatQuestion,
    bool preferCache = true,
  }) async {
    final projection = await projections.build(
      storeKind: storeKind,
      intent: intent,
    );
    if (projection == null) return null;
    if (preferCache) {
      final cached = await repository.loadAccepted(projection);
      if (cached != null) {
        final delivery = ExplanationDelivery(
          projection: projection,
          explanation: cached,
          fromCache: true,
          usedFallback:
              cached.metadata.runtime == InferenceRuntime.deterministic,
        );
        if (chatQuestion != null) {
          await repository.appendChatExchange(
            projection: projection,
            question: chatQuestion,
            explanation: cached,
          );
        }
        return delivery;
      }
    }

    final primary = await _selectPrimaryRuntime();
    final primaryAttempt = await _invoke(primary, projection);
    final primarySafety = guard.validateResult(
      primaryAttempt,
      projection.request,
      projection.guardContext,
    );
    final guardedPrimary = _withSafety(primaryAttempt, primarySafety);
    await repository.saveAttempt(
      projection: projection,
      result: guardedPrimary,
      safety: primarySafety,
    );
    if (primarySafety.accepted && guardedPrimary.output != null) {
      return _delivery(
        projection,
        guardedPrimary,
        usedFallback: primary.runtime == InferenceRuntime.deterministic,
        chatQuestion: chatQuestion,
      );
    }
    if (primary.runtime == InferenceRuntime.deterministic) return null;

    final fallbackAttempt = await _invoke(_deterministic, projection);
    final fallbackSafety = guard.validateResult(
      fallbackAttempt,
      projection.request,
      projection.guardContext,
    );
    final guardedFallback = _withSafety(fallbackAttempt, fallbackSafety);
    await repository.saveAttempt(
      projection: projection,
      result: guardedFallback,
      safety: fallbackSafety,
    );
    if (!fallbackSafety.accepted || guardedFallback.output == null) return null;
    return _delivery(
      projection,
      guardedFallback,
      usedFallback: true,
      chatQuestion: chatQuestion,
    );
  }

  Future<void> cancel() async {
    final active = _activeRuntime;
    if (active != null) await active.cancel();
  }

  Future<ExplanationRuntime> _selectPrimaryRuntime() async {
    if (storeKind == StoreKind.live && enablePhoneRuntime) {
      if (await _isAvailable(_phone)) return _phone;
    }
    if (storeKind == StoreKind.demo && enableDevelopmentRuntime) {
      if (await _isAvailable(_development)) return _development;
    }
    return _deterministic;
  }

  Future<bool> _isAvailable(ExplanationRuntime runtime) async {
    try {
      return (await runtime.inspect()).state == ModelArtifactState.available;
    } on Object {
      return false;
    }
  }

  Future<ModelExplainerResult> _invoke(
    ExplanationRuntime runtime,
    EvidenceProjection projection,
  ) async {
    _activeRuntime = runtime;
    try {
      return await runtime.explain(
        ExplanationInvocation(
          request: projection.request,
          guardContext: projection.guardContext,
        ),
      );
    } on Object {
      return ModelExplainerResult(
        evidenceVersion: projection.request.evidenceVersion,
        metadata: ModelRuntimeMetadata(
          runtime: runtime.runtime,
          modelName: 'unavailable',
          promptVersion: 0,
          outputGuardVersion: outputGuardVersion,
          latencyMillis: 0,
          schemaValid: false,
        ),
        safety: SafetyResult(
          accepted: false,
          failures: const ['runtime_unavailable'],
        ),
        failure: 'runtime_unavailable',
      );
    } finally {
      _activeRuntime = null;
    }
  }

  ModelExplainerResult _withSafety(
    ModelExplainerResult result,
    SafetyResult safety,
  ) => ModelExplainerResult(
    evidenceVersion: result.evidenceVersion,
    output: safety.accepted ? result.output : null,
    metadata: ModelRuntimeMetadata(
      runtime: result.metadata.runtime,
      modelName: result.metadata.modelName,
      promptVersion: result.metadata.promptVersion,
      outputGuardVersion: outputGuardVersion,
      latencyMillis: result.metadata.latencyMillis,
      schemaValid: result.metadata.schemaValid,
    ),
    safety: safety,
    failure: safety.accepted
        ? null
        : result.failure ?? safety.failures.firstOrNull,
  );

  Future<ExplanationDelivery> _delivery(
    EvidenceProjection projection,
    ModelExplainerResult result, {
    required bool usedFallback,
    required String? chatQuestion,
  }) async {
    final persisted = PersistedExplanation(
      output: result.output!,
      metadata: result.metadata,
      createdAt: DateTime.now().toUtc(),
    );
    if (chatQuestion != null) {
      await repository.appendChatExchange(
        projection: projection,
        question: chatQuestion,
        explanation: persisted,
      );
    }
    return ExplanationDelivery(
      projection: projection,
      explanation: persisted,
      fromCache: false,
      usedFallback: usedFallback,
    );
  }
}
