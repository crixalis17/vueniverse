import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:why_pulse/domain/model_runtime/deterministic_explanation_runtime.dart';
import 'package:why_pulse/domain/model_runtime/output_guard.dart';
import 'package:why_pulse/platform/generated/model_runtime_api.g.dart';

final class ExplanationInvocation {
  const ExplanationInvocation({
    required this.request,
    required this.guardContext,
  });

  final ExplainerRequest request;
  final EvidenceGuardContext guardContext;
}

abstract interface class ExplanationRuntime {
  InferenceRuntime get runtime;

  Future<ModelRuntimeStatus> inspect();

  Future<ModelExplainerResult> explain(ExplanationInvocation invocation);

  Future<bool> cancel();
}

final class PhoneMedGemmaRuntimeAdapter implements ExplanationRuntime {
  PhoneMedGemmaRuntimeAdapter({ModelRuntimeApi? api})
    : _api = api ?? ModelRuntimeApi();

  final ModelRuntimeApi _api;

  @override
  InferenceRuntime get runtime => InferenceRuntime.phoneMedGemma;

  @override
  Future<ModelRuntimeStatus> inspect() => _api.inspectRuntime();

  @override
  Future<ModelExplainerResult> explain(ExplanationInvocation invocation) =>
      _api.explain(invocation.request);

  @override
  Future<bool> cancel() => _api.cancelActive();
}

final class DeterministicExplanationRuntimeAdapter
    implements ExplanationRuntime {
  DeterministicExplanationRuntimeAdapter({
    DeterministicExplanationRuntime? runtime,
  }) : _runtime = runtime ?? DeterministicExplanationRuntime();

  final DeterministicExplanationRuntime _runtime;

  @override
  InferenceRuntime get runtime => InferenceRuntime.deterministic;

  @override
  Future<ModelRuntimeStatus> inspect() async => ModelRuntimeStatus(
    state: ModelArtifactState.available,
    modelName: 'deterministic-fallback',
  );

  @override
  Future<ModelExplainerResult> explain(
    ExplanationInvocation invocation,
  ) async => _runtime.explain(
    invocation.request,
    guardContext: invocation.guardContext,
  );

  @override
  Future<bool> cancel() async => false;
}

