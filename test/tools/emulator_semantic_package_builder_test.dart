import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/database/schema_versions.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/domain/model_runtime/deterministic_explanation_runtime.dart';
import 'package:vueniverse/domain/model_runtime/output_guard.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

import '../support/emulator_semantic_fixture.dart';

const _exportDirectory = String.fromEnvironment('EMULATOR_SEMANTIC_EXPORT_DIR');

void main() {
  late SemanticInputPackage package;
  setUpAll(() async {
    // Refuse an existing destination before constructing or writing anything.
    if (_exportDirectory.isNotEmpty) {
      await _requireAbsentDestination(_exportDirectory);
    }
    package = await buildSemanticInputPackage();
  });

  test('five raw families and exactly fifteen inspected request cases', () {
    expect(package.rawTimelines, hasLength(5));
    expect(package.projections, hasLength(15));
    expect(
      package.projections.map((row) => row['case_id']).toSet(),
      hasLength(15),
    );
    for (final family in semanticFamilies) {
      final rows = package.projections.where(
        (row) => row['family_id'] == family.name,
      );
      expect(rows.map((row) => row['intent']).toList(), semanticIntents);
      expect(
        rows.map((row) => row['evidence_bundle_id']).toSet(),
        hasLength(1),
      );
      expect(rows.map((row) => row['raw_input_sha256']).toSet(), hasLength(1));
    }
  });

  test('exact frozen wire and raw bytes match separate byte hashes', () {
    for (final row in package.projections) {
      final wire = row['request_wire_json']! as String;
      expect(jsonDecode(wire), row['pigeon_request']);
      expect(semanticSha256(wire), row['request_wire_sha256']);
      final evidence = row['evidence_snapshot_json']! as String;
      expect(semanticSha256(evidence), row['evidence_snapshot_sha256']);
      // The cache identity is not relabeled as the complete Pigeon wire hash.
      expect(row['projection_request_hash'], isNot(row['request_wire_sha256']));
    }
    for (final row in package.rawTimelines) {
      final raw = row['raw_timeline_json']! as String;
      expect(jsonDecode(raw), row['records']);
      expect(semanticSha256(raw), row['raw_input_sha256']);
      expect(semanticSha256('$raw '), isNot(row['raw_input_sha256']));
    }
  });

  test(
    'independent rebuild preserves raw/evidence semantics, not run IDs',
    () async {
      final rebuilt = await SemanticFixture.build(semanticFamilies.first);
      try {
        final projection = await rebuilt.project(semanticIntents.first);
        final frozen = package.projections.first;
        expect(
          semanticSha256(semanticRawTimelineJson(rebuilt.records)),
          frozen['raw_input_sha256'],
        );
        expect(projection.evidenceHash, frozen['evidence_hash']);
        expect(
          () => validateSemanticAnalysis(semanticFamilies[1], rebuilt.result),
          throwsA(isA<StateError>()),
          reason: 'A changed sign/family must not silently freeze as expected.',
        );
        expect(
          semanticAnalyticalFacts(rebuilt.result),
          frozen['expected_analytics'],
        );
        expect(
          projection.evidenceBundleId,
          isNot(frozen['evidence_bundle_id']),
        );
        expect(
          semanticRequestJson(projection.request)['metricsJson'],
          (frozen['pigeon_request']! as Map)['metricsJson'],
        );
      } finally {
        await rebuilt.close();
      }
    },
  );

  test(
    'export is opt-in and refuses existing empty or populated destinations',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'semantic-export-test-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      await expectLater(
        package.exportTo(temporary.path),
        throwsA(isA<StateError>()),
      );
      final fresh = '${temporary.path}/fresh';
      await package.exportTo(fresh);
      final original = await File('$fresh/app-projections.jsonl').readAsBytes();
      await expectLater(package.exportTo(fresh), throwsA(isA<StateError>()));
      expect(
        await File('$fresh/app-projections.jsonl').readAsBytes(),
        original,
      );
      expect(
        const LineSplitter().convert(utf8.decode(original)),
        hasLength(15),
      );
    },
  );

  test(
    'optional explicitly requested export preserves immutable input snapshot',
    () async {
      if (_exportDirectory.isEmpty) return;
      await package.exportTo(_exportDirectory);
    },
  );
}

final class SemanticInputPackage {
  SemanticInputPackage(this.rawTimelines, this.projections);

  final List<Map<String, Object?>> rawTimelines;
  final List<Map<String, Object?>> projections;

