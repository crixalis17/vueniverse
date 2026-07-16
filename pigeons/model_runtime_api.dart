import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/generated/model_runtime_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/app/src/main/kotlin/com/whypulse/why_pulse/modelruntime/ModelRuntimeApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.whypulse.why_pulse.modelruntime'),
    dartPackageName: 'why_pulse',
  ),
)
enum InferenceRuntime { phoneMedGemma, developmentMachine, deterministic }

class ExplorerRequest {
  ExplorerRequest({
    required this.schemaVersion,
    required this.evidenceVersion,
    required this.analysisVersion,
    required this.promptVersion,
    required this.eventSummariesJson,
    required this.availableCategoryIds,
    required this.availableInfluenceIds,
    required this.allowedOperations,
  });

  String schemaVersion;
  String evidenceVersion;
  int analysisVersion;
  int promptVersion;
  String eventSummariesJson;
  List<String> availableCategoryIds;
  List<String> availableInfluenceIds;
  List<String> allowedOperations;
}

class ExplorerDecision {
  ExplorerDecision({
    required this.operation,
    required this.categoryId,
    required this.influenceIds,
    required this.evidenceVersion,
  });

  String operation;
  String? categoryId;
  List<String> influenceIds;
  String evidenceVersion;
}

class ExplainerRequest {
  ExplainerRequest({
    required this.schemaVersion,
    required this.evidenceVersion,
    required this.findingState,
    required this.metricsJson,
    required this.promotionGatesJson,
    required this.exclusionsJson,
    required this.counterevidenceJson,
    required this.unresolvedInfluencesJson,
    required this.approvedNextObservations,
    required this.askIntent,
  });

  String schemaVersion;
  String evidenceVersion;
  String findingState;
  String metricsJson;
  String promotionGatesJson;
  String exclusionsJson;
  String counterevidenceJson;
  String unresolvedInfluencesJson;
  List<String> approvedNextObservations;
  String askIntent;
}

class ExplainerOutput {
  ExplainerOutput({
    required this.summary,
    required this.citedParagraphsJson,
    required this.uncertainty,
    required this.citedUnresolvedInfluences,
    this.approvedNextObservation,
  });

  String summary;
  String citedParagraphsJson;
  String uncertainty;
  List<String> citedUnresolvedInfluences;
  String? approvedNextObservation;
}

class ModelRuntimeMetadata {
  ModelRuntimeMetadata({
    required this.runtime,
    required this.modelName,
    required this.promptVersion,
    required this.outputGuardVersion,
    required this.latencyMillis,
    required this.schemaValid,
  });

  InferenceRuntime runtime;
  String modelName;
  int promptVersion;
  int outputGuardVersion;
  int latencyMillis;
  bool schemaValid;
}

class ModelExplainerResult {
  ModelExplainerResult({
    required this.output,
    required this.metadata,
    required this.safety,
    this.failure,
  });

  ExplainerOutput? output;
  ModelRuntimeMetadata metadata;
  SafetyResult safety;
  String? failure;
}

class SafetyResult {
  SafetyResult({required this.accepted, required this.failures});

  bool accepted;
  List<String> failures;
}

@HostApi()
abstract class ModelRuntimeApi {
  @async
  ModelExplainerResult explain(ExplainerRequest request);
}
