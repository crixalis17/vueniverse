import 'package:vueniverse/domain/analytics/meeting_analysis_models.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

enum CaffeineContextState { reportedZero, recordedExposure, unknown }

/// Conservative context screening, not a causal or medical assessment.
final class CaffeineContextPolicy {
  const CaffeineContextPolicy();

  static const lookback = Duration(hours: 4);

  List<AnalysisInfluence> relevant(
    List<AnalysisInfluence> influences, {
    required DateTime endUtc,
    required DateTime nowUtc,
  }) {
    final start = endUtc.subtract(lookback);
    return influences
        .where((item) {
          if (item.category != CheckinCategory.caffeine ||
              item.occurredAtUtc.isAfter(nowUtc)) {
            return false;
          }
          final pointInWindow =
              !item.occurredAtUtc.isBefore(start) &&
              !item.occurredAtUtc.isAfter(endUtc);
          final from = item.coverageStartUtc;
          final to = item.coverageEndUtc;
          final intervalOverlaps =
              from != null &&
              to != null &&
              from.isBefore(to) &&
              from.isBefore(endUtc) &&
              to.isAfter(start);
          return pointInWindow || intervalOverlaps;
        })
        .toList(growable: false);
  }

  CaffeineContextState assess(
    List<AnalysisInfluence> influences, {
    required DateTime endUtc,
    required DateTime nowUtc,
  }) {
    final rows = relevant(influences, endUtc: endUtc, nowUtc: nowUtc);
    bool coversWindow = false;
    bool ambiguous = false;
    for (final item in rows) {
      final amount = item.caffeineServings;
      if (item.provenanceHash.isEmpty ||
          amount == null ||
          !amount.isFinite ||
          amount < 0) {
        ambiguous = true;
        continue;
      }
      // A positive report cannot be cancelled by a conflicting zero report.
      if (amount > 0) return CaffeineContextState.recordedExposure;
      final from = item.coverageStartUtc;
      final to = item.coverageEndUtc;
      if (from == null ||
          to == null ||
          !from.isBefore(to) ||
          to.isAfter(item.occurredAtUtc)) {
        ambiguous = true;
        continue;
      }
      if (!from.isAfter(endUtc.subtract(lookback)) && !to.isBefore(endUtc)) {
        coversWindow = true;
      }
    }
    return coversWindow && !ambiguous
        ? CaffeineContextState.reportedZero
        : CaffeineContextState.unknown;
  }
}
