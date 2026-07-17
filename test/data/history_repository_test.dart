import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/data/analytics/meeting_analysis_repository.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/demo/demo_fixtures.dart';
import 'package:why_pulse/data/demo/demo_import_service.dart';
import 'package:why_pulse/data/experiments/experiment_repository.dart';
import 'package:why_pulse/data/history/history_repository.dart';
import 'package:why_pulse/domain/store_kind.dart';

void main() {
  test(
    'production history repository exposes every imported Demo lifecycle',
    () async {
      final database = WhyPulseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final imported = await DemoImportService(
        DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
      ).importInto(database);
      await MeetingAnalysisRepository(
        database,
        clock: () => imported.virtualNowUtc,
      ).runPending(ensureEvidence: true);

      final history = await HistoryRepository(
        database,
        kind: StoreKind.demo,
        experiments: ExperimentRepository(database),
      ).load();
      final statuses = history.map((item) => item.status).toSet();
      expect(
        statuses,
        containsAll({
          'supported',
          'Strengthened',
          'Inconclusive',
          'Developing',
          'Null finding',
          'Weakened',
          'Expired',
        }),
      );
      expect(
        history.singleWhere((item) => item.status == 'Expired').invalidated,
        isTrue,
      );
    },
  );

  test('Live history contains no Demo fixture lifecycle rows', () async {
    final database = WhyPulseDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.initialize(kind: StoreKind.live);

    final history = await HistoryRepository(
      database,
      kind: StoreKind.live,
      experiments: ExperimentRepository(database),
    ).load();
    expect(history, isEmpty);
  });
}
