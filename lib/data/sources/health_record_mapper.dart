import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/platform/generated/source_api.g.dart';

final class HealthRecordMapper {
  const HealthRecordMapper();

  List<SourceRecordEnvelope> toEnvelopes(NativeHealthRecord record) {
    final observedAt = DateTime.fromMillisecondsSinceEpoch(
      record.lastModifiedEpochMillis,
      isUtc: true,
    );
    return switch (record.type) {
      HealthDataType.heartRate => [
        for (final sample in record.samples)
          SourceRecordEnvelope(
            source: SourceKind.healthConnect,
            recordType: 'heart_rate',
            payload: {
              'timestamp': _iso(sample.epochMillis),
              'offset_minutes': sample.offsetMinutes,
              'value': sample.value,
              'unit': record.unit ?? 'bpm',
            },
            observedAt: observedAt,
            stableSourceId: '${record.id}|heart|${sample.epochMillis}',
            parentStableSourceId: record.id,
          ),
      ],
      HealthDataType.sleep => [
        for (final segment in record.segments)
          SourceRecordEnvelope(
            source: SourceKind.healthConnect,
            recordType: 'sleep',
            payload: {
              'start': _iso(segment.startEpochMillis),
              'end': _iso(segment.endEpochMillis),
              'offset_minutes': record.startOffsetMinutes,
              'category': segment.category,
            },
            observedAt: observedAt,
            stableSourceId:
                '${record.id}|sleep|${segment.startEpochMillis}|${segment.endEpochMillis}',
            parentStableSourceId: record.id,
          ),
      ],
      HealthDataType.steps => [
        SourceRecordEnvelope(
          source: SourceKind.healthConnect,
          recordType: 'steps',
          payload: {
            'timestamp': _iso(record.endEpochMillis),
            'offset_minutes': record.endOffsetMinutes,
            'value': record.value,
            'unit': record.unit ?? 'count',
          },
          observedAt: observedAt,
          stableSourceId: record.id,
          parentStableSourceId: record.id,
        ),
      ],
      HealthDataType.exercise => [
        _intervalEnvelope(
          record: record,
          observedAt: observedAt,
          recordType: 'workout',
          category: record.category ?? 'other',
        ),
      ],
      HealthDataType.activity => [
        _intervalEnvelope(
          record: record,
          observedAt: observedAt,
          recordType: 'activity',
          category: record.category ?? 'active',
        ),
      ],
      HealthDataType.hrvRmssd => [
        SourceRecordEnvelope(
          source: SourceKind.healthConnect,
          recordType: 'hrv_rmssd',
          payload: {
            'timestamp': _iso(record.startEpochMillis),
            'offset_minutes': record.startOffsetMinutes,
            'value': record.value,
            'unit': record.unit ?? 'ms',
          },
          observedAt: observedAt,
          stableSourceId: record.id,
          parentStableSourceId: record.id,
        ),
      ],
    };
  }

  SourceRecordEnvelope _intervalEnvelope({
    required NativeHealthRecord record,
    required DateTime observedAt,
    required String recordType,
    required String category,
  }) => SourceRecordEnvelope(
    source: SourceKind.healthConnect,
    recordType: recordType,
    payload: {
      'start': _iso(record.startEpochMillis),
      'end': _iso(record.endEpochMillis),
      'offset_minutes': record.startOffsetMinutes,
      'category': category,
    },
    observedAt: observedAt,
    stableSourceId: record.id,
    parentStableSourceId: record.id,
  );

  String _iso(int epochMillis) => DateTime.fromMillisecondsSinceEpoch(
    epochMillis,
    isUtc: true,
  ).toIso8601String();
}
