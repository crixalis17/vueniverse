import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/data/analytics/meeting_analysis_repository.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/demo/demo_fixtures.dart';
import 'package:why_pulse/data/demo/demo_import_service.dart';
import 'package:why_pulse/data/model_runtime/evidence_projection_repository.dart';
import 'package:why_pulse/data/model_runtime/explanation_repository.dart';
import 'package:why_pulse/domain/model_runtime/explanation_coordinator.dart';
import 'package:why_pulse/domain/model_runtime/explanation_runtime.dart';
import 'package:why_pulse/domain/model_runtime/deterministic_explanation_runtime.dart';
import 'package:why_pulse/domain/store_kind.dart';
import 'package:why_pulse/platform/generated/model_runtime_api.g.dart';

void main() {
  test(
    'accepted explanations are reused only through the exact cache key',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);
      final coordinator = _coordinator(database);

      final first = await coordinator.explain(intent: 'why_promoted');
      final second = await coordinator.explain(intent: 'why_promoted');

      expect(first, isNotNull);
      expect(first!.fromCache, isFalse);
      expect(second, isNotNull);
      expect(second!.fromCache, isTrue);
      expect(await database.select(database.explanations).get(), hasLength(1));
    },
  );

  test(
    'rejected model prose is not stored and deterministic output replaces it',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);
      final coordinator = _coordinator(
        database,
        developmentRuntime: _UnsafeRuntime(),
        enableDevelopmentRuntime: true,
      );

      final delivery = await coordinator.explain(intent: 'why_promoted');

      expect(delivery, isNotNull);
      expect(delivery!.usedFallback, isTrue);
      expect(
        delivery.explanation.metadata.runtime,
        InferenceRuntime.deterministic,
      );
      final attempts = await database.select(database.explanations).get();
      expect(attempts, hasLength(2));
      final rejected = attempts.singleWhere(
        (attempt) => attempt.safetyState == 'rejected',
      );
      expect(rejected.content, '{}');
      expect(rejected.safetyFailuresJson, contains('diagnosis'));
      expect(
        attempts
            .singleWhere((attempt) => attempt.safetyState == 'accepted')
            .content,
        isNot('{}'),
      );
    },
  );

  test(
    'Explorer projection contains catalogue IDs and compact fields only',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);

      final request = await EvidenceProjectionRepository(
        database,
      ).buildExplorer();

      expect(request, isNotNull);
      expect(request!.availableCategoryIds, contains('recurring_one_to_one'));
      final summaries = jsonDecode(request.eventSummariesJson) as List<Object?>;
      expect(summaries, isNotEmpty);
      for (final summary in summaries.cast<Map<Object?, Object?>>()) {
        expect(summary.keys.toSet(), {
          'categoryId',
          'localDate',
          'windowState',
          'excluded',
        });
      }
      expect(request.eventSummariesJson, isNot(contains('title')));
      expect(request.eventSummariesJson, isNot(contains('detail')));
    },
  );

  test(
    'Live explanation changes from deterministic fallback to phone model without restart',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);
      final phone = _TogglePhoneRuntime();
      final coordinator = ExplanationCoordinator(
        storeKind: StoreKind.live,
        projections: EvidenceProjectionRepository(database),
        repository: ExplanationRepository(database),
        phoneRuntime: phone,
      );

      final before = await coordinator.explain(
        intent: 'why_promoted',
        preferCache: false,
      );
      phone.available = true;
      final after = await coordinator.explain(
        intent: 'why_promoted',
        preferCache: false,
      );

      expect(before, isNotNull);
      expect(before!.usedFallback, isTrue);
      expect(
        before.explanation.metadata.runtime,
        InferenceRuntime.deterministic,
      );
      expect(after, isNotNull);
      expect(after!.usedFallback, isFalse);
      expect(
        after.explanation.metadata.runtime,
        InferenceRuntime.phoneMedGemma,
      );
    },
  );

  test(
    'Demo uses verified phone MedGemma when the development runtime is off',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);
      final phone = _TogglePhoneRuntime()..available = true;
      final coordinator = ExplanationCoordinator(
        storeKind: StoreKind.demo,
        projections: EvidenceProjectionRepository(database),
        repository: ExplanationRepository(database),
        phoneRuntime: phone,
        enableDevelopmentRuntime: false,
      );
      final progress = <InferenceProgress>[];

      final delivery = await coordinator.explain(
        intent: 'why_promoted',
        preferCache: false,
        onProgress: progress.add,
      );

      expect(delivery, isNotNull);
      expect(delivery!.usedFallback, isFalse);
      expect(
        delivery.explanation.metadata.runtime,
        InferenceRuntime.phoneMedGemma,
      );
      expect(
        progress.map((item) => item.stage),
        containsAllInOrder([
          InferenceProgressStage.preparingEvidence,
          InferenceProgressStage.checkingCache,
          InferenceProgressStage.selectingRuntime,
          InferenceProgressStage.runningInference,
          InferenceProgressStage.validatingOutput,
          InferenceProgressStage.completed,
        ]),
      );
      expect(
        progress
            .singleWhere(
              (item) => item.stage == InferenceProgressStage.runningInference,
            )
            .runtime,
        InferenceRuntime.phoneMedGemma,
      );
    },
  );

  test(
    'Demo debug prefers the faster development model before phone MedGemma',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);
      final phone = _TogglePhoneRuntime()..available = true;
      final coordinator = ExplanationCoordinator(
        storeKind: StoreKind.demo,
        projections: EvidenceProjectionRepository(database),
        repository: ExplanationRepository(database),
        phoneRuntime: phone,
        developmentRuntime: _SafeDevelopmentRuntime(),
        enableDevelopmentRuntime: true,
      );
      final progress = <InferenceProgress>[];

      final delivery = await coordinator.explain(
        intent: 'why_promoted',
        preferCache: false,
        onProgress: progress.add,
      );

      expect(delivery, isNotNull);
      expect(delivery!.usedFallback, isFalse);
      expect(
        delivery.explanation.metadata.runtime,
        InferenceRuntime.developmentMachine,
      );
      expect(
        progress
            .singleWhere(
              (item) => item.stage == InferenceProgressStage.runningInference,
            )
            .runtime,
        InferenceRuntime.developmentMachine,
      );
    },
  );

  test(
    'Demo replaces a cached backup after MedGemma becomes available',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);
      final phone = _TogglePhoneRuntime();
      final coordinator = ExplanationCoordinator(
        storeKind: StoreKind.demo,
        projections: EvidenceProjectionRepository(database),
        repository: ExplanationRepository(database),
        phoneRuntime: phone,
        enableDevelopmentRuntime: false,
      );

      final before = await coordinator.explain(intent: 'why_promoted');
      phone.available = true;
      final after = await coordinator.explain(intent: 'why_promoted');

      expect(
        before!.explanation.metadata.runtime,
        InferenceRuntime.deterministic,
      );
      expect(after!.fromCache, isFalse);
      expect(after.usedFallback, isFalse);
      expect(
        after.explanation.metadata.runtime,
        InferenceRuntime.phoneMedGemma,
      );
    },
  );
}

