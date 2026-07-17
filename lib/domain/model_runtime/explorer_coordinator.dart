import 'package:why_pulse/domain/store_kind.dart';
import 'package:why_pulse/platform/generated/model_runtime_api.g.dart';

const explorerGuardVersion = 1;
const allowedExplorerOperations = {
  'compare_repeated_event',
  'inspect_recovery',
  'check_logged_influence',
};

final class ExplorerSelection {
  const ExplorerSelection({
    required this.decision,
    required this.runtime,
    required this.usedFallback,
    required this.rejectedFailures,
  });

  final ExplorerDecision decision;
  final InferenceRuntime runtime;
  final bool usedFallback;
  final List<String> rejectedFailures;
}

final class ExplorerGuard {
  const ExplorerGuard();

  List<String> validate(ExplorerRequest request, ModelExplorerResult result) {
    final failures = <String>[];
    final decision = result.decision;
    if (result.evidenceVersion != request.evidenceVersion ||
        decision?.evidenceVersion != request.evidenceVersion) {
      failures.add('evidence_version_mismatch');
    }
    if (!result.metadata.schemaValid) failures.add('invalid_schema');
    if (result.failure != null) failures.add(result.failure!);
    if (decision == null) {
      failures.add(result.failure ?? 'missing_decision');
      return failures.toSet().toList()..sort();
    }
    if (!request.allowedOperations.contains(decision.operation)) {
      failures.add('unknown_operation');
    }
    final categoryId = decision.categoryId;
    if (categoryId == null ||
        !request.availableCategoryIds.contains(categoryId)) {
      failures.add('unknown_category');
    }
    if (decision.influenceIds.toSet().length != decision.influenceIds.length) {
      failures.add('duplicate_influence');
    }
    if (decision.influenceIds.any(
      (id) => !request.availableInfluenceIds.contains(id),
    )) {
      failures.add('unknown_influence');
    }
    if (decision.operation == 'check_logged_influence' &&
        decision.influenceIds.length != 1) {
      failures.add('influence_required');
    }
    if (decision.operation != 'check_logged_influence' &&
        decision.influenceIds.isNotEmpty) {
      failures.add('unexpected_influence');
    }
    return failures.toSet().toList()..sort();
  }
}

final class ExplorerCoordinator {
  ExplorerCoordinator({
    required this.storeKind,
    ModelRuntimeApi? api,
    this.guard = const ExplorerGuard(),
    this.enablePhoneRuntime = true,
  }) : _api = api ?? ModelRuntimeApi();

  final StoreKind storeKind;
  final ModelRuntimeApi _api;
  final ExplorerGuard guard;
  final bool enablePhoneRuntime;

  Future<ExplorerSelection> select(ExplorerRequest request) async {
    _validateRequest(request);
    if (storeKind == StoreKind.live && enablePhoneRuntime) {
      try {
        final status = await _api.inspectRuntime();
        if (status.state == ModelArtifactState.available) {
          final result = await _api.explore(request);
          final failures = guard.validate(request, result);
          if (failures.isEmpty && result.decision != null) {
            return ExplorerSelection(
              decision: result.decision!,
              runtime: InferenceRuntime.phoneMedGemma,
              usedFallback: false,
              rejectedFailures: const [],
            );
          }
          return _deterministic(request, failures);
        }
      } on Object {
        return _deterministic(request, const ['runtime_unavailable']);
      }
    }
    return _deterministic(request, const []);
  }

  ExplorerSelection _deterministic(
    ExplorerRequest request,
    List<String> rejectedFailures,
  ) {
    final canCheckInfluence =
        request.allowedOperations.contains('check_logged_influence') &&
        request.availableInfluenceIds.isNotEmpty;
    final operation = canCheckInfluence
        ? 'check_logged_influence'
        : request.allowedOperations.contains('compare_repeated_event')
        ? 'compare_repeated_event'
        : request.allowedOperations.first;
    return ExplorerSelection(
      decision: ExplorerDecision(
        operation: operation,
        categoryId: request.availableCategoryIds.first,
        influenceIds: canCheckInfluence
            ? [request.availableInfluenceIds.first]
            : const [],
        evidenceVersion: request.evidenceVersion,
      ),
      runtime: InferenceRuntime.deterministic,
      usedFallback: true,
      rejectedFailures: List.unmodifiable(rejectedFailures),
    );
  }

  void _validateRequest(ExplorerRequest request) {
    final idPattern = RegExp(r'^[a-z][a-z0-9_]{0,63}$');
    if (request.availableCategoryIds.isEmpty ||
        request.availableCategoryIds.length > 16 ||
        request.availableCategoryIds.any((id) => !idPattern.hasMatch(id)) ||
        request.availableCategoryIds.toSet().length !=
            request.availableCategoryIds.length ||
        request.availableInfluenceIds.length > 16 ||
        request.availableInfluenceIds.any((id) => !idPattern.hasMatch(id)) ||
        request.availableInfluenceIds.toSet().length !=
            request.availableInfluenceIds.length ||
        request.allowedOperations.isEmpty ||
        request.allowedOperations.length > 3 ||
        request.allowedOperations.any(
          (operation) => !allowedExplorerOperations.contains(operation),
        ) ||
        request.allowedOperations.toSet().length !=
            request.allowedOperations.length) {
      throw ArgumentError(
        'Explorer request is outside the reviewed catalogue.',
      );
    }
  }
}
