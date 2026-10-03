import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/domain/analytics/caffeine_context_policy.dart';
import 'package:vueniverse/domain/analytics/meeting_analysis_models.dart';
import 'package:vueniverse/domain/analytics/meeting_analytics_engine.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

void main() {
  const policy = CaffeineContextPolicy();
  final end = DateTime.utc(2026, 9, 4, 10);
  final now = DateTime.utc(2026, 9, 20);
  CaffeineContextState assess(List<AnalysisInfluence> rows) =>
      policy.assess(rows, endUtc: end, nowUtc: now);

  test('no log, category-only log and unscoped zero remain unknown', () {
    expect(assess([]), CaffeineContextState.unknown);
    expect(assess([report(end, amount: null)]), CaffeineContextState.unknown);
    expect(assess([report(end, scoped: false)]), CaffeineContextState.unknown);
  });
  test('explicit whole-window zero is accepted as a report', () {
    expect(assess([report(end)]), CaffeineContextState.reportedZero);
  });
  test('partial coverage is insufficient', () {
    expect(assess([report(end, hours: 3)]), CaffeineContextState.unknown);
  });
  test('exposure wins over conflicting zero reports regardless of order', () {
    final zero = report(end);
    final positive = report(end, amount: 1, scoped: false);
    for (final rows in [
      [zero, positive],
      [positive, zero],
    ]) {
      expect(assess(rows), CaffeineContextState.recordedExposure);
    }
  });
  test('malformed or unprovenanced report cannot establish zero', () {
    for (final amount in [double.nan, double.infinity, -1.0, null]) {
      expect(
        assess([report(end), report(end, amount: amount)]),
        CaffeineContextState.unknown,
      );
    }
    expect(assess([report(end, provenance: '')]), CaffeineContextState.unknown);
  });
  test('future-dated and forward-looking reports cannot establish zero', () {
    expect(
      policy.assess(
        [report(end)],
        endUtc: end,
        nowUtc: end.subtract(const Duration(minutes: 1)),
      ),
      CaffeineContextState.unknown,
    );
    expect(
      assess([report(end, loggedAt: end.subtract(const Duration(minutes: 1)))]),
      CaffeineContextState.unknown,
    );
  });
  test('four-hour boundary is included, older point reports are not', () {
    expect(
      assess([
        report(
          end.subtract(const Duration(hours: 4)),
          amount: 1,
          scoped: false,
        ),
      ]),
      CaffeineContextState.recordedExposure,
    );
    expect(
      assess([
        report(
          end.subtract(const Duration(hours: 4, seconds: 1)),
          amount: 1,
          scoped: false,
        ),
      ]),
      CaffeineContextState.unknown,
    );
  });
  test('later retrospective report covers a window across midnight', () {
    final midnightEnd = DateTime.utc(2026, 9, 4, 1);
    expect(
      policy.assess(
        [
          report(
            midnightEnd,
            loggedAt: midnightEnd.add(const Duration(hours: 2)),
          ),
        ],
        endUtc: midnightEnd,
        nowUtc: now,
      ),
      CaffeineContextState.reportedZero,
    );
  });

  const engine = MeetingAnalyticsEngine();
  test(
    'supported requires explicit zero context for both sides of each pair',
    () {
      final result = engine.analyze(timeline(zeroReports()));
      expect(result.state, EvidenceState.supported);
      expect(result.includedCount, 4);
      expect(result.unresolvedInfluenceCount, 0);
      expect(result.promotionGates['caffeine_context_reported_zero'], isTrue);
      expect(
        result.promotionGates,
        isNot(contains('no_dominant_measured_alternative')),
      );
      expect(
        result.dependencyIds,
        containsAll(zeroReports().map((row) => row.id)),
      );
    },
  );
  test(
    'missing control context prevents promotion and is counted once per pair',
    () {
      final result = engine.analyze(
        timeline(
          zeroReports().where((row) => row.occurredAtUtc.day % 4 == 0).toList(),
        ),
      );
      expect(result.state, EvidenceState.developing);
      expect(result.caffeineUnknownPairCount, 4);
      expect(result.unresolvedInfluenceCount, 4);
    },
  );
  test('exposure in either event or control prevents promotion', () {
    for (final day in [3, 4]) {
      final result = engine.analyze(
        timeline([
          ...zeroReports(),
          report(DateTime.utc(2026, 9, day, 10), amount: 1, scoped: false),
        ]),
      );
      expect(result.state, EvidenceState.developing);
      expect(result.caffeineExposurePairCount, 1);
      expect(result.unresolvedInfluenceCount, 1);
    }
  });
  test(
    'unknown context does not promote a small difference or erase a null result',
    () {
      final result = engine.analyze(timeline([], eventBpm: 71));
      expect(result.state, EvidenceState.nullFinding);
      expect(result.caffeineUnknownPairCount, 4);
    },
  );
}

AnalysisInfluence report(
  DateTime end, {
  double? amount = 0,
  bool scoped = true,
  int hours = 4,
  String provenance = 'verified',
  DateTime? loggedAt,
}) => AnalysisInfluence(
  id: 'caffeine-${end.toIso8601String()}-$amount-$scoped',
  category: CheckinCategory.caffeine,
  occurredAtUtc: loggedAt ?? end,
  provenanceHash: provenance,
  caffeineServings: amount,
  coverageStartUtc: scoped ? end.subtract(Duration(hours: hours)) : null,
  coverageEndUtc: scoped ? end : null,
);

List<AnalysisInfluence> zeroReports() => [
  for (final day in [3, 4, 7, 8, 11, 12, 15, 16])
    report(DateTime.utc(2026, 9, day, 10)),
];

MeetingAnalysisDataset timeline(
  List<AnalysisInfluence> influences, {
  double eventBpm = 80,
}) => MeetingAnalysisDataset(
  nowUtc: DateTime.utc(2026, 9, 20),
  influences: influences,
  healthIntervals: const [],
  events: [
    for (final day in [4, 8, 12, 16])
      AnalysisContextEvent(
        id: 'meeting-$day',
        category: ContextCategory.recurringOneToOne,
        startAtUtc: DateTime.utc(2026, 9, day, 10),
        endAtUtc: DateTime.utc(2026, 9, day, 10, 30),
        offsetMinutes: 0,
        provenanceHash: 'meeting-hash-$day',
        recurrenceKeyHmac: 'test-series',
      ),
  ],
  heartRate: [
    for (final day in [3, 4, 7, 8, 11, 12, 15, 16])
      for (var minute = 0; minute < (day % 4 == 0 ? 60 : 15); minute++)
        AnalysisHeartRate(
          id: 'hr-$day-$minute',
          occurredAtUtc: DateTime.utc(
            2026,
            9,
            day,
            9,
            45,
          ).add(Duration(minutes: minute)),
          valueBpm: day % 4 == 0 ? eventBpm : 70,
          offsetMinutes: 0,
          provenanceHash: 'hr-hash-$day-$minute',
        ),
  ],
);
