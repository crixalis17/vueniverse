import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/demo/demo_fixtures.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
import 'package:vueniverse/domain/store_kind.dart';

final class DemoImportService {
  const DemoImportService(this.fixtureLoader);

  static const _importResultMetadataKey = 'demo_import_result';

  final DemoFixtureLoader fixtureLoader;

  Future<DemoImportResult> importInto(VueniverseDatabase database) async {
    final fixture = await fixtureLoader.load();
    await database.initialize(kind: StoreKind.demo);
    final normalizer = RecordNormalizer(identityKey: fixture.identityKey);
    final repository = CanonicalRecordRepository(database);

    final health = await repository.importRecords(
      sourceConnectionId: 'demo-health-v${fixture.fixtureVersion}',
      sourceKind: SourceKind.demoHealth,
      records: fixture.healthRecords,
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
              key: 'demo_expected_outputs',
              value: canonicalJsonEncode(fixture.expectedOutputs),
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
              key: 'demo_analysis_cases',
              value: canonicalJsonEncode(fixture.analysisCases),
              updatedAt: Value(now),
            ),
          );

      for (final experiment in fixture.experiments) {
        await _importExperiment(database, experiment);
      }
    });

    final result = DemoImportResult(
      fixtureVersion: fixture.fixtureVersion,
      virtualNowUtc: fixture.clock.now(),
      rangeStartUtc: fixture.rangeStartUtc,
      rangeEndUtc: fixture.rangeEndUtc,
      canonicalHash: await database.canonicalDataHash(),
      sourceReports: {'health': health, 'calendar': calendar, 'manual': manual},
    );
    await database
        .into(database.storeMetadata)
        .insertOnConflictUpdate(
          StoreMetadataCompanion.insert(
            key: _importResultMetadataKey,
            value: canonicalJsonEncode(result.toJson()),
            updatedAt: Value(fixture.clock.now()),
          ),
        );
    return result;
  }

  Future<void> _importExperiment(
    VueniverseDatabase database,
    Map<String, Object?> experiment,
  ) async {
    final protocolId = _fixtureString(experiment, 'id');
    final findingVersionId = _fixtureString(experiment, 'finding_version_id');
    if (findingVersionId.isNotEmpty) {
      throw FormatException(
        'Seeded Demo experiment $protocolId must not target an active finding',
      );
    }
    final expectedOutcome = _fixtureString(experiment, 'expected_outcome');
    await database
        .into(database.experimentProtocols)
        .insertOnConflictUpdate(
          ExperimentProtocolsCompanion.insert(
            id: protocolId,
            title: _fixtureString(experiment, 'title'),
            status: _fixtureString(experiment, 'status'),
            protocolJson: canonicalJsonEncode(experiment),
            version: _fixtureInteger(experiment, 'version'),
            createdAt: Value(_fixtureDateTime(experiment, 'created_at_utc')),
            updatedAt: Value(_fixtureDateTime(experiment, 'completed_at_utc')),
          ),
        );

    for (final occurrence in _fixtureObjectList(experiment, 'occurrences')) {
      final occurrenceId = _fixtureString(occurrence, 'id');
      await database
          .into(database.experimentOccurrences)
          .insertOnConflictUpdate(
            ExperimentOccurrencesCompanion.insert(
              id: occurrenceId,
              experimentProtocolId: protocolId,
              scheduledAtUtc: _fixtureDateTime(occurrence, 'scheduled_at_utc'),
              completedAtUtc: Value(
                _fixtureDateTime(occurrence, 'completed_at_utc'),
              ),
              status: _fixtureString(occurrence, 'status'),
              contextJson: canonicalJsonEncode(
                _fixtureObject(occurrence, 'context'),
              ),
            ),
          );

      for (final checkin in _fixtureObjectList(
        occurrence,
        'adherence_checkins',
      )) {
        await database
            .into(database.adherenceCheckins)
            .insertOnConflictUpdate(
              AdherenceCheckinsCompanion.insert(
                id: _fixtureString(checkin, 'id'),
                experimentOccurrenceId: occurrenceId,
                responseJson: canonicalJsonEncode(
                  _fixtureObject(checkin, 'response'),
                ),
                recordedAtUtc: _fixtureDateTime(checkin, 'recorded_at_utc'),
              ),
            );
      }
    }

    for (final result in _fixtureObjectList(experiment, 'results')) {
      final outcome = _fixtureString(result, 'outcome');
      if (outcome != expectedOutcome) {
        throw FormatException(
          'Seeded Demo experiment $protocolId expected $expectedOutcome, '
          'but persisted $outcome',
        );
      }
      await database
          .into(database.experimentResults)
          .insertOnConflictUpdate(
            ExperimentResultsCompanion.insert(
              id: _fixtureString(result, 'id'),
              experimentProtocolId: protocolId,
              outcome: outcome,
              resultJson: canonicalJsonEncode(
                _fixtureObject(result, 'details'),
              ),
              evidenceHash: _fixtureString(result, 'evidence_hash'),
              analysisVersion: _fixtureInteger(result, 'analysis_version'),
              createdAt: Value(_fixtureDateTime(result, 'created_at_utc')),
            ),
          );
    }
  }

  Future<DemoImportResult?> restoreFrom(VueniverseDatabase database) async {
    final row =
        await (database.select(database.storeMetadata)
              ..where((item) => item.key.equals(_importResultMetadataKey)))
            .getSingleOrNull();
    if (row == null) return null;
    try {
      final decoded = jsonDecode(row.value);
      if (decoded is! Map) return null;
      return DemoImportResult.fromJson({
        for (final entry in decoded.entries) '${entry.key}': entry.value,
      });
    } on Object {
      return null;
    }
  }
}

