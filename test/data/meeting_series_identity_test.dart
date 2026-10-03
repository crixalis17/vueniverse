import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/domain/analytics/meeting_analysis_models.dart';
import 'package:vueniverse/domain/analytics/meeting_analytics_engine.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

void main() {
  const engine = MeetingAnalyticsEngine();
  final events = [
    meeting(4, 'a'),
    meeting(8, 'a'),
    meeting(12, 'b'),
    meeting(16, 'b'),
  ];

  test('different recurring series cannot combine to reach four meetings', () {
    final result = engine.analyze(data(events));
    expect(result.candidateCount, 2);
    expect(result.includedCount, 2);
    expect(result.promotionGates['four_usable_meetings'], isFalse);
    expect(
      result.occurrences.map((row) => row.event.recurrenceKeyHmac).toSet(),
      {'b'},
    );
  });
  test('explicit series analyzes its own occurrences, not the category', () {
    final result = engine.analyze(data(events), recurrenceKeyHmac: 'a');
    expect(result.occurrences.map((row) => row.event.id), [
      'meeting-4',
      'meeting-8',
    ]);
    expect(
      engine.analyze(data(events), recurrenceKeyHmac: 'absent').candidateCount,
      0,
    );
  });
  test(
    'mixed explicit event selection is rejected instead of silently pooled',
    () {
      expect(
        () =>
            engine.analyze(data(events), eventIds: {'meeting-4', 'meeting-12'}),
        throwsArgumentError,
      );
      expect(
        engine
            .analyze(
              data(events),
              eventIds: {'meeting-4', 'meeting-12'},
              recurrenceKeyHmac: 'a',
            )
            .candidateCount,
        1,
      );
    },
  );
  test('largest cohort wins regardless of input order or measured effect', () {
    final rows = [...events, meeting(18, 'a')];
    for (final input in [rows, rows.reversed.toList()]) {
      final result = engine.analyze(data(input));
      expect(result.candidateCount, 3);
      expect(
        result.occurrences.every((row) => row.event.recurrenceKeyHmac == 'a'),
        isTrue,
      );
    }
  });
  test('missing identity cannot produce a repeated-pattern finding', () {
    final result = engine.analyze(
      data([
        for (final day in [4, 8, 12, 16]) meeting(day, null),
      ]),
    );
    expect(result.includedCount, 0);
    expect(result.state, EvidenceState.insufficientData);
    expect(result.excludedByReason, {'missing_recurrence_identity': 4});
  });
  test('unidentified events do not join an identified series', () {
    final result = engine.analyze(data([meeting(4, 'a'), meeting(8, null)]));
    expect(result.candidateCount, 1);
    expect(result.occurrences.single.event.id, 'meeting-4');
  });
  test('other recurring series still blocks a candidate control', () {
    final result = engine.analyze(
      data([meeting(4, 'a'), meeting(3, 'b')]),
      recurrenceKeyHmac: 'a',
    );
    expect(
      result.occurrences.single.controlStartUtc,
      isNot(DateTime.utc(2026, 9, 3, 9, 45)),
    );
  });
}

AnalysisContextEvent meeting(int day, String? key) => AnalysisContextEvent(
  id: 'meeting-$day',
  category: ContextCategory.recurringOneToOne,
  startAtUtc: DateTime.utc(2026, 9, day, 10),
  endAtUtc: DateTime.utc(2026, 9, day, 10, 30),
  offsetMinutes: 0,
  provenanceHash: 'hash-$day',
  recurrenceKeyHmac: key,
);

MeetingAnalysisDataset data(List<AnalysisContextEvent> events) =>
    MeetingAnalysisDataset(
      nowUtc: DateTime.utc(2026, 9, 20),
      events: events,
      healthIntervals: const [],
      influences: const [],
      heartRate: [
        for (var day = 1; day <= 19; day++)
          for (var minute = 0; minute < 60; minute++)
            AnalysisHeartRate(
              id: 'hr-$day-$minute',
              occurredAtUtc: DateTime.utc(
                2026,
                9,
                day,
                9,
                45,
              ).add(Duration(minutes: minute)),
              valueBpm: events.any((event) => event.startAtUtc.day == day)
                  ? 80
                  : 70,
              offsetMinutes: 0,
              provenanceHash: 'hash-$day-$minute',
            ),
      ],
    );
