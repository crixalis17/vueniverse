import 'dart:convert';

import 'package:why_pulse/data/analytics/meeting_analysis_repository.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/domain/analytics/meeting_analysis_models.dart';
import 'package:why_pulse/domain/models/canonical_domain_models.dart';

const demoMeetingHeartRateEngine = 'recurring_one_to_one_heart_rate_v1';

enum DemoScenarioKind { calculated, lifecycle, illustrative, experiment }

final class DemoScenarioSpec {
  const DemoScenarioSpec({
    required this.id,
    required this.kind,
    required this.historyTitle,
    required this.historySubtitle,
    required this.historyDate,
    required this.historyStatus,
    required this.videoGuidance,
    required this.eventIds,
    this.engine,
    this.expected,
    this.lifecycleState,
    this.invalidationReason,
  });

  final String id;
  final DemoScenarioKind kind;
  final String historyTitle;
  final String historySubtitle;
  final String historyDate;
  final String historyStatus;
  final String videoGuidance;
  final String? engine;
  final List<String> eventIds;
  final DemoScenarioExpected? expected;
  final String? lifecycleState;
  final String? invalidationReason;

  bool get isCalculated => kind == DemoScenarioKind.calculated;
}

final class DemoScenarioExpected {
  const DemoScenarioExpected({
    required this.state,
    required this.candidateCount,
    required this.includedCount,
    required this.controlCount,
    required this.positiveCount,
    required this.counterevidenceCount,
    required this.excludedCount,
    required this.medianDifferenceBpm,
    required this.effectLowerBpm,
    required this.effectUpperBpm,
    required this.recoveryDurationMinutes,
    required this.excludedByReason,
  });

  final EvidenceState state;
  final int candidateCount;
  final int includedCount;
  final int controlCount;
  final int positiveCount;
  final int counterevidenceCount;
  final int excludedCount;
  final double medianDifferenceBpm;
  final double effectLowerBpm;
  final double effectUpperBpm;
  final double recoveryDurationMinutes;
  final Map<String, int> excludedByReason;
}

final class DemoScenarioEvaluation {
  const DemoScenarioEvaluation({required this.spec, this.result});

  final DemoScenarioSpec spec;
  final MeetingAnalysisResult? result;

  bool get isCalculated => result != null;

  String get historyStatus => switch (result?.state) {
    EvidenceState.supported => 'Supported',
    EvidenceState.developing => 'Developing',
    EvidenceState.nullFinding => 'Null finding',
    EvidenceState.contradictory => 'Mixed',
    EvidenceState.insufficientData => 'Needs data',
    EvidenceState.stale => 'Stale',
    EvidenceState.invalidated => 'Expired',
    null => spec.historyStatus,
  };
}

final class DemoScenarioAnalysisRepository {
  DemoScenarioAnalysisRepository(
    this.database, {
    MeetingAnalysisRepository? analysis,
  }) : analysis = analysis ?? MeetingAnalysisRepository(database);

  final WhyPulseDatabase database;
  final MeetingAnalysisRepository analysis;

  Future<List<DemoScenarioEvaluation>> loadValidated() =>
      _load(validateExpectedOutput: true);

  /// Re-evaluates scenario subsets against the current Demo store without
  /// requiring the untouched fixture-v3 outputs. Demo check-in edits are
  /// allowed to change those results and must not make the next startup fail.
  Future<List<DemoScenarioEvaluation>> loadCurrent() =>
      _load(validateExpectedOutput: false);

  Future<List<DemoScenarioEvaluation>> _load({
    required bool validateExpectedOutput,
  }) async {
    final specs = await _loadSpecs();
    _validateUniqueIds(specs);
    final canonicalIds = await _resolveCanonicalEventIds(specs);
    final evaluations = <DemoScenarioEvaluation>[];
    for (final spec in specs) {
      _validateShape(spec);
      if (!spec.isCalculated) {
        evaluations.add(DemoScenarioEvaluation(spec: spec));
        continue;
      }
      final resolved = <String>{
        for (final rawId in spec.eventIds)
          if (canonicalIds[rawId] case final canonicalId?) canonicalId,
      };
      if (resolved.length != spec.eventIds.length) {
        final missing = spec.eventIds
            .where((rawId) => !canonicalIds.containsKey(rawId))
            .toList(growable: false);
        throw DemoScenarioContractException(
          spec.id,
          'Fixture event IDs did not resolve: ${missing.join(', ')}',
        );
      }
      final result = await analysis.evaluate(eventIds: resolved);
      if (validateExpectedOutput) _validateResult(spec, result);
      evaluations.add(DemoScenarioEvaluation(spec: spec, result: result));
    }
    return List.unmodifiable(evaluations);
  }

