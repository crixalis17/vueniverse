import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/analytics/evidence_validity_repository.dart';
import 'package:vueniverse/domain/model_runtime/output_guard.dart';
import 'package:vueniverse/domain/store_kind.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

final class EvidenceProjection {
  const EvidenceProjection({
    required this.evidenceBundleId,
    required this.evidenceHash,
    required this.requestHash,
    required this.request,
    required this.guardContext,
  });

  final String evidenceBundleId;
  final String evidenceHash;
  final String requestHash;
  final ExplainerRequest request;
  final EvidenceGuardContext guardContext;
}

final class EvidenceProjectionRepository {
  const EvidenceProjectionRepository(this.database);

  final VueniverseDatabase database;

  Future<ExplorerRequest?> buildExplorer() async {
    final finding =
        await (database.select(database.findingVersions)
              ..where((row) => row.validUntil.isNull())
              ..orderBy([(row) => OrderingTerm.desc(row.version)]))
            .getSingleOrNull();
    if (finding == null || finding.status == 'invalidated') return null;
    final evidence =
        await (database.select(database.evidenceBundles)
              ..where((row) => row.id.equals(finding.evidenceBundleId)))
            .getSingleOrNull();
    if (evidence == null ||
        !await EvidenceValidityRepository(database).isCurrent(evidence)) {
      return null;
    }
    final analysis = await (database.select(
      database.analysisRuns,
    )..where((row) => row.id.equals(evidence.analysisRunId))).getSingleOrNull();
    if (analysis == null) return null;
    final windows =
        await (database.select(database.eventWindows)
              ..where((row) => row.analysisRunId.equals(evidence.analysisRunId))
              ..orderBy([(row) => OrderingTerm.asc(row.startAtUtc)]))
            .get();
    final contextIds = windows.map((window) => window.contextEventId).toSet();
    if (contextIds.isEmpty) return null;
    final contexts = await (database.select(
      database.contextEvents,
    )..where((row) => row.id.isIn(contextIds))).get();
    final contextById = {for (final context in contexts) context.id: context};
    final categoryIds = contexts
        .map((context) => _catalogueId(context.category))
        .toSet();
    if (categoryIds.isEmpty) return null;
    final checkins = await database.select(database.manualCheckins).get();
    const approvedInfluences = {'caffeine', 'exercise', 'illness', 'travel'};
    final influenceIds = checkins
        .map((checkin) => checkin.category)
        .where(approvedInfluences.contains)
        .toSet();
    final operations = <String>[
      'compare_repeated_event',
      'inspect_recovery',
      if (influenceIds.isNotEmpty) 'check_logged_influence',
    ];
    return ExplorerRequest(
      schemaVersion: 'explorer-v1',
      evidenceVersion: evidence.id,
      analysisVersion: analysis.analysisVersion,
      promptVersion: 1,
      eventSummariesJson: jsonEncode([
        for (final window in windows.take(30))
          if (contextById[window.contextEventId] case final context?)
            {
              'categoryId': _catalogueId(context.category),
              'localDate': context.originalLocalDate,
              'windowState': window.status,
              'excluded': window.exclusionReason != null,
            },
      ]),
      availableCategoryIds: categoryIds.toList()..sort(),
      availableInfluenceIds: influenceIds.toList()..sort(),
      allowedOperations: operations,
    );
  }

  String _catalogueId(String value) => value
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .toLowerCase();

