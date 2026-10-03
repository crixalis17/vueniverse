import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/demo/demo_scenario_analysis_repository.dart';
import 'package:vueniverse/data/demo/demo_ui_content.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

void main() {
  test('every calculated Demo scenario produces its declared output', () async {
    final database = await _preparedDatabase();
    addTearDown(database.close);

    final scenarios = await DemoScenarioAnalysisRepository(
      database,
    ).loadValidated();
    final calculated = scenarios.where((scenario) => scenario.isCalculated);

    expect(calculated, hasLength(5));
    expect(
      {
        for (final scenario in calculated)
          scenario.spec.id: scenario.result!.state,
      },
      {
        'supported-recurring-pattern': EvidenceState.developing,
        'null-small-difference': EvidenceState.nullFinding,
        'contradictory-mixed-direction': EvidenceState.contradictory,
        'developing-early-repeat': EvidenceState.developing,
        'insufficient-travel-confounded': EvidenceState.insufficientData,
      },
    );

    final primary = calculated.singleWhere(
      (scenario) => scenario.spec.id == 'supported-recurring-pattern',
    );
    expect(primary.result!.candidateCount, 12);
    expect(primary.result!.includedCount, 8);
    expect(primary.result!.positiveCount, 6);
    expect(primary.result!.counterevidenceCount, 2);
    expect(primary.result!.medianDifferenceBpm, 11);

    expect(
      scenarios.where(
        (scenario) => scenario.spec.kind == DemoScenarioKind.lifecycle,
      ),
      hasLength(2),
    );
    expect(
      scenarios.where(
        (scenario) => scenario.spec.kind == DemoScenarioKind.illustrative,
      ),
      hasLength(7),
    );
    expect(
      scenarios.where((scenario) => !scenario.spec.isCalculated),
      everyElement(
        isA<DemoScenarioEvaluation>().having(
          (scenario) => scenario.result,
          'result',
          isNull,
        ),
      ),
    );
  });

  test(
    'UI calculation labels match the executable scenario contract',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);
      final contract = await DemoScenarioAnalysisRepository(
        database,
      ).loadValidated();

      final contractCalculated = contract
          .where((scenario) => scenario.isCalculated)
          .map((scenario) => scenario.spec.id);
      final uiCalculated = demoScenarios
          .where((scenario) => scenario.usesCalculatedEvidence)
          .map((scenario) => scenario.id);
      expect(uiCalculated, unorderedEquals(contractCalculated));
      expect(
        demoScenarios.map((scenario) => scenario.id).toSet(),
        hasLength(16),
      );

      for (final scenario in demoScenarios) {
        expect(scenario.videoGuidance, isNotEmpty, reason: scenario.id);
        expect(scenario.sourceDisclosure, isNotEmpty, reason: scenario.id);
        switch (scenario.kind) {
          case DemoScenarioKind.calculated:
            expect(
              scenario.sourceDisclosure,
              contains('Fixture-calculated'),
              reason: scenario.id,
            );
          case DemoScenarioKind.illustrative:
            expect(scenario.badge, 'ILLUSTRATIVE', reason: scenario.id);
            expect(
              scenario.sourceDisclosure,
              contains('not calculated'),
              reason: scenario.id,
            );
          case DemoScenarioKind.lifecycle:
            expect(scenario.badge, 'LIFECYCLE', reason: scenario.id);
            expect(
              scenario.sourceDisclosure,
              contains('not recalculated'),
              reason: scenario.id,
            );
          case DemoScenarioKind.experiment:
            expect(scenario.badge, 'SNAPSHOT TEST', reason: scenario.id);
            expect(
              scenario.sourceDisclosure,
              contains('Seeded completed Snapshot experiment'),
              reason: scenario.id,
            );
        }
      }
    },
  );

  test('illustrative metadata cannot declare a calculation engine', () async {
    final database = await _preparedDatabase();
    addTearDown(database.close);
    final metadata = await (database.select(
      database.storeMetadata,
    )..where((row) => row.key.equals('demo_analysis_cases'))).getSingle();
    final cases = (jsonDecode(metadata.value) as List<Object?>)
        .cast<Map<String, Object?>>();
    final illustrative = cases.firstWhere(
      (item) => item['kind'] == 'illustrative',
    );
    illustrative['engine'] = demoMeetingHeartRateEngine;
    await (database.update(database.storeMetadata)
          ..where((row) => row.key.equals('demo_analysis_cases')))
        .write(StoreMetadataCompanion(value: Value(jsonEncode(cases))));

    await expectLater(
      DemoScenarioAnalysisRepository(database).loadValidated(),
      throwsA(isA<DemoScenarioContractException>()),
    );
  });

  test(
    'current scenario evaluation tolerates normal Demo context edits',
    () async {
      final database = await _preparedDatabase();
      addTearDown(database.close);
      await (database.delete(
        database.manualCheckins,
      )..where((row) => row.category.equals('travel'))).go();

      await expectLater(
        DemoScenarioAnalysisRepository(database).loadValidated(),
        throwsA(isA<DemoScenarioContractException>()),
      );
      final current = await DemoScenarioAnalysisRepository(
        database,
      ).loadCurrent();
      expect(
        current
            .singleWhere(
              (scenario) =>
                  scenario.spec.id == 'insufficient-travel-confounded',
            )
            .result,
        isNotNull,
      );
    },
  );
}

Future<VueniverseDatabase> _preparedDatabase() async {
  final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
  await DemoImportService(
    DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
  ).importInto(database);
  return database;
}