Future<WhyPulseDatabase> _preparedDatabase() async {
  final database = WhyPulseDatabase.forTesting(NativeDatabase.memory());
  final imported = await DemoImportService(
    DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
  ).importInto(database);
  await MeetingAnalysisRepository(
    database,
    clock: () => imported.virtualNowUtc,
  ).runPending(ensureEvidence: true);
  return database;
}

ExplanationCoordinator _coordinator(
  WhyPulseDatabase database, {
  ExplanationRuntime? developmentRuntime,
  bool enableDevelopmentRuntime = false,
}) => ExplanationCoordinator(
  storeKind: StoreKind.demo,
  projections: EvidenceProjectionRepository(database),
  repository: ExplanationRepository(database),
  developmentRuntime: developmentRuntime,
  enableDevelopmentRuntime: enableDevelopmentRuntime,
);

final class _UnsafeRuntime implements ExplanationRuntime {
  @override
  InferenceRuntime get runtime => InferenceRuntime.developmentMachine;

  @override
  Future<bool> cancel() async => false;

  @override
  Future<ModelExplainerResult> explain(ExplanationInvocation invocation) async {
    return ModelExplainerResult(
      evidenceVersion: invocation.request.evidenceVersion,
      output: ExplainerOutput(
        summary: 'This diagnosis was caused by 99 bpm.',
        citedParagraphsJson:
            '[{"text":"Take medication.","citations":["finding_state"]}]',
        uncertainty: 'none',
        citedUnresolvedInfluences: const [],
      ),
      metadata: ModelRuntimeMetadata(
        runtime: runtime,
        modelName: 'unsafe-test-model',
        promptVersion: 1,
        outputGuardVersion: 0,
        latencyMillis: 1,
        schemaValid: true,
      ),
      safety: SafetyResult(accepted: true, failures: const []),
    );
  }

