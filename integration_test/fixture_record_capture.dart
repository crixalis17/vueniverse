import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

/// Test-only ASCII transport, not production logging or a raw reasoning capture.
/// A fresh in-memory bundled fixture is a prerequisite at the caller.
List<String> fixtureRecordLines({
  required String captureId,
  required String intent,
  required String kind,
  required Map<String, Object?> payload,
}) {
  if (!RegExp(r'^[a-z0-9_-]{1,48}$').hasMatch(captureId) ||
      !const {
        'why_promoted',
        'disagreement',
        'observe_next',
      }.contains(intent) ||
      !const {'model_attempt', 'app_delivery'}.contains(kind)) {
    throw ArgumentError('Invalid fixture capture envelope');
  }
  final bytes = utf8.encode(jsonEncode(payload));
  if (bytes.length > 16384) throw ArgumentError('Fixture record exceeds bound');
  const chunkSize = 480;
  final count = (bytes.length + chunkSize - 1) ~/ chunkSize;
  final digest = sha256.convert(bytes).toString();
  return [
    for (var index = 0; index < count; index++)
      'VUENIVERSE_PHONE_CONTRACT_CHUNK ${jsonEncode({'capture_id': captureId, 'intent': intent, 'kind': kind, 'index': index, 'count': count, 'sha256': digest, 'data_b64': base64Encode(bytes.sublist(index * chunkSize, math.min((index + 1) * chunkSize, bytes.length)))})}',
  ];
}
