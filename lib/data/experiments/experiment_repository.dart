import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/experiments/experiment_reminder_scheduler.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';
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
    if (finding == null) return null;
    final event =
        await (database.select(database.contextEvents)
              ..where(
                (row) =>
                    row.category.equals(ContextCategory.recurringOneToOne.name),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.startAtUtc)])
              ..limit(1))
            .getSingleOrNull();
    return (
      findingVersionId: finding.id,
      recurrenceKeyHmac: event?.recurrenceKeyHmac,
    );
  }

  Future<ExperimentProtocolModel> start({
    required String evidenceBundleId,
    required String findingVersionId,
    required String recurrenceKeyHmac,
    required DateTime createdAtUtc,
    List<ExperimentOccurrenceModel> occurrences = const [],
  }) async {
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
      result.add(
        ExperimentProtocolModel(
          id: row.id,
          evidenceBundleId: row.evidenceBundleId,
          findingVersionId: protocol.findingVersionId,
          recurrenceKeyHmac: protocol.recurrenceKeyHmac,
          status: _protocolStatus(row.status),
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
