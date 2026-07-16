typedef JsonMap = Map<String, Object?>;

enum SourceKind {
  healthConnect,
  calendar,
  manual,
  demoHealth,
  demoCalendar,
  demoManual,
}

enum SignalKind { heartRate, heartRateVariability, steps }

enum HealthIntervalKind { sleep, workout, activity }

enum ContextCategory { recurringOneToOne, teamMeeting, otherRecurringMeeting }

enum CheckinCategory { caffeine, exercise, illness, mood, travel, custom }

enum RecomputeStatus { pending, running, completed, failed }

enum AnalysisStatus { pending, running, completed, failed, stale }

enum EvidenceState {
  supported,
  developing,
  nullFinding,
  contradictory,
  insufficientData,
  stale,
  invalidated,
}

enum ExperimentState { draft, active, paused, completed, invalidated }

enum ExperimentResultState { strengthened, weakened, unchanged, inconclusive }

final class SourceRecordEnvelope {
  const SourceRecordEnvelope({
    required this.source,
    required this.recordType,
    required this.payload,
    required this.observedAt,
    this.stableSourceId,
    this.parentStableSourceId,
  });

  final SourceKind source;
  final String recordType;
  final JsonMap payload;
  final DateTime observedAt;
  final String? stableSourceId;
  final String? parentStableSourceId;
}

final class SourceProvenance {
  const SourceProvenance({
    required this.source,
    required this.sourceRecordIdentity,
    required this.observedAtUtc,
    required this.normalizationVersion,
    this.parentSourceRecordIdentity,
  });

  final SourceKind source;
  final String sourceRecordIdentity;
  final DateTime observedAtUtc;
  final int normalizationVersion;
  final String? parentSourceRecordIdentity;

  JsonMap toJson() => {
    'source': source.name,
    'sourceRecordIdentity': sourceRecordIdentity,
    'observedAtUtc': observedAtUtc.toUtc().toIso8601String(),
    'normalizationVersion': normalizationVersion,
    if (parentSourceRecordIdentity != null)
      'parentSourceRecordIdentity': parentSourceRecordIdentity,
  };
}

final class CanonicalSignalSample {
  const CanonicalSignalSample({
    required this.id,
    required this.kind,
    required this.occurredAtUtc,
    required this.value,
    required this.unit,
    required this.originalOffsetMinutes,
    required this.originalLocalDate,
    required this.provenance,
    required this.canonicalPayloadHash,
  });

  final String id;
  final SignalKind kind;
  final DateTime occurredAtUtc;
  final double value;
  final String unit;
  final int originalOffsetMinutes;
  final String originalLocalDate;
  final SourceProvenance provenance;
  final String canonicalPayloadHash;
}

final class CanonicalHealthInterval {
  const CanonicalHealthInterval({
    required this.id,
    required this.kind,
    required this.category,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.originalOffsetMinutes,
    required this.originalLocalDate,
    required this.provenance,
    required this.canonicalPayloadHash,
  });

  final String id;
  final HealthIntervalKind kind;
  final String category;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final int originalOffsetMinutes;
  final String originalLocalDate;
  final SourceProvenance provenance;
  final String canonicalPayloadHash;
}

final class CanonicalContextEvent {
  const CanonicalContextEvent({
    required this.id,
    required this.category,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.originalOffsetMinutes,
    required this.originalLocalDate,
    required this.provenance,
    required this.canonicalPayloadHash,
    this.recurrenceKeyHmac,
  });

  final String id;
  final ContextCategory category;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final String? recurrenceKeyHmac;
  final int originalOffsetMinutes;
  final String originalLocalDate;
  final SourceProvenance provenance;
  final String canonicalPayloadHash;
}

final class CanonicalManualCheckin {
  const CanonicalManualCheckin({
    required this.id,
    required this.category,
    required this.occurredAtUtc,
    required this.value,
    required this.originalOffsetMinutes,
    required this.originalLocalDate,
    required this.provenance,
    required this.canonicalPayloadHash,
  });

  final String id;
  final CheckinCategory category;
  final DateTime occurredAtUtc;
  final JsonMap value;
  final int originalOffsetMinutes;
  final String originalLocalDate;
  final SourceProvenance provenance;
  final String canonicalPayloadHash;
}

final class SyncCheckpoint {
  const SyncCheckpoint({
    required this.sourceConnectionId,
    required this.recordType,
    required this.cursor,
    required this.updatedAtUtc,
  });

  final String sourceConnectionId;
  final String recordType;
  final String cursor;
  final DateTime updatedAtUtc;
}

final class RecomputeRequest {
  const RecomputeRequest({
    required this.id,
    required this.dirtyStartUtc,
    required this.dirtyEndUtc,
    required this.reason,
    required this.status,
    required this.analysisVersion,
    this.sourceId,
    this.retryCount = 0,
    this.lastCheckpoint,
  });

