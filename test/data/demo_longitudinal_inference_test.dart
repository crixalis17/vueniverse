import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/model_runtime/evidence_projection_repository.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';

void main() {
  test(
    'Demo v4 provides 30 complete days for evidence and bounded inference',
    () async {
      final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final imported = await DemoImportService(
        DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
      ).importInto(database);

      expect(imported.fixtureVersion, 4);
      expect(imported.coverageDayCount, 30);
      final expectedDays = <String>[
        for (var offset = 0; offset < imported.coverageDayCount; offset++)
          _dateKey(imported.rangeStartUtc.add(Duration(days: offset))),
      ];
      expect(expectedDays.toSet(), hasLength(30));
      expect(
        expectedDays.last,
        _dateKey(imported.rangeEndUtc),
        reason: 'The declared Demo range must contain 30 consecutive days.',
      );

      final signals = await database.select(database.signalSamples).get();
      final intervals = await database.select(database.healthIntervals).get();
      final contexts = await database.select(database.contextEvents).get();
      final checkIns = await database.select(database.manualCheckins).get();

      for (final day in expectedDays) {
        final dailySignals = signals.where(
          (sample) => sample.originalLocalDate == day,
        );
        expect(
          dailySignals.where((sample) => sample.signalType == 'heartRate'),
          hasLength(greaterThanOrEqualTo(47)),
          reason: '$day should have ambient and summary heart-rate samples.',
        );
        expect(
          dailySignals.where(
            (sample) => sample.signalType == 'heartRateVariability',
          ),
          hasLength(1),
          reason: '$day should have one HRV summary.',
        );
        expect(
          dailySignals.where((sample) => sample.signalType == 'steps'),
          hasLength(1),
          reason: '$day should have one step summary.',
        );
        expect(
          intervals.where(
            (interval) =>
                interval.intervalType == 'sleep' &&
                _localDate(interval.endAtUtc, interval.originalOffsetMinutes) ==
                    day,
          ),
          hasLength(1),
          reason: '$day should have one sleep session ending that day.',
        );
        expect(
          intervals.where(
            (interval) =>
                interval.intervalType == 'activity' &&
                interval.originalLocalDate == day,
          ),
          hasLength(1),
          reason: '$day should have one activity interval.',
        );
        expect(
          contexts.where((event) => event.originalLocalDate == day),
          hasLength(1),
          reason: '$day should have one privacy-safe Calendar event.',
        );
        expect(
          checkIns.where((checkIn) => checkIn.originalLocalDate == day),
          hasLength(1),
          reason: '$day should have one manual context check-in.',
        );
      }

      expect(
        signals.every(
          (sample) => !sample.occurredAtUtc.isAfter(imported.virtualNowUtc),
        ),
        isTrue,
        reason: 'Demo signals must not leak future data into inference.',
      );
      expect(
        intervals.every(
          (interval) =>
              !interval.startAtUtc.isAfter(imported.virtualNowUtc) &&
              !interval.endAtUtc.isAfter(imported.virtualNowUtc),
        ),
        isTrue,
        reason: 'Demo health intervals must be complete by the fixture clock.',
      );
      expect(
        contexts.every(
          (event) =>
              !event.startAtUtc.isAfter(imported.virtualNowUtc) &&
              !event.endAtUtc.isAfter(imported.virtualNowUtc),
        ),
        isTrue,
        reason: 'Only past Demo context events should be canonicalized.',
      );
      expect(
        checkIns.every(
          (checkIn) => !checkIn.occurredAtUtc.isAfter(imported.virtualNowUtc),
        ),
        isTrue,
        reason: 'Demo check-ins must not be later than the fixture clock.',
      );

      expect(contexts, hasLength(30));
      expect(contexts.map((event) => event.category).toSet(), {
        ContextCategory.recurringOneToOne.name,
        ContextCategory.teamMeeting.name,
        ContextCategory.otherRecurringMeeting.name,
      });
      expect(checkIns, hasLength(30));
      expect(
        checkIns.map((checkIn) => checkIn.category).toSet(),
        CheckinCategory.values.map((category) => category.name).toSet(),
      );
      final workouts = intervals.where(
        (interval) => interval.intervalType == 'workout',
      );
      expect(workouts, hasLength(10));
      expect(workouts.map((workout) => workout.category).toSet(), {
        'walking',
        'running',
        'cycling',
        'strength',
        'yoga',
        'other',
      });

      final analysis = MeetingAnalysisRepository(
        database,
        clock: () => imported.virtualNowUtc,
      );
      final result = await analysis.evaluate();
      expect(result.state, EvidenceState.developing);
      expect(result.candidateCount, 12);
      expect(result.includedCount, 8);
      expect(result.positiveCount, 6);
      expect(result.counterevidenceCount, 2);
      expect(result.medianDifferenceBpm, closeTo(11, 0.001));
      await analysis.runPending(ensureEvidence: true);

      final projections = EvidenceProjectionRepository(database);
      final projection = await projections.build(
        storeKind: StoreKind.demo,
        intent: 'why_promoted',
      );
      expect(projection, isNotNull);
      final request = projection!.request;
      final metrics = _object(jsonDecode(request.metricsJson));
      expect(request.schemaVersion, 'explainer-v7');
      expect(request.findingState, EvidenceState.developing.name);
      expect(metrics['candidate_count'], 12);
      expect(metrics['included_count'], 8);
      expect(metrics['positive_count'], 6);
      expect(metrics['counterevidence_count'], 2);
      expect(metrics['median_difference_bpm'], 11);
      expect(metrics, hasLength(lessThanOrEqualTo(32)));
      expect(metrics.keys, everyElement(matches(RegExp(r'^[a-z][a-z0-9_]*$'))));
      final boundedProjection = [
        request.metricsJson,
        request.promotionGatesJson,
        request.exclusionsJson,
        request.counterevidenceJson,
        request.unresolvedInfluencesJson,
        ...request.approvedNextObservations,
      ].join(' ');
      for (final forbidden in [
        'demo-meeting-',
        'fictional-weekly',
        'calendar title',
        'attendee',
        'email',
      ]) {
        expect(boundedProjection.toLowerCase(), isNot(contains(forbidden)));
      }

      final explorer = await projections.buildExplorer();
      expect(explorer, isNotNull);
      expect(explorer!.availableCategoryIds, ['recurring_one_to_one']);
      expect(
        explorer.availableInfluenceIds,
        unorderedEquals(['caffeine', 'exercise', 'illness', 'travel']),
      );
      expect(
        explorer.allowedOperations,
        unorderedEquals([
          'compare_repeated_event',
          'inspect_recovery',
          'check_logged_influence',
        ]),
      );
      final eventSummaries = (jsonDecode(explorer.eventSummariesJson) as List)
          .cast<Map<String, Object?>>();
      expect(eventSummaries, hasLength(12));
      expect(
        eventSummaries.where((summary) => summary['excluded'] == true),
        hasLength(4),
      );
      for (final summary in eventSummaries) {
        expect(summary.keys.toSet(), {
          'categoryId',
          'localDate',
          'windowState',
          'excluded',
        });
        expect(summary['categoryId'], 'recurring_one_to_one');
      }
      expect(explorer.eventSummariesJson, isNot(contains('demo-meeting-')));
      expect(explorer.eventSummariesJson, isNot(contains('title')));
      expect(explorer.eventSummariesJson, isNot(contains('detail')));
    },
  );
}

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _localDate(DateTime utc, int offsetMinutes) =>
    _dateKey(utc.toUtc().add(Duration(minutes: offsetMinutes)));

Map<String, Object?> _object(Object? value) {
  if (value is! Map) throw const FormatException('Expected an object');
  return {for (final entry in value.entries) '${entry.key}': entry.value};
}
