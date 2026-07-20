import 'dart:math' as math;

import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/domain/models/app_models.dart';

/// Builds the read-only Observe dashboard from canonical, local records.
///
/// The dashboard deliberately reads the normalized tables rather than raw
/// provider payloads, so it inherits source redaction and Live/Demo isolation.
final class ObserveDashboardRepository {
  const ObserveDashboardRepository(this.database);

  final WhyPulseDatabase database;

  Future<ObserveDashboardData> load({
    required DateTime asOf,
    required bool isDemo,
  }) async {
    final rangeEnd = _dateOnly(asOf);
    final rangeStart = rangeEnd.subtract(const Duration(days: 29));
    final accumulators = <String, _DayAccumulator>{
      for (var index = 0; index < 30; index++)
        _dateKey(rangeStart.add(Duration(days: index))): _DayAccumulator(),
    };
    final recent = <ObserveActivityData>[];

    var heartRateRecords = 0;
    var hrvRecords = 0;
    var stepRecords = 0;
    var sleepRecords = 0;
    var workoutRecords = 0;
    var activityRecords = 0;
    var eventRecords = 0;
    var checkInRecords = 0;

    final signals = await database.select(database.signalSamples).get();
    for (final signal in signals) {
      if (signal.occurredAtUtc.isAfter(asOf)) continue;
      final day = _parseLocalDay(signal.originalLocalDate);
      final accumulator = day == null ? null : accumulators[_dateKey(day)];
      if (accumulator == null) continue;
      accumulator.recordCount++;
      switch (signal.signalType) {
        case 'heartRate':
          heartRateRecords++;
          accumulator.heartRates.add(signal.value);
        case 'heartRateVariability':
          hrvRecords++;
        case 'steps':
          stepRecords++;
          accumulator.steps += signal.value;
          recent.add(
            ObserveActivityData(
              kind: ObserveActivityKind.steps,
              title: 'Daily steps',
              detail: '${signal.value.round()} steps recorded',
              occurredAt: signal.occurredAtUtc,
            ),
          );
      }
    }

    final intervals = await database.select(database.healthIntervals).get();
    for (final interval in intervals) {
      if (interval.endAtUtc.isAfter(asOf)) continue;
      final day = interval.intervalType == 'sleep'
          ? _dateOnly(
              interval.endAtUtc.add(
                Duration(minutes: interval.originalOffsetMinutes),
              ),
            )
          : _parseLocalDay(interval.originalLocalDate);
      final accumulator = day == null ? null : accumulators[_dateKey(day)];
      if (accumulator == null) continue;
      accumulator.recordCount++;
      final minutes = math.max(
        0,
        interval.endAtUtc.difference(interval.startAtUtc).inMinutes,
      );
      switch (interval.intervalType) {
        case 'sleep':
          sleepRecords++;
          accumulator.sleepMinutes += minutes;
          recent.add(
            ObserveActivityData(
              kind: ObserveActivityKind.sleep,
              title: 'Sleep session',
              detail: '${_decimalHours(minutes)} h recorded',
              occurredAt: interval.endAtUtc,
            ),
          );
        case 'workout':
          workoutRecords++;
          recent.add(
            ObserveActivityData(
              kind: ObserveActivityKind.workout,
              title: 'Workout',
              detail: '${_sentenceCase(interval.category)} · $minutes min',
              occurredAt: interval.startAtUtc,
            ),
          );
        case 'activity':
          activityRecords++;
      }
    }

    final events = await database.select(database.contextEvents).get();
    for (final event in events) {
      final day = _parseLocalDay(event.originalLocalDate);
      final accumulator = day == null ? null : accumulators[_dateKey(day)];
      if (accumulator == null || event.startAtUtc.isAfter(asOf)) continue;
      eventRecords++;
      accumulator.eventCount++;
      accumulator.recordCount++;
      recent.add(
        ObserveActivityData(
          kind: ObserveActivityKind.calendar,
          title: _eventLabel(event.category),
          detail:
              '${event.endAtUtc.difference(event.startAtUtc).inMinutes} min · identity removed',
          occurredAt: event.startAtUtc,
        ),
      );
    }

    final checkIns = await database.select(database.manualCheckins).get();
    for (final checkIn in checkIns) {
      final day = _parseLocalDay(checkIn.originalLocalDate);
      final accumulator = day == null ? null : accumulators[_dateKey(day)];
      if (accumulator == null || checkIn.occurredAtUtc.isAfter(asOf)) continue;
      checkInRecords++;
      accumulator.checkInCount++;
      accumulator.recordCount++;
      recent.add(
        ObserveActivityData(
          kind: ObserveActivityKind.checkIn,
          title: '${_sentenceCase(checkIn.category)} check-in',
          detail: 'User-entered context',
          occurredAt: checkIn.occurredAtUtc,
        ),
      );
    }

    recent.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final days = <ObserveDayData>[
      for (var index = 0; index < 30; index++)
        () {
          final day = rangeStart.add(Duration(days: index));
          final accumulator = accumulators[_dateKey(day)]!;
          return ObserveDayData(
            day: day,
            heartRateMedianBpm: _median(accumulator.heartRates),
            sleepMinutes: accumulator.sleepMinutes == 0
                ? null
                : accumulator.sleepMinutes,
            steps: accumulator.steps == 0 ? null : accumulator.steps,
            eventCount: accumulator.eventCount,
            checkInCount: accumulator.checkInCount,
            recordCount: accumulator.recordCount,
          );
        }(),
    ];

    return ObserveDashboardData(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      asOf: asOf,
      isDemo: isDemo,
      days: List.unmodifiable(days),
      recentActivity: List.unmodifiable(recent.take(6)),
      heartRateRecords: heartRateRecords,
      hrvRecords: hrvRecords,
      stepRecords: stepRecords,
      sleepRecords: sleepRecords,
      workoutRecords: workoutRecords,
      activityRecords: activityRecords,
      eventRecords: eventRecords,
      checkInRecords: checkInRecords,
    );
  }
}

final class _DayAccumulator {
  final List<double> heartRates = [];
  double sleepMinutes = 0;
  double steps = 0;
  int eventCount = 0;
  int checkInCount = 0;
  int recordCount = 0;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime? _parseLocalDay(String value) {
  final parsed = DateTime.tryParse(value);
  return parsed == null ? null : _dateOnly(parsed);
}

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle];
  return (sorted[middle - 1] + sorted[middle]) / 2;
}

String _decimalHours(int minutes) =>
    (minutes / 60).toStringAsFixed(minutes % 60 == 0 ? 0 : 1);

String _sentenceCase(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  if (spaced.isEmpty) return spaced;
  return '${spaced[0].toUpperCase()}${spaced.substring(1).toLowerCase()}';
}

String _eventLabel(String category) => switch (category) {
  'recurringOneToOne' => 'Recurring 1:1',
  'teamMeeting' => 'Team meeting',
  _ => 'Recurring event',
};
