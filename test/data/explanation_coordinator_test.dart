import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/model_runtime/evidence_projection_repository.dart';
import 'package:vueniverse/data/model_runtime/explanation_repository.dart';
import 'package:vueniverse/domain/model_runtime/explanation_coordinator.dart';
import 'package:vueniverse/domain/model_runtime/explanation_runtime.dart';
import 'package:vueniverse/domain/model_runtime/deterministic_explanation_runtime.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

void main() {
  test(
    'developing evidence approves context collection, not a personal intervention',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);
      final projection = (await EvidenceProjectionRepository(
        database,
      ).build(storeKind: StoreKind.demo, intent: 'observe_next'))!;
      expect(projection.request.findingState, 'developing');
      expect(
        projection.request.approvedNextObservations.any(
          (text) => text.contains('quiet buffer'),
        ),
        isFalse,
      );
    },
  );
  test('artifact switches cannot reuse the previous model answer', () async {
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
    final first = (await coordinator.explain(intent: 'why_promoted'))!;
    expect(first.explanation.metadata.modelName, 'fixture-phone-medgemma');
    phone.modelName = 'selected-lora@revision';
    final next = (await coordinator.explain(intent: 'why_promoted'))!;
    expect(next.fromCache, isFalse);
    expect(next.explanation.metadata.modelName, 'selected-lora@revision');
    expect(await database.select(database.explanations).get(), hasLength(2));
    expect(
      (await coordinator.explain(intent: 'why_promoted'))!.fromCache,
      isTrue,
    );
  });
  test(
    'held candidate cannot bypass readiness through an accepted cache',
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
      final first = (await coordinator.explain(intent: 'why_promoted'))!;
      expect(first.usedFallback, isFalse);
      phone.contractVerified = false;
      final held = (await coordinator.explain(intent: 'why_promoted'))!;
      expect(held.usedFallback, isTrue);
      expect(held.fromCache, isFalse);
      expect(phone.explainCalls, 1);
      final rows = await database.select(database.explanations).get();
      expect(rows, hasLength(2));
      expect(
        rows.any(
          (row) =>
              row.runtime == 'phoneMedGemma' && row.safetyState == 'accepted',
        ),
        isTrue,
      );
      final next = (await coordinator.explain(intent: 'why_promoted'))!;
      expect(next.usedFallback, isTrue);
      expect(next.fromCache, isTrue);
      expect(phone.explainCalls, 1);
    },
  );
  test(
    'source changes during inference suppress the obsolete response',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);
      final coordinator = ExplanationCoordinator(
        storeKind: StoreKind.demo,
        projections: EvidenceProjectionRepository(database),
        repository: ExplanationRepository(database),
        deterministicRuntime: _ChangingEvidenceRuntime(database),
        enablePhoneRuntime: false,
        enableDevelopmentRuntime: false,
      );
      expect(await coordinator.explain(intent: 'why_promoted'), isNull);
      expect(await database.select(database.explanations).get(), isEmpty);
    },
  );
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
    'evidence projection binds metric values and bounds to citations',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);

      final projection = await EvidenceProjectionRepository(
        database,
      ).build(storeKind: StoreKind.demo, intent: 'why_promoted');

      expect(projection, isNotNull);
      expect(projection!.request.schemaVersion, 'explainer-v7');
      final bindings = projection.guardContext.allowedNumbersByCitation;
      expect(bindings['median_difference_bpm'], {8, 11, 14});
      expect(bindings['candidate_count'], {12});
      expect(bindings['included_count'], {8});
      expect(bindings['median_difference_bpm'], isNot(contains(12)));
      expect(bindings['completeness'], contains(100));
      expect(
        projection.guardContext.allowedNumbers,
        containsAll(bindings.values.expand((values) => values).toSet()),
      );
      expect(
        projection.guardContext.allowedInfluenceIds,
        containsAll({'caffeine_timing', 'recent_exercise', 'unusual_stress'}),
      );
      expect(
        projection.request.approvedNextObservations.first,
        contains('Log caffeine intake'),
      );
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

Future<VueniverseDatabase> _preparedDatabase() async {
  final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
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
  VueniverseDatabase database, {
  ExplanationRuntime? developmentRuntime,
  bool enableDevelopmentRuntime = false,
}) => ExplanationCoordinator(
  storeKind: StoreKind.demo,
  projections: EvidenceProjectionRepository(database),
  repository: ExplanationRepository(database),
  developmentRuntime: developmentRuntime,
  enableDevelopmentRuntime: enableDevelopmentRuntime,
);

final class _ChangingEvidenceRuntime implements ExplanationRuntime {
  _ChangingEvidenceRuntime(this.database);
  final VueniverseDatabase database;
  @override
  InferenceRuntime get runtime => InferenceRuntime.deterministic;
  @override
  Future<bool> cancel() async => true;
  @override
  Future<ModelRuntimeStatus> inspect() async => ModelRuntimeStatus(
    state: ModelArtifactState.available,
    modelName: 'changing-test',
  );
  @override
  Future<ModelExplainerResult> explain(ExplanationInvocation invocation) async {
    final output = DeterministicExplanationRuntime().explain(
      invocation.request,
      guardContext: invocation.guardContext,
    );
    await database
        .update(database.evidenceBundles)
        .write(const EvidenceBundlesCompanion(status: Value('stale')));
    return output;
  }
}

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
  bool contractVerified = true;
  int explainCalls = 0;
  String modelName = 'fixture-phone-medgemma';

  @override
  InferenceRuntime get runtime => InferenceRuntime.phoneMedGemma;

  @override
  Future<bool> cancel() async => false;

  @override
  Future<ModelExplainerResult> explain(ExplanationInvocation invocation) async {
    explainCalls += 1;
    final deterministic = DeterministicExplanationRuntime().explain(
      invocation.request,
      guardContext: invocation.guardContext,
    );
    return ModelExplainerResult(
      evidenceVersion: deterministic.evidenceVersion,
      output: deterministic.output,
      metadata: ModelRuntimeMetadata(
        runtime: runtime,
        modelName: modelName,
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
        ? (contractVerified
              ? ModelArtifactState.available
              : ModelArtifactState.contractUnverified)
        : ModelArtifactState.missing,
    modelName: modelName,
  );
}