  Future<List<DemoScenarioSpec>> _loadSpecs() async {
    final metadata = await (database.select(
      database.storeMetadata,
    )..where((row) => row.key.equals('demo_analysis_cases'))).getSingleOrNull();
    if (metadata == null) {
      throw const DemoScenarioContractException(
        'demo_analysis_cases',
        'Demo scenario metadata is missing.',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(metadata.value);
    } on FormatException {
      throw const DemoScenarioContractException(
        'demo_analysis_cases',
        'Demo scenario metadata is not valid JSON.',
      );
    }
    if (decoded is! List) {
      throw const DemoScenarioContractException(
        'demo_analysis_cases',
        'Demo scenario metadata must be a list.',
      );
    }
    return List.unmodifiable([
      for (final value in decoded) _parseSpec(_object(value, 'scenario')),
    ]);
  }

  DemoScenarioSpec _parseSpec(Map<String, Object?> value) {
    final id = _string(value, 'id');
    final kindName = _string(value, 'kind');
    final kind = DemoScenarioKind.values
        .where((candidate) => candidate.name == kindName)
        .firstOrNull;
    if (kind == null || kind == DemoScenarioKind.experiment) {
      throw DemoScenarioContractException(id, 'Unsupported kind: $kindName');
    }
    final expectedValue = value['expected'];
    return DemoScenarioSpec(
      id: id,
      kind: kind,
      historyTitle: _string(value, 'history_title'),
      historySubtitle: _string(value, 'history_subtitle'),
      historyDate: _string(value, 'history_date'),
      historyStatus: _string(value, 'history_status'),
      videoGuidance: _string(value, 'video_guidance'),
      engine: _optionalString(value['engine']),
      eventIds: List.unmodifiable(
        _optionalList(
          value['event_ids'],
        ).map((item) => _nonEmptyString(item, '$id.event_ids')),
      ),
      expected: expectedValue == null
          ? null
          : _parseExpected(id, _object(expectedValue, '$id.expected')),
      lifecycleState: _optionalString(value['lifecycle_state']),
      invalidationReason: _optionalString(value['invalidation_reason']),
    );
  }

  DemoScenarioExpected _parseExpected(String id, Map<String, Object?> value) {
    final stateName = _string(value, 'state');
    final state = EvidenceState.values
        .where((candidate) => candidate.name == stateName)
        .firstOrNull;
    if (state == null) {
      throw DemoScenarioContractException(id, 'Unknown state: $stateName');
    }
    final exclusions = _object(
      value['excluded_by_reason'],
      '$id.expected.excluded_by_reason',
    );
    return DemoScenarioExpected(
      state: state,
      candidateCount: _integer(value, 'candidate_count'),
      includedCount: _integer(value, 'included_count'),
      controlCount: _integer(value, 'control_count'),
      positiveCount: _integer(value, 'positive_count'),
      counterevidenceCount: _integer(value, 'counterevidence_count'),
      excludedCount: _integer(value, 'excluded_count'),
      medianDifferenceBpm: _number(value, 'median_difference_bpm'),
      effectLowerBpm: _number(value, 'effect_lower_bpm'),
      effectUpperBpm: _number(value, 'effect_upper_bpm'),
      recoveryDurationMinutes: _number(value, 'recovery_duration_minutes'),
      excludedByReason: Map.unmodifiable({
        for (final entry in exclusions.entries)
          entry.key: _wholeNumber(
            entry.value,
            '$id.expected.excluded_by_reason.${entry.key}',
          ),
      }),
    );
  }

  Future<Map<String, String>> _resolveCanonicalEventIds(
    List<DemoScenarioSpec> specs,
  ) async {
    final requiredIds = specs
        .where((spec) => spec.isCalculated)
        .expand((spec) => spec.eventIds)
        .toSet();
    if (requiredIds.isEmpty) return const {};
    final profileMetadata =
        await (database.select(database.storeMetadata)
              ..where((row) => row.key.equals('demo_meeting_profiles')))
            .getSingleOrNull();
    if (profileMetadata == null) {
      throw const DemoScenarioContractException(
        'demo_meeting_profiles',
        'Meeting profile metadata is missing.',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(profileMetadata.value);
    } on FormatException {
      throw const DemoScenarioContractException(
        'demo_meeting_profiles',
        'Meeting profile metadata is not valid JSON.',
      );
    }
    if (decoded is! List) {
      throw const DemoScenarioContractException(
        'demo_meeting_profiles',
        'Meeting profile metadata must be a list.',
      );
    }
    final eventIdByStart = <DateTime, String>{};
    for (final value in decoded) {
      final profile = _object(value, 'demo_meeting_profiles');
      final rawId = profile['event_id'];
      final start = profile['event_start_utc'];
      if (rawId is! String ||
          start is! String ||
          !requiredIds.contains(rawId)) {
        continue;
      }
      final parsed = DateTime.tryParse(start);
      if (parsed == null) {
        throw DemoScenarioContractException(
          rawId,
          'Meeting profile has an invalid start timestamp.',
        );
      }
      eventIdByStart[parsed.toUtc()] = rawId;
    }
    final contexts = await database.select(database.contextEvents).get();
    final result = <String, String>{};
    for (final context in contexts) {
      final rawId = eventIdByStart[context.startAtUtc.toUtc()];
      if (rawId == null) continue;
      if (result.containsKey(rawId)) {
        throw DemoScenarioContractException(
          rawId,
          'Multiple canonical context events matched one fixture event.',
        );
      }
      result[rawId] = context.id;
    }
    return Map.unmodifiable(result);
  }

  void _validateUniqueIds(List<DemoScenarioSpec> specs) {
    final seen = <String>{};
    for (final spec in specs) {
      if (!seen.add(spec.id)) {
        throw DemoScenarioContractException(
          spec.id,
          'Scenario IDs must be unique.',
        );
      }
    }
  }

  void _validateShape(DemoScenarioSpec spec) {
    if (spec.videoGuidance.length < 20) {
      throw DemoScenarioContractException(
        spec.id,
        'Video guidance must explain how to present the scenario.',
      );
    }
    if (spec.isCalculated) {
      if (spec.engine != demoMeetingHeartRateEngine) {
        throw DemoScenarioContractException(
          spec.id,
          'Calculated scenarios must name $demoMeetingHeartRateEngine.',
        );
      }
      if (spec.eventIds.isEmpty ||
          spec.eventIds.toSet().length != spec.eventIds.length) {
        throw DemoScenarioContractException(
          spec.id,
          'Calculated scenarios need unique fixture event IDs.',
        );
      }
      if (spec.expected == null) {
        throw DemoScenarioContractException(
          spec.id,
          'Calculated scenarios need exact expected output.',
        );
      }
      return;
    }
    if (spec.engine != null ||
        spec.eventIds.isNotEmpty ||
        spec.expected != null) {
      throw DemoScenarioContractException(
        spec.id,
        'Only calculated scenarios may declare an engine, events, or output.',
      );
    }
    if (spec.kind == DemoScenarioKind.lifecycle &&
        spec.lifecycleState == null) {
      throw DemoScenarioContractException(
        spec.id,
        'Lifecycle scenarios need an explicit state.',
      );
    }
    if (spec.kind == DemoScenarioKind.lifecycle &&
        spec.lifecycleState == 'invalidated' &&
        spec.invalidationReason == null) {
      throw DemoScenarioContractException(
        spec.id,
        'Invalidated lifecycle scenarios need an invalidation reason.',
      );
    }
    if (spec.kind == DemoScenarioKind.illustrative &&
        spec.historyStatus != 'Illustrative') {
      throw DemoScenarioContractException(
        spec.id,
        'Illustrative scenarios must be labelled Illustrative.',
      );
    }
  }

  void _validateResult(DemoScenarioSpec spec, MeetingAnalysisResult result) {
    final expected = spec.expected!;
    final mismatches = <String>[];
    void exact(String name, Object actual, Object wanted) {
      if (actual != wanted) mismatches.add('$name=$actual (expected $wanted)');
    }

    void close(String name, double actual, double wanted) {
      if ((actual - wanted).abs() > 0.001) {
        mismatches.add('$name=$actual (expected $wanted)');
      }
    }

    exact('state', result.state.name, expected.state.name);
    exact('candidate_count', result.candidateCount, expected.candidateCount);
    exact('included_count', result.includedCount, expected.includedCount);
    exact('control_count', result.controlsCount, expected.controlCount);
    exact('positive_count', result.positiveCount, expected.positiveCount);
    exact(
      'counterevidence_count',
      result.counterevidenceCount,
      expected.counterevidenceCount,
    );
    final excludedCount = result.excludedByReason.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    exact('excluded_count', excludedCount, expected.excludedCount);
    final exclusionsMatch =
        result.excludedByReason.length == expected.excludedByReason.length &&
        expected.excludedByReason.entries.every(
          (entry) => result.excludedByReason[entry.key] == entry.value,
        );
    if (!exclusionsMatch) {
      mismatches.add(
        'excluded_by_reason=${result.excludedByReason} '
        '(expected ${expected.excludedByReason})',
      );
    }
    close(
      'median_difference_bpm',
      result.medianDifferenceBpm,
      expected.medianDifferenceBpm,
    );
    close('effect_lower_bpm', result.effectLowerBpm, expected.effectLowerBpm);
    close('effect_upper_bpm', result.effectUpperBpm, expected.effectUpperBpm);
    close(
      'recovery_duration_minutes',
      result.recoveryDurationMinutes,
      expected.recoveryDurationMinutes,
    );
    final actualHistoryStatus = DemoScenarioEvaluation(
      spec: spec,
      result: result,
    ).historyStatus;
    exact('history_status', actualHistoryStatus, spec.historyStatus);
    if (mismatches.isNotEmpty) {
      throw DemoScenarioContractException(spec.id, mismatches.join('; '));
    }
  }

  Map<String, Object?> _object(Object? value, String field) {
    if (value is! Map) {
      throw DemoScenarioContractException(field, 'Expected an object.');
    }
    return {for (final entry in value.entries) '${entry.key}': entry.value};
  }

  String _string(Map<String, Object?> value, String key) =>
      _nonEmptyString(value[key], key);

  String _nonEmptyString(Object? value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw DemoScenarioContractException(
        field,
        'Expected a non-empty string.',
      );
    }
    return value.trim();
  }

  String? _optionalString(Object? value) {
    if (value == null) return null;
    return _nonEmptyString(value, 'optional_string');
  }

  List<Object?> _optionalList(Object? value) {
    if (value == null) return const [];
    if (value is! List) {
      throw const DemoScenarioContractException(
        'event_ids',
        'Expected a list.',
      );
    }
    return value.cast<Object?>();
  }

  int _integer(Map<String, Object?> value, String key) =>
      _wholeNumber(value[key], key);

  int _wholeNumber(Object? value, String field) {
    if (value is! num || value != value.roundToDouble()) {
      throw DemoScenarioContractException(field, 'Expected an integer.');
    }
    return value.toInt();
  }

  double _number(Map<String, Object?> value, String key) {
    final item = value[key];
    if (item is! num || !item.toDouble().isFinite) {
      throw DemoScenarioContractException(key, 'Expected a finite number.');
    }
    return item.toDouble();
  }
}

final class DemoScenarioContractException implements Exception {
  const DemoScenarioContractException(this.scenarioId, this.message);

  final String scenarioId;
  final String message;

  @override
  String toString() => 'Demo scenario $scenarioId: $message';
}
