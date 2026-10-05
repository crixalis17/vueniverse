import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/sources/ultrahuman_client.dart';

void main() {
  const day = '2026-09-01';
  Map<String, Object?> payload() => {
    'status': 200,
    'error': null,
    'data': {
      'latest_time_zone': 'Asia/Kolkata',
      'metrics': {day: <Object?>[]},
    },
  };
  test(
    'personal endpoint sends raw authorization and no account selector',
    () async {
      final transport = _Transport(200, payload());
      final result = await UltrahumanClient(
        transport: transport,
      ).fetchDay(localDate: day, token: 'test-token');
      expect(
        transport.uri.toString(),
        'https://partner.ultrahuman.com/api/v1/partner/daily_metrics?date=$day',
      );
      expect(transport.authorization, 'test-token');
      expect(result.localDate, day);
      expect(result.metrics, isEmpty);
      expect(result.toString(), isNot(contains(day)));
    },
  );
  for (final code in [401, 403, 429, 302, 500]) {
    test('HTTP $code returns safe error without upstream contents', () async {
      final transport = _Transport(code, {'secret': 'do-not-show'});
      await expectLater(
        UltrahumanClient(
          transport: transport,
        ).fetchDay(localDate: day, token: 'test-token'),
        throwsA(
          isA<UltrahumanException>().having(
            (e) => e.toString(),
            'redacted',
            isNot(contains('do-not-show')),
          ),
        ),
      );
    });
  }
  test(
    'invalid dates and header-injection token rejected before transport',
    () async {
      final transport = _Transport(200, payload());
      final client = UltrahumanClient(transport: transport);
      for (final date in [
        '2026-02-30',
        '2026-09-01&email=someone',
        '2026-9-1',
      ]) {
        await expectLater(
          client.fetchDay(localDate: date, token: 'test-token'),
          throwsA(isA<UltrahumanException>()),
        );
      }
      await expectLater(
        client.fetchDay(localDate: day, token: 'bad\r\nX-secret: yes'),
        throwsA(isA<UltrahumanException>()),
      );
      expect(transport.calls, 0);
    },
  );
  test(
    'malformed payload, omitted day, application error and zone rejected',
    () async {
      for (final invalid in [
        <String, Object?>{},
        {'status': 200, 'error': 'private failure'},
        {
          'status': 200,
          'error': null,
          'data': {'metrics': {}},
        },
        {
          'status': 200,
          'error': null,
          'data': {
            'metrics': {day: []},
          },
        },
      ]) {
        await expectLater(
          UltrahumanClient(
            transport: _Transport(200, invalid),
          ).fetchDay(localDate: day, token: 'test-token'),
          throwsA(isA<UltrahumanException>()),
        );
      }
    },
  );
  test('bounds injected response size and completion wait', () async {
    await expectLater(
      UltrahumanClient(
        transport: _Transport(200, payload()),
        maxResponseBytes: 2,
      ).fetchDay(localDate: day, token: 'test-token'),
      throwsA(
        isA<UltrahumanException>().having(
          (e) => e.safeCode,
          'code',
          'response_too_large',
        ),
      ),
    );
    await expectLater(
      UltrahumanClient(
        transport: _NeverTransport(),
        timeout: const Duration(milliseconds: 2),
      ).fetchDay(localDate: day, token: 'test-token'),
      throwsA(
        isA<UltrahumanException>().having(
          (e) => e.safeCode,
          'code',
          'request_timeout',
        ),
      ),
    );
  });
  test(
    'invalid UTF-8, invalid JSON and network errors expose only safe codes',
    () async {
      for (final bytes in [
        <int>[255],
        utf8.encode('{private upstream error'),
      ]) {
        await expectLater(
          UltrahumanClient(
            transport: _RawTransport(bytes),
          ).fetchDay(localDate: day, token: 'test-token'),
          throwsA(
            isA<UltrahumanException>().having(
              (e) => e.safeCode,
              'code',
              'request_failed',
            ),
          ),
        );
      }
      await expectLater(
        UltrahumanClient(
          transport: _RawTransport(null),
        ).fetchDay(localDate: day, token: 'test-token'),
        throwsA(
          isA<UltrahumanException>().having(
            (e) => e.toString(),
            'safe',
            isNot(contains('sensitive')),
          ),
        ),
      );
    },
  );
}

class _RawTransport implements UltrahumanTransport {
  _RawTransport(this.bytes);
  final List<int>? bytes;
  @override
  Future<UltrahumanHttpResponse> get({
    required Uri uri,
    required String authorization,
    required Duration timeout,
    required int maxResponseBytes,
  }) async {
    if (bytes == null) throw StateError('sensitive upstream detail');
    return UltrahumanHttpResponse(statusCode: 200, bytes: bytes!);
  }
}

class _Transport implements UltrahumanTransport {
  _Transport(this.status, this.payload);
  final int status;
  final Object payload;
  Uri? uri;
  String? authorization;
  int calls = 0;
  @override
  Future<UltrahumanHttpResponse> get({
    required Uri uri,
    required String authorization,
    required Duration timeout,
    required int maxResponseBytes,
  }) async {
    calls++;
    this.uri = uri;
    this.authorization = authorization;
    return UltrahumanHttpResponse(
      statusCode: status,
      bytes: utf8.encode(jsonEncode(payload)),
    );
  }
}

class _NeverTransport implements UltrahumanTransport {
  @override
  Future<UltrahumanHttpResponse> get({
    required Uri uri,
    required String authorization,
    required Duration timeout,
    required int maxResponseBytes,
  }) => Completer<UltrahumanHttpResponse>().future;
}
