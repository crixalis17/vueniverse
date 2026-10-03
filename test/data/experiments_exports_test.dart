import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:vueniverse/data/database/schema_versions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/experiments/experiment_repository.dart';
import 'package:vueniverse/data/exports/evidence_export_service.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/models/experiment_models.dart';
import 'package:vueniverse/domain/store_kind.dart';

void main() {
  late VueniverseDatabase database;
  late Directory exportDirectory;

  setUp(() async {
    database = VueniverseDatabase.forTesting(NativeDatabase.memory());
    await database.initialize(kind: StoreKind.live);
    exportDirectory = await Directory.systemTemp.createTemp(
      'vueniverse-export-',
    );
  });

  tearDown(() async {
    await database.close();
    if (await exportDirectory.exists()) {
      await exportDirectory.delete(recursive: true);
    }
  });

  test(
    'experiment start context stays scoped with multiple findings and events',
    () async {
      for (final suffix in ['current', 'other']) {
        await database
            .into(database.analysisRuns)
            .insert(
              AnalysisRunsCompanion.insert(
                id: 'analysis-$suffix',
                status: 'completed',
                rangeStartUtc: DateTime.utc(2026, 6, 1),
                rangeEndUtc: DateTime.utc(2026, 7, 16),
                analysisVersion: 1,
                startedAt: DateTime.utc(2026, 7, 16),
                inputHash: 'input-$suffix',
              ),
            );
        await database
            .into(database.evidenceBundles)
            .insert(
              EvidenceBundlesCompanion.insert(
                id: 'evidence-$suffix',
                analysisRunId: 'analysis-$suffix',
                status: 'supported',
                title: 'Evidence $suffix',
                claimType: 'test',
                evidenceHash: 'hash-$suffix',
                promotionPolicyVersion: 1,
              ),
            );
        await database
            .into(database.findingVersions)
            .insert(
              FindingVersionsCompanion.insert(
                id: 'finding-$suffix:v1',
                findingId: 'finding-$suffix',
                evidenceBundleId: 'evidence-$suffix',
                version: 1,
                status: 'supported',
                validFrom: DateTime.utc(2026, 7, 16),
              ),
            );
      }
      for (final event in [
        ('older', DateTime.utc(2026, 7, 9), 'recurrence-older'),
        ('latest', DateTime.utc(2026, 7, 16), 'recurrence-latest'),
      ]) {
        await database
            .into(database.contextEvents)
            .insert(
              ContextEventsCompanion.insert(
                id: 'event-${event.$1}',
                category: ContextCategory.recurringOneToOne.name,
                startAtUtc: event.$2,
                endAtUtc: event.$2.add(const Duration(hours: 1)),
                recurrenceKeyHmac: Value(event.$3),
                originalOffsetMinutes: 0,
                originalLocalDate: '2026-07-16',
                provenanceJson: '{}',
                canonicalPayloadHash: 'event-hash-${event.$1}',
              ),
            );
      }

      await _currentFixture(
        database,
        evidenceId: 'evidence-current',
        findingId: 'finding-current:v1',
        key: 'recurrence-older',
        eventId: 'event-older',
      );
      final context = await ExperimentRepository(
        database,
      ).resolveStartContext(evidenceBundleId: 'evidence-current');

      expect(context?.findingVersionId, 'finding-current:v1');
      expect(context?.recurrenceKeyHmac, 'recurrence-older');
    },
  );

  test('experiment protocol and occurrence survive reload', () async {
    await database
        .into(database.analysisRuns)
        .insert(
          AnalysisRunsCompanion.insert(
            id: 'analysis-1',
            status: 'completed',
            rangeStartUtc: DateTime.utc(2026, 6, 1),
            rangeEndUtc: DateTime.utc(2026, 7, 16),
            analysisVersion: 1,
            startedAt: DateTime.utc(2026, 7, 16),
            inputHash: 'input',
          ),
        );
    await database
        .into(database.evidenceBundles)
        .insert(
          EvidenceBundlesCompanion.insert(
            id: 'evidence-1',
            analysisRunId: 'analysis-1',
            status: 'supported',
            title: 'Test evidence',
            claimType: 'test',
            evidenceHash: 'hash',
            promotionPolicyVersion: 1,
          ),
        );
    await _currentFixture(
      database,
      evidenceId: 'evidence-1',
      findingId: 'finding:v1',
      key: 'recurrence-hmac',
    );
    final repository = ExperimentRepository(database);
    final created = await repository.start(
      evidenceBundleId: 'evidence-1',
      findingVersionId: 'finding:v1',
      recurrenceKeyHmac: 'recurrence-hmac',
      createdAtUtc: DateTime.utc(2026, 7, 16),
    );
    expect(created.occurrences, hasLength(3));
    await expectLater(
      repository.recordAdherence(
        occurrenceId: created.occurrences.first.id,
        adhered: true,
        recordedAtUtc: DateTime.utc(2026, 7, 16),
      ),
      throwsStateError,
    );
    expect(await database.select(database.adherenceCheckins).get(), isEmpty);
    await repository.recordAdherence(
      occurrenceId: created.occurrences.first.id,
      adhered: true,
      recordedAtUtc: DateTime.utc(2026, 7, 23),
    );
    final restored = await repository.loadProtocols();
    expect(restored.single.status, ExperimentProtocolStatus.active);
    expect(
      restored.single.occurrences.first.status,
      ExperimentOccurrenceStatus.adhered,
    );

    await repository.pause(created.id);
    expect(
      (await repository.loadProtocols()).single.status,
      ExperimentProtocolStatus.paused,
    );
    await repository.resume(created.id);
    expect(
      (await repository.loadProtocols()).single.status,
      ExperimentProtocolStatus.active,
    );
    for (final occurrence in created.occurrences.skip(1)) {
      await repository.recordAdherence(
        occurrenceId: occurrence.id,
        adhered: true,
        recordedAtUtc: occurrence.scheduledAtUtc,
      );
    }
    expect(
      (await repository.loadProtocols()).single.status,
      ExperimentProtocolStatus.completed,
    );
  });

  test(
    'experiment cancellation and early stop persist distinct states',
    () async {
      await database
          .into(database.analysisRuns)
          .insert(
            AnalysisRunsCompanion.insert(
              id: 'analysis-lifecycle',
              status: 'completed',
              rangeStartUtc: DateTime.utc(2026, 6, 1),
              rangeEndUtc: DateTime.utc(2026, 7, 16),
              analysisVersion: 1,
              startedAt: DateTime.utc(2026, 7, 16),
              inputHash: 'input-lifecycle',
            ),
          );
      await database
          .into(database.evidenceBundles)
          .insert(
            EvidenceBundlesCompanion.insert(
              id: 'evidence-lifecycle',
              analysisRunId: 'analysis-lifecycle',
              status: 'supported',
              title: 'Lifecycle evidence',
              claimType: 'test',
              evidenceHash: 'hash-lifecycle',
              promotionPolicyVersion: 1,
            ),
          );
      await _currentFixture(
        database,
        evidenceId: 'evidence-lifecycle',
        findingId: 'finding:cancel',
        key: 'recurrence-cancel',
      );
      final repository = ExperimentRepository(database);
      final cancelled = await repository.start(
        evidenceBundleId: 'evidence-lifecycle',
        findingVersionId: 'finding:cancel',
        recurrenceKeyHmac: 'recurrence-cancel',
        createdAtUtc: DateTime.utc(2026, 7, 16),
      );
      await repository.cancel(cancelled.id);
      expect(
        (await repository.loadProtocols()).first.status,
        ExperimentProtocolStatus.cancelled,
      );

      final stopped = await repository.start(
        evidenceBundleId: 'evidence-lifecycle',
        findingVersionId: 'finding:cancel',
        recurrenceKeyHmac: 'recurrence-cancel',
        createdAtUtc: DateTime.utc(2026, 7, 17),
      );
      await repository.stop(stopped.id);
      expect(
        (await repository.loadProtocols()).first.status,
        ExperimentProtocolStatus.stopped,
      );
    },
  );

  test('PDF and canonical JSON exports share one integrity hash', () async {
    await _currentFixture(
      database,
      evidenceId: 'evidence-export',
      findingId: 'finding:v1',
      key: 'recurrence-export',
    );
    final result =
        await EvidenceExportService(
          database,
          directoryPath: exportDirectory.path,
        ).export(
          const EvidenceExportDocument(
            storeKind: 'live',
            evidenceVersion: 'finding:v1',
            status: 'supported',
            title: 'Recurring 1:1 and heart rate',
            metrics: {'median_difference_bpm': 11},
            sources: [
              {'id': 'health-connect', 'last_sync': '2026-07-16T12:00:00Z'},
            ],
            exclusions: {'workout_overlap': 2},
            counterevidence: {'count': 2},
            influences: ['unresolved_influences'],
            runtime: 'deterministic',
            safetyState: 'accepted',
          ),
        );
    final json = await File(result.jsonPath).readAsString();
    final pdf = await File(result.pdfPath).readAsBytes();
    expect(jsonDecode(json), isA<Map>());
    expect(result.hash, hasLength(64));
    expect(pdf.take(8), orderedEquals(utf8.encode('%PDF-1.4')));
    expect(String.fromCharCodes(pdf), contains(result.hash));
    final exports = EvidenceExportService(
      database,
      directoryPath: exportDirectory.path,
    );
    expect(await exports.canShare(result.jsonPath), isTrue);
    await (database.update(database.evidenceBundles)
          ..where((row) => row.id.equals('evidence-export')))
        .write(const EvidenceBundlesCompanion(status: Value('stale')));
    expect(await exports.canShare(result.jsonPath), isFalse);
    expect(await File(result.jsonPath).exists(), isTrue);
  });

  test('export source descriptors preserve Demo and Live provenance', () {
    final demoSources = evidenceExportSources(StoreKind.demo);
    expect(demoSources.map((source) => source['id']), [
      SourceKind.demoHealth.name,
      SourceKind.demoCalendar.name,
      SourceKind.demoManual.name,
    ]);
    expect(demoSources.every((source) => source['fictional'] == true), isTrue);
    expect(
      demoSources.singleWhere(
        (source) => source['id'] == SourceKind.demoManual.name,
      )['role'],
      'logged_context',
    );

    final liveSources = evidenceExportSources(StoreKind.live);
    expect(liveSources.map((source) => source['id']), [
      SourceKind.healthConnect.name,
      SourceKind.calendar.name,
      SourceKind.manual.name,
    ]);
    expect(liveSources.every((source) => source['fictional'] == false), isTrue);
  });
}

