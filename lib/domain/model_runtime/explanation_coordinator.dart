import 'package:flutter/foundation.dart';
import 'package:vueniverse/data/model_runtime/evidence_projection_repository.dart';
import 'package:vueniverse/data/model_runtime/explanation_repository.dart';
import 'package:vueniverse/domain/model_runtime/deterministic_explanation_runtime.dart';
import 'package:vueniverse/domain/model_runtime/explanation_runtime.dart';
import 'package:vueniverse/domain/model_runtime/output_guard.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

const developmentMedGemmaEnabled = bool.fromEnvironment(
  'VUENIVERSE_DEVELOPMENT_MEDGEMMA',
  defaultValue: kDebugMode,
);

enum InferenceProgressStage {
  preparingEvidence,
  checkingCache,
  selectingRuntime,
  runningInference,
  validatingOutput,
  usingFallback,
  completed,
}

final class InferenceProgress {
  const InferenceProgress({
    required this.stage,
    this.runtime,
    this.fromCache = false,
  });

  final InferenceProgressStage stage;
  final InferenceRuntime? runtime;
  final bool fromCache;
}

typedef InferenceProgressCallback = void Function(InferenceProgress progress);

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
    InferenceProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const InferenceProgress(stage: InferenceProgressStage.preparingEvidence),
    );
    final projection = await projections.build(
      storeKind: storeKind,
      intent: intent,
    );
    if (projection == null) return null;
    onProgress?.call(
      const InferenceProgress(stage: InferenceProgressStage.checkingCache),
    );
    if (preferCache) {
      final cached = await repository.loadAccepted(projection);
      if (cached != null &&
          guard.validate(cached.output, projection.guardContext).accepted &&
          await _cachedArtifactMatches(cached.metadata)) {
        final modelRuntimes =
            cached.metadata.runtime == InferenceRuntime.deterministic
            ? await _selectModelRuntimes(onProgress: onProgress)
            : const <ExplanationRuntime>[];
        if (modelRuntimes.isEmpty) {
          if (!await repository.isCurrent(projection)) return null;
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
          onProgress?.call(
            InferenceProgress(
              stage: InferenceProgressStage.completed,
              runtime: cached.metadata.runtime,
              fromCache: true,
            ),
          );
          return await repository.isCurrent(projection) ? delivery : null;
        }
      }
    }

    final modelRuntimes = await _selectModelRuntimes(onProgress: onProgress);
    for (final runtime in modelRuntimes) {
      onProgress?.call(
        InferenceProgress(
          stage: InferenceProgressStage.runningInference,
          runtime: runtime.runtime,
        ),
      );
      final attempt = await _invoke(runtime, projection);
      if (!await repository.isCurrent(projection)) return null;
      onProgress?.call(
        InferenceProgress(
          stage: InferenceProgressStage.validatingOutput,
          runtime: runtime.runtime,
        ),
      );
      final safety = guard.validateResult(
        attempt,
        projection.request,
        projection.guardContext,
      );
      if (kDebugMode && !safety.accepted) {
        debugPrint(
          'Vueniverse inference rejected '
          '${runtime.runtime.name}: ${safety.failures.join(', ')} '
          '(failure=${attempt.failure}, '
          'schemaValid=${attempt.metadata.schemaValid}, '
          'latencyMillis=${attempt.metadata.latencyMillis})',
        );
      }
      final guarded = _withSafety(attempt, safety);
      await repository.saveAttempt(
        projection: projection,
        result: guarded,
        safety: safety,
      );
      if (safety.accepted && guarded.output != null) {
        final delivery = await _delivery(
          projection,
          guarded,
          usedFallback: false,
          chatQuestion: chatQuestion,
        );
        onProgress?.call(
          InferenceProgress(
            stage: InferenceProgressStage.completed,
            runtime: runtime.runtime,
          ),
        );
        return delivery;
      }
    }

    onProgress?.call(
      const InferenceProgress(
        stage: InferenceProgressStage.usingFallback,
        runtime: InferenceRuntime.deterministic,
      ),
    );
    final fallbackAttempt = await _invoke(_deterministic, projection);
    if (!await repository.isCurrent(projection)) return null;
    onProgress?.call(
      const InferenceProgress(
        stage: InferenceProgressStage.validatingOutput,
        runtime: InferenceRuntime.deterministic,
      ),
    );
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
    final delivery = await _delivery(
      projection,
      guardedFallback,
      usedFallback: true,
      chatQuestion: chatQuestion,
    );
    onProgress?.call(
      const InferenceProgress(
        stage: InferenceProgressStage.completed,
        runtime: InferenceRuntime.deterministic,
      ),
    );
    return delivery;
  }

  Future<void> cancel() async {
    final active = _activeRuntime;
    if (active != null) await active.cancel();
  }

  Future<List<ExplanationRuntime>> _selectModelRuntimes({
    InferenceProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const InferenceProgress(stage: InferenceProgressStage.selectingRuntime),
    );
    final runtimes = <ExplanationRuntime>[];
    if (storeKind == StoreKind.demo &&
        enableDevelopmentRuntime &&
        await _isAvailable(_development)) {
      runtimes.add(_development);
    }
    if (enablePhoneRuntime && await _isAvailable(_phone)) {
      runtimes.add(_phone);
    }
    return runtimes;
  }

  Future<bool> _cachedArtifactMatches(ModelRuntimeMetadata metadata) async {
    // Retain prior fallback rows as history, but never replay prose generated
    // by an older deterministic template after a semantic correction.
    if (metadata.runtime == InferenceRuntime.deterministic &&
        metadata.promptVersion != deterministicExplanationPromptVersion) {
      return false;
    }
    final runtime = switch (metadata.runtime) {
      InferenceRuntime.phoneMedGemma when enablePhoneRuntime => _phone,
      InferenceRuntime.developmentMachine
          when enableDevelopmentRuntime && storeKind == StoreKind.demo =>
        _development,
      InferenceRuntime.deterministic => _deterministic,
      _ => null,
    };
    if (runtime == null) return false;
    try {
      // A matching identity does not authorize a held/unready model's cached
      // answer. Preserve its historical row, but do not serve it as current.
      final status = await runtime.inspect();
      return status.state == ModelArtifactState.available &&
          status.modelName == metadata.modelName;
    } on Object {
      return false;
    }
  }

  Future<bool> _isAvailable(ExplanationRuntime runtime) async {
    try {
      final status = await runtime.inspect();
      final available = status.state == ModelArtifactState.available;
      if (kDebugMode) {
        debugPrint(
          'Vueniverse runtime ${runtime.runtime.name}: '
          '${status.state.name}${status.detail == null ? '' : ' (${status.detail})'}',
        );
      }
      return available;
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Vueniverse runtime ${runtime.runtime.name} inspection failed: '
          '${error.runtimeType}',
        );
      }
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

  Future<ExplanationDelivery?> _delivery(
    EvidenceProjection projection,
    ModelExplainerResult result, {
    required bool usedFallback,
    required String? chatQuestion,
  }) async {
    if (!await repository.isCurrent(projection)) return null;
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
    if (!await repository.isCurrent(projection)) return null;
    return ExplanationDelivery(
      projection: projection,
      explanation: persisted,
      fromCache: false,
      usedFallback: usedFallback,
    );
  }
}
