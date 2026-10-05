import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/model_runtime/evidence_projection_repository.dart';
import 'package:vueniverse/domain/model_runtime/output_guard.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'retained fixture DTO can be rechecked without model or owner data',
    () async {
      final report =
          jsonDecode(
                await File(
                  'experiments/readiness/first-person-local-v1/phone-lora-contract8-single-report.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      expect(report['scope']['owner_data_accessed'], isFalse);
      final attempt =
          report['records']['model_attempt'] as Map<String, dynamic>;
      final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await const DemoImportService(
        DemoFixtureLoader(RootBundleFixtureAssetReader()),
      ).importInto(database);
      await MeetingAnalysisRepository(
        database,
        clock: () => fixture.virtualNowUtc,
      ).runPending(ensureEvidence: true);
      final projection = (await EvidenceProjectionRepository(
        database,
      ).build(storeKind: StoreKind.demo, intent: 'why_promoted'))!;
      final output = ExplainerOutput(
        summary: attempt['summary'] as String,
        citedParagraphsJson: jsonEncode(attempt['paragraphs']),
        uncertainty: attempt['uncertainty'] as String,
        citedUnresolvedInfluences: (attempt['unresolved_influences'] as List)
            .cast<String>(),
        approvedNextObservation: attempt['next_observation'] as String?,
      );
      final safety = const OutputGuard().validate(
        output,
        projection.guardContext,
      );
      expect(outputGuardVersion, 7);
      expect(safety.accepted, isFalse);
      expect(safety.failures, isNot(contains('metric_role_numeric_mismatch')));
      // Existing lexical causal flag remains; it is not proof of asserted causation.
      expect(safety.failures, contains('causal_claim'));
      expect(report['manual_semantic_review']['verdict'], 'reject');
    },
  );
}
