import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:why_pulse/data/database/schema_versions.dart';
import 'package:why_pulse/domain/models/canonical_domain_models.dart';

final class RecordNormalizer {
  RecordNormalizer({required List<int> identityKey})
    : _identityHmac = Hmac(sha256, List<int>.unmodifiable(identityKey));

  final Hmac _identityHmac;

  NormalizationBatch normalizeAll(Iterable<SourceRecordEnvelope> records) {
    final signals = <CanonicalSignalSample>[];
    final intervals = <CanonicalHealthInterval>[];
    final contextEvents = <CanonicalContextEvent>[];
    final manualCheckins = <CanonicalManualCheckin>[];
    final rejected = <String, int>{};

    for (final record in records) {
      try {
        switch (record.recordType) {
          case 'heart_rate':
          case 'hrv_rmssd':
          case 'steps':
            signals.add(_normalizeSignal(record));
          case 'sleep':
          case 'workout':
          case 'activity':
            intervals.add(_normalizeHealthInterval(record));
          case 'calendar_event':
            contextEvents.add(_normalizeContextEvent(record));
          case 'manual_checkin':
            manualCheckins.add(_normalizeManualCheckin(record));
          default:
            throw const NormalizationException('unsupported_record_type');
        }
      } on NormalizationException catch (error) {
        rejected.update(
          error.safeReason,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      } on Object {
        rejected.update(
          'malformed_record',
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return NormalizationBatch(
      signalSamples: List.unmodifiable(signals),
      healthIntervals: List.unmodifiable(intervals),
      contextEvents: List.unmodifiable(contextEvents),
      manualCheckins: List.unmodifiable(manualCheckins),
      rejectedCounts: Map.unmodifiable(rejected),
    );
  }

  CanonicalSignalSample _normalizeSignal(SourceRecordEnvelope record) {
    final time = _readTime(record.payload, 'timestamp');
    final value = _readNumber(record.payload, 'value');
    final unit = _readString(record.payload, 'unit').toLowerCase();
    final identity = _identity(record);

    late final SignalKind kind;
    late final double normalizedValue;
    late final String normalizedUnit;
    switch (record.recordType) {
      case 'heart_rate':
        kind = SignalKind.heartRate;
        normalizedValue = switch (unit) {
          'bpm' || 'beats_per_minute' => value,
          'beats_per_second' => value * 60,
          _ => throw const NormalizationException('unsupported_unit'),
        };
        normalizedUnit = 'bpm';
        if (normalizedValue <= 0 || normalizedValue > 300) {
          throw const NormalizationException('impossible_value');
        }
      case 'hrv_rmssd':
        kind = SignalKind.heartRateVariability;
        normalizedValue = switch (unit) {
          'ms' || 'milliseconds' => value,
          's' || 'seconds' => value * 1000,
          _ => throw const NormalizationException('unsupported_unit'),
        };
        normalizedUnit = 'ms';
        if (normalizedValue <= 0 || normalizedValue > 2000) {
          throw const NormalizationException('impossible_value');
        }
      case 'steps':
        kind = SignalKind.steps;
        if (value < 0 || value > 1000000 || value != value.roundToDouble()) {
          throw const NormalizationException('impossible_value');
        }
        normalizedValue = value.roundToDouble();
        normalizedUnit = 'count';
      default:
        throw const NormalizationException('unsupported_record_type');
    }

    final payload = <String, Object?>{
      'kind': kind.name,
      'occurredAtUtc': time.utc.toIso8601String(),
      'value': normalizedValue,
      'unit': normalizedUnit,
      'originalOffsetMinutes': time.offsetMinutes,
      'originalLocalDate': time.localDate,
    };
    final payloadHash = canonicalPayloadHash(payload);
    return CanonicalSignalSample(
      id: _canonicalId(record, identity, payloadHash),
      kind: kind,
      occurredAtUtc: time.utc,
      value: normalizedValue,
      unit: normalizedUnit,
      originalOffsetMinutes: time.offsetMinutes,
      originalLocalDate: time.localDate,
      provenance: _provenance(record, identity),
      canonicalPayloadHash: payloadHash,
    );
  }

  CanonicalHealthInterval _normalizeHealthInterval(
    SourceRecordEnvelope record,
  ) {
    final start = _readTime(record.payload, 'start');
    final end = _readTime(record.payload, 'end');
    if (!end.utc.isAfter(start.utc) ||
        end.utc.difference(start.utc).inDays > 7) {
      throw const NormalizationException('impossible_duration');
    }
    final identity = _identity(record);
    final category = _normalizeHealthCategory(
      record.recordType,
      _readString(record.payload, 'category').toLowerCase(),
    );
    final kind = switch (record.recordType) {
      'sleep' => HealthIntervalKind.sleep,
      'workout' => HealthIntervalKind.workout,
      'activity' => HealthIntervalKind.activity,
      _ => throw const NormalizationException('unsupported_record_type'),
    };
    final payload = <String, Object?>{
      'kind': kind.name,
      'category': category,
      'startAtUtc': start.utc.toIso8601String(),
      'endAtUtc': end.utc.toIso8601String(),
      'durationSeconds': end.utc.difference(start.utc).inSeconds,
      'originalOffsetMinutes': start.offsetMinutes,
      'originalLocalDate': start.localDate,
    };
    final payloadHash = canonicalPayloadHash(payload);
    return CanonicalHealthInterval(
      id: _canonicalId(record, identity, payloadHash),
      kind: kind,
      category: category,
      startAtUtc: start.utc,
      endAtUtc: end.utc,
      originalOffsetMinutes: start.offsetMinutes,
      originalLocalDate: start.localDate,
      provenance: _provenance(record, identity),
      canonicalPayloadHash: payloadHash,
    );
  }

  CanonicalContextEvent _normalizeContextEvent(SourceRecordEnvelope record) {
    final start = _readTime(record.payload, 'start');
    final end = _readTime(record.payload, 'end');
    if (!end.utc.isAfter(start.utc) ||
        end.utc.difference(start.utc).inHours > 24) {
      throw const NormalizationException('impossible_duration');
    }
    final identity = _identity(record);
    final rawCategory = _readString(record.payload, 'category');
    final category = switch (rawCategory) {
      'recurring_one_to_one' => ContextCategory.recurringOneToOne,
      'team_meeting' => ContextCategory.teamMeeting,
      'other_recurring_meeting' => ContextCategory.otherRecurringMeeting,
      _ => throw const NormalizationException('unsupported_category'),
    };
    final recurrenceId = record.payload['recurrence_id'];
    final recurrenceKeyHmac = recurrenceId is String && recurrenceId.isNotEmpty
        ? _identityHmac.convert(utf8.encode(recurrenceId)).toString()
        : null;
    final payload = <String, Object?>{
      'category': category.name,
      'startAtUtc': start.utc.toIso8601String(),
      'endAtUtc': end.utc.toIso8601String(),
      'durationSeconds': end.utc.difference(start.utc).inSeconds,
      'recurrenceKeyHmac': recurrenceKeyHmac,
      'originalOffsetMinutes': start.offsetMinutes,
      'originalLocalDate': start.localDate,
    };
    final payloadHash = canonicalPayloadHash(payload);
    return CanonicalContextEvent(
      id: _canonicalId(record, identity, payloadHash),
      category: category,
      startAtUtc: start.utc,
      endAtUtc: end.utc,
      recurrenceKeyHmac: recurrenceKeyHmac,
      originalOffsetMinutes: start.offsetMinutes,
      originalLocalDate: start.localDate,
      provenance: _provenance(record, identity),
      canonicalPayloadHash: payloadHash,
    );
  }

  CanonicalManualCheckin _normalizeManualCheckin(SourceRecordEnvelope record) {
    final time = _readTime(record.payload, 'timestamp');
    final rawCategory = _readString(record.payload, 'category');
    final category = switch (rawCategory) {
      'caffeine' => CheckinCategory.caffeine,
      'exercise' => CheckinCategory.exercise,
      'illness' => CheckinCategory.illness,
      'mood' => CheckinCategory.mood,
      'travel' => CheckinCategory.travel,
      'custom' => CheckinCategory.custom,
      _ => throw const NormalizationException('unsupported_category'),
    };
    final value = record.payload['value'];
    if (value is! Map<String, Object?> || value.isEmpty) {
      throw const NormalizationException('malformed_value');
    }
    if (category == CheckinCategory.custom && value['reviewed'] != true) {
      throw const NormalizationException('unreviewed_custom_category');
    }
    final identity = _identity(record);
    final payload = <String, Object?>{
      'category': category.name,
      'occurredAtUtc': time.utc.toIso8601String(),
      'value': value,
      'originalOffsetMinutes': time.offsetMinutes,
      'originalLocalDate': time.localDate,
    };
    final payloadHash = canonicalPayloadHash(payload);
    return CanonicalManualCheckin(
      id: _canonicalId(record, identity, payloadHash),
      category: category,
      occurredAtUtc: time.utc,
      value: Map.unmodifiable(value),
      originalOffsetMinutes: time.offsetMinutes,
      originalLocalDate: time.localDate,
      provenance: _provenance(record, identity),
      canonicalPayloadHash: payloadHash,
    );
  }

  String _normalizeHealthCategory(String recordType, String category) {
    final accepted = switch (recordType) {
      'sleep' => const {'asleep', 'awake', 'light', 'deep', 'rem', 'unknown'},
      'workout' => const {
        'walking',
        'running',
        'cycling',
        'strength',
        'yoga',
        'other',
      },
      'activity' => const {'active', 'sedentary', 'unknown'},
      _ => const <String>{},
    };
    if (!accepted.contains(category)) {
      throw const NormalizationException('unsupported_category');
    }
    return category;
  }

  SourceProvenance _provenance(SourceRecordEnvelope record, String identity) =>
      SourceProvenance(
        source: record.source,
        sourceRecordIdentity: identity,
        observedAtUtc: record.observedAt.toUtc(),
        normalizationVersion: SchemaVersions.normalization,
        parentSourceRecordIdentity: record.parentStableSourceId == null
            ? null
            : sourceRecordIdentity(record.parentStableSourceId!),
      );

  String sourceRecordIdentity(String stableSourceId) =>
      'hmac:${_identityHmac.convert(utf8.encode(stableSourceId))}';

  String _identity(SourceRecordEnvelope record) {
    final stableId = record.stableSourceId;
    if (stableId != null && stableId.isNotEmpty) {
      return sourceRecordIdentity(stableId);
    }
    return 'payload:${canonicalPayloadHash(record.payload)}';
  }

  String _canonicalId(
    SourceRecordEnvelope record,
    String identity,
    String payloadHash,
  ) {
    final identityInput = record.stableSourceId == null
        ? '${record.source.name}|${record.recordType}|$payloadHash'
        : '${record.source.name}|${record.recordType}|$identity';
    return sha256.convert(utf8.encode(identityInput)).toString();
  }

  _NormalizedTime _readTime(JsonMap payload, String key) {
    final raw = payload[key];
    final offset = payload['offset_minutes'];
    if (raw is! String || offset is! num || offset != offset.roundToDouble()) {
      throw const NormalizationException('malformed_time');
    }
    final parsed = DateTime.tryParse(raw);
    final offsetMinutes = offset.toInt();
    if (parsed == null || offsetMinutes < -840 || offsetMinutes > 840) {
      throw const NormalizationException('malformed_time');
    }
    final utc = parsed.toUtc();
    final local = utc.add(Duration(minutes: offsetMinutes));
    final localDate =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    return _NormalizedTime(
      utc: utc,
      offsetMinutes: offsetMinutes,
      localDate: localDate,
    );
  }

  double _readNumber(JsonMap payload, String key) {
    final value = payload[key];
    if (value is! num || !value.toDouble().isFinite) {
      throw const NormalizationException('malformed_value');
    }
    return value.toDouble();
  }

  String _readString(JsonMap payload, String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty) {
      throw const NormalizationException('malformed_value');
    }
    return value.trim();
  }
}

final class NormalizationBatch {
  const NormalizationBatch({
    required this.signalSamples,
    required this.healthIntervals,
    required this.contextEvents,
    required this.manualCheckins,
    required this.rejectedCounts,
  });

  final List<CanonicalSignalSample> signalSamples;
  final List<CanonicalHealthInterval> healthIntervals;
  final List<CanonicalContextEvent> contextEvents;
  final List<CanonicalManualCheckin> manualCheckins;
  final Map<String, int> rejectedCounts;

  int get acceptedCount =>
      signalSamples.length +
      healthIntervals.length +
      contextEvents.length +
      manualCheckins.length;

  int get rejectedCount =>
      rejectedCounts.values.fold(0, (sum, value) => sum + value);
}

final class NormalizationException implements Exception {
  const NormalizationException(this.safeReason);

  final String safeReason;
}

final class _NormalizedTime {
  const _NormalizedTime({
    required this.utc,
    required this.offsetMinutes,
    required this.localDate,
  });

  final DateTime utc;
  final int offsetMinutes;
  final String localDate;
}

String canonicalPayloadHash(Object? value) =>
    sha256.convert(utf8.encode(canonicalJsonEncode(value))).toString();

String canonicalJsonEncode(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries =
        value.entries
            .map(
              (entry) =>
                  MapEntry(entry.key.toString(), _canonicalize(entry.value)),
            )
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    return {for (final entry in entries) entry.key: entry.value};
  }
  if (value is Iterable) {
    return value.map(_canonicalize).toList(growable: false);
  }
  if (value is DateTime) return value.toUtc().toIso8601String();
  return value;
}
