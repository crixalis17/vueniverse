import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/sources/manual_checkin_repository.dart';
import 'package:vueniverse/data/sources/source_repository.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';

void main() {
  test(
    'bootstrap and repeated manual revisions retain a linear finding history',
    () async {
      final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await database.initialize(kind: StoreKind.live);
      await SourceRepository(database).initializeLiveSources();
      var clock = DateTime.utc(2026, 10, 4, 10);
      final analysis = MeetingAnalysisRepository(database, clock: () => clock);
      final checkins = ManualCheckinRepository(
        database: database,
        canonicalRecords: CanonicalRecordRepository(database),
        normalizer: RecordNormalizer(identityKey: List.filled(32, 19)),
        clock: () => clock,
      );
      await analysis.runPending(ensureEvidence: true);
      for (var revision = 0; revision < 3; revision++) {
        clock = clock.add(const Duration(seconds: 1));
        await checkins.save(
          ManualCheckinRecord(
            id: 'synthetic-repeated-manual-entry',
            category: CheckinCategory.mood,
            occurredAt: DateTime.utc(2026, 10, 4, 9),
            detail: 'Synthetic revision $revision',
          ),
        );
        final evidence = await analysis.runPending();
        expect(evidence?.status, 'insufficientData');
      }
      final versions = await database.select(database.findingVersions).get();
      versions.sort((a, b) => a.version.compareTo(b.version));
      expect(versions.map((row) => row.version), [1, 2, 3, 4]);
      expect(versions.where((row) => row.validUntil == null), hasLength(1));
      expect(versions.first.supersedesId, isNull);
      for (var index = 1; index < versions.length; index++) {
        expect(versions[index].supersedesId, versions[index - 1].id);
        expect(versions[index - 1].validUntil, isNotNull);
      }
      expect((await checkins.load()).single.detail, 'Synthetic revision 2');
      final runs = await database.select(database.analysisRuns).get();
      expect(runs, hasLength(4));
      expect(runs.every((row) => row.status == 'completed'), isTrue);
      expect(
        (await database.select(database.recomputeJobs).get()).every(
          (row) => row.status == 'completed',
        ),
        isTrue,
      );
    },
  );
}
