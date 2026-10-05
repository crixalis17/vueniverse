import 'package:vueniverse/domain/store_kind.dart';

/// Metadata only: no values, journal text, titles, or provider record IDs.
final class CollectionCoverage {
  const CollectionCoverage({required this.storeKind, required this.groups});
  final StoreKind storeKind;
  final List<CollectionCoverageGroup> groups;
  int get retainedRecords => groups.fold(0, (sum, group) => sum + group.count);
}

final class CollectionCoverageGroup {
  const CollectionCoverageGroup({
    required this.sourceConnectionId,
    required this.sourceKind,
    required this.canonicalKind,
    required this.recordType,
    required this.count,
    required this.firstObservedAtUtc,
    required this.lastObservedAtUtc,
    required this.lastIndexedAtUtc,
  });
  final String sourceConnectionId;
  final String sourceKind;
  final String canonicalKind;
  final String recordType;
  final int count;
  final DateTime firstObservedAtUtc;
  final DateTime lastObservedAtUtc;
  final DateTime lastIndexedAtUtc;
}

/// Accepted is normalization throughput, not newly inserted records.
final class CollectionReceipt {
  const CollectionReceipt({
    required this.id,
    required this.kind,
    required this.sourceConnectionId,
    required this.status,
    required this.recordedAtUtc,
    required this.finishedAtUtc,
    required this.recordsSeen,
    required this.recordsAccepted,
    required this.recordsRejected,
    required this.recordsDeleted,
    required this.rejectionReasons,
    required this.hasError,
    required this.deletionReason,
    this.receiptSchema,
    this.recordsInserted,
    this.recordsChanged,
    this.recordsDuplicate,
    this.reportedTimezone,
    this.requestedLocalDate,
  });
  final String id;
  final String kind;
  final String? sourceConnectionId;
  final String status;
  final DateTime recordedAtUtc;
  final DateTime? finishedAtUtc;
  final int? recordsSeen;
  final int? recordsAccepted;
  final int? recordsRejected;
  final int? recordsDeleted;
  final Map<String, int> rejectionReasons;
  final bool hasError;
  final String? deletionReason;

  // Versioned metadata only; legacy or malformed counters remain unknown.
  final int? receiptSchema;
  final int? recordsInserted;
  final int? recordsChanged;
  final int? recordsDuplicate;
  final String? reportedTimezone;
  final String? requestedLocalDate;
  CollectionHistoryCursor get cursor =>
      CollectionHistoryCursor(recordedAtUtc: recordedAtUtc, kind: kind, id: id);
}

final class CollectionHistoryCursor {
  const CollectionHistoryCursor({
    required this.recordedAtUtc,
    required this.kind,
    required this.id,
  });
  final DateTime recordedAtUtc;
  final String kind;
  final String id;
}

final class CollectionHistoryPage {
  const CollectionHistoryPage({
    required this.storeKind,
    required this.receipts,
    required this.nextCursor,
  });
  final StoreKind storeKind;
  final List<CollectionReceipt> receipts;
  final CollectionHistoryCursor? nextCursor;
}
