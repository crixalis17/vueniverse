import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/replay/moment_replay_repository.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

void main() {
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
      expect(result.state, EvidenceState.supported);
      expect(result.candidateCount, 12);
      expect(result.includedCount, 8);
      expect(result.positiveCount, 6);
      expect(result.counterevidenceCount, 2);
      expect(result.excludedByReason.values.fold(0, (a, b) => a + b), 4);
      expect(result.controlsCount, 12);
      expect(result.medianDifferenceBpm, closeTo(11, 0.01));
      expect(result.effectLowerBpm, closeTo(8, 0.01));
      expect(result.effectUpperBpm, closeTo(14, 0.01));
      expect(result.recoveryDurationMinutes, closeTo(42, 0.01));
      expect(result.promotionGates.values, everyElement(isTrue));

      final evidence = await repository.runPending(ensureEvidence: true);
      expect(evidence?.status, EvidenceState.supported.name);
      expect(await database.select(database.eventWindows).get(), hasLength(12));
      expect(
        await database.select(database.controlMatches).get(),
        hasLength(12),
      );
      expect(
        await database.select(database.findingVersions).get(),
        hasLength(1),
      );
      final replay = await MomentReplayRepository(database).loadCurrent();
      expect(replay, isNotNull);
      expect(replay!.traces, hasLength(8));
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