final class DevelopmentMachineMedGemmaRuntimeAdapter
    implements ExplanationRuntime {
  DevelopmentMachineMedGemmaRuntimeAdapter({
    Uri? baseUri,
    this.timeout = const Duration(seconds: 120),
  }) : baseUri = baseUri ?? Uri.parse('http://127.0.0.1:8765');

  final Uri baseUri;
  final Duration timeout;

  @override
  InferenceRuntime get runtime => InferenceRuntime.developmentMachine;

  @override
  Future<ModelRuntimeStatus> inspect() async {
    try {
      final response = await _request('GET', '/ready');
      return ModelRuntimeStatus(
        state: response.statusCode == HttpStatus.ok
            ? ModelArtifactState.available
            : ModelArtifactState.missing,
        modelName: 'google/medgemma-1.5-4b-it-Q4_K_M',
        detail: response.statusCode == HttpStatus.ok
            ? null
            : 'development_backend_not_ready',
      );
    } on Object {
      return ModelRuntimeStatus(
        state: ModelArtifactState.missing,
        modelName: 'google/medgemma-1.5-4b-it-Q4_K_M',
        detail: 'development_backend_unavailable',
      );
    }
  }

  @override
  Future<ModelExplainerResult> explain(ExplanationInvocation invocation) async {
    final request = invocation.request;
    try {
      final response = await _request(
        'POST',
        '/v1/explain',
        body: {
          'schemaVersion': 'whypulse-model-service-v1',
          'store': 'demo',
          'request': _requestJson(request),
          'timeoutMillis': timeout.inMilliseconds,
          'maxOutputTokens': 384,
        },
      );
      final decoded = _decodeObject(response.body);
      if (response.statusCode != HttpStatus.ok) {
        if (kDebugMode) {
          final error = decoded?['error'];
          final code = error is Map ? error['code'] : null;
          debugPrint(
            'WhyPulse Demo runtime HTTP ${response.statusCode}'
            '${code == null ? '' : ' ($code)'}',
          );
        }
        return _failure(request.evidenceVersion, 'development_backend_error');
      }
      if (decoded == null) {
        return _failure(request.evidenceVersion, 'invalid_backend_response');
      }
      final payload = decoded;
      if (payload['evidenceVersion'] != request.evidenceVersion) {
        return _failure(request.evidenceVersion, 'evidence_version_mismatch');
      }
      final rawOutput = payload['rawOutput'];
      final metadataValue = payload['metadata'];
      if (rawOutput is! String || metadataValue is! Map) {
        return _failure(request.evidenceVersion, 'invalid_model_output');
      }
      final output = _decodeObject(rawOutput);
      if (output == null) {
        return _failure(request.evidenceVersion, 'invalid_model_output');
      }
      final metadata = {
        for (final entry in metadataValue.entries) '${entry.key}': entry.value,
      };
      final summary = output['summary'];
      final citedParagraphsJson = output['citedParagraphsJson'];
      final uncertainty = output['uncertainty'];
      final citedInfluences = output['citedUnresolvedInfluences'];
      final approvedNextObservation = output['approvedNextObservation'];
      final modelName = metadata['modelName'];
      final promptVersion = metadata['promptVersion'];
      final latencyMillis = metadata['latencyMillis'];
      final schemaValid = metadata['schemaValid'];
      if (summary is! String ||
          citedParagraphsJson is! String ||
          uncertainty is! String ||
          citedInfluences is! List ||
          citedInfluences.any((value) => value is! String) ||
          (approvedNextObservation != null &&
              approvedNextObservation is! String) ||
          (modelName != null && modelName is! String) ||
          (promptVersion != null && promptVersion is! num) ||
          (latencyMillis != null && latencyMillis is! num) ||
          schemaValid is! bool) {
        return _failure(request.evidenceVersion, 'invalid_model_output');
      }
      return ModelExplainerResult(
        evidenceVersion: request.evidenceVersion,
        output: ExplainerOutput(
          summary: summary,
          citedParagraphsJson: citedParagraphsJson,
          uncertainty: uncertainty,
          citedUnresolvedInfluences: citedInfluences.cast<String>(),
          approvedNextObservation: approvedNextObservation as String?,
        ),
        metadata: ModelRuntimeMetadata(
          runtime: InferenceRuntime.developmentMachine,
          modelName: modelName as String? ?? 'medgemma-development',
          promptVersion: (promptVersion as num?)?.toInt() ?? 1,
          outputGuardVersion: 0,
          latencyMillis: (latencyMillis as num?)?.toInt() ?? 0,
          schemaValid: schemaValid,
        ),
        safety: SafetyResult(accepted: true, failures: const []),
      );
    } on TimeoutException {
      return _failure(request.evidenceVersion, 'timeout');
    } on Object {
      return _failure(
        request.evidenceVersion,
        'development_backend_unavailable',
      );
    }
  }

  @override
  Future<bool> cancel() async {
    try {
      final response = await _request('POST', '/v1/cancel', body: const {});
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['cancelled'] == true;
    } on Object {
      return false;
    }
  }

  Future<_RuntimeHttpResponse> _request(
    String method,
    String path, {
    Object? body,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final uri = baseUri.replace(path: path);
      final request = method == 'GET'
          ? await client.getUrl(uri)
          : await client.postUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      if (body != null) {
        final encodedBody = utf8.encode(jsonEncode(body));
        request.headers.contentType = ContentType.json;
        request.contentLength = encodedBody.length;
        request.add(encodedBody);
      }
      final response = await request.close().timeout(timeout);
      final responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(timeout);
      return _RuntimeHttpResponse(response.statusCode, responseBody);
    } finally {
      client.close(force: true);
    }
  }

  Map<String, Object?> _requestJson(ExplainerRequest request) => {
    'schemaVersion': request.schemaVersion,
    'evidenceVersion': request.evidenceVersion,
    'findingState': request.findingState,
    'metricsJson': request.metricsJson,
    'promotionGatesJson': request.promotionGatesJson,
    'exclusionsJson': request.exclusionsJson,
    'counterevidenceJson': request.counterevidenceJson,
    'unresolvedInfluencesJson': request.unresolvedInfluencesJson,
    'approvedNextObservations': request.approvedNextObservations,
    'askIntent': request.askIntent,
  };

  Map<String, Object?>? _decodeObject(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      return {for (final entry in value.entries) '${entry.key}': entry.value};
    } on FormatException {
      return null;
    }
  }

  ModelExplainerResult _failure(String evidenceVersion, String code) =>
      ModelExplainerResult(
        evidenceVersion: evidenceVersion,
        output: null,
        metadata: ModelRuntimeMetadata(
          runtime: InferenceRuntime.developmentMachine,
          modelName: 'medgemma-development',
          promptVersion: 1,
          outputGuardVersion: 0,
          latencyMillis: 0,
          schemaValid: false,
        ),
        safety: SafetyResult(accepted: false, failures: [code]),
        failure: code,
      );
}

final class _RuntimeHttpResponse {
  const _RuntimeHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
