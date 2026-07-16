import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/demo/demo_fixtures.dart';
import 'package:why_pulse/data/demo/demo_import_service.dart';
import 'package:why_pulse/data/observe/observe_dashboard_repository.dart';

void main() {
  test('Observe dashboard summarizes canonical Demo records', () async {
    final database = WhyPulseDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final imported = await DemoImportService(
      DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
    ).importInto(database);

    final dashboard = await ObserveDashboardRepository(
      database,
    ).load(asOf: imported.virtualNowUtc, isDemo: true);

    expect(dashboard.isDemo, isTrue);
    expect(dashboard.activeDayCount, 30);
    expect(dashboard.totalRecordCount, 209);
    expect(dashboard.eventRecords, 12);
    expect(dashboard.checkInRecords, 12);
    expect(dashboard.sleepRecords, 30);
    expect(dashboard.workoutRecords, 4);
    expect(dashboard.days.last.steps, 7800);
    expect(dashboard.days.last.sleepMinutes, 458);
    expect(dashboard.recentActivity, hasLength(6));
    expect(
      dashboard.recentActivity.every(
        (activity) => !activity.detail.contains('fictional-weekly-1to1'),
      ),
      isTrue,
    );
  });
}
