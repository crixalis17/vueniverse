import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vueniverse/domain/model_runtime/explanation_runtime.dart';
import 'package:vueniverse/domain/model_runtime/output_guard.dart';
import 'package:vueniverse/platform/generated/model_runtime_api.g.dart';

import '../test/support/emulator_semantic_replay.dart';
import 'fixture_record_capture.dart';

/// Supervised development replay, not normal candidate activation or app UI QA.
/// Opens only the staged, checksummed synthetic file; no database or connector.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'frozen emulator semantic LoRA replay captures all attempted cases',
    (_) async {
      const input = String.fromEnvironment('VUENIVERSE_SEMANTIC_INPUT');
      const inputSha = String.fromEnvironment(
        'VUENIVERSE_SEMANTIC_INPUT_SHA256',
      );
      const runId = String.fromEnvironment('VUENIVERSE_SEMANTIC_RUN_ID');
      if (!RegExp(r'^[a-z0-9_-]{1,40}$').hasMatch(runId)) {
        throw ArgumentError('A unique bounded semantic run ID is required');
      }
      final cases = await loadSemanticReplayFile(input, inputSha);
      final phone = PhoneMedGemmaRuntimeAdapter();
      addTearDown(phone.cancel);
      final status = await phone.inspect();
      expect(status.state, ModelArtifactState.available);
      expect(status.modelName, contains('@lora-v7-q4-dd9c2a212672a5bb'));
      const guard = OutputGuard();
      final deterministic = DeterministicExplanationRuntimeAdapter();
      var attempted = 0;
      String? stopReason;
      await _event({
        'event': 'run_start',
        'run_id': runId,
        'variant': 'lora_v7',
        'input_sha256': inputSha,
        'planned_cases': 15,
        'model': status.modelName,
        'owner_data_accessed': false,
        'cache_path_used': false,
        'delivery_is_simulation': true,
      });
      for (var index = 0; index < cases.length; index++) {
        final item = cases[index];
        final identity = {
          'run_id': runId,
          'case_id': item.id,
          'case_index': index,
          'variant': 'lora_v7',
          'request_wire_sha256': item.requestWireSha256,
        };
        await _event({'event': 'case_start', ...identity});
        final timer = Stopwatch()..start();
        final result = await phone.explain(
          ExplanationInvocation(
            request: item.request,
            guardContext: item.guardContext,
          ),
        );
        timer.stop();
        attempted++;
        final safety = guard.validateResult(
          result,
          item.request,
          item.guardContext,
        );
        final captureId = '$runId-$index';
        await _record(captureId, item.request.askIntent, 'model_attempt', {
          ...identity,
          'elapsed_ms': timer.elapsedMilliseconds,
          'raw_dto': semanticResultJson(result),
          'guard_result': semanticSafetyJson(safety),
          'from_cache': false,
        });
        final critical = safety.failures
            .where(_criticalSafetyFailures.contains)
            .toList();
        if (result.metadata.modelName != status.modelName ||
            result.metadata.promptVersion != 8 ||
            result.evidenceVersion != item.request.evidenceVersion) {
          stopReason = 'runtime_contract_mismatch';
        } else if (critical.isNotEmpty) {
          stopReason = 'critical_safety_flag';
        } else if (result.failure != null &&
            result.failure != 'invalid_model_output') {
          stopReason = 'runtime_failure:${result.failure}';
        }
        final accepted = safety.accepted && result.output != null;
        final fallback = accepted
            ? null
            : await deterministic.explain(
                ExplanationInvocation(
                  request: item.request,
                  guardContext: item.guardContext,
                ),
              );
        final fallbackSafety = fallback == null
            ? null
            : guard.validateResult(fallback, item.request, item.guardContext);
        await _record(captureId, item.request.askIntent, 'app_delivery', {
          ...identity,
          'delivery_is_simulation': true,
          'coordinator_executed': false,
          'delivery_mode': accepted ? 'model' : 'deterministic',
          'fallback': !accepted,
          'from_cache': false,
          'fallback_dto': fallback == null
              ? null
              : semanticResultJson(fallback),
          'fallback_guard_result': fallbackSafety == null
              ? null
              : semanticSafetyJson(fallbackSafety),
        });
        await _event({
          'event': 'case_end',
          ...identity,
          'schema_valid': result.metadata.schemaValid,
          'guard_accepted': safety.accepted,
          'stop_reason': stopReason,
        });
        if (stopReason != null) break;
      }
      await _event({
        'event': 'run_complete',
        'run_id': runId,
        'variant': 'lora_v7',
        'attempted_cases': attempted,
        'unattempted_cases': 15 - attempted,
        'status': stopReason == null ? 'completed' : 'stopped',
        'stop_reason': stopReason,
        'semantic_judgment': 'pending',
        'candidate_activation': false,
      });
      expect(
        stopReason,
        isNull,
        reason: 'Diagnostic stopped; preserve completed cases, no retries',
      );
    },
    timeout: const Timeout(Duration(minutes: 45)),
  );
}

// Conservative lexical stop flags, not semantic verdicts. causal_claim is
// deliberately excluded: negated causal language has known lexical false positives.
const _criticalSafetyFailures = {
  'diagnosis',
  'treatment',
  'prescription',
  'medication_advice',
  'medical_advice',
  'calendar_identity',
  'personal_identity',
  'cross_store_reference',
};

Future<void> _event(Map<String, Object?> payload) async {
  debugPrint(
    'VUENIVERSE_SEMANTIC_EVENT ${jsonEncode(payload)}',
    wrapWidth: 1000,
  );
  await debugPrintDone;
}

Future<void> _record(
  String captureId,
  String intent,
  String kind,
  Map<String, Object?> payload,
) async {
  for (final line in fixtureRecordLines(
    captureId: captureId,
    intent: intent,
    kind: kind,
    payload: payload,
  )) {
    debugPrint(line, wrapWidth: 1000);
  }
  await debugPrintDone;
}
