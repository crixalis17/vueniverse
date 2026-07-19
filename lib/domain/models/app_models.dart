import 'package:flutter/material.dart';

enum AppMode { live, demo }

enum FeatureTier { core, preview, later }

enum SourceStatus {
  connected,
  available,
  limited,
  paused,
  unavailable,
  permissionRequired,
  partiallyPermitted,
  syncing,
  connectedEmpty,
  connectedData,
  error,
  disconnected,
  deleting,
  stale,
  demoFixtureLoaded,
  availableInLive,
}

enum ExperimentStatus {
  draft,
  active,
  paused,
  completed,
  cancelled,
  stopped,
  invalidated,
}

enum ExperimentOutcome { strengthened, weakened, unchanged, inconclusive }

enum SourceAction {
  connect,
  refresh,
  pause,
  resume,
  disconnect,
  deleteData,
  openSettings,
}

class SourceData {
  const SourceData({
    required this.id,
    required this.name,
    required this.description,
    required this.contribution,
    required this.icon,
    required this.status,
    required this.tier,
    this.lastSync,
    this.completeness = 0,
    this.statusDetail,
    this.recordCount = 0,
    this.permissionsGranted = 0,
    this.permissionsTotal = 0,
  });

  final String id;
  final String name;
  final String description;
  final String contribution;
  final IconData icon;
  final SourceStatus status;
  final FeatureTier tier;
  final String? lastSync;
  final int completeness;
  final String? statusDetail;
  final int recordCount;
  final int permissionsGranted;
  final int permissionsTotal;

  SourceData copyWith({
    SourceStatus? status,
    String? lastSync,
    int? completeness,
    String? statusDetail,
    int? recordCount,
    int? permissionsGranted,
    int? permissionsTotal,
  }) {
    return SourceData(
      id: id,
      name: name,
      description: description,
      contribution: contribution,
      icon: icon,
      status: status ?? this.status,
      tier: tier,
      lastSync: lastSync ?? this.lastSync,
      completeness: completeness ?? this.completeness,
      statusDetail: statusDetail ?? this.statusDetail,
      recordCount: recordCount ?? this.recordCount,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      permissionsTotal: permissionsTotal ?? this.permissionsTotal,
    );
  }
}

class CheckInData {
  const CheckInData({
    required this.id,
    required this.when,
    required this.context,
    required this.detail,
    required this.icon,
    this.category = 'custom',
    this.customLabel,
  });

  final String id;
  final DateTime when;
  final String context;
  final String detail;
  final IconData icon;
  final String category;
  final String? customLabel;
}

enum ObserveActivityKind { sleep, workout, calendar, checkIn, steps }

class ObserveDayData {
  const ObserveDayData({
    required this.day,
    required this.heartRateMedianBpm,
    required this.sleepMinutes,
    required this.steps,
    required this.eventCount,
    required this.checkInCount,
    required this.recordCount,
  });

  final DateTime day;
  final double? heartRateMedianBpm;
  final double? sleepMinutes;
  final double? steps;
  final int eventCount;
  final int checkInCount;
  final int recordCount;

  int get visibleStreamCount => [
    heartRateMedianBpm,
    sleepMinutes,
    steps,
    if (eventCount > 0) eventCount,
    if (checkInCount > 0) checkInCount,
  ].where((value) => value != null).length;
}

class ObserveActivityData {
  const ObserveActivityData({
    required this.kind,
    required this.title,
    required this.detail,
    required this.occurredAt,
  });

  final ObserveActivityKind kind;
  final String title;
  final String detail;
  final DateTime occurredAt;
}

class ObserveDashboardData {
  const ObserveDashboardData({
    required this.rangeStart,
    required this.rangeEnd,
    required this.asOf,
    required this.isDemo,
    required this.days,
    required this.recentActivity,
    required this.heartRateRecords,
    required this.hrvRecords,
    required this.stepRecords,
    required this.sleepRecords,
    required this.workoutRecords,
    required this.activityRecords,
    required this.eventRecords,
    required this.checkInRecords,
  });

  final DateTime rangeStart;
  final DateTime rangeEnd;
  final DateTime asOf;
  final bool isDemo;
  final List<ObserveDayData> days;
  final List<ObserveActivityData> recentActivity;
  final int heartRateRecords;
  final int hrvRecords;
  final int stepRecords;
  final int sleepRecords;
  final int workoutRecords;
  final int activityRecords;
  final int eventRecords;
  final int checkInRecords;

  int get totalRecordCount =>
      heartRateRecords +
      hrvRecords +
      stepRecords +
      sleepRecords +
      workoutRecords +
      activityRecords +
      eventRecords +
      checkInRecords;