  Future<void> exportTo(String destination) async {
    await _requireAbsentDestination(destination);
    final directory = Directory(destination);
    await directory.create();
    await File('${directory.path}/raw-timelines.jsonl').writeAsString(
      '${rawTimelines.map(jsonEncode).join('\n')}\n',
      flush: true,
    );
    await File(
      '${directory.path}/app-projections.jsonl',
    ).writeAsString('${projections.map(jsonEncode).join('\n')}\n', flush: true);
    await File('${directory.path}/input-export-metadata.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert({
        'schema': 'emulator-semantic-input-export-v1',
        'split': 'inspected_development',
        'raw_family_count': rawTimelines.length,
        'request_count': projections.length,
        'analytical_clock_utc': semanticClock.toIso8601String(),
        'normalization_version': SchemaVersions.normalization,
        'analysis_version': SchemaVersions.meetingAnalysis,
        'promotion_policy_version': SchemaVersions.promotionPolicy,
        'projection_schema': 'explainer-v8',
        'deterministic_fallback_version': deterministicExplanationPromptVersion,
        'output_guard_version': outputGuardVersion,
        'pigeon_question_field': {'present_in_current_schema': false, 'note': 'The current ExplainerRequest has no optional question field; no field is invented.'},
        'reproducibility': {'raw_and_analytical_content': 'Deterministic under fixed raw inputs, identity keys, versions and analytical clock.', 'same_database_request_bytes': 'Repeated projection construction was checked byte-for-byte for every case.', 'independent_run_identifiers': 'Production analysisRunId includes real wall-clock microseconds; evidenceVersion is run-bound. Independent rebuilds intentionally have different identifiers. Preserve this snapshot unchanged for comparisons; do not remap IDs.', 'projection_request_hash': 'App cache/projection identity, not the full Pigeon request byte hash.', 'request_wire_sha256': 'SHA256 of UTF-8 request_wire_json with the exact Pigeon field values and serialized JSON-string fields retained.', 'evidence_hash': 'App analytical evidence content hash; independent of run-bound evidence IDs.', 'evidence_snapshot_sha256': 'SHA256 of UTF-8 evidence_snapshot_json for the actual database bundle and metric-row snapshot.', 'raw_input_sha256': 'SHA256 of UTF-8 raw_timeline_json, with raw envelope order preserved.'},
        'model_attempts': 0,
        'deterministic_baseline_is_llm_target': false,
      })}\n',
      flush: true,
    );
  }
}

