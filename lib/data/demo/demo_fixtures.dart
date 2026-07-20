import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:why_pulse/domain/models/canonical_domain_models.dart';

abstract interface class FixtureAssetReader {
  Future<String> read(String assetPath);
}

final class RootBundleFixtureAssetReader implements FixtureAssetReader {
  const RootBundleFixtureAssetReader();

  @override
  Future<String> read(String assetPath) => rootBundle.loadString(assetPath);
}

final class FileFixtureAssetReader implements FixtureAssetReader {
  const FileFixtureAssetReader(this.workspaceRoot);

  final String workspaceRoot;

  @override
  Future<String> read(String assetPath) =>
      File('$workspaceRoot/$assetPath').readAsString();
}

final class DemoFixtureBundle {
  const DemoFixtureBundle({
    required this.fixtureVersion,
    required this.clock,
    required this.rangeStartUtc,
    required this.rangeEndUtc,
    required this.identityKey,
    required this.healthRecords,
    required this.calendarRecords,
    required this.manualRecords,
    required this.expectedOutputs,
    required this.analysisCases,
    required this.experiments,
    required this.meetingProfiles,
  });

  final int fixtureVersion;
  final FixtureClock clock;
  final DateTime rangeStartUtc;
  final DateTime rangeEndUtc;
  final List<int> identityKey;
  final List<SourceRecordEnvelope> healthRecords;
  final List<SourceRecordEnvelope> calendarRecords;
  final List<SourceRecordEnvelope> manualRecords;
  final Map<String, Object?> expectedOutputs;
  final List<Map<String, Object?>> analysisCases;
  final List<Map<String, Object?>> experiments;
  final List<DemoMeetingProfile> meetingProfiles;

  int get recordCount =>
      healthRecords.length + calendarRecords.length + manualRecords.length;

  int get coverageDayCount {
    final start = DateTime.utc(
      rangeStartUtc.year,
      rangeStartUtc.month,
      rangeStartUtc.day,
    );
    final end = DateTime.utc(
      rangeEndUtc.year,
      rangeEndUtc.month,
      rangeEndUtc.day,
    );
    return end.difference(start).inDays + 1;
  }
}

final class FixtureClock {
  const FixtureClock(this.nowUtc);

  final DateTime nowUtc;

  DateTime now() => nowUtc;
}

final class DemoFixtureLoader {
  const DemoFixtureLoader(this.assets);

  final FixtureAssetReader assets;

  Future<DemoFixtureBundle> load() async {
    final manifest = await _readObject('assets/demo/manifest.json');
    final sources = _object(manifest['sources']);
    final health = await _readObject('assets/demo/${sources['health']}');
    final calendar = await _readObject('assets/demo/${sources['calendar']}');
    final manual = await _readObject('assets/demo/${sources['manual']}');
    final edgeCases = await _readObject(
      'assets/demo/${manifest['edge_cases']}',
    );
    final analysisCasesData = await _readObject(
      'assets/demo/${manifest['analysis_cases']}',
    );
    final experimentsData = await _readObject(
      'assets/demo/${manifest['experiments']}',
    );
    final now = DateTime.parse(_string(manifest['virtual_clock'])).toUtc();
    final rangeStartUtc = DateTime.parse(
      _string(manifest['range_start']),
    ).toUtc();
    final rangeEndUtc = DateTime.parse(_string(manifest['range_end'])).toUtc();
    _validateCoverageRange(
      health,
      rangeStartUtc: rangeStartUtc,
      rangeEndUtc: rangeEndUtc,
      virtualNowUtc: now,
    );

    return DemoFixtureBundle(
      fixtureVersion: _integer(manifest['fixture_version']),
      clock: FixtureClock(now),
      rangeStartUtc: rangeStartUtc,
      rangeEndUtc: rangeEndUtc,
      identityKey: utf8.encode(_string(manifest['identity_key'])),
      healthRecords: List.unmodifiable(
        _healthRecords(health, calendar, edgeCases, now),
      ),
      calendarRecords: List.unmodifiable(_calendarRecords(calendar, now)),
      manualRecords: List.unmodifiable(_manualRecords(manual, now)),
      expectedOutputs: Map.unmodifiable(_object(manifest['expected_outputs'])),
      analysisCases: List.unmodifiable(
        _list(analysisCasesData['cases']).map(_object),
      ),
      experiments: List.unmodifiable(
        _list(experimentsData['protocols']).map(_object),
      ),
      meetingProfiles: List.unmodifiable(_meetingProfiles(health, calendar)),
    );
  }

