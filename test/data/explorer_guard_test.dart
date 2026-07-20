import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/domain/model_runtime/explorer_coordinator.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

void main() {
  final request = ExplorerRequest(
    schemaVersion: 'explorer-v1',
    evidenceVersion: 'evidence-v1',
    analysisVersion: 1,
    promptVersion: 1,
    eventSummariesJson: '[]',
    availableCategoryIds: const ['recurring_meeting'],
    availableInfluenceIds: const ['caffeine'],
    allowedOperations: const [
      'compare_repeated_event',
      'check_logged_influence',
    ],
  );

  test('Explorer guard accepts only an allow-listed decision', () {
    final failures = const ExplorerGuard().validate(
      request,
      ModelExplorerResult(
        evidenceVersion: 'evidence-v1',
        decision: ExplorerDecision(
          operation: 'check_logged_influence',
          categoryId: 'recurring_meeting',
          influenceIds: const ['caffeine'],
          evidenceVersion: 'evidence-v1',
        ),
        metadata: _metadata(schemaValid: true),
      ),
    );
    expect(failures, isEmpty);
  });

  test('Explorer guard rejects unknown IDs and evidence versions', () {
    final failures = const ExplorerGuard().validate(
      request,
      ModelExplorerResult(
        evidenceVersion: 'other-evidence',
        decision: ExplorerDecision(
          operation: 'arbitrary_query',
          categoryId: 'private_calendar_title',
          influenceIds: const ['medication'],
          evidenceVersion: 'other-evidence',
        ),
        metadata: _metadata(schemaValid: true),
      ),
    );
    expect(
      failures,
      containsAll([
        'evidence_version_mismatch',
        'unknown_operation',
        'unknown_category',
        'unknown_influence',
      ]),
    );
  });

  test(
    'Demo Explorer stays deterministic without contacting a model',
    () async {
      final selection = await ExplorerCoordinator(
        storeKind: StoreKind.demo,
        enablePhoneRuntime: true,
      ).select(request);
      expect(selection.runtime, InferenceRuntime.deterministic);
      expect(selection.decision.operation, 'check_logged_influence');
      expect(selection.decision.influenceIds, ['caffeine']);
    },
  );

  test(
    'Explorer rejects catalogue expansion before runtime invocation',
    () async {
      final invalid = ExplorerRequest(
        schemaVersion: request.schemaVersion,
        evidenceVersion: request.evidenceVersion,
        analysisVersion: request.analysisVersion,
        promptVersion: request.promptVersion,
        eventSummariesJson: request.eventSummariesJson,
        availableCategoryIds: const ['recurring_meeting'],
        availableInfluenceIds: const [],
        allowedOperations: const ['run_arbitrary_query'],
      );

      await expectLater(
        ExplorerCoordinator(storeKind: StoreKind.demo).select(invalid),
        throwsArgumentError,
      );
    },
  );
}

ModelRuntimeMetadata _metadata({required bool schemaValid}) =>
    ModelRuntimeMetadata(
      runtime: InferenceRuntime.phoneMedGemma,
      modelName: 'test',
      promptVersion: 1,
      outputGuardVersion: explorerGuardVersion,
      latencyMillis: 1,
      schemaValid: schemaValid,
    );
