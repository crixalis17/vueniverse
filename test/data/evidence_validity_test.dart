import 'dart:io';
import 'package:drift/drift.dart' show Value, BooleanExpressionOperators;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/analytics/meeting_analysis_repository.dart';
import 'package:vueniverse/data/database/schema_versions.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/demo/demo_import_service.dart';
import 'package:vueniverse/data/experiments/experiment_repository.dart';
import 'package:vueniverse/data/experiments/experiment_reminder_scheduler.dart';
import 'package:vueniverse/data/exports/evidence_export_service.dart';
import 'package:vueniverse/data/model_runtime/evidence_projection_repository.dart';
import 'package:vueniverse/data/model_runtime/explanation_repository.dart';
import 'package:vueniverse/data/replay/moment_replay_repository.dart';
import 'package:vueniverse/domain/model_runtime/explanation_coordinator.dart';
import 'package:vueniverse/domain/models/experiment_models.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/notification_api.g.dart';

void main() {
  for (final change in ['analysis', 'promotion', 'new_context', 'stale']) {
    test(
      '$change blocks direct replay, projection, cached answer and experiment',
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
        final evidence = (await analysis.runPending(ensureEvidence: true))!;
        // This freshness test uses an explicitly supported protocol fixture;
        // the untouched demo remains developing and cannot start interventions.
        await (database.update(database.evidenceBundles)
              ..where((row) => row.id.equals(evidence.id)))
            .write(const EvidenceBundlesCompanion(status: Value('supported')));
        await (database.update(database.findingVersions)
              ..where((row) => row.evidenceBundleId.equals(evidence.id)))
            .write(const FindingVersionsCompanion(status: Value('supported')));
        await (database.update(database.evidenceMetrics)..where(
              (row) =>
                  row.evidenceBundleId.equals(evidence.id) &
                  row.metric.equals('unresolved_influence_count'),
            ))
            .write(const EvidenceMetricsCompanion(value: Value(0)));
        final projections = EvidenceProjectionRepository(database);
        final repository = ExplanationRepository(database);
        final coordinator = ExplanationCoordinator(
          storeKind: StoreKind.demo,
          projections: projections,
          repository: repository,
          enablePhoneRuntime: false,
          enableDevelopmentRuntime: false,
        );
        final answer = (await coordinator.explain(intent: 'why_promoted'))!;
        final notifications = _RecordingNotifications();
        final experiments = ExperimentRepository(
          database,
          reminders: ExperimentReminderScheduler(api: notifications),
        );
        final context = (await experiments.resolveStartContext(
          evidenceBundleId: evidence.id,
        ))!;
        final protocol = await experiments.start(
          evidenceBundleId: evidence.id,
          findingVersionId: context.findingVersionId,
          recurrenceKeyHmac: context.recurrenceKeyHmac!,
          createdAtUtc: imported.virtualNowUtc,
        );
        final explanationsBefore = await database
            .select(database.explanations)
            .get();
        expect(await experiments.reconcileReminderFreshness(), isEmpty);
        expect(notifications.cancelled, isEmpty);
        if (change == 'analysis') {
          await (database.update(
            database.analysisRuns,
          )..where((row) => row.id.equals(evidence.analysisRunId))).write(
            AnalysisRunsCompanion(
              analysisVersion: Value(SchemaVersions.meetingAnalysis - 1),
            ),
          );
        } else if (change == 'promotion') {
          await (database.update(
            database.evidenceBundles,
          )..where((row) => row.id.equals(evidence.id))).write(
            EvidenceBundlesCompanion(
              promotionPolicyVersion: Value(SchemaVersions.promotionPolicy - 1),
            ),
          );
        } else if (change == 'stale') {
          await (database.update(database.evidenceBundles)
                ..where((row) => row.id.equals(evidence.id)))
              .write(const EvidenceBundlesCompanion(status: Value('stale')));
        } else {
          await database
              .into(database.manualCheckins)
              .insert(
                ManualCheckinsCompanion.insert(
                  id: 'newly-recorded-context',
                  category: 'illness',
                  occurredAtUtc: imported.virtualNowUtc,
                  valueJson: '{}',
                  originalOffsetMinutes: 330,
                  originalLocalDate: '2026-07-16',
                  provenanceJson: '{}',
                  canonicalPayloadHash: 'new-hash',
                ),
              );
        }
        expect(await analysis.currentEvidence(), isNull);
        expect(
          await projections.build(
            storeKind: StoreKind.demo,
            intent: 'why_promoted',
          ),
          isNull,
        );
        expect(await projections.buildExplorer(), isNull);
        expect(await MomentReplayRepository(database).loadCurrent(), isNull);
        expect(await repository.loadAccepted(answer.projection), isNull);
        expect(await coordinator.explain(intent: 'why_promoted'), isNull);
        expect(
          await experiments.resolveStartContext(evidenceBundleId: evidence.id),
          isNull,
        );
        expect(
          (await experiments.loadProtocols())
              .firstWhere((row) => row.id == protocol.id)
              .status,
          ExperimentProtocolStatus.invalidated,
        );
        await expectLater(experiments.resume(protocol.id), throwsStateError);
        expect(await experiments.reconcileReminderFreshness(), isEmpty);
        expect(
          notifications.cancelled.toSet(),
          notifications.scheduled.toSet(),
        );
        expect(notifications.cancelled, hasLength(3));
        // Read boundaries do not delete historical answers or protocols.
        expect(
          await database.select(database.explanations).get(),
          explanationsBefore,
        );
        final fresh = await analysis.runPending();
        expect(fresh, isNotNull);
        expect(await analysis.currentEvidence(), isNotNull);
      },
    );
  }

  test(
    'developing or unresolved evidence cannot start an intervention',
    () async {
      final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final imported = await DemoImportService(
        DemoFixtureLoader(FileFixtureAssetReader(Directory.current.path)),
      ).importInto(database);
      final evidence = (await MeetingAnalysisRepository(
        database,
        clock: () => imported.virtualNowUtc,
      ).runPending(ensureEvidence: true))!;
      final experiments = ExperimentRepository(database);
      final historicalProtocols = await database
          .select(database.experimentProtocols)
          .get();
      expect(evidence.status, 'developing');
      expect(
        await experiments.resolveStartContext(evidenceBundleId: evidence.id),
        isNull,
      );
      await (database.update(database.evidenceBundles)
            ..where((row) => row.id.equals(evidence.id)))
          .write(const EvidenceBundlesCompanion(status: Value('supported')));
      await (database.update(database.findingVersions)
            ..where((row) => row.evidenceBundleId.equals(evidence.id)))
          .write(const FindingVersionsCompanion(status: Value('supported')));
      expect(
        await experiments.resolveStartContext(evidenceBundleId: evidence.id),
        isNull,
      );
      await expectLater(
        experiments.start(
          evidenceBundleId: evidence.id,
          findingVersionId: 'unused',
          recurrenceKeyHmac: 'unused',
          createdAtUtc: imported.virtualNowUtc,
        ),
        throwsStateError,
      );
      await (database.delete(database.evidenceMetrics)..where(
            (row) =>
                row.evidenceBundleId.equals(evidence.id) &
                row.metric.equals('unresolved_influence_count'),
          ))
          .go();
      expect(
        await experiments.resolveStartContext(evidenceBundleId: evidence.id),
        isNull,
        reason: 'Missing influence accounting is unknown, not zero',
      );
      expect(
        await database.select(database.experimentProtocols).get(),
        historicalProtocols,
      );
    },
  );

  test('unbacked export refuses to create files', () async {
    final database = VueniverseDatabase.forTesting(NativeDatabase.memory());
    final directory = await Directory.systemTemp.createTemp(
      'vueniverse-stale-export-',
    );
    addTearDown(database.close);
    addTearDown(() => directory.delete(recursive: true));
    await expectLater(
      EvidenceExportService(database, directoryPath: directory.path).export(
        const EvidenceExportDocument(
          storeKind: 'live',
          evidenceVersion: 'unknown',
          status: 'supported',
          title: 'Unbacked',
          metrics: {},
          sources: [],
          exclusions: {},
          counterevidence: {},
          influences: [],
          runtime: 'deterministic',
          safetyState: 'accepted',
        ),
      ),
      throwsStateError,
    );
    expect(await directory.list().toList(), isEmpty);
  });
}

class _RecordingNotifications extends NotificationApi {
  final scheduled = <String>[];
  final cancelled = <String>[];
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> schedule(NotificationSchedule schedule) async {
    scheduled.add(schedule.id);
  }

  @override
  Future<void> cancel(String id) async {
    cancelled.add(id);
  }
}