  void _validateCoverageRange(
    Map<String, Object?> health, {
    required DateTime rangeStartUtc,
    required DateTime rangeEndUtc,
    required DateTime virtualNowUtc,
  }) {
    if (rangeEndUtc.isBefore(rangeStartUtc) ||
        virtualNowUtc.isBefore(rangeStartUtc) ||
        virtualNowUtc.isAfter(rangeEndUtc)) {
      throw const FormatException('Invalid demo coverage range');
    }
    final dates = [
      for (final rawDay in _list(health['days']))
        _localDateTime(_string(_list(rawDay).first), 0),
    ];
    if (dates.length < 30 || dates.toSet().length != dates.length) {
      throw const FormatException(
        'Demo health history must contain at least 30 unique days',
      );
    }
    for (var index = 1; index < dates.length; index++) {
      if (dates[index].difference(dates[index - 1]).inDays != 1) {
        throw const FormatException('Demo health days must be consecutive');
      }
    }
    final expectedStart = DateTime.utc(
      rangeStartUtc.year,
      rangeStartUtc.month,
      rangeStartUtc.day,
    );
    final expectedEnd = DateTime.utc(
      rangeEndUtc.year,
      rangeEndUtc.month,
      rangeEndUtc.day,
    );
    if (dates.first != expectedStart || dates.last != expectedEnd) {
      throw const FormatException(
        'Demo health days must match the declared range',
      );
    }
  }

  List<DemoMeetingProfile> _meetingProfiles(
    Map<String, Object?> data,
    Map<String, Object?> calendar,
  ) {
    final events = {
      for (final raw in _list(calendar['events']))
        _string(_list(raw).first): _list(raw),
    };
    return [
      for (final raw in _list(data['meeting_profiles']))
        () {
          final profile = _list(raw);
          final event = events[_string(profile[0])]!;
          return DemoMeetingProfile(
            eventId: _string(profile[0]),
            eventStartUtc: DateTime.parse(_string(event[1])).toUtc(),
            eventEndUtc: DateTime.parse(_string(event[2])).toUtc(),
            controlDate: _string(profile[1]),
            offsetMinutes: _integer(profile[2]),
            baseline: _number(profile[3]),
            difference: _number(profile[4]),
            recoveryMinutes: _integer(profile[5]),
            coveragePercent: _integer(profile[6]),
          );
        }(),
    ];
  }

