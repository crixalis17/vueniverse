import 'package:vueniverse/app/app_preferences.dart';

// ignore_for_file: prefer_initializing_formals
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/database/schema_versions.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/demo/demo_scenario_analysis_repository.dart';
import 'package:vueniverse/data/experiments/experiment_repository.dart';
import 'package:vueniverse/data/exports/evidence_export_service.dart';
import 'package:vueniverse/data/model_runtime/evidence_projection_repository.dart';
import 'package:vueniverse/data/model_runtime/explanation_repository.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/security/store_security_gateway.dart';
import 'package:vueniverse/data/sources/manual_checkin_repository.dart';
import 'package:vueniverse/data/sources/source_platform_gateway.dart';
import 'package:vueniverse/data/sources/source_repository.dart';
import 'package:vueniverse/data/sources/source_sync_service.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/domain/model_runtime/explanation_coordinator.dart';
import 'package:vueniverse/domain/model_runtime/explorer_coordinator.dart';

final class StoreCoordinator {
  StoreCoordinator({
    required StoreSecurityGateway security,
    required AppPreferences preferences,
    required DemoImportService demoImporter,
    SourcePlatformGateway? sourcePlatform,
  }) : _security = security,
       _preferences = preferences,
       _demoImporter = demoImporter,
       _sourcePlatform = sourcePlatform ?? PigeonSourcePlatformGateway();

  final StoreSecurityGateway _security;
  final AppPreferences _preferences;
  final DemoImportService _demoImporter;
  final SourcePlatformGateway _sourcePlatform;

  RepositoryGraph? _active;

  RepositoryGraph? get active => _active;

  Future<RepositoryGraph> initialize() async {
    final preferred = await _preferences.getActiveMode();
    return switchTo(preferred);
  }

  Future<RepositoryGraph> switchTo(StoreKind kind) async {
    if (_active?.kind == kind) return _active!;
    await _closeActive();
    final material = await _security.open(kind);
    final database = VueniverseDatabase.encrypted(
      path: material.databasePath,
      passphrase: material.passphrase,
    );
    try {
      if (kind == StoreKind.demo && !material.databaseIsNew) {
        final storedFixture =
            await (database.select(database.storeMetadata)
                  ..where((row) => row.key.equals('demo_fixture_version')))
                .getSingleOrNull();
        if (storedFixture?.value != SchemaVersions.demoFixture.toString()) {
          await database.close();
          await _security.delete(StoreKind.demo);
          return switchTo(StoreKind.demo);
        }
      }
      await database.initialize(kind: kind);
      DemoImportResult? demoImport;
      if (kind == StoreKind.demo && material.databaseIsNew) {
        demoImport = await _demoImporter.importInto(database);
      } else if (kind == StoreKind.demo) {
        demoImport = await _demoImporter.restoreFrom(database);
        if (demoImport == null ||
            demoImport.fixtureVersion != SchemaVersions.demoFixture) {
          await database.close();
          await _security.delete(StoreKind.demo);
          return switchTo(StoreKind.demo);
        }
      }
      final identityKey = await database.getOrCreateSourceIdentityKey();
      final normalizer = RecordNormalizer(identityKey: identityKey);
      final canonicalRecords = CanonicalRecordRepository(database);
      final sourceRepository = SourceRepository(database);
      final demoNow = demoImport?.virtualNowUtc;
      final analysis = MeetingAnalysisRepository(
        database,
        clock: demoNow == null ? null : () => demoNow,
      );
      final explanationRepository = ExplanationRepository(database);
      final explanationCoordinator = ExplanationCoordinator(
        storeKind: kind,
        projections: EvidenceProjectionRepository(database),
        repository: explanationRepository,
      );
      final explorerCoordinator = ExplorerCoordinator(storeKind: kind);
      final graph = RepositoryGraph(
        kind: kind,
        databasePath: material.databasePath,
        database: database,
        canonicalRecords: canonicalRecords,
        sourceRepository: sourceRepository,
        sourceSync: SourceSyncService(
          platform: _sourcePlatform,
          sources: sourceRepository,
          canonicalRecords: canonicalRecords,
          normalizer: normalizer,
        ),
        manualCheckins: ManualCheckinRepository(
          database: database,
          canonicalRecords: canonicalRecords,
          normalizer: normalizer,
        ),
        analysis: analysis,
        experiments: ExperimentRepository(database),
        exports: EvidenceExportService(
          database,
          directoryPath: '${material.databasePath}.exports',
        ),
        explanationRepository: explanationRepository,
        explanationCoordinator: explanationCoordinator,
        explorerCoordinator: explorerCoordinator,
        demoImport: demoImport,
      );
      await analysis.runPending(ensureEvidence: true);
      if (kind == StoreKind.demo && material.databaseIsNew) {
        await DemoScenarioAnalysisRepository(
          database,
          analysis: analysis,
        ).loadValidated();
      }
      await _preferences.setActiveMode(kind);
      _active = graph;
      return graph;
    } on Object catch (error, stackTrace) {
      await database.close();
      if (kind == StoreKind.demo && material.databaseIsNew) {
        try {
          await _security.delete(StoreKind.demo);
        } on Object {
          // Preserve the initialization error. A later reset can retry cleanup.
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<RepositoryGraph> resetDemo() async {
    await _closeActive();
    await _security.delete(StoreKind.demo);
    final graph = await switchTo(StoreKind.demo);
    if (graph.demoImport == null) {
      throw const StoreCoordinatorException(
        'Demo reset did not import a fresh fixture.',
      );
    }
    return graph;
  }

  Future<void> deleteLive() async {
    if (_active?.kind == StoreKind.live) await _closeActive();
    await _security.delete(StoreKind.live);
  }

  Future<void> dispose() => _closeActive();

  Future<void> _closeActive() async {
    final graph = _active;
    _active = null;
    await graph?.close();
  }
}

final class RepositoryGraph {
  RepositoryGraph({
    required this.kind,
    required this.databasePath,
    required this.database,
    required this.canonicalRecords,
    required this.sourceRepository,
    required this.sourceSync,
    required this.manualCheckins,
    required this.analysis,
    required this.experiments,
    required this.exports,
    required this.explanationRepository,
    required this.explanationCoordinator,
    required this.explorerCoordinator,
    this.demoImport,
  });

  final StoreKind kind;
  final String databasePath;
  final VueniverseDatabase database;
  final CanonicalRecordRepository canonicalRecords;
  final SourceRepository sourceRepository;
  final SourceSyncService sourceSync;
  final ManualCheckinRepository manualCheckins;
  final MeetingAnalysisRepository analysis;
  final ExperimentRepository experiments;
  final EvidenceExportService exports;
  final ExplanationRepository explanationRepository;
  final ExplanationCoordinator explanationCoordinator;
  final ExplorerCoordinator explorerCoordinator;
  final DemoImportResult? demoImport;

  Future<void> close() async {
    await explanationCoordinator.cancel();
    await database.close();
  }
}

final class StoreCoordinatorException implements Exception {
  const StoreCoordinatorException(this.message);

  final String message;
}