final class DemoImportResult {
  const DemoImportResult({
    required this.fixtureVersion,
    required this.virtualNowUtc,
    required this.rangeStartUtc,
    required this.rangeEndUtc,
    required this.canonicalHash,
    required this.sourceReports,
  });

  final int fixtureVersion;
  final DateTime virtualNowUtc;
  final DateTime rangeStartUtc;
  final DateTime rangeEndUtc;
  final String canonicalHash;
  final Map<String, IngestionReport> sourceReports;

  int get coverageDayCount {
    final start = DateTime.utc(
      rangeStartUtc.year,
      rangeStartUtc.month,
      rangeStartUtc.day,
    );
    final end = DateTime.utc(
      rangeEndUtc.year,
      rangeEndUtc.month,
      rangeEndUtc.day,
    );
    return end.difference(start).inDays + 1;
  }

  Map<String, Object?> toJson() => {
    'fixture_version': fixtureVersion,
    'virtual_now_utc': virtualNowUtc.toIso8601String(),
    'range_start_utc': rangeStartUtc.toIso8601String(),
    'range_end_utc': rangeEndUtc.toIso8601String(),
    'canonical_hash': canonicalHash,
    'source_reports': {
      for (final entry in sourceReports.entries)
        entry.key: {
          'seen': entry.value.seen,
          'inserted': entry.value.inserted,
          'duplicates': entry.value.duplicates,
          'changed': entry.value.changed,
          'rejected_counts': entry.value.rejectedCounts,
        },
    },
  };

  factory DemoImportResult.fromJson(Map<String, Object?> value) {
    final rawReports = value['source_reports'];
    if (rawReports is! Map) {
      throw const FormatException('Missing Demo source reports');
    }
    final reports = <String, IngestionReport>{};
    for (final entry in rawReports.entries) {
      final rawReport = entry.value;
      if (rawReport is! Map) {
        throw const FormatException('Invalid Demo source report');
      }
      final rejected = rawReport['rejected_counts'];
      if (rejected is! Map) {
        throw const FormatException('Invalid Demo rejected counts');
      }
      reports['${entry.key}'] = IngestionReport(
        seen: _integer(rawReport['seen']),
        inserted: _integer(rawReport['inserted']),
        duplicates: _integer(rawReport['duplicates']),
        changed: _integer(rawReport['changed']),
        rejectedCounts: {
          for (final rejectedEntry in rejected.entries)
            '${rejectedEntry.key}': _integer(rejectedEntry.value),
        },
      );
    }
    final version = _integer(value['fixture_version']);
    final virtualNow = value['virtual_now_utc'];
    final rangeStart = value['range_start_utc'];
    final rangeEnd = value['range_end_utc'];
    final hash = value['canonical_hash'];
    if (virtualNow is! String ||
        rangeStart is! String ||
        rangeEnd is! String ||
        hash is! String ||
        hash.isEmpty) {
      throw const FormatException('Invalid Demo import result');
    }
    final virtualNowUtc = DateTime.parse(virtualNow).toUtc();
    final rangeStartUtc = DateTime.parse(rangeStart).toUtc();
    final rangeEndUtc = DateTime.parse(rangeEnd).toUtc();
    final rangeStartDay = DateTime.utc(
      rangeStartUtc.year,
      rangeStartUtc.month,
      rangeStartUtc.day,
    );
    final rangeEndDay = DateTime.utc(
      rangeEndUtc.year,
      rangeEndUtc.month,
      rangeEndUtc.day,
    );
    if (rangeEndUtc.isBefore(rangeStartUtc) ||
        virtualNowUtc.isBefore(rangeStartUtc) ||
        virtualNowUtc.isAfter(rangeEndUtc) ||
        rangeEndDay.difference(rangeStartDay).inDays + 1 < 30) {
      throw const FormatException('Invalid Demo import range');
    }
    return DemoImportResult(
      fixtureVersion: version,
      virtualNowUtc: virtualNowUtc,
      rangeStartUtc: rangeStartUtc,
      rangeEndUtc: rangeEndUtc,
      canonicalHash: hash,
      sourceReports: Map.unmodifiable(reports),
    );
  }

  static int _integer(Object? value) {
    if (value is! num || value != value.roundToDouble()) {
      throw const FormatException('Expected Demo integer');
    }
    return value.toInt();
  }
}

String _fixtureString(Map<String, Object?> value, String key) {
  final result = value[key];
  if (result is! String) {
    throw FormatException('Expected Demo string at $key');
  }
  return result;
}

int _fixtureInteger(Map<String, Object?> value, String key) {
  final result = value[key];
  if (result is! num || result != result.roundToDouble()) {
    throw FormatException('Expected Demo integer at $key');
  }
  return result.toInt();
}

DateTime _fixtureDateTime(Map<String, Object?> value, String key) =>
    DateTime.parse(_fixtureString(value, key)).toUtc();

Map<String, Object?> _fixtureObject(Map<String, Object?> value, String key) {
  final result = value[key];
  if (result is! Map) {
    throw FormatException('Expected Demo object at $key');
  }
  return {for (final entry in result.entries) '${entry.key}': entry.value};
}

List<Map<String, Object?>> _fixtureObjectList(
  Map<String, Object?> value,
  String key,
) {
  final result = value[key];
  if (result is! List) {
    throw FormatException('Expected Demo list at $key');
  }
  return [
    for (final item in result)
      if (item is Map)
        {for (final entry in item.entries) '${entry.key}': entry.value}
      else
        throw FormatException('Expected Demo object in $key'),
  ];
}