  List<SourceRecordEnvelope> _healthRecords(
    Map<String, Object?> data,
    Map<String, Object?> calendar,
    Map<String, Object?> edgeCases,
    DateTime observedAt,
  ) {
    final records = <SourceRecordEnvelope>[];
    for (final (dayIndex, rawDay) in _list(data['days']).indexed) {
      final day = _list(rawDay);
      if (day.length != 6) {
        throw const FormatException('Invalid demo health day');
      }
      final date = _string(day[0]);
      final baseHeartRate = _number(day[1]);
      final steps = _integer(day[2]);
      final sleepMinutes = _integer(day[3]);
      final offset = _integer(day[4]);
      final hrv = _number(day[5]);

      records.addAll([
        _record(SourceKind.demoHealth, 'heart_rate', 'demo-hr-$date-morning', {
          'timestamp': _localToUtc(date, 7, 30, offset),
          'offset_minutes': offset,
          'value': baseHeartRate - 4,
          'unit': 'bpm',
        }, observedAt),
        _record(SourceKind.demoHealth, 'heart_rate', 'demo-hr-$date-meeting', {
          'timestamp': _localToUtc(date, 9, 45, offset),
          'offset_minutes': offset,
          'value': baseHeartRate,
          'unit': 'bpm',
        }, observedAt),
        _record(SourceKind.demoHealth, 'heart_rate', 'demo-hr-$date-evening', {
          'timestamp': _localToUtc(date, 18, 0, offset),
          'offset_minutes': offset,
          'value': baseHeartRate - 2,
          'unit': 'bpm',
        }, observedAt),
        _record(SourceKind.demoHealth, 'hrv_rmssd', 'demo-hrv-$date', {
          'timestamp': _localToUtc(date, 7, 35, offset),
          'offset_minutes': offset,
          'value': hrv,
          'unit': 'ms',
        }, observedAt),
        _record(SourceKind.demoHealth, 'steps', 'demo-steps-$date', {
          'timestamp': _localToUtc(date, 23, 0, offset),
          'offset_minutes': offset,
          'value': steps,
          'unit': 'count',
        }, observedAt),
      ]);
      records.addAll(
        _backgroundHeartRateRecords(
          date: date,
          offsetMinutes: offset,
          dailyBaseline: baseHeartRate,
          dayIndex: dayIndex,
          observedAt: observedAt,
        ),
      );

      final wakeLocal = _localDateTime(date, 7, 0);
      final sleepLocal = wakeLocal.subtract(Duration(minutes: sleepMinutes));
      records.add(
        _record(SourceKind.demoHealth, 'sleep', 'demo-sleep-$date', {
          'start': sleepLocal
              .subtract(Duration(minutes: offset))
              .toUtc()
              .toIso8601String(),
          'end': wakeLocal
              .subtract(Duration(minutes: offset))
              .toUtc()
              .toIso8601String(),
          'offset_minutes': offset,
          'category': 'asleep',
        }, observedAt),
      );
    }

    for (final rawWorkout in _list(data['workouts'])) {
      final workout = _list(rawWorkout);
      records.add(
        _record(SourceKind.demoHealth, 'workout', _string(workout[0]), {
          'start': _string(workout[1]),
          'end': _string(workout[2]),
          'offset_minutes': _integer(workout[3]),
          'category': _string(workout[4]),
        }, observedAt),
      );
    }

    for (final rawActivity in _list(data['activities'])) {
      final activity = _list(rawActivity);
      if (activity.length != 5) {
        throw const FormatException('Invalid demo activity interval');
      }
      records.add(
        _record(SourceKind.demoHealth, 'activity', _string(activity[0]), {
          'start': _string(activity[1]),
          'end': _string(activity[2]),
          'offset_minutes': _integer(activity[3]),
          'category': _string(activity[4]),
        }, observedAt),
      );
    }

    final calendarEvents = {
      for (final rawEvent in _list(calendar['events']))
        _string(_list(rawEvent)[0]): _list(rawEvent),
    };
    for (final rawProfile in _list(data['meeting_profiles'])) {
      final profile = _list(rawProfile);
      if (profile.length != 7) {
        throw const FormatException('Invalid demo meeting profile');
      }
      final eventId = _string(profile[0]);
      final event = calendarEvents[eventId];
      if (event == null) {
        throw FormatException('Missing Calendar event for $eventId');
      }
      final eventStart = DateTime.parse(_string(event[1])).toUtc();
      final eventEnd = DateTime.parse(_string(event[2])).toUtc();
      final controlDate = _string(profile[1]);
      final offsetMinutes = _integer(profile[2]);
      final baseline = _number(profile[3]);
      final difference = _number(profile[4]);
      final recoveryMinutes = _integer(profile[5]);
      final coveragePercent = _integer(profile[6]);
      final windowStart = eventStart.subtract(const Duration(minutes: 15));
      final windowEnd = eventEnd.add(const Duration(minutes: 60));
      final totalMinutes = windowEnd.difference(windowStart).inMinutes;
      for (var minute = 0; minute < totalMinutes; minute++) {
        if (!_includeFixtureMinute(minute, coveragePercent)) continue;
        final timestamp = windowStart.add(Duration(minutes: minute));
        final value = timestamp.isBefore(eventStart)
            ? baseline + difference
            : timestamp.isBefore(eventEnd)
            ? baseline + difference + 3
            : timestamp.difference(eventEnd).inMinutes < recoveryMinutes
            ? baseline + 6
            : baseline;
        records.add(
          _record(
            SourceKind.demoHealth,
            'heart_rate',
            'demo-hr-$eventId-window-$minute',
            {
              'timestamp': timestamp.toIso8601String(),
              'offset_minutes': offsetMinutes,
              'value': value,
              'unit': 'bpm',
            },
            observedAt,
          ),
        );
      }

      final eventLocal = eventStart.add(Duration(minutes: offsetMinutes));
      final controlLocalStart = _localDateTime(
        controlDate,
        eventLocal.hour,
        eventLocal.minute,
      ).subtract(const Duration(minutes: 15));
      final controlStart = controlLocalStart.subtract(
        Duration(minutes: offsetMinutes),
      );
      for (var minute = 0; minute < 15; minute++) {
        records.add(
          _record(
            SourceKind.demoHealth,
            'heart_rate',
            'demo-hr-$eventId-control-$minute',
            {
              'timestamp': controlStart
                  .add(Duration(minutes: minute))
                  .toIso8601String(),
              'offset_minutes': offsetMinutes,
              'value': baseline,
              'unit': 'bpm',
            },
            observedAt,
          ),
        );
      }
    }

    final duplicateId = _string(edgeCases['duplicate_health_id']);
    final duplicate = records.firstWhere(
      (record) => record.stableSourceId == duplicateId,
    );
    records.add(duplicate);

    final changed = _object(edgeCases['changed_record']);
    for (final valueKey in ['old_value', 'new_value']) {
      records.add(
        _record(
          SourceKind.demoHealth,
          _string(changed['record_type']),
          _string(changed['stable_id']),
          {
            'timestamp': _string(changed['timestamp']),
            'offset_minutes': _integer(changed['offset_minutes']),
            'value': _number(changed[valueKey]),
            'unit': _string(changed['unit']),
          },
          observedAt,
        ),
      );
    }
    for (final rawMalformed in _list(edgeCases['malformed_records'])) {
      final malformed = _object(rawMalformed);
      records.add(
        SourceRecordEnvelope(
          source: SourceKind.demoHealth,
          recordType: _string(malformed['record_type']),
          payload: malformed,
          observedAt: observedAt,
        ),
      );
    }
    return records;
  }

