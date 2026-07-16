import 'package:drift/drift.dart';
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/demo/demo_fixtures.dart';
import 'package:why_pulse/data/normalization/record_normalizer.dart';
import 'package:why_pulse/data/repositories/canonical_record_repository.dart';
import 'package:why_pulse/domain/models/canonical_domain_models.dart';
import 'package:why_pulse/domain/store_kind.dart';

final class DemoImportService {
  const DemoImportService(this.fixtureLoader);

  final DemoFixtureLoader fixtureLoader;

  Future<DemoImportResult> importInto(WhyPulseDatabase database) async {
    final fixture = await fixtureLoader.load();
    await database.initialize(kind: StoreKind.demo);
    final normalizer = RecordNormalizer(identityKey: fixture.identityKey);
    final repository = CanonicalRecordRepository(database);

    final health = await repository.importRecords(
      sourceConnectionId: 'demo-health-v${fixture.fixtureVersion}',
      sourceKind: SourceKind.demoHealth,
      records: fixture.healthRecords.where(
        (record) =>
            !(record.stableSourceId?.contains('-window-') ?? false) &&
            !(record.stableSourceId?.contains('-control-') ?? false),
      ),
      normalizer: normalizer,
      syncRunId: 'demo-health-import-v${fixture.fixtureVersion}',
    );
    final calendar = await repository.importRecords(
      sourceConnectionId: 'demo-calendar-v${fixture.fixtureVersion}',
      sourceKind: SourceKind.demoCalendar,
      records: fixture.calendarRecords.where(
        (record) => !(record.stableSourceId?.contains('-future-') ?? false),
      ),
      normalizer: normalizer,
      syncRunId: 'demo-calendar-import-v${fixture.fixtureVersion}',
    );
    final manual = await repository.importRecords(
      sourceConnectionId: 'demo-manual-v${fixture.fixtureVersion}',
      sourceKind: SourceKind.demoManual,
      records: fixture.manualRecords,
      normalizer: normalizer,
      syncRunId: 'demo-manual-import-v${fixture.fixtureVersion}',
    );

    await database.transaction(() async {
      final now = fixture.clock.now();
      await database
          .into(database.storeMetadata)
          .insertOnConflictUpdate(
            StoreMetadataCompanion.insert(
              key: 'demo_virtual_clock',
              value: now.toIso8601String(),
              updatedAt: Value(now),
            ),
          );
      await database
          .into(database.storeMetadata)
          .insertOnConflictUpdate(
            StoreMetadataCompanion.insert(
              key: 'demo_meeting_profiles',
              value: canonicalJsonEncode(
                fixture.meetingProfiles
                    .map((profile) => profile.toJson())
                    .toList(),
              ),
              updatedAt: Value(now),
            ),
          );
      await database
          .into(database.storeMetadata)
          .insertOnConflictUpdate(
            StoreMetadataCompanion.insert(
              key: 'demo_expected_outputs',
              value: canonicalJsonEncode(fixture.expectedOutputs),
              updatedAt: Value(now),
            ),
          );
      await database
          .into(database.storeMetadata)
          .insertOnConflictUpdate(
            StoreMetadataCompanion.insert(
              key: 'demo_analysis_cases',
              value: canonicalJsonEncode(fixture.analysisCases),
              updatedAt: Value(now),
            ),
          );

      for (final experiment in fixture.experiments) {
        await database
            .into(database.experimentProtocols)
            .insertOnConflictUpdate(
              ExperimentProtocolsCompanion.insert(
                id: experiment['id']! as String,
                title: experiment['title']! as String,
                status: experiment['status']! as String,
                protocolJson: canonicalJsonEncode(experiment),
                version: experiment['version']! as int,
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }
    });

    return DemoImportResult(
      fixtureVersion: fixture.fixtureVersion,
      virtualNowUtc: fixture.clock.now(),
      canonicalHash: await database.canonicalDataHash(),
      sourceReports: {'health': health, 'calendar': calendar, 'manual': manual},
    );
  }
}

final class DemoImportResult {
  const DemoImportResult({
    required this.fixtureVersion,
    required this.virtualNowUtc,
    required this.canonicalHash,
    required this.sourceReports,
  });

  final int fixtureVersion;
  final DateTime virtualNowUtc;
  final String canonicalHash;
  final Map<String, IngestionReport> sourceReports;
}
