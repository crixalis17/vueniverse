import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/model_runtime/evidence_projection_repository.dart';
import 'package:vueniverse/data/model_runtime/explanation_repository.dart';
import 'package:vueniverse/domain/model_runtime/explanation_coordinator.dart';
import 'package:vueniverse/domain/model_runtime/explanation_runtime.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

/// Actual app prompt + Dart guard, not the shorter native microbenchmark prompt.
/// Uses only an in-memory Snapshot fixture; never erases or reads the owner's store.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'selected LoRA passes the real app contract without fallback',
    (_) async {
      final phone = PhoneMedGemmaRuntimeAdapter();
      final status = await phone.inspect();
      expect(
        status.state,
        ModelArtifactState.available,
        reason:
            'Stage and verify the selected LoRA before this supervised check',
      );
      expect(status.modelName, contains('lora-v7'));
      expect(status.modelName, contains('@lora-v7-q4-dd9c2a212672a5bb'));
      final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await const DemoImportService(
        DemoFixtureLoader(RootBundleFixtureAssetReader()),
      ).importInto(database);
      await MeetingAnalysisRepository(
        database,
        clock: () => fixture.virtualNowUtc,
      ).runPending(ensureEvidence: true);
      final coordinator = ExplanationCoordinator(
        storeKind: StoreKind.demo,
        projections: EvidenceProjectionRepository(database),
        repository: ExplanationRepository(database),
        phoneRuntime: phone,
        enableDevelopmentRuntime: false,
      );
      final failures = <String>[];
      const selectedIntent = String.fromEnvironment(
        'VUENIVERSE_CONTRACT_INTENT',
      );
      const allIntents = ['why_promoted', 'disagreement', 'observe_next'];
      expect(
        selectedIntent.isEmpty || allIntents.contains(selectedIntent),
        isTrue,
      );
      for (final intent
          in selectedIntent.isEmpty ? allIntents : [selectedIntent]) {
        final timer = Stopwatch()..start();
        final delivery = await coordinator.explain(
          intent: intent,
          preferCache: false,
        );
        timer.stop();
        final attempts = await (database.select(
          database.explanations,
        )..where((row) => row.intent.equals(intent))).get();
        // Fixture-only diagnostics: no owner store or personal source is opened.
        debugPrint(
          'VUENIVERSE_PHONE_CONTRACT ${jsonEncode({
            'intent': intent,
            'elapsed_ms': timer.elapsedMilliseconds,
            'model': status.modelName,
            'delivered': delivery != null,
            'fallback': delivery?.usedFallback,
            'cache': delivery?.fromCache,
            'summary': delivery?.explanation.output.summary,
            'uncertainty': delivery?.explanation.output.uncertainty,
            'accepted_paragraphs': delivery == null || delivery.usedFallback ? null : jsonDecode(delivery.explanation.output.citedParagraphsJson),
            'accepted_unresolved_influences': delivery == null || delivery.usedFallback ? null : delivery.explanation.output.citedUnresolvedInfluences,
            'accepted_next_observation': delivery == null || delivery.usedFallback ? null : delivery.explanation.output.approvedNextObservation,
            'fixture_evidence': delivery == null ? null : {'finding_state': delivery.projection.request.findingState, 'metrics': jsonDecode(delivery.projection.request.metricsJson), 'promotion_gates': jsonDecode(delivery.projection.request.promotionGatesJson), 'unresolved_influences': jsonDecode(delivery.projection.request.unresolvedInfluencesJson), 'approved_next_observations': delivery.projection.request.approvedNextObservations},
            'attempts': attempts.map((row) => {'runtime': row.runtime, 'safety_state': row.safetyState, 'safety_failures': jsonDecode(row.safetyFailuresJson), 'failure_code': row.failureCode, 'latency_ms': row.latencyMillis, 'schema_valid': row.schemaValid}).toList(),
          })}',
        );
        if (delivery == null) {
          failures.add('$intent: no delivered app answer');
          continue;
        }
        if (delivery.usedFallback) {
          failures.add('$intent: deterministic fallback');
        }
        if (delivery.fromCache) failures.add('$intent: cached answer');
        if (delivery.explanation.metadata.runtime !=
            InferenceRuntime.phoneMedGemma) {
          failures.add('$intent: wrong runtime');
        }
        if (delivery.explanation.metadata.modelName != status.modelName) {
          failures.add('$intent: wrong model revision');
        }
        if (delivery.explanation.output.summary.trim().isEmpty) {
          failures.add('$intent: empty summary');
        }
      }
      expect(
        failures,
        isEmpty,
        reason: 'All three real app intents must pass without fallback/cache',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