  int get healthRecordCount =>
      heartRateRecords +
      hrvRecords +
      stepRecords +
      sleepRecords +
      workoutRecords +
      activityRecords;

  int get activeDayCount => days.where((day) => day.recordCount > 0).length;

  int get activeStreamCount => [
    heartRateRecords,
    hrvRecords,
    stepRecords,
    sleepRecords,
    workoutRecords,
    activityRecords,
    eventRecords,
    checkInRecords,
  ].where((count) => count > 0).length;

  bool get isEmpty => totalRecordCount == 0;
}

final class ReplayTraceData {
  const ReplayTraceData({required this.label, required this.valuesBpm});

  final String label;
  final List<double> valuesBpm;
}

final class MomentReplayData {
  const MomentReplayData({
    required this.phases,
    required this.traces,
    required this.matchedBaselineBpm,
    required this.sourceLabel,
  });

  final List<String> phases;
  final List<ReplayTraceData> traces;
  final List<double> matchedBaselineBpm;
  final String sourceLabel;

  bool get isUsable =>
      phases.length >= 2 &&
      matchedBaselineBpm.length == phases.length &&
      traces.isNotEmpty &&
      traces.every((trace) => trace.valuesBpm.length == phases.length);
}

class CalendarSeriesData {
  const CalendarSeriesData({
    required this.transientId,
    required this.title,
    required this.recurrenceRule,
    required this.timeZone,
    this.category,
  });

  final String transientId;
  final String title;
  final String recurrenceRule;
  final String timeZone;
  final String? category;

  CalendarSeriesData copyWith({String? category}) => CalendarSeriesData(
    transientId: transientId,
    title: title,
    recurrenceRule: recurrenceRule,
    timeZone: timeZone,
    category: category ?? this.category,
  );
}

class ChatMessageData {
  const ChatMessageData({
    required this.text,
    required this.fromUser,
    this.evidence = const [],
    this.uncertainty,
    this.runtimeLabel,
    this.modelName,
    this.latencyMillis,
  });

  final String text;
  final bool fromUser;
  final List<String> evidence;
  final String? uncertainty;
  final String? runtimeLabel;
  final String? modelName;
  final int? latencyMillis;
}

class ExplanationParagraphData {
  const ExplanationParagraphData({required this.text, required this.citations});

  final String text;
  final List<String> citations;
}

class ExplanationData {
  const ExplanationData({
    required this.summary,
    required this.paragraphs,
    required this.uncertainty,
    required this.runtimeLabel,
    required this.deterministicFallback,
    required this.fromCache,
    required this.createdAt,
    this.modelName,
    this.latencyMillis,
    this.nextObservation,
  });

  final String summary;
  final List<ExplanationParagraphData> paragraphs;
  final String uncertainty;
  final String runtimeLabel;
  final bool deterministicFallback;
  final bool fromCache;
  final DateTime createdAt;
  final String? modelName;
  final int? latencyMillis;
  final String? nextObservation;
}

class HistoryItemData {
  const HistoryItemData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    required this.icon,
    required this.accent,
    this.invalidated = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String date;
  final String status;
  final IconData icon;
  final Color accent;
  final bool invalidated;
}

final class FindingData {
  const FindingData({
    required this.status,
    required this.title,
    required this.evidenceHash,
    required this.evidenceVersion,
    required this.candidateCount,
    required this.includedCount,
    required this.controlsCount,
    required this.positiveCount,
    required this.counterevidenceCount,
    required this.medianDifferenceBpm,
    required this.effectLowerBpm,
    required this.effectUpperBpm,
    required this.completeness,
    required this.recoveryDurationMinutes,
    required this.unresolvedInfluenceCount,
    required this.createdAt,
    this.invalidated = false,
  });

  final String status;
  final String title;
  final String evidenceHash;
  final String evidenceVersion;
  final int candidateCount;
  final int includedCount;
  final int controlsCount;
  final int positiveCount;
  final int counterevidenceCount;
  final double medianDifferenceBpm;
  final double effectLowerBpm;
  final double effectUpperBpm;
  final double completeness;
  final double recoveryDurationMinutes;
  final int unresolvedInfluenceCount;
  final DateTime createdAt;
  final bool invalidated;

  bool get isCurrent => !invalidated && status == 'supported';
}

class EvidenceFact {
  const EvidenceFact({
    required this.label,
    required this.value,
    required this.detail,
    required this.source,
    required this.accent,
  });

  final String label;
  final String value;
  final String detail;
  final String source;
  final Color accent;
}