  Future<EvidenceProjection?> build({
    required StoreKind storeKind,
    required String intent,
  }) async {
    final finding =
        await (database.select(database.findingVersions)
              ..where((row) => row.validUntil.isNull())
              ..orderBy([(row) => OrderingTerm.desc(row.version)]))
            .getSingleOrNull();
    if (finding == null || finding.status == 'invalidated') return null;
    final evidence =
        await (database.select(database.evidenceBundles)
              ..where((row) => row.id.equals(finding.evidenceBundleId)))
            .getSingleOrNull();
    if (evidence == null ||
        !await EvidenceValidityRepository(database).isCurrent(evidence)) {
      return null;
    }

    final metricRows = await (database.select(
      database.evidenceMetrics,
    )..where((row) => row.evidenceBundleId.equals(evidence.id))).get();
    final windows = await (database.select(
      database.eventWindows,
    )..where((row) => row.analysisRunId.equals(evidence.analysisRunId))).get();
    final excluded = windows
        .where((window) => window.exclusionReason != null)
        .toList(growable: false);

    final metrics = <String, num>{
      for (final row in metricRows) row.metric: row.value,
      'finding_state': 1,
      'exclusions': excluded.length,
    };
    metrics.putIfAbsent(
      'counterevidence_count',
      () =>
          metricRows
              .where((row) => row.metric == 'counterevidence_count')
              .firstOrNull
              ?.value ??
          0,
    );
    metrics.putIfAbsent(
      'unresolved_influence_count',
      () =>
          metricRows
              .where((row) => row.metric == 'unresolved_influence_count')
              .firstOrNull
              ?.value ??
          0,
    );
    metrics['unresolved_influences'] =
        metrics['unresolved_influence_count'] ?? 0;

    final exclusions = <String, String>{
      for (final entry in excluded.indexed)
        'exclusion_${entry.$1 + 1}': entry.$2.exclusionReason!,
    };
    final counterevidence = {
      'counterevidence_count': metrics['counterevidence_count'],
    };
    final unresolvedCount = (metrics['unresolved_influence_count'] ?? 0)
        .toDouble();
    final unresolved = <String, String>{
      if (unresolvedCount > 0) ...{
        'caffeine_timing':
            'Caffeine was recorded or remains unknown in meeting or comparison windows. A missing log does not mean zero intake; this check does not establish causation.',
        'recent_exercise':
            'Recent exercise is a possible contributor to record, not a proven cause.',
        'unusual_stress':
            'Unusual stress or schedule pressure is a possible contributor to record, not a proven cause.',
      },
    };
    final observations = <String>[
      if (unresolvedCount == 0 &&
          finding.status == 'supported' &&
          evidence.status == 'supported')
        'Test a 10-minute quiet buffer before the next three eligible recurring 1:1 meetings.',
      'Log caffeine intake and the time period covered for both meetings and comparison periods, plus exercise, illness, travel, and unusual stress.',
    ];
    final orderedMetrics = SplayTreeMap<String, num>.of(metrics);
    final request = ExplainerRequest(
      // Version the projection hash when the phone LoRA prompt/decoder changes;
      // an accepted pre-bridge answer must not satisfy this new request's cache.
      schemaVersion: 'explainer-v8',
      evidenceVersion: evidence.id,
      findingState: finding.status,
      metricsJson: jsonEncode(orderedMetrics),
      promotionGatesJson: jsonEncode({
        'status': evidence.status,
        'policyVersion': evidence.promotionPolicyVersion,
      }),
      exclusionsJson: jsonEncode(exclusions),
      counterevidenceJson: jsonEncode(counterevidence),
      unresolvedInfluencesJson: jsonEncode(unresolved),
      approvedNextObservations: observations,
      askIntent: intent,
    );
    final requestPayload = jsonEncode({
      'evidenceHash': evidence.evidenceHash,
      'intent': intent,
      'schemaVersion': request.schemaVersion,
      'metrics': orderedMetrics,
      'gates': request.promotionGatesJson,
      'exclusions': exclusions,
      'counterevidence': counterevidence,
      'unresolved': unresolved,
      'observations': observations,
    });
    final allowedNumbersByCitation = <String, Set<num>>{
      for (final entry in orderedMetrics.entries) entry.key: {entry.value},
    };
    for (final row in metricRows) {
      allowedNumbersByCitation.putIfAbsent(row.metric, () => <num>{})
        ..add(row.value)
        ..addAll([
          if (row.lowerBound != null) row.lowerBound!,
          if (row.upperBound != null) row.upperBound!,
        ]);
    }
    if (orderedMetrics['completeness'] case final completeness?) {
      allowedNumbersByCitation['completeness']!.add(completeness * 100);
    }
    final allowedNumbers = <num>{
      for (final values in allowedNumbersByCitation.values) ...values,
    };
    return EvidenceProjection(
      evidenceBundleId: evidence.id,
      evidenceHash: evidence.evidenceHash,
      requestHash: sha256.convert(utf8.encode(requestPayload)).toString(),
      request: request,
      guardContext: EvidenceGuardContext(
        evidenceVersion: evidence.id,
        allowedCitations: orderedMetrics.keys.toSet(),
        allowedInfluenceIds: unresolved.keys.toSet(),
        allowedNumbers: allowedNumbers,
        allowedNumbersByCitation: allowedNumbersByCitation,
        allowedNextObservations: observations.toSet(),
        primaryMetricValues: Map<String, num>.unmodifiable(orderedMetrics),
        liveStore: storeKind == StoreKind.live,
      ),
    );
  }
}
