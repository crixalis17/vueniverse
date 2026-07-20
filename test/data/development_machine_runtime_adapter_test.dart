import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:why_pulse/domain/model_runtime/explanation_runtime.dart';
import 'package:why_pulse/domain/model_runtime/output_guard.dart';
import 'package:why_pulse/platform/generated/model_runtime_api.g.dart';

void main() {
  test('development adapter reports readiness and maps a bounded response', () async {
    final capturedRequest = Completer<Map<String, Object?>>();
    final server = await _startServer((request) async {
      if (request.method == 'GET' && request.uri.path == '/ready') {
        await _writeJson(request.response, HttpStatus.ok, {'status': 'ready'});
        return;
      }
      if (request.method == 'POST' && request.uri.path == '/v1/explain') {
        final body = _object(
          jsonDecode(await utf8.decoder.bind(request).join()),
        );
        if (!capturedRequest.isCompleted) capturedRequest.complete(body);
        final requestPayload = _object(body['request']);
        await _writeJson(request.response, HttpStatus.ok, {
          'schemaVersion': 'whypulse-model-service-result-v1',
          'evidenceVersion': requestPayload['evidenceVersion'],
          'rawOutput': jsonEncode({
            'summary':
                'Across 8 meetings, the usual difference was +11 beats per minute.',
            'citedParagraphsJson': jsonEncode([
              {
                'text':
                    'Across 8 meetings, the usual difference was +11 beats per minute.',
                'citations': ['included_count', 'median_difference_bpm'],
              },
            ]),
            'uncertainty':
                'This pattern does not prove why the change happened.',
            'citedUnresolvedInfluences': <String>[],
            'approvedNextObservation':
                'Log caffeine before the next similar meeting.',
          }),
          'metadata': {
            'modelName': 'google/medgemma-1.5-4b-it-Q4_K_M',
            'promptVersion': 7,
            'latencyMillis': 123,
            'schemaValid': true,
          },
        });
        return;
      }
      await _writeJson(request.response, HttpStatus.notFound, {
        'error': 'not_found',
      });
    });
    addTearDown(() async {
      await server.close(force: true);
    });
    final adapter = DevelopmentMachineMedGemmaRuntimeAdapter(
      baseUri: _baseUri(server),
      timeout: const Duration(seconds: 2),
    );

    final status = await adapter.inspect();
    final result = await adapter.explain(_invocation());
    final body = await capturedRequest.future;

    expect(status.state, ModelArtifactState.available);
    expect(status.detail, isNull);
    expect(body['schemaVersion'], 'whypulse-model-service-v1');
    expect(body['store'], 'demo');
    expect(body['timeoutMillis'], 2000);
    expect(body['maxOutputTokens'], 384);
    final sentRequest = _object(body['request']);
    expect(sentRequest, {
      'schemaVersion': 'explainer-v3',
      'evidenceVersion': 'evidence-v1',
      'findingState': 'supported',
      'metricsJson':
          '{"candidate_count":12,"included_count":8,"median_difference_bpm":11}',
      'promotionGatesJson': '{"status":"supported"}',
      'exclusionsJson': '{"exclusion_1":"travel"}',
      'counterevidenceJson': '{"counterevidence_count":2}',
      'unresolvedInfluencesJson':
          '{"unresolved_influences":"2 details remain"}',
      'approvedNextObservations': [
        'Log caffeine before the next similar meeting.',
      ],
      'askIntent': 'why_promoted',
    });
    expect(result.failure, isNull);
    expect(result.safety.accepted, isTrue);
    expect(result.output?.summary, contains('+11 beats per minute'));
    expect(result.output?.approvedNextObservation, contains('Log caffeine'));
    expect(result.metadata.runtime, InferenceRuntime.developmentMachine);
    expect(result.metadata.modelName, 'google/medgemma-1.5-4b-it-Q4_K_M');
    expect(result.metadata.promptVersion, 7);
    expect(result.metadata.latencyMillis, 123);
    expect(result.metadata.schemaValid, isTrue);
  });

  test('development adapter reports a reachable but unready backend', () async {
    final server = await _startServer((request) async {
      await _writeJson(request.response, HttpStatus.serviceUnavailable, {
        'status': 'not_ready',
      });
    });
    addTearDown(() async {
      await server.close(force: true);
    });
    final adapter = DevelopmentMachineMedGemmaRuntimeAdapter(
      baseUri: _baseUri(server),
      timeout: const Duration(seconds: 1),
    );

    final status = await adapter.inspect();

    expect(status.state, ModelArtifactState.missing);
    expect(status.detail, 'development_backend_not_ready');
  });

  test(
    'development adapter rejects mismatched evidence and malformed model output',
    () async {
      final mismatch = await _explainWithResponse({
        'evidenceVersion': 'other-evidence',
        'rawOutput': _validRawOutput(),
        'metadata': _validMetadata(),
      });
      final malformed = await _explainWithResponse({
        'evidenceVersion': 'evidence-v1',
        'rawOutput': 'not-json',
        'metadata': _validMetadata(),
      });
      final invalidTypes = await _explainWithResponse({
        'evidenceVersion': 'evidence-v1',
        'rawOutput': jsonEncode({
          'summary': 11,
          'citedParagraphsJson': '[]',
          'uncertainty': 'Uncertain.',
          'citedUnresolvedInfluences': <String>[],
          'approvedNextObservation': null,
        }),
        'metadata': _validMetadata(),
      });

      expect(mismatch.output, isNull);
      expect(mismatch.failure, 'evidence_version_mismatch');
      expect(mismatch.safety.accepted, isFalse);
      expect(malformed.output, isNull);
      expect(malformed.failure, 'invalid_model_output');
      expect(invalidTypes.output, isNull);
      expect(invalidTypes.failure, 'invalid_model_output');
    },
  );

  test(
    'development adapter distinguishes a malformed backend envelope',
    () async {
      final server = await _startServer((request) async {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write('not-json');
        await request.response.close();
      });
      addTearDown(() async {
        await server.close(force: true);
      });
      final adapter = DevelopmentMachineMedGemmaRuntimeAdapter(
        baseUri: _baseUri(server),
        timeout: const Duration(seconds: 1),
      );

      final result = await adapter.explain(_invocation());

      expect(result.output, isNull);
      expect(result.failure, 'invalid_backend_response');
      expect(result.safety.accepted, isFalse);
    },
  );

  test('development adapter calls the bounded cancellation endpoint', () async {
    final capturedBody = Completer<Map<String, Object?>>();
    final server = await _startServer((request) async {
      if (request.method == 'POST' && request.uri.path == '/v1/cancel') {
        final body = _object(
          jsonDecode(await utf8.decoder.bind(request).join()),
        );
        if (!capturedBody.isCompleted) capturedBody.complete(body);
        await _writeJson(request.response, HttpStatus.ok, {'cancelled': true});
        return;
      }
      await _writeJson(request.response, HttpStatus.notFound, {
        'error': 'not_found',
      });
    });
    addTearDown(() async {
      await server.close(force: true);
    });
    final adapter = DevelopmentMachineMedGemmaRuntimeAdapter(
      baseUri: _baseUri(server),
      timeout: const Duration(seconds: 1),
    );

    final cancelled = await adapter.cancel();

    expect(cancelled, isTrue);
    expect(await capturedBody.future, isEmpty);
  });

  test(
    'development adapter turns a slow response into a timeout failure',
    () async {
      final server = await _startServer((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        try {
          await _writeJson(request.response, HttpStatus.ok, {
            'evidenceVersion': 'evidence-v1',
            'rawOutput': _validRawOutput(),
            'metadata': _validMetadata(),
          });
        } on Object {
          // The adapter correctly closes the timed-out connection first.
        }
      });
      addTearDown(() async {
        await server.close(force: true);
      });
      final adapter = DevelopmentMachineMedGemmaRuntimeAdapter(
        baseUri: _baseUri(server),
        timeout: const Duration(milliseconds: 50),
      );

      final result = await adapter.explain(_invocation());

      expect(result.output, isNull);
      expect(result.failure, 'timeout');
      expect(result.safety.accepted, isFalse);
    },
  );
}