  @override
  Future<ModelRuntimeStatus> inspect() async => ModelRuntimeStatus(
    state: ModelArtifactState.available,
    modelName: 'unsafe-test-model',
  );
}

final class _SafeDevelopmentRuntime implements ExplanationRuntime {
  @override
  InferenceRuntime get runtime => InferenceRuntime.developmentMachine;

  @override
  Future<bool> cancel() async => false;

  @override
  Future<ModelExplainerResult> explain(ExplanationInvocation invocation) async {
    final deterministic = DeterministicExplanationRuntime().explain(
      invocation.request,
      guardContext: invocation.guardContext,
    );
    return ModelExplainerResult(
      evidenceVersion: deterministic.evidenceVersion,
      output: deterministic.output,
      metadata: ModelRuntimeMetadata(
        runtime: runtime,
        modelName: 'fixture-development-medgemma',
        promptVersion: deterministic.metadata.promptVersion,
        outputGuardVersion: deterministic.metadata.outputGuardVersion,
        latencyMillis: 1,
        schemaValid: deterministic.metadata.schemaValid,
      ),
      safety: deterministic.safety,
      failure: deterministic.failure,
    );
  }

  @override
  Future<ModelRuntimeStatus> inspect() async => ModelRuntimeStatus(
    state: ModelArtifactState.available,
    modelName: 'fixture-development-medgemma',
  );
}

final class _TogglePhoneRuntime implements ExplanationRuntime {
  bool available = false;

  @override
  InferenceRuntime get runtime => InferenceRuntime.phoneMedGemma;

  @override
  Future<bool> cancel() async => false;

  @override
  Future<ModelExplainerResult> explain(ExplanationInvocation invocation) async {
    final deterministic = DeterministicExplanationRuntime().explain(
      invocation.request,
      guardContext: invocation.guardContext,
    );
    return ModelExplainerResult(
      evidenceVersion: deterministic.evidenceVersion,
      output: deterministic.output,
      metadata: ModelRuntimeMetadata(
        runtime: runtime,
        modelName: 'fixture-phone-medgemma',
        promptVersion: deterministic.metadata.promptVersion,
        outputGuardVersion: deterministic.metadata.outputGuardVersion,
        latencyMillis: 1,
        schemaValid: deterministic.metadata.schemaValid,
      ),
      safety: deterministic.safety,
      failure: deterministic.failure,
    );
  }

  @override
  Future<ModelRuntimeStatus> inspect() async => ModelRuntimeStatus(
    state: available
        ? ModelArtifactState.available
        : ModelArtifactState.missing,
    modelName: 'fixture-phone-medgemma',
  );
}
