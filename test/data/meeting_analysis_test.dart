import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/database/schema_versions.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/replay/moment_replay_repository.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/data/sources/manual_checkin_repository.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';

void main() {
  test(
    'saved coverage reaches analytics and a positive edit blocks promotion',
    () async {
      final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final imported = await DemoImportService(
        DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
      ).importInto(database);
      final analysis = MeetingAnalysisRepository(
        database,
        clock: () => imported.virtualNowUtc,
      );
      final checkins = ManualCheckinRepository(
        database: database,
        canonicalRecords: CanonicalRecordRepository(database),
        normalizer: RecordNormalizer(
          identityKey: 'coverage-test-key'.codeUnits,
        ),
        clock: () => imported.virtualNowUtc,
      );
      final importedRecords = await checkins.load();
      final originalCaffeine = importedRecords.firstWhere(
        (row) => row.category == CheckinCategory.caffeine,
      );
      await checkins.save(
        ManualCheckinRecord(
          id: originalCaffeine.id,
          category: originalCaffeine.category,
          occurredAt: originalCaffeine.occurredAt,
          detail: 'Corrected imported check-in',
          caffeineServings: 1,
        ),
      );
      final afterEdit = await checkins.load();
      expect(afterEdit.length, importedRecords.length);
      expect(
        afterEdit.where((row) => row.id == originalCaffeine.id),
        hasLength(1),
      );
      for (final record in afterEdit) {
        if (record.category == CheckinCategory.caffeine) {
          expect(await checkins.delete(record.id), isTrue);
        }
      }
      final before = await analysis.evaluate();
      final ends = [
        for (final occurrence in before.occurrences.where(
          (row) => row.included,
        )) ...[occurrence.event.startAtUtc, occurrence.controlEndUtc],
      ];
      for (final entry in ends.indexed) {
        await checkins.save(
          ManualCheckinRecord(
            id: 'coverage-${entry.$1}',
            category: CheckinCategory.caffeine,
            occurredAt: imported.virtualNowUtc,
            detail: 'Explicit completed-window report',
            caffeineServings: 0,
            coverageStart: entry.$2.subtract(const Duration(hours: 4)),
            coverageEnd: entry.$2,
          ),
        );
      }
      final clear = await analysis.evaluate();
      expect(clear.state, EvidenceState.supported);
      expect(clear.unresolvedInfluenceCount, 0);
      final loaded = (await checkins.load()).singleWhere(
        (row) => row.id == 'coverage-0',
      );
      await checkins.save(
        ManualCheckinRecord(
          id: loaded.id,
          category: loaded.category,
          occurredAt: loaded.occurredAt,
          detail: 'Corrected intake',
          caffeineServings: 1,
          coverageStart: loaded.coverageStart,
          coverageEnd: loaded.coverageEnd,
        ),
      );
      final changed = await analysis.evaluate();
      expect(changed.state, EvidenceState.developing);
      expect(changed.caffeineExposurePairCount, greaterThan(0));
    },
  );
  test(
    'analysis refresh replaces old-version evidence without source edits',
    () async {
      final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final imported = await DemoImportService(
        DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
      ).importInto(database);
      final now = imported.virtualNowUtc;
      final repository = MeetingAnalysisRepository(database, clock: () => now);
      await database
          .into(database.analysisRuns)
          .insert(
            AnalysisRunsCompanion.insert(
              id: 'legacy-run',
              status: 'completed',
              rangeStartUtc: now.subtract(const Duration(days: 30)),
              rangeEndUtc: now,
              analysisVersion: 1,
              startedAt: now,
              inputHash: 'legacy-input',
            ),
          );
      await database
          .into(database.evidenceBundles)
          .insert(
            EvidenceBundlesCompanion.insert(
              id: 'legacy-evidence',
              analysisRunId: 'legacy-run',
              status: 'supported',
              title: 'Legacy finding',
              claimType: 'repeated_event_heart_rate_difference',
              evidenceHash: 'legacy-v1',
              promotionPolicyVersion: 1,
            ),
          );
      await database
          .into(database.findingVersions)
          .insert(
            FindingVersionsCompanion.insert(
              id: 'recurring-one-to-one-heart-rate:v1',
              findingId: 'recurring-one-to-one-heart-rate',
              evidenceBundleId: 'legacy-evidence',
              version: 1,
              status: 'supported',
              validFrom: now,
            ),
          );
      await database
          .update(database.recomputeJobs)
          .write(const RecomputeJobsCompanion(status: Value('completed')));
      expect(
        await (database.select(
          database.recomputeJobs,
        )..where((row) => row.status.equals('pending'))).get(),
        isEmpty,
      );

      final refreshed = (await repository.runPending())!;
      expect(refreshed.id, isNot('legacy-evidence'));
      final run = await (database.select(
        database.analysisRuns,
      )..where((row) => row.id.equals(refreshed.analysisRunId))).getSingle();
      expect(run.analysisVersion, SchemaVersions.meetingAnalysis);
      final old = await (database.select(
        database.evidenceBundles,
      )..where((row) => row.id.equals('legacy-evidence'))).getSingle();
      expect(old.status, EvidenceState.stale.name);
      expect((await repository.runPending())!.id, refreshed.id);
    },
  );

  test(
    'Demo raw records produce the exact deterministic meeting evidence',
    () async {
      final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final imported = await DemoImportService(
        DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
      ).importInto(database);
      final repository = MeetingAnalysisRepository(
        database,
        clock: () => imported.virtualNowUtc,
      );

      final result = await repository.evaluate();
      // ignore: avoid_print
      print(
        [
          for (final item in result.occurrences)
            '${item.event.startAtUtc.toIso8601String()} '
                'diff=${item.differenceBpm} control=${item.controlStartUtc.toIso8601String()} '
                'excluded=${item.exclusionReason}',
        ].join('\n'),
      );
      expect(result.state, EvidenceState.developing);
      expect(result.candidateCount, 12);
      expect(result.includedCount, 7);
      expect(result.positiveCount, 6);
      expect(result.counterevidenceCount, 1);
      expect(result.excludedByReason.values.fold(0, (a, b) => a + b), 5);
      expect(result.controlsCount, 11);
      expect(result.medianDifferenceBpm, closeTo(11, 0.01));
      expect(result.effectLowerBpm, closeTo(8, 0.01));
      expect(result.effectUpperBpm, closeTo(18, 0.01));
      expect(result.recoveryDurationMinutes, closeTo(39, 0.01));
      expect(result.promotionGates['caffeine_context_reported_zero'], isFalse);
      expect(result.caffeineExposurePairCount, greaterThan(0));
      expect(result.caffeineUnknownPairCount, greaterThan(0));

      final evidence = await repository.runPending(ensureEvidence: true);
      expect(evidence?.status, EvidenceState.developing.name);
      expect(await database.select(database.eventWindows).get(), hasLength(12));
      expect(
        await database.select(database.controlMatches).get(),
        hasLength(11),
      );
      expect(
        await database.select(database.findingVersions).get(),
        hasLength(1),
      );
      final replay = await MomentReplayRepository(database).loadCurrent();
      expect(replay, isNotNull);
      expect(replay!.traces, hasLength(7));
      expect(replay.isUsable, isTrue);
      expect(replay.matchedBaselineBpm, hasLength(3));

      await database.enqueueRecompute(
        dirtyStartUtc: imported.virtualNowUtc.subtract(const Duration(days: 1)),
        dirtyEndUtc: imported.virtualNowUtc,
        reason: 'duplicate_replay',
      );
      await repository.runPending();
      expect(
        await database.select(database.findingVersions).get(),
        hasLength(1),
      );
    },
  );
}
