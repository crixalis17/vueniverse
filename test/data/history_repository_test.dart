import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/experiments/experiment_repository.dart';
import 'package:vueniverse/data/history/history_repository.dart';
import 'package:vueniverse/domain/store_kind.dart';

void main() {
  test(
    'production history repository exposes every imported Demo lifecycle',
    () async {
      final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
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
          'developing',
          'Strengthened',
          'Inconclusive',
          'Developing',
          'Null finding',
          'Mixed',
          'Needs data',
          'Expired',
          'Weakened',
        }),
      );
      expect(history, hasLength(9));
      expect(history.where((item) => item.status == 'Illustrative'), isEmpty);
      expect(
        history.singleWhere((item) => item.status == 'Strengthened').subtitle,
        'Recovery was 9 minutes faster across 3 eligible meetings',
      );
      expect(
        history
            .singleWhere((item) => item.status == 'Strengthened')
            .analysisLabel,
        'Seeded Snapshot experiment result',
      );
      expect(
        history.singleWhere((item) => item.status == 'Inconclusive').subtitle,
        '1 eligible completion · 1 skipped change · 1 low coverage',
      );
      expect(
        history
            .singleWhere((item) => item.id == 'null-small-difference')
            .status,
        'Null finding',
      );
      expect(
        history
            .singleWhere((item) => item.id == 'contradictory-mixed-direction')
            .status,
        'Mixed',
      );
      expect(
        history.singleWhere((item) => item.status == 'Expired').invalidated,
        isTrue,
      );
      expect(
        history.singleWhere((item) => item.status == 'Expired').analysisLabel,
        'Seeded Snapshot lifecycle receipt',
      );
    },
  );

  test('Live history contains no Demo fixture lifecycle rows', () async {
    final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.initialize(kind: StoreKind.live);

    final history = await HistoryRepository(
      database,
      kind: StoreKind.live,
      experiments: ExperimentRepository(database),
    ).load();
    expect(history, isEmpty);
  });

  test('calculated Demo history reflects travel-context deletion', () async {
    final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final imported = await DemoImportService(
      DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
    ).importInto(database);
    await MeetingAnalysisRepository(
      database,
      clock: () => imported.virtualNowUtc,
    ).runPending(ensureEvidence: true);
    final repository = HistoryRepository(
      database,
      kind: StoreKind.demo,
      experiments: ExperimentRepository(database),
    );

    final before = (await repository.load()).singleWhere(
      (item) => item.id == 'insufficient-travel-confounded',
    );
    expect(before.status, 'Needs data');
    expect(before.subtitle, contains('0 usable'));
    expect(before.subtitle, contains('1 excluded'));

    await (database.delete(
      database.manualCheckins,
    )..where((row) => row.category.equals('travel'))).go();

    final after = (await repository.load()).singleWhere(
      (item) => item.id == 'insufficient-travel-confounded',
    );
    expect(after.status, 'Needs data');
    expect(after.subtitle, isNot(before.subtitle));
    expect(after.subtitle, contains('1 usable'));
    expect(after.subtitle, contains('usual difference +9 bpm'));
    expect(after.subtitle, isNot(contains('excluded')));
  });
}
