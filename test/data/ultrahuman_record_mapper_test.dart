import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/sources/ultrahuman_client.dart';
import 'package:vueniverse/data/sources/ultrahuman_record_mapper.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

void main() {
  final start = DateTime.utc(2026, 9, 1, 12);
  final epoch = start.millisecondsSinceEpoch ~/ 1000;
  final now = DateTime.utc(2026, 9, 2);
  UltrahumanDayResponse response(List<Object?> metrics) =>
      UltrahumanDayResponse(
        localDate: '2026-09-01',
        timezoneName: 'Asia/Kolkata',
        metrics: metrics,
      );
  Map<String, Object?> hr(List<Object?> rows, {String unit = 'BPM'}) => {
    'type': 'hr',
    'object': {'unit': unit, 'values': rows},
  };
  Map<String, Object?> sample(Object? value, {Object? timestamp}) => {
    'value': value,
    'timestamp': timestamp ?? epoch,
  };
  const mapper = UltrahumanRecordMapper(offsetResolver: _offset);

  test(
    'actual epoch HR maps with API zone and stable id into canonical pipeline',
    () {
      final result = mapper.mapDay(
        response([
          hr([sample(72)]),
        ]),
        observedAt: now,
      );
      expect(result.records.length, 1);
      expect(result.records.single.source, SourceKind.ultrahuman);
      expect(result.records.single.payload['offset_minutes'], 330);
      final canonical = RecordNormalizer(
        identityKey: [1, 2, 3],
      ).normalizeAll(result.records);
      expect(canonical.rejectedCount, 0);
      expect(canonical.signalSamples.single.value, 72);
      expect(canonical.signalSamples.single.occurredAtUtc, start);
      expect(canonical.signalSamples.single.originalLocalDate, '2026-09-01');
      expect(
        canonical.signalSamples.single.provenance.source,
        SourceKind.ultrahuman,
      );
      final next = mapper.mapDay(
        response([
          hr([sample(73)]),
        ]),
        observedAt: now.add(const Duration(hours: 1)),
      );
      expect(
        next.records.single.stableSourceId,
        result.records.single.stableSourceId,
      );
    },
  );
  test('missing and malformed readings are never imputed', () {
    final result = mapper.mapDay(
      response([
        hr([
          sample(null),
          sample(-1),
          sample(301),
          sample(60, timestamp: epoch * 1000),
          null,
        ]),
      ]),
      observedAt: now,
    );
    expect(result.records, isEmpty);
    expect(result.rejectedCounts.values.reduce((a, b) => a + b), 5);
  });
  test('unknown timezone, other-day and future timestamps rejected', () {
    final unknown = UltrahumanRecordMapper(offsetResolver: (_, _) => null);
    expect(
      unknown
          .mapDay(
            response([
              hr([sample(70)]),
            ]),
            observedAt: now,
          )
          .rejectedCounts['unresolved_timezone'],
      1,
    );
    final result = mapper.mapDay(
      response([
        hr([
          sample(70, timestamp: epoch - 86400),
          sample(70, timestamp: epoch + 86400),
        ]),
      ]),
      observedAt: now,
    );
    expect(result.records, isEmpty);
    expect(result.rejectedCounts['invalid_timestamp'], 1);
    expect(result.rejectedCounts['observation_outside_requested_day'], 1);
  });
  test(
    'unsupported steps/HRV summaries not relabeled or mistaken for missing HR',
    () {
      final result = mapper.mapDay(
        response([
          {
            'type': 'steps',
            'object': {
              'values': [sample(1.5)],
              'total': 100,
            },
          },
          {
            'type': 'hrv',
            'object': {
              'values': [sample(42)],
            },
          },
        ]),
        observedAt: now,
      );
      expect(result.records, isEmpty);
      expect(result.rejectedCounts, isEmpty);
      expect(result.skippedMetricTypes, {'steps', 'hrv'});
    },
  );
  test(
    'duplicates deduplicate, conflicting same-instant HR rejected rather than averaged',
    () {
      final result = mapper.mapDay(
        response([
          hr([sample(70), sample(70), sample(90), sample(70)]),
        ]),
        observedAt: now,
      );
      expect(result.records, isEmpty);
      expect(result.rejectedCounts['duplicate_observation'], isNull);
      expect(result.rejectedCounts['conflicting_observation'], 1);
      expect(result.inputObservationCount, 4);
      expect(result.duplicateObservationCount, 0);
      expect(result.rejectedObservationCount, 4);
      final duplicate = mapper.mapDay(
        response([
          hr([sample(70)]),
          hr([sample(70)]),
        ]),
        observedAt: now,
      );
      expect(duplicate.records, isEmpty);
      expect(duplicate.rejectedCounts['duplicate_metric_type'], 2);
    },
  );
  test(
    'sleep stage boundaries preserved, bedtimes not treated as actual sleep',
    () {
      final result = mapper.mapDay(
        response([
          {
            'type': 'sleep',
            'object': {
              'bedtime_start': epoch - 1000,
              'bedtime_end': epoch + 2000,
              'sleep_graph': {
                'data': [
                  {'start': epoch, 'end': epoch + 60, 'type': 'deep_sleep'},
                  {'start': epoch + 60, 'end': epoch + 120, 'type': 'awake'},
                ],
              },
            },
          },
        ]),
        observedAt: now,
      );
      final canonical = RecordNormalizer(
        identityKey: [1, 2, 3],
      ).normalizeAll(result.records);
      expect(canonical.healthIntervals.length, 2);
      expect(canonical.healthIntervals.map((i) => i.category), [
        'deep',
        'awake',
      ]);
      expect(
        canonical.healthIntervals.first.endAtUtc.difference(
          canonical.healthIntervals.first.startAtUtc,
        ),
        const Duration(minutes: 1),
      );
    },
  );
  test('overlapping stages and timezone transition fail closed', () {
    final day = response([
      {
        'type': 'sleep',
        'object': {
          'sleep_graph': {
            'data': [
              {'start': epoch, 'end': epoch + 120, 'type': 'deep_sleep'},
              {'start': epoch + 60, 'end': epoch + 180, 'type': 'light_sleep'},
            ],
          },
        },
      },
    ]);
    final result = mapper.mapDay(day, observedAt: now);
    expect(result.records, isEmpty);
    expect(result.rejectedCounts['overlapping_sleep_segments'], 2);
    final changing = UltrahumanRecordMapper(
      offsetResolver: (_, instant) => instant.isAfter(start) ? 60 : 0,
    );
    expect(
      changing
          .mapDay(day, observedAt: now)
          .rejectedCounts['sleep_offset_changed'],
      1,
    );
  });
  test('unknown HR unit and unknown sleep stage rejected, not relabeled', () {
    final result = mapper.mapDay(
      response([
        hr([sample(1)], unit: 'beats_per_second'),
        {
          'type': 'sleep',
          'object': {
            'sleep_graph': {
              'data': [
                {'start': epoch, 'end': epoch + 60, 'type': 'invented-stage'},
              ],
            },
          },
        },
      ]),
      observedAt: now,
    );
    expect(result.records, isEmpty);
    expect(result.rejectedCounts['unsupported_heart_rate_unit'], 1);
    expect(result.rejectedCounts['invalid_sleep_segment'], 1);
  });
  test(
    'raw observation counters distinguish retained duplicate rejected and unsupported rows',
    () {
      final result = mapper.mapDay(
        response([
          hr([
            sample(70),
            sample(70),
            sample(72, timestamp: epoch + 60),
            sample(null, timestamp: epoch + 120),
            null,
          ]),
          {
            'type': 'steps',
            'object': {
              'values': [sample(42)],
            },
          },
        ]),
        observedAt: now,
      );
      expect(result.inputObservationCount, 5);
      expect(result.records.length, 2);
      expect(result.duplicateObservationCount, 1);
      expect(result.rejectedObservationCount, 2);
      _expectAccounting(result);
    },
  );
  test(
    'conflicting groups reject every row irrespective of original order',
    () {
      for (final values in [
        [70, 70, 90, 70],
        [90, 70, 70, 70],
        [70, 90, 70, 70],
        [70, 70, 70, 90],
      ]) {
        final result = mapper.mapDay(
          response([hr(values.map(sample).toList())]),
          observedAt: now,
        );
        expect(result.inputObservationCount, 4);
        expect(result.rejectedObservationCount, 4);
        expect(result.duplicateObservationCount, 0);
        expect(result.records, isEmpty);
        _expectAccounting(result);
      }
      for (final values in [
        [70, null, 70],
        [null, 70, 70],
        [70, 70, null],
      ]) {
        final result = mapper.mapDay(
          response([hr(values.map(sample).toList())]),
          observedAt: now,
        );
        expect(result.rejectedObservationCount, 3);
        expect(result.duplicateObservationCount, 0);
        expect(result.records, isEmpty);
        _expectAccounting(result);
      }
    },
  );
  test(
    'metric-level failures account for all array entries without treating metadata as row',
    () {
      final wrongUnit = mapper.mapDay(
        response([hr(List.generate(100, (_) => sample(70)), unit: 'unknown')]),
        observedAt: now,
      );
      expect(wrongUnit.inputObservationCount, 100);
      expect(wrongUnit.rejectedObservationCount, 100);
      expect(wrongUnit.rejectedCounts['unsupported_heart_rate_unit'], 1);
      _expectAccounting(wrongUnit);
      final duplicateMetric = mapper.mapDay(
        response([
          hr([sample(70), sample(70)]),
          hr([sample(70)]),
        ]),
        observedAt: now,
      );
      expect(duplicateMetric.inputObservationCount, 3);
      expect(duplicateMetric.rejectedObservationCount, 3);
      _expectAccounting(duplicateMetric);
      final missing = mapper.mapDay(
        response([
          {
            'type': 'hr',
            'object': {'unit': 'BPM'},
          },
        ]),
        observedAt: now,
      );
      expect(missing.inputObservationCount, 0);
      expect(missing.rejectedObservationCount, 0);
      expect(missing.rejectedCounts['missing_observations'], 1);
      _expectAccounting(missing);
    },
  );
  test('overlap converts duplicate stages into rejected raw rows', () {
    final stage = {'start': epoch, 'end': epoch + 120, 'type': 'deep_sleep'};
    final result = mapper.mapDay(
      response([
        {
          'type': 'sleep',
          'object': {
            'sleep_graph': {
              'data': [
                stage,
                stage,
                {
                  'start': epoch + 60,
                  'end': epoch + 180,
                  'type': 'light_sleep',
                },
                {'start': epoch + 180, 'end': epoch + 240, 'type': 'awake'},
              ],
            },
          },
        },
      ]),
      observedAt: now,
    );
    expect(result.inputObservationCount, 4);
    expect(result.records.length, 1);
    expect(result.rejectedObservationCount, 3);
    expect(result.duplicateObservationCount, 0);
    _expectAccounting(result);
  });
}

void _expectAccounting(UltrahumanMappingResult result) => expect(
  result.inputObservationCount,
  result.records.length +
      result.duplicateObservationCount +
      result.rejectedObservationCount,
);

int? _offset(String zone, DateTime instant) =>
    zone == 'Asia/Kolkata' ? 330 : null;
