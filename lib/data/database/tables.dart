import 'package:drift/drift.dart';

@DataClassName('StoreMetadataRow')
class StoreMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('SourceConnectionRow')
class SourceConnections extends Table {
  TextColumn get id => text()();
  TextColumn get sourceType => text()();
  TextColumn get status => text()();
  TextColumn get configurationJson =>
      text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SourcePermissionRow')
class SourcePermissions extends Table {
  TextColumn get id => text()();
  TextColumn get sourceConnectionId =>
      text().references(SourceConnections, #id)();
  TextColumn get recordType => text()();
  TextColumn get status => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SyncRunRow')
class SyncRuns extends Table {
  TextColumn get id => text()();
  TextColumn get sourceConnectionId =>
      text().references(SourceConnections, #id)();
  TextColumn get status => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  IntColumn get recordsSeen => integer().withDefault(const Constant(0))();
  IntColumn get recordsAccepted => integer().withDefault(const Constant(0))();
  IntColumn get recordsRejected => integer().withDefault(const Constant(0))();
  TextColumn get errorCode => text().nullable()();
  TextColumn get errorDetails => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SyncCursorRow')
class SyncCursors extends Table {
  TextColumn get id => text()();
  TextColumn get sourceConnectionId =>
      text().references(SourceConnections, #id)();
  TextColumn get recordType => text()();
  TextColumn get cursor => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SyncSeenRecordRow')
class SyncSeenRecords extends Table {
  TextColumn get id => text()();
  TextColumn get syncRunId => text().references(SyncRuns, #id)();
  TextColumn get sourceRecordHmac => text()();
  DateTimeColumn get seenAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RawRecordIndexRow')
class RawRecordIndex extends Table {
  TextColumn get id => text()();
  TextColumn get sourceConnectionId =>
      text().references(SourceConnections, #id)();
  TextColumn get sourceKind => text()();
  TextColumn get sourceRecordHmac => text().nullable()();
  TextColumn get canonicalPayloadHash => text()();
  TextColumn get canonicalKind => text()();
  TextColumn get canonicalId => text()();
  DateTimeColumn get occurredAtUtc => dateTime()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SignalSampleRow')
class SignalSamples extends Table {
  TextColumn get id => text()();
  TextColumn get signalType => text()();
  DateTimeColumn get occurredAtUtc => dateTime()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  IntColumn get originalOffsetMinutes => integer()();
  TextColumn get originalLocalDate => text()();
  TextColumn get provenanceJson => text()();
  TextColumn get canonicalPayloadHash => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HealthIntervalRow')
class HealthIntervals extends Table {
  TextColumn get id => text()();
  TextColumn get intervalType => text()();
  TextColumn get category => text()();
  DateTimeColumn get startAtUtc => dateTime()();
  DateTimeColumn get endAtUtc => dateTime()();
  IntColumn get originalOffsetMinutes => integer()();
  TextColumn get originalLocalDate => text()();
  TextColumn get provenanceJson => text()();
  TextColumn get canonicalPayloadHash => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ContextEventRow')
class ContextEvents extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  DateTimeColumn get startAtUtc => dateTime()();
  DateTimeColumn get endAtUtc => dateTime()();
  TextColumn get recurrenceKeyHmac => text().nullable()();
  IntColumn get originalOffsetMinutes => integer()();
  TextColumn get originalLocalDate => text()();
  TextColumn get provenanceJson => text()();
  TextColumn get canonicalPayloadHash => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ManualCheckinRow')
class ManualCheckins extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  DateTimeColumn get occurredAtUtc => dateTime()();
  TextColumn get valueJson => text()();
  IntColumn get originalOffsetMinutes => integer()();
  TextColumn get originalLocalDate => text()();
  TextColumn get provenanceJson => text()();
  TextColumn get canonicalPayloadHash => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RecomputeJobRow')
class RecomputeJobs extends Table {
  TextColumn get id => text()();
  DateTimeColumn get dirtyStartUtc => dateTime()();
  DateTimeColumn get dirtyEndUtc => dateTime()();
  TextColumn get reason => text()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get status => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastCheckpoint => text().nullable()();
  IntColumn get analysisVersion => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AnalysisRunRow')
class AnalysisRuns extends Table {
  TextColumn get id => text()();
  TextColumn get status => text()();
  DateTimeColumn get rangeStartUtc => dateTime()();
  DateTimeColumn get rangeEndUtc => dateTime()();
  IntColumn get analysisVersion => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get inputHash => text()();
  TextColumn get outputHash => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EventWindowRow')
class EventWindows extends Table {
  TextColumn get id => text()();
  TextColumn get analysisRunId => text().references(AnalysisRuns, #id)();
  TextColumn get contextEventId => text().references(ContextEvents, #id)();
  DateTimeColumn get startAtUtc => dateTime()();
  DateTimeColumn get endAtUtc => dateTime()();
  TextColumn get status => text()();
  TextColumn get exclusionReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ControlMatchRow')
class ControlMatches extends Table {
  TextColumn get id => text()();
  TextColumn get eventWindowId => text().references(EventWindows, #id)();
  DateTimeColumn get startAtUtc => dateTime()();
  DateTimeColumn get endAtUtc => dateTime()();
  RealColumn get score => real()();
  TextColumn get factorsJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('WindowMetricRow')
class WindowMetrics extends Table {
  TextColumn get id => text()();
  TextColumn get eventWindowId => text().references(EventWindows, #id)();
  TextColumn get controlMatchId =>
      text().nullable().references(ControlMatches, #id)();
  TextColumn get metric => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  TextColumn get qualityState => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EvidenceBundleRow')
class EvidenceBundles extends Table {
  TextColumn get id => text()();
  TextColumn get analysisRunId => text().references(AnalysisRuns, #id)();
  TextColumn get status => text()();
  TextColumn get title => text()();
  TextColumn get claimType => text()();
  TextColumn get evidenceHash => text()();
  IntColumn get promotionPolicyVersion => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get staleAt => dateTime().nullable()();
  TextColumn get staleReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EvidenceMetricRow')
class EvidenceMetrics extends Table {
  TextColumn get id => text()();
  TextColumn get evidenceBundleId => text().references(EvidenceBundles, #id)();
  TextColumn get metric => text()();
  RealColumn get value => real()();
  RealColumn get lowerBound => real().nullable()();
  RealColumn get upperBound => real().nullable()();
  TextColumn get unit => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EvidenceDependencyRow')
class EvidenceDependencies extends Table {
  TextColumn get id => text()();
  TextColumn get evidenceBundleId => text().references(EvidenceBundles, #id)();
  TextColumn get dependencyKind => text()();
  TextColumn get dependencyId => text()();
  TextColumn get dependencyHash => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FindingVersionRow')
class FindingVersions extends Table {
  TextColumn get id => text()();
  TextColumn get findingId => text()();
  TextColumn get evidenceBundleId => text().references(EvidenceBundles, #id)();
  IntColumn get version => integer()();
  TextColumn get status => text()();
  DateTimeColumn get validFrom => dateTime()();
  DateTimeColumn get validUntil => dateTime().nullable()();
  TextColumn get supersedesId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExplanationRow')
class Explanations extends Table {
  TextColumn get id => text()();
  TextColumn get evidenceBundleId => text().references(EvidenceBundles, #id)();
  TextColumn get runtime => text()();
  TextColumn get content => text()();
  TextColumn get safetyState => text()();
  IntColumn get promptVersion => integer()();
  IntColumn get outputGuardVersion => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ChatSessionRow')
class ChatSessions extends Table {
  TextColumn get id => text()();
  TextColumn get evidenceBundleId => text().references(EvidenceBundles, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ChatMessageRow')
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get chatSessionId => text().references(ChatSessions, #id)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get safetyState => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExperimentProtocolRow')
class ExperimentProtocols extends Table {
  TextColumn get id => text()();
  TextColumn get evidenceBundleId =>
      text().nullable().references(EvidenceBundles, #id)();
  TextColumn get title => text()();
  TextColumn get status => text()();
  TextColumn get protocolJson => text()();
  IntColumn get version => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExperimentOccurrenceRow')
class ExperimentOccurrences extends Table {
  TextColumn get id => text()();
  TextColumn get experimentProtocolId =>
      text().references(ExperimentProtocols, #id)();
  DateTimeColumn get scheduledAtUtc => dateTime()();
  DateTimeColumn get completedAtUtc => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get contextJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AdherenceCheckinRow')
class AdherenceCheckins extends Table {
  TextColumn get id => text()();
  TextColumn get experimentOccurrenceId =>
      text().references(ExperimentOccurrences, #id)();
  TextColumn get responseJson => text()();
  DateTimeColumn get recordedAtUtc => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExperimentResultRow')
class ExperimentResults extends Table {
  TextColumn get id => text()();
  TextColumn get experimentProtocolId =>
      text().references(ExperimentProtocols, #id)();
  TextColumn get outcome => text()();
  TextColumn get resultJson => text()();
  TextColumn get evidenceHash => text()();
  IntColumn get analysisVersion => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get invalidatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExperimentDependencyRow')
class ExperimentDependencies extends Table {
  TextColumn get id => text()();
  TextColumn get experimentResultId =>
      text().references(ExperimentResults, #id)();
  TextColumn get dependencyKind => text()();
  TextColumn get dependencyId => text()();
  TextColumn get dependencyHash => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ExportRecordRow')
class ExportRecords extends Table {
  TextColumn get id => text()();
  TextColumn get exportType => text()();
  TextColumn get status => text()();
  TextColumn get filePath => text()();
  TextColumn get contentHash => text().nullable()();
  IntColumn get exportSchemaVersion => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DeletionAuditRow')
class DeletionAudit extends Table {
  TextColumn get id => text()();
  TextColumn get scope => text()();
  TextColumn get sourceId => text().nullable()();
  IntColumn get recordsDeleted => integer()();
  TextColumn get invalidatedJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
