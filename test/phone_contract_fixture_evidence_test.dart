import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/model_runtime/evidence_projection_repository.dart';
import 'package:vueniverse/domain/store_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'phone contract fixture evidence can be reviewed without model inference',
    () async {
      final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await const DemoImportService(
        DemoFixtureLoader(RootBundleFixtureAssetReader()),
      ).importInto(database);
      await MeetingAnalysisRepository(
        database,
        clock: () => fixture.virtualNowUtc,
      ).runPending(ensureEvidence: true);
      final projections = EvidenceProjectionRepository(database);
      for (final intent in ['why_promoted', 'disagreement', 'observe_next']) {
        final projection = await projections.build(
          storeKind: StoreKind.demo,
          intent: intent,
        );
        expect(projection, isNotNull);
        final request = projection!.request;
        // Host-only fixture projection: no owner database or model runtime exists.
        debugPrint(
          'VUENIVERSE_FIXTURE_EVIDENCE ${jsonEncode({'intent': intent, 'finding_state': request.findingState, 'schema_version': request.schemaVersion, 'metrics': jsonDecode(request.metricsJson), 'promotion_gates': jsonDecode(request.promotionGatesJson), 'exclusions': jsonDecode(request.exclusionsJson), 'counterevidence': jsonDecode(request.counterevidenceJson), 'unresolved_influences': jsonDecode(request.unresolvedInfluencesJson), 'approved_next_observations': request.approvedNextObservations})}',
        );
      }
    },
  );
}
