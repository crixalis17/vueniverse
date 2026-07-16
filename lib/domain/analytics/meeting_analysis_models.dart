import 'package:why_pulse/domain/models/canonical_domain_models.dart';

final class AnalysisHeartRate {
  const AnalysisHeartRate({
    required this.id,
    required this.occurredAtUtc,
    required this.valueBpm,
    required this.offsetMinutes,
    required this.provenanceHash,
  });

  final String id;
  final DateTime occurredAtUtc;
  final double valueBpm;
  final int offsetMinutes;
  final String provenanceHash;
}

final class AnalysisContextEvent {
  const AnalysisContextEvent({
    required this.id,
    required this.category,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.offsetMinutes,
    required this.provenanceHash,
    this.recurrenceKeyHmac,
  });

  final String id;
  final ContextCategory category;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final int offsetMinutes;
  final String provenanceHash;
  final String? recurrenceKeyHmac;
}

final class AnalysisHealthInterval {
  const AnalysisHealthInterval({
    required this.id,
    required this.kind,
    required this.startAtUtc,
    required this.endAtUtc,
    required this.provenanceHash,
  });

  final String id;
  final HealthIntervalKind kind;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
  final String provenanceHash;
}

final class AnalysisInfluence {
  const AnalysisInfluence({
    required this.id,
    required this.category,
    required this.occurredAtUtc,
    required this.provenanceHash,
  });

  final String id;
  final CheckinCategory category;
  final DateTime occurredAtUtc;
  final String provenanceHash;
}

final class MeetingAnalysisDataset {
  const MeetingAnalysisDataset({
    required this.nowUtc,
    required this.heartRate,
    required this.events,
    required this.healthIntervals,
    required this.influences,
  });

  final DateTime nowUtc;
  final List<AnalysisHeartRate> heartRate;
  final List<AnalysisContextEvent> events;
  final List<AnalysisHealthInterval> healthIntervals;
  final List<AnalysisInfluence> influences;
}

final class WindowMeasure {
  const WindowMeasure({
    required this.medianBpm,
    required this.completeness,
    required this.sampleIds,
  });

  final double? medianBpm;
  final double completeness;
  final List<String> sampleIds;
}

final class MeetingOccurrenceResult {
  const MeetingOccurrenceResult({
    required this.event,
    required this.pre,
    required this.during,
    required this.recovery,
    required this.control,
    required this.controlStartUtc,
    required this.controlEndUtc,
    required this.controlScore,
    required this.controlFactors,
    required this.dependencyIds,
    this.differenceBpm,
    this.recoveryDurationMinutes,
    this.exclusionReason,
  });

  final AnalysisContextEvent event;
  final WindowMeasure pre;
  final WindowMeasure during;
  final WindowMeasure recovery;
  final WindowMeasure control;
  final DateTime controlStartUtc;
  final DateTime controlEndUtc;
  final double controlScore;
  final Map<String, Object?> controlFactors;
  final List<String> dependencyIds;
  final double? differenceBpm;
  final int? recoveryDurationMinutes;
  final String? exclusionReason;

  bool get included => exclusionReason == null;
}

final class MeetingAnalysisResult {
  const MeetingAnalysisResult({
    required this.state,
    required this.title,
    required this.claimType,
    required this.rangeStartUtc,
    required this.rangeEndUtc,
    required this.occurrences,
    required this.candidateCount,
    required this.includedCount,
    required this.controlsCount,
    required this.positiveCount,
    required this.counterevidenceCount,
    required this.excludedByReason,
    required this.medianDifferenceBpm,
    required this.effectLowerBpm,
    required this.effectUpperBpm,
    required this.consistency,
    required this.completeness,
    required this.recoveryDurationMinutes,
    required this.unresolvedInfluenceCount,
    required this.promotionGates,
    required this.dependencyIds,
  });

  final EvidenceState state;
  final String title;
  final String claimType;
  final DateTime rangeStartUtc;
  final DateTime rangeEndUtc;
  final List<MeetingOccurrenceResult> occurrences;
  final int candidateCount;
  final int includedCount;
  final int controlsCount;
  final int positiveCount;
  final int counterevidenceCount;
  final Map<String, int> excludedByReason;
  final double medianDifferenceBpm;
  final double effectLowerBpm;
  final double effectUpperBpm;
  final double consistency;
  final double completeness;
  final double recoveryDurationMinutes;
  final int unresolvedInfluenceCount;
  final Map<String, bool> promotionGates;
  final List<String> dependencyIds;
}
