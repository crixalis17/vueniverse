import 'package:drift/drift.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/domain/models/app_models.dart';

final class MomentReplayRepository {
  const MomentReplayRepository(this.database);

  final WhyPulseDatabase database;

  Future<MomentReplayData?> loadCurrent() async {
    final finding =
        await (database.select(database.findingVersions)
              ..where((row) => row.validUntil.isNull())
              ..orderBy([(row) => OrderingTerm.desc(row.version)]))
            .getSingleOrNull();
    if (finding == null || finding.status == 'invalidated') return null;
    final evidence =
        await (database.select(database.evidenceBundles)
              ..where((row) => row.id.equals(finding.evidenceBundleId)))
            .getSingleOrNull();
    if (evidence == null || evidence.status == 'invalidated') return null;

    final windows =
        await (database.select(database.eventWindows)
              ..where(
                (row) =>
                    row.analysisRunId.equals(evidence.analysisRunId) &
                    row.status.equals('included'),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.startAtUtc)]))
            .get();
    if (windows.isEmpty) return null;

    final traces = <ReplayTraceData>[];
    final controlValues = <double>[];
    for (final window in windows) {
      final metrics = await (database.select(
        database.windowMetrics,
      )..where((row) => row.eventWindowId.equals(window.id))).get();
      final values = {
        for (final metric in metrics) metric.metric: metric.value,
      };
      final pre = values['pre_event_median'];
      final during = values['during_event_median'];
      final recovery = values['recovery_median'];
      final control = values['control_median'];
      if (pre == null ||
          during == null ||
          recovery == null ||
          control == null) {
        continue;
      }
      traces.add(
        ReplayTraceData(
          label: 'Repeat ${traces.length + 1}',
          valuesBpm: [pre, during, recovery],
        ),
      );
      controlValues.add(control);
    }
    if (traces.isEmpty) return null;
    controlValues.sort();
    final midpoint = controlValues.length ~/ 2;
    final baseline = controlValues.length.isOdd
        ? controlValues[midpoint]
        : (controlValues[midpoint - 1] + controlValues[midpoint]) / 2;
    return MomentReplayData(
      phases: const ['Before', 'During', 'Recovery'],
      traces: List.unmodifiable(traces),
      matchedBaselineBpm: List.filled(3, baseline),
      sourceLabel: 'Persisted included event windows · matched controls',
    );
  }
}