Future<void> _currentFixture(
  VueniverseDatabase database, {
  required String evidenceId,
  required String findingId,
  required String key,
  String? eventId,
}) async {
  final now = DateTime.utc(2026, 7, 16);
  final event = eventId ?? 'fixture-event';
  if (eventId == null) {
    await database
        .into(database.contextEvents)
        .insert(
          ContextEventsCompanion.insert(
            id: event,
            category: ContextCategory.recurringOneToOne.name,
            startAtUtc: now,
            endAtUtc: now.add(const Duration(minutes: 30)),
            recurrenceKeyHmac: Value(key),
            originalOffsetMinutes: 0,
            originalLocalDate: '2026-07-16',
            provenanceJson: '{}',
            canonicalPayloadHash: 'event-hash',
          ),
        );
  }
  var evidence = await (database.select(
    database.evidenceBundles,
  )..where((row) => row.id.equals(evidenceId))).getSingleOrNull();
  final runId = evidence?.analysisRunId ?? 'analysis-export';
  if (evidence == null) {
    await database
        .into(database.analysisRuns)
        .insert(
          AnalysisRunsCompanion.insert(
            id: runId,
            status: 'completed',
            rangeStartUtc: now,
            rangeEndUtc: now,
            analysisVersion: SchemaVersions.meetingAnalysis,
            startedAt: now,
            inputHash: 'pending',
          ),
        );
    await database
        .into(database.evidenceBundles)
        .insert(
          EvidenceBundlesCompanion.insert(
            id: evidenceId,
            analysisRunId: runId,
            status: 'supported',
            title: 'Fixture',
            claimType: 'test',
            evidenceHash: 'fixture-hash',
            promotionPolicyVersion: SchemaVersions.promotionPolicy,
          ),
        );
    evidence = await (database.select(
      database.evidenceBundles,
    )..where((row) => row.id.equals(evidenceId))).getSingle();
  }
  await (database.update(
    database.analysisRuns,
  )..where((row) => row.id.equals(runId))).write(
    AnalysisRunsCompanion(
      analysisVersion: Value(SchemaVersions.meetingAnalysis),
      inputHash: Value(await database.canonicalDataHash()),
    ),
  );
  await (database.update(
    database.evidenceBundles,
  )..where((row) => row.id.equals(evidenceId))).write(
    const EvidenceBundlesCompanion(
      promotionPolicyVersion: Value(SchemaVersions.promotionPolicy),
    ),
  );
  await database
      .into(database.findingVersions)
      .insertOnConflictUpdate(
        FindingVersionsCompanion.insert(
          id: findingId,
          findingId: findingId,
          evidenceBundleId: evidenceId,
          version: 1,
          status: 'supported',
          validFrom: now,
        ),
      );
  await database
      .into(database.eventWindows)
      .insert(
        EventWindowsCompanion.insert(
          id: 'window:$evidenceId',
          analysisRunId: runId,
          contextEventId: event,
          startAtUtc: now,
          endAtUtc: now.add(const Duration(minutes: 30)),
          status: 'included',
        ),
      );
}
