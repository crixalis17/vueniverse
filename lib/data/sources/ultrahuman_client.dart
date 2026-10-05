import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Safe, token-owner-only access. Never persist or log the token or response.
final class UltrahumanClient {
  UltrahumanClient({
    UltrahumanTransport? transport,
    this.timeout = const Duration(seconds: 30),
    this.maxResponseBytes = 8 * 1024 * 1024,
  }) : _transport = transport ?? IoUltrahumanTransport() {
    if (timeout <= Duration.zero || maxResponseBytes <= 0) {
      throw ArgumentError('Invalid Ultrahuman request bounds');
    }
  }

  final UltrahumanTransport _transport;
  final Duration timeout;
  final int maxResponseBytes;

  Future<UltrahumanDayResponse> fetchDay({
    required String localDate,
    required String token,
  }) async {
    validateUltrahumanDate(localDate);
    // The official personal endpoint expects the token itself, not Bearer.
    if (token.isEmpty ||
        token.length > 8192 ||
        token != token.trim() ||
        RegExp(r'[\x00-\x20\x7f]').hasMatch(token)) {
      throw const UltrahumanException('invalid_token');
    }
    final uri = Uri.https(
      'partner.ultrahuman.com',
      '/api/v1/partner/daily_metrics',
      {'date': localDate},
    );
    try {
      final response = await _transport
          .get(
            uri: uri,
            authorization: token,
            timeout: timeout,
            maxResponseBytes: maxResponseBytes,
          )
          .timeout(timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const UltrahumanException('authorization_failed');
      }
      if (response.statusCode == 429) {
        throw const UltrahumanException('rate_limited');
      }
      if (response.statusCode != 200) {
        throw const UltrahumanException('upstream_unavailable');
      }
      if (response.bytes.length > maxResponseBytes) {
        throw const UltrahumanException('response_too_large');
      }
      final payload = jsonDecode(utf8.decode(response.bytes));
      if (payload is! Map<String, dynamic> ||
          payload['status'] != 200 ||
          payload['error'] != null ||
          payload['data'] is! Map<String, dynamic>) {
        throw const UltrahumanException('invalid_response');
      }
      final data = payload['data'] as Map<String, dynamic>;
      final metrics = data['metrics'];
      if (metrics is! Map<String, dynamic> ||
          !metrics.containsKey(localDate) ||
          metrics[localDate] is! List) {
        throw const UltrahumanException('missing_requested_day');
      }
      final zone = data['latest_time_zone'];
      if (zone is! String || zone.trim().isEmpty || zone.length > 128) {
        throw const UltrahumanException('missing_timezone');
      }
      return UltrahumanDayResponse(
        localDate: localDate,
        timezoneName: zone,
        metrics: List<Object?>.unmodifiable(metrics[localDate] as List),
      );
    } on UltrahumanException {
      rethrow;
    } on TimeoutException {
      throw const UltrahumanException('request_timeout');
    } on Object {
      // Do not expose server bodies, URIs, or underlying network exceptions.
      throw const UltrahumanException('request_failed');
    }
  }
}

final class UltrahumanDayResponse {
  const UltrahumanDayResponse({
    required this.localDate,
    required this.timezoneName,
    required this.metrics,
  });
  final String localDate;
  final String timezoneName;
  final List<Object?> metrics;

  @override
  String toString() => 'UltrahumanDayResponse(redacted)';
}

final class UltrahumanException implements Exception {
  const UltrahumanException(this.safeCode);
  final String safeCode;
  @override
  String toString() => 'UltrahumanException($safeCode)';
}

abstract interface class UltrahumanTransport {
  Future<UltrahumanHttpResponse> get({
    required Uri uri,
    required String authorization,
    required Duration timeout,
    required int maxResponseBytes,
  });
}

final class UltrahumanHttpResponse {
  const UltrahumanHttpResponse({required this.statusCode, required this.bytes});
  final int statusCode;
  final List<int> bytes;
  @override
  String toString() => 'UltrahumanHttpResponse($statusCode, redacted)';
}

final class IoUltrahumanTransport implements UltrahumanTransport {
  @override
  Future<UltrahumanHttpResponse> get({
    required Uri uri,
    required String authorization,
    required Duration timeout,
    required int maxResponseBytes,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    var expired = false;
    final timer = Timer(timeout, () {
      expired = true;
      client.close(force: true);
    });
    try {
      final request = await client.getUrl(uri);
      // Never forward credentials across a redirect, including same-host.
      request.followRedirects = false;
      request.headers.set(HttpHeaders.authorizationHeader, authorization);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      if (response.statusCode != 200) {
        return UltrahumanHttpResponse(
          statusCode: response.statusCode,
          bytes: const [],
        );
      }
      if (response.contentLength > maxResponseBytes) {
        throw const UltrahumanException('response_too_large');
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        if (bytes.length + chunk.length > maxResponseBytes) {
          throw const UltrahumanException('response_too_large');
        }
        bytes.addAll(chunk);
      }
      return UltrahumanHttpResponse(
        statusCode: response.statusCode,
        bytes: bytes,
      );
    } on Object {
      if (expired) throw TimeoutException('Ultrahuman request deadline');
      rethrow;
    } finally {
      timer.cancel();
      client.close(force: true);
    }
  }
}

void validateUltrahumanDate(String date) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
    throw const UltrahumanException('invalid_date');
  }
  final parsed = DateTime.tryParse('${date}T00:00:00Z');
  if (parsed == null ||
      parsed.toIso8601String().substring(0, 10) != date ||
      parsed.year < 2000 ||
      parsed.year > 2100) {
    throw const UltrahumanException('invalid_date');
  }
}
