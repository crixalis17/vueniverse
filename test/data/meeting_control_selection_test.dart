import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/domain/analytics/meeting_analysis_models.dart';
import 'package:vueniverse/domain/analytics/meeting_analytics_engine.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

void main() {
  const engine = MeetingAnalyticsEngine();
  for (final category in [
    CheckinCategory.illness,
    CheckinCategory.travel,
    CheckinCategory.exercise,
  ]) {
    for (final day in [9, 10]) {
      test('${category.name} screens event and control day $day', () {
        final result = engine.analyze(
          contextDataset(
            influences: [
              AnalysisInfluence(
                id: 'context',
                category: category,
                occurredAtUtc: DateTime.utc(2026, 9, day, 8),
                provenanceHash: 'hash',
              ),
            ],
          ),
        );
        if (day == 9) {
          expect(
            result.occurrences.single.controlStartUtc,
            DateTime.utc(2026, 9, 7, 9, 45),
          );
        } else {
          expect(result.occurrences.single.exclusionReason, category.name);
        }
      });
    }
  }
  for (final minutesBefore in [0, 30, 31]) {
    test('control workout recovery boundary $minutesBefore minutes', () {
      final end = DateTime.utc(
        2026,
        9,
        9,
        9,
        45,
      ).subtract(Duration(minutes: minutesBefore));
      final result = engine.analyze(
        contextDataset(
          intervals: [
            AnalysisHealthInterval(
              id: 'workout',
              kind: HealthIntervalKind.workout,
              startAtUtc: end.subtract(const Duration(minutes: 20)),
              endAtUtc: end,
              provenanceHash: 'hash',
            ),
          ],
        ),
      );
      expect(
        result.occurrences.single.controlStartUtc,
        DateTime.utc(2026, 9, minutesBefore <= 30 ? 7 : 9, 9, 45),
      );
    });
  }
  for (final category in ContextCategory.values) {
    test('control excludes unselected ${category.name} events', () {
      final result = engine.analyze(
        dataset(category: category, cleanControl: true),
        eventIds: {'target'},
      );
      expect(result.candidateCount, 1);
      final occurrence = result.occurrences.single;
      expect(occurrence.controlStartUtc, DateTime.utc(2026, 9, 7, 9, 45));
      expect(occurrence.control.medianBpm, 70);
      expect(occurrence.differenceBpm, 10);
    });
  }

  test('all contaminated controls produce insufficient evidence', () {
    final result = engine.analyze(
      dataset(category: ContextCategory.teamMeeting, cleanControl: false),
      eventIds: {'target'},
    );
    expect(result.state, EvidenceState.insufficientData);
    expect(result.controlsCount, 0);
    expect(result.occurrences.single.exclusionReason, 'missing_control');
  });

  test(
    'adjacent event outside the recovery window does not block a control',
    () {
      final source = dataset(
        category: ContextCategory.teamMeeting,
        cleanControl: false,
      );
      final result = engine.analyze(
        MeetingAnalysisDataset(
          nowUtc: source.nowUtc,
          heartRate: source.heartRate,
          events: [
            source.events.first,
            event('earlier', 9, ContextCategory.teamMeeting, hour: 8),
          ],
          healthIntervals: const [],
          influences: const [],
        ),
        eventIds: {'target'},
      );
      expect(result.controlsCount, 1);
      expect(
        result.occurrences.single.controlStartUtc,
        DateTime.utc(2026, 9, 9, 9, 45),
      );
    },
  );
}

MeetingAnalysisDataset contextDataset({
  List<AnalysisInfluence> influences = const [],
  List<AnalysisHealthInterval> intervals = const [],
}) => MeetingAnalysisDataset(
  nowUtc: DateTime.utc(2026, 9, 11),
  events: [event('target', 10, ContextCategory.recurringOneToOne)],
  heartRate: [
    ...samples(10, 80, 60),
    ...samples(9, 100, 15),
    ...samples(7, 70, 15),
  ],
  healthIntervals: intervals,
  influences: influences,
);

AnalysisContextEvent event(
  String id,
  int day,
  ContextCategory category, {
  int hour = 10,
}) => AnalysisContextEvent(
  id: id,
  category: category,
  startAtUtc: DateTime.utc(2026, 9, day, hour),
  endAtUtc: DateTime.utc(2026, 9, day, hour, 30),
  offsetMinutes: 0,
  provenanceHash: 'provenance-$id',
);

MeetingAnalysisDataset dataset({
  required ContextCategory category,
  required bool cleanControl,
}) => MeetingAnalysisDataset(
  nowUtc: DateTime.utc(2026, 9, 11),
  events: [
    event('target', 10, ContextCategory.recurringOneToOne),
    event('other', 9, category),
  ],
  heartRate: [
    ...samples(10, 80, 60),
    ...samples(9, 100, 15),
    if (cleanControl) ...samples(7, 70, 15),
  ],
  healthIntervals: const [],
  influences: const [],
);

List<AnalysisHeartRate> samples(int day, double bpm, int minutes) => [
  for (var minute = 0; minute < minutes; minute++)
    AnalysisHeartRate(
      id: 'hr-$day-$minute',
      occurredAtUtc: DateTime.utc(
        2026,
        9,
        day,
        9,
        45,
      ).add(Duration(minutes: minute)),
      valueBpm: bpm,
      offsetMinutes: 0,
      provenanceHash: 'hr-provenance-$day-$minute',
    ),
];
