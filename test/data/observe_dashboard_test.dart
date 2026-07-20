import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/observe/observe_dashboard_repository.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

void main() {
  test('Observe dashboard summarizes canonical Demo records', () async {
    final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final imported = await DemoImportService(
      DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
    ).importInto(database);

    final dashboard = await ObserveDashboardRepository(
      database,
    ).load(asOf: imported.virtualNowUtc, isDemo: true);

    expect(dashboard.isDemo, isTrue);
    expect(dashboard.activeDayCount, 30);
    expect(dashboard.totalRecordCount, 2990);
    expect(dashboard.heartRateRecords, 2800);
    expect(dashboard.hrvRecords, 30);
    expect(dashboard.stepRecords, 30);
    expect(dashboard.eventRecords, 30);
    expect(dashboard.checkInRecords, 30);
    expect(dashboard.sleepRecords, 30);
    expect(dashboard.workoutRecords, 10);
    expect(dashboard.activityRecords, 30);
    expect(dashboard.days.last.steps, 7800);
    expect(dashboard.days.last.sleepMinutes, 458);
    expect(dashboard.recentActivity, hasLength(6));
    expect(
      dashboard.recentActivity.every(
        (activity) => !activity.detail.contains('fictional-weekly-1to1'),
      ),
      isTrue,
    );

    await CanonicalRecordRepository(database).importRecords(
      sourceConnectionId: 'demo-future-filter-test',
      sourceKind: SourceKind.demoHealth,
      records: [
        SourceRecordEnvelope(
          source: SourceKind.demoHealth,
          recordType: 'steps',
          stableSourceId: 'demo-future-steps',
          payload: const {
            'timestamp': '2026-07-16T18:20:00Z',
            'offset_minutes': 330,
            'value': 9999,
            'unit': 'count',
          },
          observedAt: imported.virtualNowUtc,
        ),
      ],
      normalizer: RecordNormalizer(identityKey: 'future-filter'.codeUnits),
      syncRunId: 'demo-future-filter-test',
    );
    final withoutFuture = await ObserveDashboardRepository(
      database,
    ).load(asOf: imported.virtualNowUtc, isDemo: true);
    expect(withoutFuture.totalRecordCount, 2990);
    expect(withoutFuture.stepRecords, 30);
  });
}
