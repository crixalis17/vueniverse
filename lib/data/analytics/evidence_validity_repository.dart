import 'package:drift/drift.dart';
import 'package:vueniverse/data/database/schema_versions.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';

/// Read-only freshness checks. Historical evidence and user records are retained.
final class EvidenceValidityRepository {
  const EvidenceValidityRepository(this.database);
  final VueniverseDatabase database;

  Future<bool> isCurrent(EvidenceBundleRow evidence) async =>
      await staleReason(evidence) == null;

  Future<String?> staleReason(EvidenceBundleRow evidence) async {
    final row = await (database.select(
      database.evidenceBundles,
    )..where((row) => row.id.equals(evidence.id))).getSingleOrNull();
    if (row == null) return 'evidence_unavailable';
    if (row.status == 'invalidated' || row.status == 'stale') return row.status;
    final run = await (database.select(
      database.analysisRuns,
    )..where((item) => item.id.equals(row.analysisRunId))).getSingleOrNull();
    if (run == null || run.status != 'completed') return 'analysis_unavailable';
    if (run.analysisVersion != SchemaVersions.meetingAnalysis ||
        row.promotionPolicyVersion != SchemaVersions.promotionPolicy) {
      return 'analysis_policy_changed';
    }
    if (run.inputHash != await database.canonicalDataHash()) {
      return 'canonical_inputs_changed';
    }
    final finding =
        await (database.select(database.findingVersions)
              ..where(
                (item) =>
                    item.evidenceBundleId.equals(row.id) &
                    item.validUntil.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    if (finding == null ||
        finding.status == 'invalidated' ||
        finding.status == 'stale') {
      return 'finding_superseded';
    }
    return null;
  }

  Future<EvidenceBundleRow?> load(String id) async {
    final row = await (database.select(
      database.evidenceBundles,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    return row != null && await isCurrent(row) ? row : null;
  }
}