Future<HttpServer> _startServer(
  Future<void> Function(HttpRequest request) handler,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) => unawaited(handler(request)));
  return server;
}

Uri _baseUri(HttpServer server) => Uri(
  scheme: 'http',
  host: InternetAddress.loopbackIPv4.address,
  port: server.port,
);

Future<void> _writeJson(HttpResponse response, int status, Object body) async {
  response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  await response.close();
}

Future<ModelExplainerResult> _explainWithResponse(
  Map<String, Object?> response,
) async {
  final server = await _startServer((request) async {
    await utf8.decoder.bind(request).join();
    await _writeJson(request.response, HttpStatus.ok, response);
  });
  try {
    return await DevelopmentMachineMedGemmaRuntimeAdapter(
      baseUri: _baseUri(server),
      timeout: const Duration(seconds: 1),
    ).explain(_invocation());
  } finally {
    await server.close(force: true);
  }
}

ExplanationInvocation _invocation() => ExplanationInvocation(
  request: ExplainerRequest(
    schemaVersion: 'explainer-v3',
    evidenceVersion: 'evidence-v1',
    findingState: 'supported',
    metricsJson:
        '{"candidate_count":12,"included_count":8,"median_difference_bpm":11}',
    promotionGatesJson: '{"status":"supported"}',
    exclusionsJson: '{"exclusion_1":"travel"}',
    counterevidenceJson: '{"counterevidence_count":2}',
    unresolvedInfluencesJson: '{"unresolved_influences":"2 details remain"}',
    approvedNextObservations: const [
      'Log caffeine before the next similar meeting.',
    ],
    askIntent: 'why_promoted',
  ),
  guardContext: const EvidenceGuardContext(
    evidenceVersion: 'evidence-v1',
    allowedCitations: {
      'candidate_count',
      'included_count',
      'median_difference_bpm',
    },
    allowedInfluenceIds: {'unresolved_influences'},
    allowedNumbers: {12, 8, 11},
    allowedNumbersByCitation: {
      'candidate_count': {12},
      'included_count': {8},
      'median_difference_bpm': {11},
    },
    allowedNextObservations: {'Log caffeine before the next similar meeting.'},
  ),
);

String _validRawOutput() => jsonEncode({
  'summary':
      'Across 8 meetings, the usual difference was +11 beats per minute.',
  'citedParagraphsJson': jsonEncode([
    {
      'text':
          'Across 8 meetings, the usual difference was +11 beats per minute.',
      'citations': ['included_count', 'median_difference_bpm'],
    },
  ]),
  'uncertainty': 'This pattern does not prove why the change happened.',
  'citedUnresolvedInfluences': <String>[],
  'approvedNextObservation': null,
});

Map<String, Object?> _validMetadata() => {
  'modelName': 'fixture-medgemma',
  'promptVersion': 1,
  'latencyMillis': 10,
  'schemaValid': true,
};

Map<String, Object?> _object(Object? value) {
  if (value is! Map) throw const FormatException('Expected an object');
  return {for (final entry in value.entries) '${entry.key}': entry.value};
}