  Iterable<SourceRecordEnvelope> _backgroundHeartRateRecords({
    required String date,
    required int offsetMinutes,
    required double dailyBaseline,
    required int dayIndex,
    required DateTime observedAt,
  }) sync* {
    var sampleIndex = 0;
    for (var localMinute = 6 * 60; localMinute < 23 * 60; localMinute += 20) {
      // Meeting and matched-control windows have minute-resolution samples.
      // Leave that period untouched so ambient data cannot change the
      // deterministic evidence calculation.
      if (localMinute >= 9 * 60 + 30 && localMinute < 12 * 60) continue;
      final localHour = localMinute ~/ 60;
      final circadianOffset = switch (localHour) {
        < 8 => -6,
        < 9 => -3,
        < 12 => 1,
        < 14 => 4,
        < 17 => 2,
        < 20 => 0,
        _ => -3,
      };
      final smallVariation = ((dayIndex * 3 + sampleIndex) % 5) - 2;
      final value = (dailyBaseline + circadianOffset + smallVariation)
          .clamp(45, 120)
          .toDouble();
      final hour = (localMinute ~/ 60).toString().padLeft(2, '0');
      final minute = (localMinute % 60).toString().padLeft(2, '0');
      yield _record(
        SourceKind.demoHealth,
        'heart_rate',
        'demo-hr-$date-background-$hour$minute',
        {
          'timestamp': _localToUtc(
            date,
            localMinute ~/ 60,
            localMinute % 60,
            offsetMinutes,
          ),
          'offset_minutes': offsetMinutes,
          'value': value,
          'unit': 'bpm',
        },
        observedAt,
      );
      sampleIndex++;
    }
  }

  bool _includeFixtureMinute(int minute, int coveragePercent) {
    if (coveragePercent >= 100) return true;
    if (coveragePercent <= 0) return false;
    return (minute * 37) % 100 < coveragePercent;
  }

  List<SourceRecordEnvelope> _calendarRecords(
    Map<String, Object?> data,
    DateTime observedAt,
  ) => [
    for (final rawEvent in _list(data['events']))
      _record(
        SourceKind.demoCalendar,
        'calendar_event',
        _string(_list(rawEvent)[0]),
        {
          'start': _string(_list(rawEvent)[1]),
          'end': _string(_list(rawEvent)[2]),
          'offset_minutes': _integer(_list(rawEvent)[3]),
          'category': _string(data['category']),
          'recurrence_id': _string(data['recurrence_id']),
        },
        observedAt,
      ),
    for (final rawEvent
        in data['other_events'] == null
            ? const <Object?>[]
            : _list(data['other_events']))
      _record(
        SourceKind.demoCalendar,
        'calendar_event',
        _string(_list(rawEvent)[0]),
        {
          'start': _string(_list(rawEvent)[1]),
          'end': _string(_list(rawEvent)[2]),
          'offset_minutes': _integer(_list(rawEvent)[3]),
          'category': _string(_list(rawEvent)[4]),
          'recurrence_id': _string(_list(rawEvent)[5]),
        },
        observedAt,
      ),
  ];

