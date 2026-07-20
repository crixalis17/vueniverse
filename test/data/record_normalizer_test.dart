import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

void main() {
  final observedAt = DateTime.utc(2026, 7, 16, 12);

  SourceRecordEnvelope record(
    String type,
    Map<String, Object?> payload, {
    String? stableId,
  }) => SourceRecordEnvelope(
    source: SourceKind.demoHealth,
    recordType: type,
    stableSourceId: stableId,
    payload: payload,
    observedAt: observedAt,
  );

  test('normalizes units, UTC, original offset and local date', () {
    final normalizer = RecordNormalizer(identityKey: 'fixture-key'.codeUnits);
    final batch = normalizer.normalizeAll([
      record('heart_rate', {
        'timestamp': '2026-07-16T10:00:00+05:30',
        'offset_minutes': 330,
        'value': 1.25,
        'unit': 'beats_per_second',
      }, stableId: 'heart-1'),
      record('hrv_rmssd', {
        'timestamp': '2026-07-16T10:01:00+05:30',
        'offset_minutes': 330,
        'value': 0.042,
        'unit': 'seconds',
      }, stableId: 'hrv-1'),
      record('steps', {
        'timestamp': '2026-07-16T23:00:00+05:30',
        'offset_minutes': 330,
        'value': 8123,
        'unit': 'count',
      }, stableId: 'steps-1'),
    ]);

    expect(batch.rejectedCount, 0);
    expect(batch.signalSamples[0].value, 75);
    expect(batch.signalSamples[0].unit, 'bpm');
    expect(
      batch.signalSamples[0].occurredAtUtc,
      DateTime.utc(2026, 7, 16, 4, 30),
    );
    expect(batch.signalSamples[0].originalOffsetMinutes, 330);
    expect(batch.signalSamples[0].originalLocalDate, '2026-07-16');
    expect(batch.signalSamples[1].value, closeTo(42, 0.0001));
    expect(batch.signalSamples[1].unit, 'ms');
    expect(batch.signalSamples[2].value, 8123);
    expect(batch.signalSamples[2].unit, 'count');
  });

  test(
    'rejects malformed, impossible and unsupported records with safe counts',
    () {
      final normalizer = RecordNormalizer(identityKey: 'fixture-key'.codeUnits);
      final batch = normalizer.normalizeAll([
        record('heart_rate', {
          'timestamp': '2026-07-16T10:00:00Z',
          'offset_minutes': 0,
          'value': -1,
          'unit': 'bpm',
        }),
        record('steps', {
          'timestamp': '2026-07-16T10:00:00Z',
          'offset_minutes': 0,
          'value': 2.5,
          'unit': 'count',
        }),
        record('unknown', {'value': 10}),
      ]);

      expect(batch.acceptedCount, 0);
      expect(batch.rejectedCount, 3);
      expect(batch.rejectedCounts['impossible_value'], 2);
      expect(batch.rejectedCounts['unsupported_record_type'], 1);
      expect(batch.rejectedCounts.keys, isNot(contains('heart_rate')));
    },
  );

  test(
    'HMAC identity is stable while changed content changes the payload hash',
    () {
      final normalizer = RecordNormalizer(identityKey: 'fixture-key'.codeUnits);
      NormalizationBatch normalize(double value) => normalizer.normalizeAll([
        record('heart_rate', {
          'timestamp': '2026-07-16T10:00:00Z',
          'offset_minutes': 0,
          'value': value,
          'unit': 'bpm',
        }, stableId: 'private-source-id'),
      ]);

      final first = normalize(70).signalSamples.single;
      final changed = normalize(71).signalSamples.single;
      expect(first.id, changed.id);
      expect(first.provenance.sourceRecordIdentity, startsWith('hmac:'));
      expect(
        first.provenance.sourceRecordIdentity,
        changed.provenance.sourceRecordIdentity,
      );
      expect(first.canonicalPayloadHash, isNot(changed.canonicalPayloadHash));
      expect(
        first.provenance.sourceRecordIdentity,
        isNot(contains('private-source-id')),
      );
    },
  );

  test('calendar normalization discards raw descriptive fields', () {
    final normalizer = RecordNormalizer(identityKey: 'fixture-key'.codeUnits);
    final batch = normalizer.normalizeAll([
      SourceRecordEnvelope(
        source: SourceKind.demoCalendar,
        recordType: 'calendar_event',
        stableSourceId: 'calendar-id',
        observedAt: observedAt,
        payload: const {
          'start': '2026-07-16T05:00:00Z',
          'end': '2026-07-16T05:30:00Z',
          'offset_minutes': 330,
          'category': 'recurring_one_to_one',
          'recurrence_id': 'series-id',
          'title': 'Private title',
          'attendees': ['Private person'],
        },
      ),
    ]);

    final event = batch.contextEvents.single;
    expect(event.category, ContextCategory.recurringOneToOne);
    expect(event.recurrenceKeyHmac, isNot(contains('series-id')));
    expect(event.toString(), isNot(contains('Private title')));
  });
}
