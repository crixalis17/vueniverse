import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/demo/demo_fixtures.dart';
import 'package:why_pulse/data/demo/demo_import_service.dart';

void main() {
  test('three fresh Demo imports produce the same canonical hash', () async {
    final importer = DemoImportService(
      DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
    );
    final hashes = <String>[];

    for (var run = 0; run < 3; run++) {
      final database = WhyPulseDatabase.forTesting(NativeDatabase.memory());
      final result = await importer.importInto(database);
      hashes.add(result.canonicalHash);

      expect(result.fixtureVersion, 1);
      expect(result.virtualNowUtc, DateTime.utc(2026, 7, 16, 12));
      expect(result.sourceReports['health']!.inserted, 185);
      expect(result.sourceReports['health']!.duplicates, 1);
      expect(result.sourceReports['health']!.changed, 1);
      expect(result.sourceReports['health']!.rejected, 2);
      expect(result.sourceReports['calendar']!.inserted, 12);
      expect(result.sourceReports['manual']!.inserted, 12);
      expect(
        await database.select(database.signalSamples).get(),
        hasLength(151),
      );
      expect(
        await database.select(database.healthIntervals).get(),
        hasLength(34),
      );
      expect(
        await database.select(database.contextEvents).get(),
        hasLength(12),
      );
      expect(
        await database.select(database.manualCheckins).get(),
        hasLength(12),
      );
      expect(
        await database.select(database.experimentProtocols).get(),
        hasLength(2),
      );
      final analysisCases = await (database.select(
        database.storeMetadata,
      )..where((row) => row.key.equals('demo_analysis_cases'))).getSingle();
      expect(analysisCases.value, contains('supported-recurring-pattern'));
      expect(analysisCases.value, contains('null-comparison'));
      expect(analysisCases.value, contains('contradictory-comparison'));
      expect(analysisCases.value, contains('missing-context-comparison'));
      expect(
        (await database.select(database.signalSamples).get()).where(
          (sample) => sample.originalOffsetMinutes == 60,
        ),
        isNotEmpty,
      );
      await database.close();
    }

    expect(hashes.toSet(), hasLength(1));
  });
}