  final String id;
  final DateTime dirtyStartUtc;
  final DateTime dirtyEndUtc;
  final String reason;
  final String? sourceId;
  final RecomputeStatus status;
  final int retryCount;
  final String? lastCheckpoint;
  final int analysisVersion;
}

final class AnalysisRun {
  const AnalysisRun({
    required this.id,
    required this.status,
    required this.rangeStartUtc,
    required this.rangeEndUtc,
    required this.analysisVersion,
    required this.inputHash,
    this.outputHash,
  });

  final String id;
  final AnalysisStatus status;
  final DateTime rangeStartUtc;
  final DateTime rangeEndUtc;
  final int analysisVersion;
  final String inputHash;
  final String? outputHash;
}

final class EventWindow {
  const EventWindow({
    required this.id,
    required this.contextEventId,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.included,
    this.exclusionReason,
  });

  final String id;
  final String contextEventId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final bool included;
  final String? exclusionReason;
}

final class ControlMatch {
  const ControlMatch({
    required this.id,
    required this.eventWindowId,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.score,
    required this.factors,
  });

  final String id;
  final String eventWindowId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final double score;
  final JsonMap factors;
}

final class EvidenceMetric {
  const EvidenceMetric({
    required this.name,
    required this.value,
    required this.unit,
    this.lowerBound,
    this.upperBound,
  });

  final String name;
  final double value;
  final String unit;
  final double? lowerBound;
  final double? upperBound;
}

final class EvidenceBundle {
  const EvidenceBundle({
    required this.id,
    required this.state,
    required this.title,
    required this.claimType,
    required this.evidenceHash,
    required this.metrics,
    required this.promotionPolicyVersion,
    required this.createdAtUtc,
  });

  final String id;
  final EvidenceState state;
  final String title;
  final String claimType;
  final String evidenceHash;
  final List<EvidenceMetric> metrics;
  final int promotionPolicyVersion;
  final DateTime createdAtUtc;
}

final class FindingVersion {
  const FindingVersion({
    required this.id,
    required this.findingId,
    required this.evidenceBundleId,
    required this.version,
    required this.state,
    required this.validFromUtc,
    this.validUntilUtc,
    this.supersedesId,
  });

  final String id;
  final String findingId;
  final String evidenceBundleId;
  final int version;
  final EvidenceState state;
  final DateTime validFromUtc;
  final DateTime? validUntilUtc;
  final String? supersedesId;
}

final class ExplanationRecord {
  const ExplanationRecord({
    required this.id,
    required this.evidenceBundleId,
    required this.runtime,
    required this.content,
    required this.safetyState,
    required this.promptVersion,
    required this.outputGuardVersion,
    required this.createdAtUtc,
  });

  final String id;
  final String evidenceBundleId;
  final String runtime;
  final String content;
  final String safetyState;
  final int promptVersion;
  final int outputGuardVersion;
  final DateTime createdAtUtc;
}

final class ExperimentProtocol {
  const ExperimentProtocol({
    required this.id,
    required this.title,
    required this.state,
    required this.protocol,
    required this.version,
    this.evidenceBundleId,
  });

  final String id;
  final String? evidenceBundleId;
  final String title;
  final ExperimentState state;
  final JsonMap protocol;
  final int version;
}

final class ExperimentOccurrence {
  const ExperimentOccurrence({
    required this.id,
    required this.experimentProtocolId,
    required this.scheduledAtUtc,
    required this.status,
    required this.context,
    this.completedAtUtc,
  });

  final String id;
  final String experimentProtocolId;
  final DateTime scheduledAtUtc;
  final DateTime? completedAtUtc;
  final String status;
  final JsonMap context;
}

final class AdherenceCheckIn {
  const AdherenceCheckIn({
    required this.id,
    required this.experimentOccurrenceId,
    required this.response,
    required this.recordedAtUtc,
  });

  final String id;
  final String experimentOccurrenceId;
  final JsonMap response;
  final DateTime recordedAtUtc;
}

final class ExperimentResult {
  const ExperimentResult({
    required this.id,
    required this.experimentProtocolId,
    required this.outcome,
    required this.result,
    required this.evidenceHash,
    required this.analysisVersion,
    required this.createdAtUtc,
  });

  final String id;
  final String experimentProtocolId;
  final ExperimentResultState outcome;
  final JsonMap result;
  final String evidenceHash;
  final int analysisVersion;
  final DateTime createdAtUtc;
}

final class ExportRecord {
  const ExportRecord({
    required this.id,
    required this.exportType,
    required this.status,
    required this.filePath,
    required this.exportSchemaVersion,
    required this.createdAtUtc,
    this.contentHash,
  });

  final String id;
  final String exportType;
  final String status;
  final String filePath;
  final String? contentHash;
  final int exportSchemaVersion;
  final DateTime createdAtUtc;
}
