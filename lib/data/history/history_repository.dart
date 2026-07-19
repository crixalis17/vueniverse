import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:why_pulse/app/theme.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/experiments/experiment_repository.dart';
import 'package:why_pulse/domain/models/app_models.dart';
import 'package:why_pulse/domain/models/experiment_models.dart';
import 'package:why_pulse/domain/store_kind.dart';

final class HistoryRepository {
  const HistoryRepository(
    this.database, {
    required this.kind,
    required this.experiments,
  });

  final WhyPulseDatabase database;
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

    final metadata = await (database.select(
      database.storeMetadata,
    )..where((row) => row.key.equals('demo_analysis_cases'))).getSingleOrNull();
    final cases = <Map<String, Object?>>[];
    if (metadata != null) {
      try {
        final decoded = jsonDecode(metadata.value);
        if (decoded is List) {
          for (final item in decoded.whereType<Map>()) {
            cases.add(item.cast<String, Object?>());
          }
        }
      } on FormatException {
        // Corrupt Demo metadata is omitted instead of inventing history rows.
      }
    }
    final hasPersistedSupported = persisted.any(
      (item) => item.status.toLowerCase() == 'supported',
    );
    final lifecycle = <HistoryItemData>[
      for (final item in cases)
        if (item['history_status'] case final String status)
          if (!(hasPersistedSupported &&
              item['id'] == 'supported-recurring-pattern'))
            HistoryItemData(
              id:
                  item['id'] as String? ??
                  'demo-history-${item['expected_state'] ?? 'case'}',
              title: item['history_title'] as String? ?? 'Demo evidence case',
              subtitle:
                  item['history_subtitle'] as String? ??
                  'Deterministic fictional evidence lifecycle fixture',
              date: item['history_date'] as String? ?? 'Demo fixture',
              status: status,
              icon: _demoHistoryIcon(status),
              accent: _historyColor(status.toLowerCase().replaceAll(' ', '_')),
              invalidated: status == 'Expired',
            ),
    ];
    final protocols = await experiments.loadProtocols();
    final experimentHistory = <HistoryItemData>[
      for (final protocol in protocols)
        if (protocol.findingVersionId.isEmpty &&
            protocol.status == ExperimentProtocolStatus.completed)
          HistoryItemData(
            id: protocol.id,
            title: 'Quiet-buffer experiment',
            subtitle: protocol.id.contains('inconclusive')
                ? 'The test remained inconclusive after missing context'
                : 'Recovery was 9 minutes faster with the buffer',
            date: 'Completed Jul 12',
            status: protocol.id.contains('inconclusive')
                ? 'Inconclusive'
                : 'Strengthened',
            icon: Icons.science_rounded,
            accent: PulseColors.cyan,
          ),
    ];
    return List.unmodifiable([
      ...persisted,
      ...experimentHistory,
      ...lifecycle,
    ]);
  }
}

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.month}/${local.day} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

Color _historyColor(String status) => switch (status) {
  'supported' => PulseColors.lime,
  'developing' => PulseColors.cyan,
  'contradictory' || 'weakened' => PulseColors.amber,
  'null_finding' => PulseColors.nullBlue,
  'invalidated' || 'expired' => PulseColors.coral,
  'needs_data' => PulseColors.textTertiary,
  _ => PulseColors.textTertiary,
};

IconData _demoHistoryIcon(String status) => switch (status) {
  'Supported' => Icons.monitor_heart_rounded,
  'Developing' => Icons.directions_walk_rounded,
  'Null finding' => Icons.bedtime_rounded,
  'Weakened' => Icons.nights_stay_outlined,
  'Expired' => Icons.flight_outlined,
  'Needs data' => Icons.watch_off_outlined,
  _ => Icons.analytics_outlined,
};
