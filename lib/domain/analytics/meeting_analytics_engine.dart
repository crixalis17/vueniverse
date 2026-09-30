import 'dart:math' as math;

import 'package:vueniverse/domain/analytics/caffeine_context_policy.dart';
import 'package:vueniverse/domain/analytics/meeting_analysis_models.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

final class MeetingAnalyticsEngine {
  const MeetingAnalyticsEngine();

  static const preEvent = Duration(minutes: 15);
  static const primaryRecovery = Duration(minutes: 15);
  static const recoveryHorizon = Duration(minutes: 60);
  static const minimumCompleteness = 0.75;
  static const caffeinePolicy = CaffeineContextPolicy();

  MeetingAnalysisResult analyze(
    MeetingAnalysisDataset dataset, {
    Set<String>? eventIds,
  }) {
    final now = dataset.nowUtc.toUtc();
    final rangeStart = now.subtract(const Duration(days: 30));
    final events =
        dataset.events
            .where(
              (event) =>
                  event.category == ContextCategory.recurringOneToOne &&
                  !event.endAtUtc.isAfter(now) &&
                  !event.startAtUtc.isBefore(rangeStart) &&
                  (eventIds == null || eventIds.contains(event.id)),
            )
            .toList()
          ..sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
    final minuteBins = _minuteBins(dataset.heartRate);
    final usedControls = <DateTime>{};
    final occurrences = <MeetingOccurrenceResult>[];

    for (final event in events) {
      final preStart = event.startAtUtc.subtract(preEvent);
      final duringEnd = event.endAtUtc;
      final primaryEnd = event.endAtUtc.add(primaryRecovery);
      final pre = _measure(minuteBins, preStart, event.startAtUtc);
      final during = _measure(minuteBins, event.startAtUtc, duringEnd);
      final recovery = _measure(minuteBins, event.endAtUtc, primaryEnd);
      final control = _findControl(
        event: event,
        // Selection limits the target occurrences, not the calendar context.
        // A control must be clear of all known events, including other categories.
        events: dataset.events,
        heartRate: dataset.heartRate,
        minuteBins: minuteBins,
        intervals: dataset.healthIntervals,
        influences: dataset.influences,
        usedControls: usedControls,
        rangeStartUtc: rangeStart,
        rangeEndUtc: now,
      );

      String? exclusion = _eventExclusion(
        event,
        pre,
        during,
        recovery,
        control?.measure,
        dataset,
      );
      final difference =
          pre.medianBpm == null || control?.measure.medianBpm == null
          ? null
          : pre.medianBpm! - control!.measure.medianBpm!;
      final dependencyIds = <String>{
        event.id,
        ...pre.sampleIds,
        ...during.sampleIds,
        ...recovery.sampleIds,
        ...?control?.measure.sampleIds,
        ..._overlappingDependencyIds(event, dataset),
        ...caffeinePolicy
            .relevant(dataset.influences, endUtc: event.startAtUtc, nowUtc: now)
            .map((item) => item.id),
        if (control != null)
          ...caffeinePolicy
              .relevant(
                dataset.influences,
                endUtc: control.endAtUtc,
                nowUtc: now,
              )
              .map((item) => item.id),
      }.toList()..sort();
      if (dependencyIds.any((id) => id.isEmpty)) {
        exclusion ??= 'missing_provenance';
      }
      occurrences.add(
        MeetingOccurrenceResult(
          event: event,
          pre: pre,
          during: during,
          recovery: recovery,
          control: control?.measure ?? _emptyMeasure(),
          controlStartUtc: control?.startAtUtc ?? preStart,
          controlEndUtc: control?.endAtUtc ?? event.startAtUtc,
          controlScore: control?.score ?? double.infinity,
          controlFactors: control?.factors ?? const {},
          dependencyIds: dependencyIds,
          differenceBpm: difference,
          recoveryDurationMinutes: _recoveryDuration(
            minuteBins,
            event.endAtUtc,
            control?.measure.medianBpm,
          ),
          exclusionReason: exclusion,
        ),
      );
      if (control != null) usedControls.add(control.startAtUtc);
    }

    final included = occurrences.where((item) => item.included).toList();
    final differences = included
        .map((item) => item.differenceBpm)
        .whereType<double>()
        .toList();
    final medianDifference = _median(differences) ?? 0;
    final directionPositive = medianDifference >= 0;
    final consistent = differences.where(
      (value) => directionPositive ? value > 0 : value < 0,
    );
    final counterevidence = differences.length - consistent.length;
    final consistency = differences.isEmpty
        ? 0.0
        : consistent.length / differences.length;
    final materialConsistent = consistent
        .where((value) => value.abs() >= 5)
        .map((value) => value.abs())
        .toList();
    final completenessValues = included
        .map(
          (item) => math.min(
            item.pre.completeness,
            math.min(item.during.completeness, item.recovery.completeness),
          ),
        )
        .toList();
    final completeness = completenessValues.isEmpty
        ? 0.0
        : completenessValues.reduce((a, b) => a + b) /
              completenessValues.length;
    final recoveryValues = included
        .map((item) => item.recoveryDurationMinutes)
        .whereType<int>()
        .map((value) => value.toDouble())
        .toList();
    final excludedByReason = <String, int>{};
    for (final item in occurrences.where((item) => !item.included)) {
      excludedByReason.update(
        item.exclusionReason!,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    var unresolved = 0;
    var caffeineUnknownPairs = 0;
    var caffeineExposurePairs = 0;
    for (final item in included) {
      final contexts = [
        caffeinePolicy.assess(
          dataset.influences,
          endUtc: item.event.startAtUtc,
          nowUtc: now,
        ),
        caffeinePolicy.assess(
          dataset.influences,
          endUtc: item.controlEndUtc,
          nowUtc: now,
        ),
      ];
      final unknown = contexts.contains(CaffeineContextState.unknown);
      final exposure = contexts.contains(CaffeineContextState.recordedExposure);
      if (unknown) caffeineUnknownPairs++;
      if (exposure) caffeineExposurePairs++;
      if (unknown || exposure) unresolved++;
    }
    final provenanceComplete = occurrences.every(
      (item) =>
          item.event.provenanceHash.isNotEmpty && item.dependencyIds.isNotEmpty,
    );
    final gates = <String, bool>{
      'four_usable_meetings': included.length >= 4,
      'four_controls':
          occurrences.where((item) => item.control.medianBpm != null).length >=
          4,
      'completeness': completeness >= minimumCompleteness,
      'consistent_direction': consistency >= 2 / 3,
      'material_difference': medianDifference.abs() >= 5,
      'caffeine_context_reported_zero': included.isNotEmpty && unresolved == 0,
      'complete_provenance': provenanceComplete,
    };
    final hasBothDirections =
        differences.any((value) => value > 0) &&
        differences.any((value) => value < 0);
    final state = _promote(
      includedCount: included.length,
      gates: gates,
      medianDifference: medianDifference,
      hasBothDirections: hasBothDirections,
      consistency: consistency,
    );
    final dependencies =
        occurrences.expand((item) => item.dependencyIds).toSet().toList()
          ..sort();

    return MeetingAnalysisResult(
      state: state,
      title: 'Recurring 1:1 and heart rate',
      claimType: 'repeated_event_heart_rate_difference',
      rangeStartUtc: rangeStart,
      rangeEndUtc: now,
      occurrences: List.unmodifiable(occurrences),
      candidateCount: events.length,
      includedCount: included.length,
      controlsCount: occurrences
          .where((item) => item.control.medianBpm != null)
          .length,
      positiveCount: differences.where((value) => value > 0).length,
      counterevidenceCount: counterevidence,
      excludedByReason: Map.unmodifiable(excludedByReason),
      medianDifferenceBpm: medianDifference,
      effectLowerBpm: materialConsistent.isEmpty
          ? 0
          : materialConsistent.reduce(math.min),
      effectUpperBpm: materialConsistent.isEmpty
          ? 0
          : materialConsistent.reduce(math.max),
      consistency: consistency,
      completeness: completeness,
      recoveryDurationMinutes: _median(recoveryValues) ?? 0,
      unresolvedInfluenceCount: unresolved,
      caffeineUnknownPairCount: caffeineUnknownPairs,
      caffeineExposurePairCount: caffeineExposurePairs,
      promotionGates: Map.unmodifiable(gates),
      dependencyIds: List.unmodifiable(dependencies),
    );
  }

  EvidenceState _promote({
    required int includedCount,
    required Map<String, bool> gates,
    required double medianDifference,
    required bool hasBothDirections,
    required double consistency,
  }) {
    if (includedCount == 0) return EvidenceState.insufficientData;
    if (includedCount < 4) {
      if (hasBothDirections) return EvidenceState.contradictory;
      if (medianDifference.abs() < 5) return EvidenceState.nullFinding;
      return includedCount >= 2
          ? EvidenceState.developing
          : EvidenceState.insufficientData;
    }
    if (medianDifference.abs() < 5) return EvidenceState.nullFinding;
    if (hasBothDirections && consistency < 2 / 3) {
      return EvidenceState.contradictory;
    }
    if (gates.values.every((passed) => passed)) {
      return EvidenceState.supported;
    }
    return EvidenceState.developing;
  }

  String? _eventExclusion(
    AnalysisContextEvent event,
    WindowMeasure pre,
    WindowMeasure during,
    WindowMeasure recovery,
    WindowMeasure? control,
    MeetingAnalysisDataset dataset,
  ) {
    if (!event.endAtUtc.isAfter(event.startAtUtc) ||
        event.endAtUtc.difference(event.startAtUtc) >
            const Duration(hours: 24)) {
      return 'invalid_event_duration';
    }
    if (event.provenanceHash.isEmpty) return 'missing_provenance';
    final preStart = event.startAtUtc.subtract(preEvent);
    final horizonEnd = event.endAtUtc.add(recoveryHorizon);
    final contextExclusion = _contextExclusion(
      preStart,
      horizonEnd,
      event.offsetMinutes,
      dataset.healthIntervals,
      dataset.influences,
      dataset.nowUtc,
    );
    if (contextExclusion != null) return contextExclusion;
    if (control?.medianBpm == null) return 'missing_control';
    if (math.min(
          pre.completeness,
          math.min(during.completeness, recovery.completeness),
        ) <
        minimumCompleteness) {
      return 'low_heart_rate_coverage';
    }
    if ([
      ...pre.sampleIds,
      ...during.sampleIds,
      ...recovery.sampleIds,
    ].isEmpty) {
      return 'missing_provenance';
    }
    return null;
  }

  // These are recorded-context exclusions, not evidence of absent confounders.
  String? _contextExclusion(
    DateTime preStart,
    DateTime horizonEnd,
    int offsetMinutes,
    List<AnalysisHealthInterval> intervals,
    List<AnalysisInfluence> influences,
    DateTime nowUtc,
  ) {
    for (final interval in intervals.where(
      (item) => item.kind == HealthIntervalKind.workout,
    )) {
      final overlaps = _overlaps(
        interval.startAtUtc,
        interval.endAtUtc,
        preStart,
        horizonEnd,
      );
      final endedBeforePre =
          !interval.endAtUtc.isAfter(preStart) &&
          !interval.endAtUtc.isBefore(
            preStart.subtract(const Duration(minutes: 30)),
          );
      if (overlaps || endedBeforePre) return 'workout_overlap';
    }
    for (final category in [
      CheckinCategory.travel,
      CheckinCategory.illness,
      CheckinCategory.exercise,
    ]) {
      for (final item in influences.where(
        (item) => item.category == category,
      )) {
        if (item.occurredAtUtc.isAfter(nowUtc)) continue;
        final local = item.occurredAtUtc.add(Duration(minutes: offsetMinutes));
        final dayStart = DateTime.utc(
          local.year,
          local.month,
          local.day,
        ).subtract(Duration(minutes: offsetMinutes));
        if (_overlaps(
          preStart,
          horizonEnd,
          dayStart,
          dayStart.add(const Duration(days: 1)),
        )) {
          return category.name;
        }
      }
    }
    return null;
  }

  _ControlCandidate? _findControl({
    required AnalysisContextEvent event,
    required List<AnalysisContextEvent> events,
    required List<AnalysisHeartRate> heartRate,
    required Map<DateTime, List<AnalysisHeartRate>> minuteBins,
    required List<AnalysisHealthInterval> intervals,
    required List<AnalysisInfluence> influences,
    required Set<DateTime> usedControls,
    required DateTime rangeStartUtc,
    required DateTime rangeEndUtc,
  }) {
    final eventLocalStart = event.startAtUtc.add(
      Duration(minutes: event.offsetMinutes),
    );
    final targetLocalPre = eventLocalStart.subtract(preEvent);
    final localDates = <DateTime>{};
    for (final sample in heartRate.where(
      (sample) => sample.offsetMinutes == event.offsetMinutes,
    )) {
      final local = sample.occurredAtUtc.add(
        Duration(minutes: sample.offsetMinutes),
      );
      localDates.add(DateTime.utc(local.year, local.month, local.day));
    }
    final eventLocalDate = DateTime.utc(
      eventLocalStart.year,
      eventLocalStart.month,
      eventLocalStart.day,
    );
    final candidates = <_ControlCandidate>[];
    for (final date in localDates) {
      if (date == eventLocalDate) continue;
      final localStart = DateTime.utc(
        date.year,
        date.month,
        date.day,
        targetLocalPre.hour,
        targetLocalPre.minute,
      );
      final start = localStart.subtract(Duration(minutes: event.offsetMinutes));
      final end = start.add(preEvent);
      if (start.isBefore(rangeStartUtc) || end.isAfter(rangeEndUtc)) continue;
      if (usedControls.contains(start)) continue;
      if (events.any(
        (other) => _overlaps(
          start,
          end,
          other.startAtUtc.subtract(preEvent),
          other.endAtUtc.add(recoveryHorizon),
        ),
      )) {
        continue;
      }
      if (_contextExclusion(
            start,
            end,
            event.offsetMinutes,
            intervals,
            influences,
            rangeEndUtc,
          ) !=
          null) {
        continue;
      }
      final measure = _measure(minuteBins, start, end);
      if (measure.completeness < minimumCompleteness) continue;
      final weekdayMismatch = date.weekday == eventLocalDate.weekday ? 0 : 1;
      final dayDistance = date.difference(eventLocalDate).inDays.abs();
      // Keep a nearby no-meeting day ahead of a distant same-weekday day.
      // This preserves the fixture's explicit matched controls and avoids
      // silently drifting a comparison weeks away when the calendar repeats.
      final score = dayDistance * 10 + weekdayMismatch.toDouble();
      candidates.add(
        _ControlCandidate(
          startAtUtc: start,
          endAtUtc: end,
          measure: measure,
          score: score,
          factors: {
            'local_start_distance_minutes': 0,
            'weekday_match': weekdayMismatch == 0,
            'calendar_day_distance': dayDistance,
            'selected_event_overlap': false,
            'workout_overlap': false,
            'recorded_context_screen_passed': true,
            'completeness': measure.completeness,
          },
        ),
      );
    }
    candidates.sort((a, b) {
      final score = a.score.compareTo(b.score);
      return score != 0 ? score : a.startAtUtc.compareTo(b.startAtUtc);
    });
    return candidates.firstOrNull;
  }

  Map<DateTime, List<AnalysisHeartRate>> _minuteBins(
    List<AnalysisHeartRate> samples,
  ) {
    final bins = <DateTime, List<AnalysisHeartRate>>{};
    for (final sample in samples) {
      final time = sample.occurredAtUtc.toUtc();
      final minute = DateTime.utc(
        time.year,
        time.month,
        time.day,
        time.hour,
        time.minute,
      );
      bins.putIfAbsent(minute, () => []).add(sample);
    }
    return bins;
  }

  WindowMeasure _measure(
    Map<DateTime, List<AnalysisHeartRate>> bins,
    DateTime startUtc,
    DateTime endUtc,
  ) {
    final expected = math.max(1, endUtc.difference(startUtc).inMinutes);
    final values = <double>[];
    final sampleIds = <String>[];
    for (var minute = 0; minute < expected; minute++) {
      final rows = bins[_minute(startUtc.add(Duration(minutes: minute)))];
      if (rows == null || rows.isEmpty) continue;
      values.add(
        rows.map((row) => row.valueBpm).reduce((a, b) => a + b) / rows.length,
      );
      sampleIds.addAll(rows.map((row) => row.id));
    }
    return WindowMeasure(
      medianBpm: _median(values),
      completeness: values.length / expected,
      sampleIds: List.unmodifiable(sampleIds),
    );
  }

  int? _recoveryDuration(
    Map<DateTime, List<AnalysisHeartRate>> bins,
    DateTime recoveryStartUtc,
    double? baseline,
  ) {
    if (baseline == null) return null;
    final tolerance = math.max(3.0, baseline.abs() * 0.05);
    for (var minute = 0; minute <= recoveryHorizon.inMinutes - 5; minute++) {
      var within = true;
      for (var offset = 0; offset < 5; offset++) {
        final rows =
            bins[_minute(
              recoveryStartUtc.add(Duration(minutes: minute + offset)),
            )];
        if (rows == null || rows.isEmpty) {
          within = false;
          break;
        }
        final value =
            rows.map((row) => row.valueBpm).reduce((a, b) => a + b) /
            rows.length;
        if ((value - baseline).abs() > tolerance) {
          within = false;
          break;
        }
      }
      if (within) return minute;
    }
    return null;
  }

  List<String> _overlappingDependencyIds(
    AnalysisContextEvent event,
    MeetingAnalysisDataset dataset,
  ) => [
    for (final interval in dataset.healthIntervals)
      if (_overlaps(
        interval.startAtUtc,
        interval.endAtUtc,
        event.startAtUtc.subtract(const Duration(hours: 1)),
        event.endAtUtc.add(recoveryHorizon),
      ))
        interval.id,
    for (final influence in dataset.influences)
      if (_sameLocalDate(
        influence.occurredAtUtc,
        event.startAtUtc,
        event.offsetMinutes,
      ))
        influence.id,
  ];

  bool _sameLocalDate(DateTime aUtc, DateTime bUtc, int offsetMinutes) {
    final a = aUtc.add(Duration(minutes: offsetMinutes));
    final b = bUtc.add(Duration(minutes: offsetMinutes));
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _overlaps(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) => aStart.isBefore(bEnd) && bStart.isBefore(aEnd);

  DateTime _minute(DateTime value) => DateTime.utc(
    value.toUtc().year,
    value.toUtc().month,
    value.toUtc().day,
    value.toUtc().hour,
    value.toUtc().minute,
  );

  WindowMeasure _emptyMeasure() =>
      const WindowMeasure(medianBpm: null, completeness: 0, sampleIds: []);

  double? _median(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

final class _ControlCandidate {
  const _ControlCandidate({
    required this.startAtUtc,
    required this.endAtUtc,
    required this.measure,
    required this.score,
    required this.factors,
  });

  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final WindowMeasure measure;
  final double score;
  final Map<String, Object?> factors;
}
