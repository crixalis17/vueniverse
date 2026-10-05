import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/domain/analytics/meeting_analysis_models.dart';
import 'package:vueniverse/domain/analytics/meeting_analytics_engine.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

void main() {
  const engine = MeetingAnalyticsEngine();
  test('recovery cannot include elevated readings before a sub-minute end', () {
    final source = timeline(offset: 0, sampleOffset: 0);
    final event = source.events.single;
    final end = event.endAtUtc.add(const Duration(seconds: 30));
    final result = engine.analyze(
      MeetingAnalysisDataset(
        nowUtc: source.nowUtc,
        healthIntervals: const [],
        influences: const [],
        events: [
          AnalysisContextEvent(
            id: event.id,
            category: event.category,
            startAtUtc: event.startAtUtc,
            endAtUtc: end,
            offsetMinutes: 0,
            provenanceHash: event.provenanceHash,
            recurrenceKeyHmac: event.recurrenceKeyHmac,
          ),
        ],
        heartRate: [
          for (final row in source.heartRate)
            if (row.occurredAtUtc != event.endAtUtc) row,
          AnalysisHeartRate(
            id: 'still-meeting',
            occurredAtUtc: event.endAtUtc,
            valueBpm: 120,
            offsetMinutes: 0,
            provenanceHash: 'still-meeting',
          ),
          for (var minute = 1; minute <= 10; minute++)
            sample(
              'recovered-$minute',
              event.endAtUtc.add(Duration(minutes: minute)),
              0,
            ),
        ],
      ),
    );
    expect(result.occurrences.single.recoveryDurationMinutes, 0);
  });
  test(
    'sub-minute meeting boundaries exclude earlier samples and retain final minute',
    () {
      final start = DateTime.utc(2026, 9, 10, 10, 0, 30);
      final result = engine.analyze(
        MeetingAnalysisDataset(
          nowUtc: DateTime.utc(2026, 9, 11),
          healthIntervals: const [],
          influences: const [],
          events: [
            AnalysisContextEvent(
              id: 'seconds',
              category: ContextCategory.recurringOneToOne,
              startAtUtc: start,
              endAtUtc: start.add(const Duration(minutes: 30)),
              offsetMinutes: 0,
              provenanceHash: 'hash',
              recurrenceKeyHmac: 'series',
            ),
          ],
          heartRate: [
            for (final day in [9, 10])
              for (var minute = 0; minute <= 60; minute++)
                sample(
                  'hr-$day-$minute',
                  DateTime.utc(
                    2026,
                    9,
                    day,
                    9,
                    45,
                  ).add(Duration(minutes: minute)),
                  0,
                ),
          ],
        ),
      );
      final pre = result.occurrences.single.pre;
      expect(pre.sampleIds, isNot(contains('hr-10-0')));
      expect(pre.sampleIds, contains('hr-10-15'));
      expect(pre.completeness, 1);
    },
  );
  test('different-offset samples cannot provide event completeness', () {
    final result = engine.analyze(timeline(offset: 330, sampleOffset: 0));
    expect(result.includedCount, 0);
    expect(result.excludedByReason, {'time_offset_changed': 1});
  });
  test('DST-offset transition inside an event window is excluded', () {
    final source = timeline(offset: 60, sampleOffset: 60);
    final result = engine.analyze(
      MeetingAnalysisDataset(
        nowUtc: source.nowUtc,
        events: source.events,
        healthIntervals: const [],
        influences: const [],
        heartRate: [
          ...source.heartRate,
          sample('transition', DateTime.utc(2026, 9, 10, 10, 5), 0),
        ],
      ),
    );
    expect(result.excludedByReason, {'time_offset_changed': 1});
  });
  test(
    'inconsistent-offset control is rejected without averaging conflicting samples',
    () {
      final source = timeline(offset: 330, sampleOffset: 330);
      final result = engine.analyze(
        MeetingAnalysisDataset(
          nowUtc: source.nowUtc,
          events: source.events,
          healthIntervals: const [],
          influences: const [],
          heartRate: [
            ...source.heartRate,
            sample('conflict', DateTime.utc(2026, 9, 9, 9, 50), 0),
          ],
        ),
      );
      expect(result.excludedByReason, {'missing_control': 1});
    },
  );
  test('local-day illness at a different UTC date excludes the meeting', () {
    final source = timeline(offset: 330, sampleOffset: 330);
    final result = engine.analyze(
      MeetingAnalysisDataset(
        nowUtc: source.nowUtc,
        events: source.events,
        healthIntervals: const [],
        heartRate: source.heartRate,
        influences: [
          AnalysisInfluence(
            id: 'illness',
            category: CheckinCategory.illness,
            occurredAtUtc: DateTime.utc(2026, 9, 9, 20),
            provenanceHash: 'hash',
          ),
        ],
      ),
    );
    expect(result.excludedByReason, {'illness': 1});
  });
  test('a future-dated same-local-day report is not used at the cutoff', () {
    final source = timeline(offset: 330, sampleOffset: 330);
    final result = engine.analyze(
      MeetingAnalysisDataset(
        nowUtc: DateTime.utc(2026, 9, 10, 12),
        events: source.events,
        healthIntervals: const [],
        heartRate: source.heartRate,
        influences: [
          AnalysisInfluence(
            id: 'future',
            category: CheckinCategory.illness,
            occurredAtUtc: DateTime.utc(2026, 9, 10, 15),
            provenanceHash: 'hash',
          ),
        ],
      ),
    );
    expect(result.includedCount, 1);
  });
}

AnalysisHeartRate sample(String id, DateTime time, int offset) =>
    AnalysisHeartRate(
      id: id,
      occurredAtUtc: time,
      valueBpm: 70,
      offsetMinutes: offset,
      provenanceHash: id,
    );

MeetingAnalysisDataset timeline({
  required int offset,
  required int sampleOffset,
}) => MeetingAnalysisDataset(
  nowUtc: DateTime.utc(2026, 9, 11),
  healthIntervals: const [],
  influences: const [],
  events: [
    AnalysisContextEvent(
      id: 'meeting',
      category: ContextCategory.recurringOneToOne,
      startAtUtc: DateTime.utc(2026, 9, 10, 10),
      endAtUtc: DateTime.utc(2026, 9, 10, 10, 30),
      offsetMinutes: offset,
      provenanceHash: 'hash',
      recurrenceKeyHmac: 'series',
    ),
  ],
  heartRate: [
    for (final day in [9, 10])
      for (var minute = 0; minute < (day == 10 ? 60 : 15); minute++)
        sample(
          'hr-$day-$minute',
          DateTime.utc(2026, 9, day, 9, 45).add(Duration(minutes: minute)),
          sampleOffset,
        ),
  ],
);
