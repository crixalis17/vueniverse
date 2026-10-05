import 'package:vueniverse/data/sources/ultrahuman_client.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

/// Resolve the API's IANA zone at the observation instant, not the phone zone.
/// Null means unknown: reject the observation rather than assume UTC.
typedef UltrahumanOffsetResolver =
    int? Function(String zone, DateTime instantUtc);

final class UltrahumanRecordMapper {
  const UltrahumanRecordMapper({required this.offsetResolver});
  final UltrahumanOffsetResolver offsetResolver;

  UltrahumanMappingResult mapDay(
    UltrahumanDayResponse day, {
    required DateTime observedAt,
  }) {
    validateUltrahumanDate(day.localDate);
    final records = <String, SourceRecordEnvelope>{};
    final rejected = <String, int>{};
    final skippedMetricTypes = <String>{};
    final seenTypes = <String>{};
    final ambiguousTypes = <String>{};
    final seenIdentities = <String, String>{};
    final validRowCounts = <String, int>{};
    final conflictedIdentities = <String>{};
    var inputObservationCount = 0;
    var duplicateObservationCount = 0;
    var rejectedObservationCount = 0;
    void reject(String reason) =>
        rejected.update(reason, (n) => n + 1, ifAbsent: () => 1);
    void rejectObservation(String reason, [String? identity]) {
      reject(reason);
      rejectedObservationCount++;
      if (identity != null) conflictedIdentities.add(identity);
    }

    // Duplicate metric objects are ambiguous; do not choose first/last silently.
    for (final item in day.metrics) {
      if (item is Map && item['type'] is String) {
        final type = item['type'] as String;
        if (!seenTypes.add(type)) ambiguousTypes.add(type);
      }
    }
    for (final item in day.metrics) {
      if (item is! Map || item['type'] is! String || item['object'] is! Map) {
        reject('malformed_metric');
        continue;
      }
      final type = item['type'] as String;
      final object = item['object'] as Map;
      if (type != 'hr' && type != 'sleep') {
        skippedMetricTypes.add(switch (type) {
          'hrv' || 'steps' => type,
          _ => 'other',
        });
        continue;
      }
      final values = type == 'hr'
          ? object['values']
          : (object['sleep_graph'] is Map
                ? (object['sleep_graph'] as Map)['data']
                : null);
      if (values is! List) {
        reject('missing_observations');
        continue;
      }
      inputObservationCount += values.length;
      if (ambiguousTypes.contains(type)) {
        reject('duplicate_metric_type');
        rejectedObservationCount += values.length;
        continue;
      }
      if (type == 'hr' && object['unit'] != 'BPM' && object['unit'] != 'bpm') {
        reject('unsupported_heart_rate_unit');
        rejectedObservationCount += values.length;
        continue;
      }
      for (final value in values) {
        if (value is! Map) {
          rejectObservation('malformed_observation');
          continue;
        }
        final start = _epoch(
          type == 'hr' ? value['timestamp'] : value['start'],
        );
        if (start == null || start.isAfter(observedAt.toUtc())) {
          rejectObservation('invalid_timestamp');
          continue;
        }
        final identity = 'ultrahuman:$type:${start.millisecondsSinceEpoch}';
        int? offset;
        try {
          offset = offsetResolver(day.timezoneName, start);
        } on Object {
          offset = null;
        }
        if (offset == null || offset < -840 || offset > 840) {
          rejectObservation('unresolved_timezone', identity);
          continue;
        }
        final localDay = start
            .add(Duration(minutes: offset))
            .toIso8601String()
            .substring(0, 10);
        if (type == 'hr' && localDay != day.localDate) {
          rejectObservation('observation_outside_requested_day', identity);
          continue;
        }
        late final JsonMap payload;
        if (type == 'hr') {
          final bpm = value['value'];
          if (bpm is! num || !bpm.isFinite || bpm <= 0 || bpm > 300) {
            rejectObservation('invalid_heart_rate', identity);
            continue;
          }
          payload = {
            'timestamp': start.toIso8601String(),
            'offset_minutes': offset,
            'value': bpm.toDouble(),
            'unit': 'bpm',
          };
        } else {
          final end = _epoch(value['end']);
          final category = switch (value['type']) {
            'awake' => 'awake',
            'deep_sleep' => 'deep',
            'light_sleep' => 'light',
            'rem_sleep' => 'rem',
            _ => null,
          };
          if (end == null ||
              !end.isAfter(start) ||
              end.isAfter(observedAt.toUtc()) ||
              end.difference(start) > const Duration(hours: 24) ||
              category == null) {
            rejectObservation('invalid_sleep_segment', identity);
            continue;
          }
          int? endOffset;
          try {
            endOffset = offsetResolver(
              day.timezoneName,
              end.subtract(const Duration(microseconds: 1)),
            );
          } on Object {
            endOffset = null;
          }
          if (endOffset != offset) {
            rejectObservation('sleep_offset_changed', identity);
            continue;
          }
          // A sleep episode can cross midnight. Require overlap with the requested day.
          final endDay = end
              .subtract(const Duration(microseconds: 1))
              .add(Duration(minutes: offset))
              .toIso8601String()
              .substring(0, 10);
          if (localDay.compareTo(day.localDate) > 0 ||
              endDay.compareTo(day.localDate) < 0) {
            rejectObservation('observation_outside_requested_day', identity);
            continue;
          }
          payload = {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
            'offset_minutes': offset,
            'category': category,
          };
        }
        final signature = payload.toString();
        validRowCounts.update(identity, (n) => n + 1, ifAbsent: () => 1);
        if (conflictedIdentities.contains(identity)) continue;
        final previous = seenIdentities[identity];
        if (previous != null && previous != signature) {
          records.remove(identity);
          conflictedIdentities.add(identity);
          continue;
        }
        if (previous != null) {
          continue;
        }
        seenIdentities[identity] = signature;
        records[identity] = SourceRecordEnvelope(
          source: SourceKind.ultrahuman,
          recordType: type == 'hr' ? 'heart_rate' : 'sleep',
          payload: payload,
          observedAt: observedAt.toUtc(),
          stableSourceId: identity,
          parentStableSourceId:
              'ultrahuman:daily_metrics:${day.localDate}:$type',
        );
      }
    }
    for (final entry in validRowCounts.entries) {
      if (conflictedIdentities.contains(entry.key)) {
        rejectedObservationCount += entry.value;
        records.remove(entry.key);
        reject('conflicting_observation');
      } else {
        duplicateObservationCount += entry.value - 1;
        if (entry.value > 1) {
          rejected['duplicate_observation'] =
              (rejected['duplicate_observation'] ?? 0) + entry.value - 1;
        }
      }
    }
    final sorted = records.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final sleep = sorted.where((e) => e.value.recordType == 'sleep').toList();
    sleep.sort(
      (a, b) => DateTime.parse(
        a.value.payload['start'] as String,
      ).compareTo(DateTime.parse(b.value.payload['start'] as String)),
    );
    final overlap = <String>{};
    DateTime? furthestEnd;
    String? furthestId;
    // Sweep identifies every overlapping participant without quadratic work.
    for (final entry in sleep) {
      final start = DateTime.parse(entry.value.payload['start'] as String);
      final end = DateTime.parse(entry.value.payload['end'] as String);
      if (furthestEnd != null && start.isBefore(furthestEnd)) {
        overlap.addAll([entry.key, furthestId!]);
      }
      if (furthestEnd == null || end.isAfter(furthestEnd)) {
        furthestEnd = end;
        furthestId = entry.key;
      }
    }
    if (overlap.isNotEmpty) {
      rejected['overlapping_sleep_segments'] = overlap.length;
      for (final identity in overlap) {
        final count = validRowCounts[identity]!;
        rejectedObservationCount += count;
        duplicateObservationCount -= count - 1;
        final duplicates = rejected['duplicate_observation'] ?? 0;
        if (duplicates > 0) {
          rejected['duplicate_observation'] = duplicates - (count - 1);
        }
      }
      if (rejected['duplicate_observation'] == 0) {
        rejected.remove('duplicate_observation');
      }
    }
    return UltrahumanMappingResult(
      records: List.unmodifiable(
        sorted
            .where((e) => !overlap.contains(e.key))
            .map((entry) => entry.value),
      ),
      rejectedCounts: Map.unmodifiable(rejected),
      skippedMetricTypes: Set.unmodifiable(skippedMetricTypes),
      inputObservationCount: inputObservationCount,
      duplicateObservationCount: duplicateObservationCount,
      rejectedObservationCount: rejectedObservationCount,
    );
  }

  DateTime? _epoch(Object? value) {
    // Observed official personal payload uses UNIX seconds, never guess millis.
    if (value is! int || value < 946684800 || value > 4133980800) return null;
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
  }
}

final class UltrahumanMappingResult {
  const UltrahumanMappingResult({
    required this.records,
    required this.rejectedCounts,
    required this.skippedMetricTypes,
    required this.inputObservationCount,
    required this.duplicateObservationCount,
    required this.rejectedObservationCount,
  });
  final List<SourceRecordEnvelope> records;
  final Map<String, int> rejectedCounts;
  final Set<String> skippedMetricTypes;

  /// Actual rows in supported HR/sleep arrays, not number of metric objects.
  final int inputObservationCount;
  final int duplicateObservationCount;
  final int rejectedObservationCount;
}
