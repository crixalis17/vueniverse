import 'package:why_pulse/app/app_preferences.dart';

// ignore_for_file: prefer_initializing_formals
import 'package:why_pulse/data/database/why_pulse_database.dart';
import 'package:why_pulse/data/analytics/meeting_analysis_repository.dart';
import 'package:why_pulse/data/demo/demo_import_service.dart';
import 'package:why_pulse/data/experiments/experiment_repository.dart';
import 'package:why_pulse/data/exports/evidence_export_service.dart';
import 'package:why_pulse/data/repositories/canonical_record_repository.dart';
import 'package:why_pulse/data/security/store_security_gateway.dart';
import 'package:why_pulse/data/sources/manual_checkin_repository.dart';
import 'package:why_pulse/data/sources/source_platform_gateway.dart';
import 'package:why_pulse/data/sources/source_repository.dart';
import 'package:why_pulse/data/sources/source_sync_service.dart';
import 'package:why_pulse/data/normalization/record_normalizer.dart';
import 'package:why_pulse/domain/store_kind.dart';

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
    final database = WhyPulseDatabase.encrypted(
      path: material.databasePath,
      passphrase: material.passphrase,
    );
    try {
      await database.initialize(kind: kind);
      DemoImportResult? demoImport;
      if (kind == StoreKind.demo && material.databaseIsNew) {
        demoImport = await _demoImporter.importInto(database);
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
        demoImport: demoImport,
      );
      _active = graph;
      await analysis.runPending(ensureEvidence: true);
      await _preferences.setActiveMode(kind);
      return graph;
    } on Object {
      await database.close();
      rethrow;
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
    this.demoImport,
  });

  final StoreKind kind;
  final String databasePath;
  final WhyPulseDatabase database;
  final CanonicalRecordRepository canonicalRecords;
  final SourceRepository sourceRepository;
  final SourceSyncService sourceSync;
  final ManualCheckinRepository manualCheckins;
  final MeetingAnalysisRepository analysis;
  final ExperimentRepository experiments;
  final EvidenceExportService exports;
  final DemoImportResult? demoImport;

  Future<void> close() => database.close();
}

final class StoreCoordinatorException implements Exception {
  const StoreCoordinatorException(this.message);

  final String message;
}
