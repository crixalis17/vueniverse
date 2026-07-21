import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:vueniverse/app/theme.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_scenario_analysis_repository.dart';
import 'package:vueniverse/data/experiments/experiment_repository.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/domain/models/experiment_models.dart';
import 'package:vueniverse/domain/store_kind.dart';

final class HistoryRepository {
  const HistoryRepository(
    this.database, {
    required this.kind,
    required this.experiments,
  });

  final VueniverseDatabase database;
  final StoreKind kind;
  final ExperimentRepository experiments;

  Future<List<HistoryItemData>> load() async {
    final rows = await (database.select(
      database.findingVersions,
    )..orderBy([(row) => OrderingTerm.desc(row.validFrom)])).get();
    final persisted = <HistoryItemData>[
      for (final row in rows)
        HistoryItemData(
          id: row.id,
          title: 'Recurring 1:1 and heart rate',
          subtitle: 'Finding version ${row.version}',
          date: _dateLabel(row.validFrom),
          status: row.status,
          icon: Icons.analytics_outlined,
          accent: _historyColor(row.status),
          invalidated: row.status == 'invalidated',
        ),
    ];
    if (kind != StoreKind.demo) return List.unmodifiable(persisted);

    final scenarios = await DemoScenarioAnalysisRepository(
      database,
    ).loadCurrent();
    final hasPersistedPrimary = persisted.isNotEmpty;
    final lifecycle = <HistoryItemData>[
      for (final scenario in scenarios)
        if (scenario.spec.kind != DemoScenarioKind.illustrative &&
            !(hasPersistedPrimary &&
                scenario.spec.id == 'supported-recurring-pattern'))
          HistoryItemData(
            id: scenario.spec.id,
            title: scenario.spec.historyTitle,
            subtitle: _demoScenarioSubtitle(scenario),
            date: scenario.spec.historyDate,
            status: scenario.historyStatus,
            icon: _demoHistoryIcon(scenario.historyStatus),
            accent: _historyColor(
              scenario.historyStatus.toLowerCase().replaceAll(' ', '_'),
            ),
            invalidated:
                scenario.spec.kind == DemoScenarioKind.lifecycle &&
                scenario.spec.lifecycleState == 'invalidated',
            analysisLabel: scenario.spec.kind == DemoScenarioKind.lifecycle
                ? 'Seeded Snapshot lifecycle receipt'
                : 'Meeting comparison v1',
          ),
    ];
    final protocols = await experiments.loadProtocols();
    final protocolById = {
      for (final protocol in protocols) protocol.id: protocol,
    };
    final resultRows = await database.select(database.experimentResults).get();
    final experimentHistory = <HistoryItemData>[
      for (final result in resultRows)
        if (protocolById[result.experimentProtocolId] case final protocol?
            when result.invalidatedAt == null &&
                protocol.findingVersionId.isEmpty &&
                protocol.status == ExperimentProtocolStatus.completed)
          HistoryItemData(
            id: result.id,
            title: result.experimentProtocolId == 'demo-experiment-inconclusive'
                ? 'Skip caffeine before a 1:1'
                : 'Quiet buffer before a 1:1',
            subtitle: _experimentSubtitle(result.outcome, result.resultJson),
            date: _completedDateLabel(result.createdAt),
            status: _titleCase(result.outcome),
            icon: Icons.science_rounded,
            accent: result.outcome == 'strengthened'
                ? PulseColors.cyan
                : PulseColors.violet,
            analysisLabel: 'Seeded Snapshot experiment result',
          ),
    ];
    return List.unmodifiable([
      ...persisted,
      ...experimentHistory,
      ...lifecycle,
    ]);
  }
}

String _demoScenarioSubtitle(DemoScenarioEvaluation scenario) {
  if (scenario.spec.kind != DemoScenarioKind.calculated) {
    return scenario.spec.historySubtitle;
  }
  final result = scenario.result;
  if (result == null) return 'Current calculation unavailable';
  final excluded = result.excludedByReason.values.fold<int>(
    0,
    (sum, count) => sum + count,
  );
  return [
    '${result.candidateCount} ${result.candidateCount == 1 ? 'meeting' : 'meetings'} checked',
    '${result.includedCount} usable',
    if (excluded > 0) '$excluded excluded',
    if (result.includedCount > 0)
      'usual difference ${_signedBpm(result.medianDifferenceBpm)}',
  ].join(' · ');
}

String _signedBpm(double value) {
  final magnitude = value.abs();
  final formatted = magnitude == magnitude.roundToDouble()
      ? magnitude.toStringAsFixed(0)
      : magnitude.toStringAsFixed(1);
  final sign = value > 0
      ? '+'
      : value < 0
      ? '−'
      : '';
  return '$sign$formatted bpm';
}

String _experimentSubtitle(String outcome, String rawDetails) {
  try {
    final decoded = jsonDecode(rawDetails);
    if (decoded case final Map<Object?, Object?> details) {
      if (outcome == 'strengthened') {
        final change = details['recovery_change_minutes'];
        final eligible = details['eligible_occurrences'];
        if (change is num && eligible is num) {
          return 'Recovery was ${change.abs().round()} minutes faster across ${eligible.round()} eligible meetings';
        }
      }
      if (outcome == 'inconclusive') {
        final eligible = details['eligible_occurrences'];
        final skipped = details['skipped_occurrences'];
        final lowCoverage = details['low_coverage_occurrences'];
        if (eligible is num && skipped is num && lowCoverage is num) {
          return '${eligible.round()} eligible completion · ${skipped.round()} skipped change · ${lowCoverage.round()} low coverage';
        }
      }
    }
  } on FormatException {
    // A malformed receipt keeps a conservative label instead of inventing a
    // result summary.
  }
  return outcome == 'strengthened'
      ? 'Completed personal test receipt'
      : 'The completed test did not have enough eligible data';
}

String _completedDateLabel(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  return 'Completed ${months[local.month - 1]} ${local.day}';
}

String _titleCase(String value) => value.isEmpty
    ? value
    : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.month}/${local.day} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

Color _historyColor(String status) => switch (status) {
  'supported' => PulseColors.lime,
  'developing' => PulseColors.cyan,
  'contradictory' || 'mixed' || 'weakened' => PulseColors.amber,
  'null_finding' => PulseColors.nullBlue,
  'invalidated' || 'expired' => PulseColors.coral,
  'needs_data' => PulseColors.textTertiary,
  'illustrative' => PulseColors.violet,
  _ => PulseColors.textTertiary,
};

IconData _demoHistoryIcon(String status) => switch (status) {
  'Supported' => Icons.monitor_heart_rounded,
  'Developing' => Icons.directions_walk_rounded,
  'Null finding' => Icons.bedtime_rounded,
  'Mixed' || 'Weakened' => Icons.compare_arrows_rounded,
  'Expired' => Icons.flight_outlined,
  'Needs data' => Icons.watch_off_outlined,
  'Illustrative' => Icons.auto_awesome_outlined,
  _ => Icons.analytics_outlined,
};
