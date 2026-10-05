import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:vueniverse/data/analytics/evidence_validity_repository.dart';
import 'package:vueniverse/data/database/schema_versions.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/experiments/experiment_reminder_scheduler.dart';
import 'package:vueniverse/domain/models/experiment_models.dart';

typedef ExperimentStartContext = ({
  String findingVersionId,
  String? recurrenceKeyHmac,
});

final class ExperimentRepository {
  ExperimentRepository(this.database, {ExperimentReminderScheduler? reminders})
    : _reminders = reminders ?? ExperimentReminderScheduler();

  final VueniverseDatabase database;
  final ExperimentReminderScheduler _reminders;

  Future<ExperimentStartContext?> resolveStartContext({
    required String evidenceBundleId,
  }) async {
    final evidence = await EvidenceValidityRepository(
      database,
    ).load(evidenceBundleId);
    if (evidence == null || evidence.status != 'supported') return null;
    final finding =
        await (database.select(database.findingVersions)
              ..where(
                (row) =>
                    row.evidenceBundleId.equals(evidenceBundleId) &
                    row.validUntil.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.version)])
              ..limit(1))
            .getSingleOrNull();
    if (finding == null || finding.status != 'supported') return null;
    final influences =
        await (database.select(database.evidenceMetrics)..where(
              (row) =>
                  row.evidenceBundleId.equals(evidenceBundleId) &
                  row.metric.equals('unresolved_influence_count'),
            ))
            .get();
    if (influences.length != 1 ||
        influences.any((row) => !row.value.isFinite || row.value != 0)) {
      return null;
    }
    final windows =
        await (database.select(database.eventWindows)..where(
              (row) =>
                  row.analysisRunId.equals(evidence.analysisRunId) &
                  row.status.equals('included'),
            ))
            .get();
    final events =
        await (database.select(database.contextEvents)..where(
              (row) => row.id.isIn(windows.map((row) => row.contextEventId)),
            ))
            .get();
    final keys = events
        .map((row) => row.recurrenceKeyHmac)
        .whereType<String>()
        .where((key) => key.trim().isNotEmpty)
        .toSet();
    if (keys.length != 1 ||
        events.any((event) => event.recurrenceKeyHmac == null)) {
      return null;
    }
    return (findingVersionId: finding.id, recurrenceKeyHmac: keys.single);
  }

  Future<ExperimentProtocolModel> start({
    required String evidenceBundleId,
    required String findingVersionId,
    required String recurrenceKeyHmac,
    required DateTime createdAtUtc,
    List<ExperimentOccurrenceModel> occurrences = const [],
  }) async {
    final context = await resolveStartContext(
      evidenceBundleId: evidenceBundleId,
    );
    if (context == null ||
        context.findingVersionId != findingVersionId ||
        context.recurrenceKeyHmac != recurrenceKeyHmac) {
      throw StateError(
        'Experiment requires current evidence for the selected series',
      );
    }
    final id = 'experiment:${createdAtUtc.microsecondsSinceEpoch}';
    final schedule = occurrences.isEmpty
        ? [
            for (var index = 0; index < 3; index++)
              ExperimentOccurrenceModel(
                id: '$id:occurrence-${index + 1}',
                scheduledAtUtc: createdAtUtc.add(Duration(days: index + 7)),
                status: ExperimentOccurrenceStatus.upcoming,
              ),
          ]
        : occurrences;
    final protocol = ExperimentProtocolModel(
      id: id,
      evidenceBundleId: evidenceBundleId,
      findingVersionId: findingVersionId,
      recurrenceKeyHmac: recurrenceKeyHmac,
      status: ExperimentProtocolStatus.active,
      createdAtUtc: createdAtUtc,
      occurrences: List.unmodifiable(schedule),
    );
    await database.transaction(() async {
      final current = await resolveStartContext(
        evidenceBundleId: evidenceBundleId,
      );
      if (current == null ||
          current.findingVersionId != findingVersionId ||
          current.recurrenceKeyHmac != recurrenceKeyHmac) {
        throw StateError('Experiment evidence changed before persistence');
      }
      await database
          .into(database.experimentProtocols)
          .insert(
            ExperimentProtocolsCompanion.insert(
              id: id,
              evidenceBundleId: Value(evidenceBundleId),
              title: 'Quiet buffer before recurring 1:1',
              status: protocol.status.name,
              protocolJson: jsonEncode({
                'finding_version_id': findingVersionId,
                'recurrence_key_hmac': recurrenceKeyHmac,
                'buffer_minutes': 10,
                'required_occurrences': 3,
                'outcome_measure': 'post_meeting_recovery_minutes',
                'comparison': 'matched_prior_recurring_one_to_one',
                'instructions': const [
                  'pause_work_in_usual_place',
                  'breathe_normally',
                  'keep_normal_routine',
                  'keep_sensor_on_through_recovery',
                  'complete_context_checkin',
                ],
                'context_fields': const [
                  'caffeine',
                  'recent_exercise',
                  'illness_or_travel',
                  'unusual_stress',
                ],
              }),
              version: 2,
              createdAt: Value(createdAtUtc),
              updatedAt: Value(createdAtUtc),
            ),
          );
      for (final occurrence in schedule) {
        await database
            .into(database.experimentOccurrences)
            .insert(
              ExperimentOccurrencesCompanion.insert(
                id: occurrence.id,
                experimentProtocolId: id,
                scheduledAtUtc: occurrence.scheduledAtUtc,
                status: occurrence.status.name,
                contextJson: '{}',
              ),
            );
      }
    });
    if (await _reminders.requestPermission()) {
      for (final occurrence in schedule) {
        if (await resolveStartContext(evidenceBundleId: evidenceBundleId) ==
            null) {
          break;
        }
        final reminderAt = occurrence.scheduledAtUtc.subtract(
          const Duration(minutes: 10),
        );
        if (!reminderAt.isAfter(createdAtUtc)) continue;
        await _reminders.schedule(
          id: occurrence.id,
          atUtc: reminderAt,
          title: 'Vueniverse experiment',
          body:
              'Pause work in your usual place for the 10-minute quiet buffer.',
        );
      }
    }
    return protocol;
  }

  /// Cancel only reminders belonging to unavailable evidence-backed protocols.
  /// Preserve all experiment/adherence records; failed cancellation can be retried.
  Future<List<String>> reconcileReminderFreshness() async {
    final protocols = await loadProtocols();
    final failures = <String>[];
    for (final protocol in protocols) {
      if (protocol.evidenceBundleId == null ||
          !const {
            ExperimentProtocolStatus.invalidated,
            ExperimentProtocolStatus.cancelled,
            ExperimentProtocolStatus.stopped,
            ExperimentProtocolStatus.paused,
          }.contains(protocol.status)) {
        continue;
      }
      for (final occurrence in protocol.occurrences) {
        if (!const {
          ExperimentOccurrenceStatus.upcoming,
          ExperimentOccurrenceStatus.reminderScheduled,
          ExperimentOccurrenceStatus.due,
        }.contains(occurrence.status)) {
          continue;
        }
        if (!await _reminders.cancel(occurrence.id)) {
          failures.add(occurrence.id);
        }
      }
    }
    return List.unmodifiable(failures);
  }

  Future<List<ExperimentProtocolModel>> loadProtocols() async {
    final rows = await (database.select(
      database.experimentProtocols,
    )..orderBy([(row) => OrderingTerm.desc(row.createdAt)])).get();
    final result = <ExperimentProtocolModel>[];
    for (final row in rows) {
      final occurrences = await (database.select(
        database.experimentOccurrences,
      )..where((item) => item.experimentProtocolId.equals(row.id))).get();
      final protocol = _decodeProtocol(row.protocolJson);
      final current =
          row.evidenceBundleId == null ||
          await resolveStartContext(evidenceBundleId: row.evidenceBundleId!) !=
              null;
      result.add(
        ExperimentProtocolModel(
          id: row.id,
          evidenceBundleId: row.evidenceBundleId,
          findingVersionId: protocol.findingVersionId,
          recurrenceKeyHmac: protocol.recurrenceKeyHmac,
          status: current
              ? _protocolStatus(row.status)
              : ExperimentProtocolStatus.invalidated,
          createdAtUtc: row.createdAt,
          occurrences: [
            for (final occurrence in occurrences)
              ExperimentOccurrenceModel(
                id: occurrence.id,
                scheduledAtUtc: occurrence.scheduledAtUtc,
                completedAtUtc: occurrence.completedAtUtc,
                status: _occurrenceStatus(occurrence.status),
              ),
          ],
        ),
      );
    }
    return List.unmodifiable(result);
  }

  Future<void> updateOccurrence(
    String occurrenceId,
    ExperimentOccurrenceStatus status, {
    DateTime? completedAtUtc,
  }) async {
    final occurrence = await (database.select(
      database.experimentOccurrences,
    )..where((row) => row.id.equals(occurrenceId))).getSingleOrNull();
    if (occurrence == null) {
      throw StateError('Experiment occurrence does not exist');
    }
    await _requireCurrentProtocol(occurrence.experimentProtocolId);
    await (database.update(
      database.experimentOccurrences,
    )..where((item) => item.id.equals(occurrenceId))).write(
      ExperimentOccurrencesCompanion(
        status: Value(status.name),
        completedAtUtc: Value(completedAtUtc),
      ),
    );
  }

  Future<void> recordAdherence({
    required String occurrenceId,
    required bool adhered,
    required DateTime recordedAtUtc,
    String? note,
  }) async {
    final occurrence = await (database.select(
      database.experimentOccurrences,
    )..where((item) => item.id.equals(occurrenceId))).getSingleOrNull();
    if (occurrence == null) {
      throw StateError('Experiment occurrence does not exist');
    }
    await _requireCurrentProtocol(occurrence.experimentProtocolId);
    const checkableStatuses = {'upcoming', 'reminderScheduled', 'due'};
    if (!checkableStatuses.contains(occurrence.status) ||
        occurrence.scheduledAtUtc.isAfter(recordedAtUtc)) {
      throw StateError('Experiment occurrence is not due');
    }
    final id = '$occurrenceId:${recordedAtUtc.microsecondsSinceEpoch}';
    final response = <String, Object?>{'adhered': adhered};
    if (note != null) response['note'] = note;
    await database
        .into(database.adherenceCheckins)
        .insert(
          AdherenceCheckinsCompanion.insert(
            id: id,
            experimentOccurrenceId: occurrenceId,
            responseJson: jsonEncode(response),
            recordedAtUtc: recordedAtUtc,
          ),
        );
    await updateOccurrence(
      occurrenceId,
      adhered
          ? ExperimentOccurrenceStatus.adhered
          : ExperimentOccurrenceStatus.partiallyAdhered,
      completedAtUtc: recordedAtUtc,
    );
    final protocolOccurrences =
        await (database.select(database.experimentOccurrences)..where(
              (item) => item.experimentProtocolId.equals(
                occurrence.experimentProtocolId,
              ),
            ))
            .get();
    const finished = {
      'adhered',
      'partiallyAdhered',
      'skipped',
      'missingCheckin',
      'calendarCancelled',
      'ineligible',
    };
    if (protocolOccurrences.isNotEmpty &&
        protocolOccurrences.every((item) => finished.contains(item.status))) {
      await _writeProtocolStatus(
        occurrence.experimentProtocolId,
        ExperimentProtocolStatus.completed,
      );
    }
  }

  Future<void> pause(String protocolId) async {
    await _cancelOutstandingReminders(protocolId);
    await _writeProtocolStatus(protocolId, ExperimentProtocolStatus.paused);
  }

  Future<void> resume(String protocolId) async {
    await _requireCurrentProtocol(protocolId);
    await _writeProtocolStatus(protocolId, ExperimentProtocolStatus.active);
    final occurrences = await (database.select(
      database.experimentOccurrences,
    )..where((item) => item.experimentProtocolId.equals(protocolId))).get();
    if (await _reminders.requestPermission()) {
      final now = DateTime.now().toUtc();
      for (final occurrence in occurrences.where(
        (item) => item.status == ExperimentOccurrenceStatus.upcoming.name,
      )) {
        final reminderAt = occurrence.scheduledAtUtc.subtract(
          const Duration(minutes: 10),
        );
        if (!reminderAt.isAfter(now)) continue;
        await _reminders.schedule(
          id: occurrence.id,
          atUtc: reminderAt,
          title: 'Vueniverse experiment',
          body:
              'Pause work in your usual place for the 10-minute quiet buffer.',
        );
      }
    }
  }

  Future<void> cancel(String protocolId) async {
    await _cancelOutstandingReminders(protocolId);
    await _writeProtocolStatus(protocolId, ExperimentProtocolStatus.cancelled);
  }

  Future<void> stop(String protocolId) async {
    await _cancelOutstandingReminders(protocolId);
    await _writeProtocolStatus(protocolId, ExperimentProtocolStatus.stopped);
  }

  Future<void> appendResult({
    required String protocolId,
    required ExperimentOutcome outcome,
    required String evidenceHash,
    required int analysisVersion,
    required Map<String, Object?> details,
  }) async {
    await _requireCurrentProtocol(protocolId);
    final protocol = await (database.select(
      database.experimentProtocols,
    )..where((row) => row.id.equals(protocolId))).getSingle();
    if (protocol.evidenceBundleId != null) {
      final evidence = await EvidenceValidityRepository(
        database,
      ).load(protocol.evidenceBundleId!);
      if (evidence == null ||
          evidence.evidenceHash != evidenceHash ||
          analysisVersion != SchemaVersions.meetingAnalysis) {
        throw StateError('Result does not match current analytical evidence');
      }
    }
    final id = '$protocolId:result:${DateTime.now().microsecondsSinceEpoch}';
    await database
        .into(database.experimentResults)
        .insert(
          ExperimentResultsCompanion.insert(
            id: id,
            experimentProtocolId: protocolId,
            outcome: outcome.name,
            resultJson: jsonEncode(details),
            evidenceHash: evidenceHash,
            analysisVersion: analysisVersion,
          ),
        );
  }

  Future<void> _requireCurrentProtocol(String id) async {
    final row = await (database.select(
      database.experimentProtocols,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (row == null ||
        row.status == 'invalidated' ||
        row.status == 'cancelled' ||
        row.status == 'stopped') {
      throw StateError('Experiment is unavailable');
    }
    if (row.evidenceBundleId != null &&
        await resolveStartContext(evidenceBundleId: row.evidenceBundleId!) ==
            null) {
      throw StateError('Experiment backing evidence is stale');
    }
  }

  ExperimentProtocolModel _decodeProtocol(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is Map) {
        return ExperimentProtocolModel(
          id: '',
          evidenceBundleId: null,
          findingVersionId: value['finding_version_id'] as String? ?? '',
          recurrenceKeyHmac: value['recurrence_key_hmac'] as String? ?? '',
          status: ExperimentProtocolStatus.active,
          createdAtUtc: DateTime.fromMillisecondsSinceEpoch(0),
          occurrences: const [],
        );
      }
    } on FormatException {
      // A corrupt protocol is returned as an empty, non-runnable protocol.
    }
    return ExperimentProtocolModel.empty();
  }

  ExperimentProtocolStatus _protocolStatus(String value) =>
      ExperimentProtocolStatus.values.firstWhere(
        (item) => item.name == value,
        orElse: () => ExperimentProtocolStatus.invalidated,
      );

  ExperimentOccurrenceStatus _occurrenceStatus(String value) =>
      ExperimentOccurrenceStatus.values.firstWhere(
        (item) => item.name == value,
        orElse: () => ExperimentOccurrenceStatus.ineligible,
      );

  Future<void> _cancelOutstandingReminders(String protocolId) async {
    final occurrences = await (database.select(
      database.experimentOccurrences,
    )..where((item) => item.experimentProtocolId.equals(protocolId))).get();
    for (final occurrence in occurrences) {
      await _reminders.cancel(occurrence.id);
    }
  }

  Future<void> _writeProtocolStatus(
    String protocolId,
    ExperimentProtocolStatus status,
  ) =>
      (database.update(
        database.experimentProtocols,
      )..where((item) => item.id.equals(protocolId))).write(
        ExperimentProtocolsCompanion(
          status: Value(status.name),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
}