Future<void> _requireAbsentDestination(String destination) async {
  if (destination.isEmpty || !destination.startsWith('/')) {
    throw ArgumentError('Export requires a nonempty absolute directory path');
  }
  if (await FileSystemEntity.type(destination, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw StateError(
      'Export destination already exists; snapshot not overwritten',
    );
  }
  if (!await Directory(destination).parent.exists()) {
    throw StateError('Export destination parent must already exist');
  }
}

Future<SemanticInputPackage> buildSemanticInputPackage() async {
  final raw = <Map<String, Object?>>[];
  final projections = <Map<String, Object?>>[];
  for (final spec in semanticFamilies) {
    final fixture = await SemanticFixture.build(spec);
    try {
      final rawJson = semanticRawTimelineJson(fixture.records);
      final rawHash = semanticSha256(rawJson);
      raw.add({
        'family_id': spec.name,
        'cluster_id': spec.name,
        'split': 'inspected_development',
        'raw_timeline_json': rawJson,
        'raw_input_sha256': rawHash,
        'records': jsonDecode(rawJson),
      });
      final bundles = await fixture.database
          .select(fixture.database.evidenceBundles)
          .get();
      final bundle = bundles.single;
      final metricRows = await fixture.database
          .select(fixture.database.evidenceMetrics)
          .get();
      metricRows.sort((a, b) => a.metric.compareTo(b.metric));
      final run =
          (await fixture.database.select(fixture.database.analysisRuns).get())
              .single;
      final evidenceJson = canonicalJsonEncode({
        'evidence_bundle': bundle.toJson(),
        'metrics': metricRows.map((row) => row.toJson()).toList(),
      });
      for (final intent in semanticIntents) {
        final projection = await fixture.project(intent);
        _validateProjectionFacts(fixture, projection.request);
        final request = semanticRequestJson(projection.request);
        final wire = jsonEncode(request);
        final repeated = await fixture.project(intent);
        if (jsonEncode(semanticRequestJson(repeated.request)) != wire ||
            projection.requestHash != repeated.requestHash) {
          throw StateError(
            'Same-database projection is not byte deterministic',
          );
        }
        final fallback = DeterministicExplanationRuntime().explain(
          projection.request,
          guardContext: projection.guardContext,
        );
        if (!fallback.safety.accepted || fallback.output == null) {
          throw StateError(
            'Deterministic baseline failed for ${spec.name}:$intent',
          );
        }
        final standaloneGuard = const OutputGuard().validateResult(
          fallback,
          projection.request,
          projection.guardContext,
        );
        if (!standaloneGuard.accepted) {
          throw StateError(
            'Standalone baseline guard rejected ${spec.name}:$intent',
          );
        }
        projections.add({
          'case_id': '${spec.name}__$intent',
          'family_id': spec.name,
          'cluster_id': spec.name,
          'split': 'inspected_development',
          'intent': intent,
          'raw_input_sha256': rawHash,
          'canonical_input_hash': run.inputHash,
          'evidence_hash': projection.evidenceHash,
          'evidence_bundle_id': projection.evidenceBundleId,
          'analysis_run_id': run.id,
          'projection_request_hash': projection.requestHash,
          'pigeon_request': request,
          'request_wire_json': wire,
          'request_wire_sha256': semanticSha256(wire),
          'evidence_snapshot_json': evidenceJson,
          'evidence_snapshot_sha256': semanticSha256(evidenceJson),
          'expected_analytics': semanticAnalyticalFacts(fixture.result),
          'guard_context': {
            'evidenceVersion': projection.guardContext.evidenceVersion,
            'allowedCitations':
                projection.guardContext.allowedCitations.toList()..sort(),
            'allowedInfluenceIds':
                projection.guardContext.allowedInfluenceIds.toList()..sort(),
            'allowedNumbers': projection.guardContext.allowedNumbers.toList()
              ..sort(),
            'allowedNumbersByCitation': {
              for (final key
                  in (projection.guardContext.allowedNumbersByCitation.keys
                      .toList()
                    ..sort()))
                key:
                    projection.guardContext.allowedNumbersByCitation[key]!
                        .toList()
                      ..sort(),
            },
            'allowedNextObservations':
                projection.guardContext.allowedNextObservations.toList()
                  ..sort(),
            'primaryMetricValues': projection.guardContext.primaryMetricValues,
            'liveStore': projection.guardContext.liveStore,
          },
          'deterministic_baseline': {
            'delivery_mode': 'deterministic',
            'is_expected_llm_target': false,
            'raw_dto': _fallbackJson(fallback),
            'standalone_guard_result': {
              'accepted': standaloneGuard.accepted,
              'failures': standaloneGuard.failures,
            },
          },
        });
      }
    } finally {
      await fixture.close();
    }
  }
  return SemanticInputPackage(raw, projections);
}

void _validateProjectionFacts(
  SemanticFixture fixture,
  ExplainerRequest request,
) {
  final metrics = jsonDecode(request.metricsJson) as Map<String, dynamic>;
  final facts = semanticAnalyticalFacts(fixture.result);
  if (request.schemaVersion != 'explainer-v8' ||
      request.findingState != facts['state']) {
    throw StateError('Projection identity/state changed');
  }
  for (final entry in facts.entries) {
    if (entry.key == 'state' || entry.key == 'promotion_gates') continue;
    if (metrics[entry.key] != entry.value) {
      throw StateError('Projection metric changed: ${entry.key}');
    }
  }
  for (final entry in fixture.result.promotionGates.entries) {
    if (metrics['gate_${entry.key}'] != (entry.value ? 1 : 0)) {
      throw StateError('Projection gate changed: ${entry.key}');
    }
  }
  final gates = jsonDecode(request.promotionGatesJson) as Map<String, dynamic>;
  if (gates['status'] != facts['state'] ||
      gates['policyVersion'] != SchemaVersions.promotionPolicy) {
    throw StateError('Projection promotion policy changed');
  }
}

Map<String, Object?> _fallbackJson(ModelExplainerResult result) => {
  'evidenceVersion': result.evidenceVersion,
  'output': result.output == null
      ? null
      : {
          'summary': result.output!.summary,
          'citedParagraphsJson': result.output!.citedParagraphsJson,
          'uncertainty': result.output!.uncertainty,
          'citedUnresolvedInfluences': result.output!.citedUnresolvedInfluences,
          'approvedNextObservation': result.output!.approvedNextObservation,
        },
  'metadata': {
    'runtime': result.metadata.runtime.name,
    'modelName': result.metadata.modelName,
    'promptVersion': result.metadata.promptVersion,
    'outputGuardVersion': result.metadata.outputGuardVersion,
    'latencyMillis': result.metadata.latencyMillis,
    'schemaValid': result.metadata.schemaValid,
  },
  'safety': {
    'accepted': result.safety.accepted,
    'failures': result.safety.failures,
  },
  'failure': result.failure,
};
