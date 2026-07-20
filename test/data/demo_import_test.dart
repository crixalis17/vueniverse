import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/demo/demo_fixtures.dart';
import 'package:why_pulse/data/demo/demo_import_service.dart';
import 'package:why_pulse/data/experiments/experiment_repository.dart';
import 'package:why_pulse/data/normalization/record_normalizer.dart';
import 'package:why_pulse/data/repositories/canonical_record_repository.dart';
import 'package:why_pulse/data/sources/manual_checkin_repository.dart';
import 'package:why_pulse/domain/models/experiment_models.dart';

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

      expect(result.fixtureVersion, 4);
      expect(result.virtualNowUtc, DateTime.utc(2026, 7, 16, 18));
      expect(result.rangeStartUtc, DateTime.utc(2026, 6, 17));
      expect(result.rangeEndUtc, DateTime.utc(2026, 7, 16, 23, 59, 59));
      expect(result.coverageDayCount, 30);
      expect(result.sourceReports['health']!.inserted, 2930);
      expect(result.sourceReports['health']!.duplicates, 1);
      expect(result.sourceReports['health']!.changed, 1);
      expect(result.sourceReports['health']!.rejected, 2);
      expect(result.sourceReports['calendar']!.inserted, 30);
      expect(result.sourceReports['manual']!.inserted, 30);
      expect(
        await database.select(database.signalSamples).get(),
        hasLength(2860),
      );
      expect(
        await database.select(database.healthIntervals).get(),
        hasLength(70),
      );
      expect(
        (await database.select(database.healthIntervals).get()).where(
          (interval) => interval.intervalType == 'activity',
        ),
        hasLength(30),
      );
      expect(
        await database.select(database.contextEvents).get(),
        hasLength(30),
      );
      expect(
        await database.select(database.manualCheckins).get(),
        hasLength(30),
      );
      expect(
        await database.select(database.experimentProtocols).get(),
        hasLength(2),
      );
      final restored = await importer.restoreFrom(database);
      expect(restored, isNotNull);
      expect(restored!.fixtureVersion, 4);
      expect(restored.virtualNowUtc, result.virtualNowUtc);
      expect(restored.rangeStartUtc, result.rangeStartUtc);
      expect(restored.rangeEndUtc, result.rangeEndUtc);
      expect(restored.coverageDayCount, 30);
      expect(restored.canonicalHash, result.canonicalHash);
      expect(restored.sourceReports['health']!.inserted, 2930);
      expect(restored.sourceReports['calendar']!.inserted, 30);
      expect(restored.sourceReports['manual']!.inserted, 30);

      final checkIns = await ManualCheckinRepository(
        database: database,
        canonicalRecords: CanonicalRecordRepository(database),
        normalizer: RecordNormalizer(
          identityKey: 'demo-checkin-test-key'.codeUnits,
        ),
      ).load();
      expect(checkIns, hasLength(30));
      expect(checkIns.first.id, 'demo-daily-checkin-18');
      expect(checkIns.first.detail, 'Demo day felt steady');
      expect(
        checkIns
            .singleWhere((item) => item.id == 'demo-checkin-12')
            .customLabel,
        'Late meal',
      );

      final meetingProfiles = await (database.select(
        database.storeMetadata,
      )..where((row) => row.key.equals('demo_meeting_profiles'))).getSingle();
      expect(meetingProfiles.value, contains('demo-meeting-01'));
      expect(meetingProfiles.value, contains('event_start_utc'));
      final analysisCases = await (database.select(
        database.storeMetadata,
      )..where((row) => row.key.equals('demo_analysis_cases'))).getSingle();
      expect(analysisCases.value, contains('supported-recurring-pattern'));
      expect(analysisCases.value, contains('null-small-difference'));
      expect(analysisCases.value, contains('contradictory-mixed-direction'));
      expect(analysisCases.value, contains('developing-early-repeat'));
      expect(analysisCases.value, contains('insufficient-travel-confounded'));
      expect(analysisCases.value, contains('expired-travel-recovery'));
      for (final status in [
        'Supported',
        'Developing',
        'Null finding',
        'Mixed',
        'Needs data',
        'Expired',
        'Illustrative',
      ]) {
        expect(analysisCases.value, contains(status));
      }
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

  test(
    'Demo import persists completed strengthened and inconclusive experiments',
    () async {
      final database = WhyPulseDatabase.forTesting(NativeDatabase.memory());
      final importer = DemoImportService(
        DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
      );

      final firstImport = await importer.importInto(database);
      final secondImport = await importer.importInto(database);

      expect(secondImport.canonicalHash, firstImport.canonicalHash);
      final protocols = await database
          .select(database.experimentProtocols)
          .get();
      expect(protocols, hasLength(2));
      expect(protocols.map((item) => item.id).toSet(), {
        'demo-experiment-strengthened',
        'demo-experiment-inconclusive',
      });
      expect(protocols.every((item) => item.status == 'completed'), isTrue);
      for (final protocol in protocols) {
        final definition = jsonDecode(protocol.protocolJson) as Map;
        expect(definition['finding_version_id'], isEmpty);
        expect(
          definition['expected_outcome'],
          anyOf('strengthened', 'inconclusive'),
        );
      }

      final restoredProtocols = await ExperimentRepository(
        database,
      ).loadProtocols();
      expect(restoredProtocols, hasLength(2));
      expect(
        restoredProtocols.every(
          (item) =>
              item.findingVersionId.isEmpty &&
              item.status == ExperimentProtocolStatus.completed &&
              item.occurrences.length == 3,
        ),
        isTrue,
      );

      final occurrences = await database
          .select(database.experimentOccurrences)
          .get();
      expect(occurrences, hasLength(6));
      expect(occurrences.every((item) => item.completedAtUtc != null), isTrue);
      final strengthenedOccurrences = occurrences
          .where(
            (item) =>
                item.experimentProtocolId == 'demo-experiment-strengthened',
          )
          .toList();
      expect(strengthenedOccurrences, hasLength(3));
      expect(
        strengthenedOccurrences.every((item) => item.status == 'adhered'),
        isTrue,
      );
      final inconclusiveOccurrences = occurrences
          .where(
            (item) =>
                item.experimentProtocolId == 'demo-experiment-inconclusive',
          )
          .toList();
      expect(inconclusiveOccurrences, hasLength(3));
      expect(inconclusiveOccurrences.map((item) => item.status).toSet(), {
        'adhered',
        'skipped',
        'ineligible',
      });
      final eligibleInconclusive = inconclusiveOccurrences.singleWhere(
        (item) => item.status == 'adhered',
      );
      expect(
        (jsonDecode(eligibleInconclusive.contextJson) as Map)['event_id'],
        'demo-meeting-11',
      );
      expect(
        (jsonDecode(eligibleInconclusive.contextJson)
            as Map)['observed_recovery_minutes'],
        38,
      );
      expect(
        inconclusiveOccurrences.where((item) {
          final context = jsonDecode(item.contextJson) as Map;
          return context['event_id'] == 'demo-meeting-08' &&
              context['eligible'] == true;
        }),
        isEmpty,
      );
      final skippedChange = inconclusiveOccurrences.singleWhere(
        (item) => item.status == 'skipped',
      );
      final skippedContext = jsonDecode(skippedChange.contextJson) as Map;
      expect(skippedContext['event_id'], 'demo-meeting-12');
      expect(skippedContext['meeting_occurred'], isTrue);
      expect(skippedContext['exclusion_reason'], 'intervention_not_completed');

      final checkins = await database.select(database.adherenceCheckins).get();
      expect(checkins, hasLength(4));
      expect(
        checkins
            .where(
              (item) => item.experimentOccurrenceId.startsWith(
                'demo-experiment-strengthened-',
              ),
            )
            .length,
        3,
      );
      expect(
        checkins.every(
          (item) => (jsonDecode(item.responseJson) as Map)['adhered'] == true,
        ),
        isTrue,
      );

      final results = await database.select(database.experimentResults).get();
      expect(results, hasLength(2));
      final strengthened = results.singleWhere(
        (item) => item.experimentProtocolId == 'demo-experiment-strengthened',
      );
      expect(strengthened.outcome, 'strengthened');
      expect(strengthened.analysisVersion, 1);
      expect(strengthened.evidenceHash, hasLength(64));
      expect(strengthened.invalidatedAt, isNull);
      final strengthenedDetails = jsonDecode(strengthened.resultJson) as Map;
      expect(strengthenedDetails['eligible_occurrences'], 3);
      expect(strengthenedDetails['adhered_occurrences'], 3);
      expect(strengthenedDetails['recovery_change_minutes'], -9);
      expect(strengthenedDetails['interpretation'], 'personal_observation');

      final inconclusive = results.singleWhere(
        (item) => item.experimentProtocolId == 'demo-experiment-inconclusive',
      );
      expect(inconclusive.outcome, 'inconclusive');
      expect(inconclusive.analysisVersion, 1);
      expect(inconclusive.evidenceHash, hasLength(64));
      expect(inconclusive.invalidatedAt, isNull);
      final inconclusiveDetails = jsonDecode(inconclusive.resultJson) as Map;
      expect(inconclusiveDetails['eligible_occurrences'], 1);
      expect(inconclusiveDetails['skipped_occurrences'], 1);
      expect(inconclusiveDetails['low_coverage_occurrences'], 1);
      expect(inconclusiveDetails['promotion_blocked'], isTrue);
      expect(
        inconclusiveDetails['reason'],
        'insufficient_eligible_occurrences',
      );

      await database.close();
    },
  );
}