  List<SourceRecordEnvelope> _manualRecords(
    Map<String, Object?> data,
    DateTime observedAt,
  ) => [
    for (final rawCheckin in _list(data['checkins']))
      _record(
        SourceKind.demoManual,
        'manual_checkin',
        _string(_list(rawCheckin)[0]),
        {
          'timestamp': _string(_list(rawCheckin)[1]),
          'offset_minutes': _integer(_list(rawCheckin)[2]),
          'category': _string(_list(rawCheckin)[3]),
          'value': _object(_list(rawCheckin)[4]),
        },
        observedAt,
      ),
  ];

  SourceRecordEnvelope _record(
    SourceKind source,
    String recordType,
    String stableId,
    Map<String, Object?> payload,
    DateTime observedAt,
  ) => SourceRecordEnvelope(
    source: source,
    recordType: recordType,
    stableSourceId: stableId,
    payload: Map.unmodifiable(payload),
    observedAt: observedAt,
  );

  String _localToUtc(String date, int hour, int minute, int offsetMinutes) =>
      _localDateTime(
        date,
        hour,
        minute,
      ).subtract(Duration(minutes: offsetMinutes)).toUtc().toIso8601String();

  DateTime _localDateTime(String date, int hour, [int minute = 0]) {
    final parts = date.split('-').map(int.parse).toList(growable: false);
    if (parts.length != 3) throw const FormatException('Invalid demo date');
    return DateTime.utc(parts[0], parts[1], parts[2], hour, minute);
  }

  Future<Map<String, Object?>> _readObject(String path) async =>
      _object(jsonDecode(await assets.read(path)));

  Map<String, Object?> _object(Object? value) {
    if (value is! Map) throw const FormatException('Expected fixture object');
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  List<Object?> _list(Object? value) {
    if (value is! List) throw const FormatException('Expected fixture list');
    return value.cast<Object?>();
  }

  String _string(Object? value) {
    if (value is! String || value.isEmpty) {
      throw const FormatException('Expected string');
    }
    return value;
  }

  int _integer(Object? value) {
    if (value is! num || value != value.roundToDouble()) {
      throw const FormatException('Expected integer');
    }
    return value.toInt();
  }

  double _number(Object? value) {
    if (value is! num || !value.toDouble().isFinite) {
      throw const FormatException('Expected number');
    }
    return value.toDouble();
  }
}

final class DemoMeetingProfile {
  const DemoMeetingProfile({
    required this.eventId,
    required this.eventStartUtc,
    required this.eventEndUtc,
    required this.controlDate,
    required this.offsetMinutes,
    required this.baseline,
    required this.difference,
    required this.recoveryMinutes,
    required this.coveragePercent,
  });

  final String eventId;
  final DateTime eventStartUtc;
  final DateTime eventEndUtc;
  final String controlDate;
  final int offsetMinutes;
  final double baseline;
  final double difference;
  final int recoveryMinutes;
  final int coveragePercent;

  Map<String, Object?> toJson() => {
    'event_id': eventId,
    'event_start_utc': eventStartUtc.toIso8601String(),
    'event_end_utc': eventEndUtc.toIso8601String(),
    'control_date': controlDate,
    'offset_minutes': offsetMinutes,
    'baseline': baseline,
    'difference': difference,
    'recovery_minutes': recoveryMinutes,
    'coverage_percent': coveragePercent,
  };

  static DemoMeetingProfile fromJson(Map<String, Object?> value) =>
      DemoMeetingProfile(
        eventId: value['event_id']! as String,
        eventStartUtc: DateTime.parse(value['event_start_utc']! as String),
        eventEndUtc: DateTime.parse(value['event_end_utc']! as String),
        controlDate: value['control_date']! as String,
        offsetMinutes: (value['offset_minutes']! as num).toInt(),
        baseline: (value['baseline']! as num).toDouble(),
        difference: (value['difference']! as num).toDouble(),
        recoveryMinutes: (value['recovery_minutes']! as num).toInt(),
        coveragePercent: (value['coverage_percent']! as num).toInt(),
      );
}
