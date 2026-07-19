import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/normalization/record_normalizer.dart';
import 'package:why_pulse/data/repositories/canonical_record_repository.dart';
import 'package:why_pulse/domain/models/canonical_domain_models.dart';
import 'package:why_pulse/domain/store_kind.dart';

void main() {
  late WhyPulseDatabase database;

  setUp(() async {
    database = WhyPulseDatabase.forTesting(NativeDatabase.memory());
    await database.initialize(kind: StoreKind.demo);
  });

  tearDown(() => database.close());

  SourceRecordEnvelope heartRate(double value) => SourceRecordEnvelope(
    source: SourceKind.demoHealth,
    recordType: 'heart_rate',
    stableSourceId: 'stable-heart-id',
    observedAt: DateTime.utc(2026, 7, 16, 12),
    payload: {
      'timestamp': '2026-07-16T10:00:00Z',
      'offset_minutes': 0,
      'value': value,
      'unit': 'bpm',
    },
  );

  test(
    'duplicate imports are idempotent and changed records replace',
    () async {
      final repository = CanonicalRecordRepository(database);
      final normalizer = RecordNormalizer(identityKey: 'demo-key'.codeUnits);
      final first = await repository.importRecords(
        sourceConnectionId: 'demo-health',
        sourceKind: SourceKind.demoHealth,
        records: [heartRate(70)],
        normalizer: normalizer,
        syncRunId: 'sync-1',
      );
      final duplicate = await repository.importRecords(
        sourceConnectionId: 'demo-health',
        sourceKind: SourceKind.demoHealth,
        records: [heartRate(70)],
        normalizer: normalizer,
        syncRunId: 'sync-2',
      );

      expect(first.inserted, 1);
      expect(duplicate.duplicates, 1);
      expect(await database.select(database.signalSamples).get(), hasLength(1));

      final indexed = await database
          .select(database.rawRecordIndex)
          .getSingle();
      await database
          .into(database.analysisRuns)
          .insert(
            AnalysisRunsCompanion.insert(
              id: 'analysis-1',
              status: 'completed',
              rangeStartUtc: DateTime.utc(2026, 7, 15),
              rangeEndUtc: DateTime.utc(2026, 7, 17),
              analysisVersion: 1,
              startedAt: DateTime.utc(2026, 7, 16),
              inputHash: 'input',
              outputHash: const Value('output'),
            ),
          );
      await database
          .into(database.evidenceBundles)
          .insert(
            EvidenceBundlesCompanion.insert(
              id: 'evidence-1',
              analysisRunId: 'analysis-1',
              status: 'supported',
              title: 'Fixture evidence',
              claimType: 'association',
              evidenceHash: 'evidence-hash',
              promotionPolicyVersion: 1,
            ),
          );
      await database
          .into(database.evidenceDependencies)
          .insert(
            EvidenceDependenciesCompanion.insert(
              id: 'dependency-1',
              evidenceBundleId: 'evidence-1',
              dependencyKind: 'signal_sample',
              dependencyId: indexed.canonicalId,
              dependencyHash: indexed.canonicalPayloadHash,
            ),
          );

      final changed = await repository.importRecords(
        sourceConnectionId: 'demo-health',
        sourceKind: SourceKind.demoHealth,
        records: [heartRate(72)],
        normalizer: normalizer,
        syncRunId: 'sync-3',
      );
      expect(changed.changed, 1);
      expect(
        (await database.select(database.signalSamples).getSingle()).value,
        72,
      );
      final evidence = await database
          .select(database.evidenceBundles)
          .getSingle();
      expect(evidence.status, 'stale');
      expect(evidence.staleReason, 'source_record_changed');
    },
  );

  test(
    'restart recovery returns running jobs to pending and coalesces overlaps',
    () async {
      await database
          .into(database.recomputeJobs)
          .insert(
            RecomputeJobsCompanion.insert(
              id: 'job-1',
              dirtyStartUtc: DateTime.utc(2026, 7, 1),
              dirtyEndUtc: DateTime.utc(2026, 7, 5),
              reason: 'sync',
              status: 'running',
              analysisVersion: 1,
            ),
          );
      await database
          .into(database.recomputeJobs)
          .insert(
            RecomputeJobsCompanion.insert(
              id: 'job-2',
              dirtyStartUtc: DateTime.utc(2026, 7, 4),
              dirtyEndUtc: DateTime.utc(2026, 7, 8),
              reason: 'changed',
              status: 'pending',
              analysisVersion: 1,
            ),
          );

      await database.recoverRecomputeJobs();
      final jobs = await database.select(database.recomputeJobs).get();
      expect(jobs, hasLength(1));
      expect(jobs.single.status, 'pending');
      expect(jobs.single.dirtyStartUtc, DateTime.utc(2026, 7, 1));
      expect(jobs.single.dirtyEndUtc, DateTime.utc(2026, 7, 8));
      expect(jobs.single.reason.split(','), containsAll(['changed', 'sync']));
    },
  );

  test('all required schema version values are persisted', () async {
    final metadata = {
      for (final row in await database.select(database.storeMetadata).get())
        row.key: row.value,
    };
    expect(metadata['store_kind'], 'demo');
    expect(metadata['database_schema_version'], '2');
    expect(metadata['normalization_version'], '1');
    expect(metadata['meeting_analysis_version'], '1');
    expect(metadata['promotion_policy_version'], '1');
    expect(metadata['demo_fixture_version'], '2');
    expect(metadata['explorer_schema_version'], '1');
    expect(metadata['explainer_schema_version'], '2');
    expect(metadata['prompt_version'], '1');
    expect(metadata['output_guard_version'], '2');
    expect(metadata['export_schema_version'], '1');
  });
}
