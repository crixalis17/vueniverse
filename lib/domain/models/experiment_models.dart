enum ExperimentProtocolStatus {
  draft,
  active,
  paused,
  completed,
  cancelled,
  stopped,
  invalidated,
}

enum ExperimentOccurrenceStatus {
  upcoming,
  reminderScheduled,
  due,
  adhered,
  partiallyAdhered,
  skipped,
  missingCheckin,
  calendarCancelled,
  ineligible,
}

enum ExperimentOutcome { strengthened, weakened, unchanged, inconclusive }

final class ExperimentOccurrenceModel {
  const ExperimentOccurrenceModel({
    required this.id,
    required this.scheduledAtUtc,
    required this.status,
    this.completedAtUtc,
  });

  final String id;
  final DateTime scheduledAtUtc;
  final DateTime? completedAtUtc;
  final ExperimentOccurrenceStatus status;
}

final class ExperimentProtocolModel {
  const ExperimentProtocolModel({
    required this.id,
    required this.evidenceBundleId,
    required this.findingVersionId,
    required this.recurrenceKeyHmac,
    required this.status,
    required this.createdAtUtc,
    required this.occurrences,
  });

  ExperimentProtocolModel.empty()
    : id = '',
      evidenceBundleId = null,
      findingVersionId = '',
      recurrenceKeyHmac = '',
      status = ExperimentProtocolStatus.invalidated,
      createdAtUtc = DateTime.fromMillisecondsSinceEpoch(0),
      occurrences = const [];

  final String id;
  final String? evidenceBundleId;
  final String findingVersionId;
  final String recurrenceKeyHmac;
  final ExperimentProtocolStatus status;
  final DateTime createdAtUtc;
  final List<ExperimentOccurrenceModel> occurrences;
}
