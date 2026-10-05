import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/fixture_record_capture.dart';

void main() {
  test(
    'fixture transport survives unicode and long records below log limit',
    () {
      final payload = <String, Object?>{
        'text': List.filled(280, '💡').join(),
        'score': 0.75,
      };
      final lines = fixtureRecordLines(
        captureId: 'fixture-1',
        intent: 'why_promoted',
        kind: 'model_attempt',
        payload: payload,
      );
      expect(lines.length, greaterThan(1));
      final bytes = <int>[];
      String? digest;
      for (final entry in lines.indexed) {
        expect(ascii.encode(entry.$2).length, lessThan(1023));
        final record =
            jsonDecode(
                  entry.$2.substring('VUENIVERSE_PHONE_CONTRACT_CHUNK '.length),
                )
                as Map<String, dynamic>;
        expect(record['index'], entry.$1);
        expect(record['count'], lines.length);
        digest ??= record['sha256'] as String;
        expect(record['sha256'], digest);
        bytes.addAll(base64Decode(record['data_b64'] as String));
      }
      expect(sha256.convert(bytes).toString(), digest);
      expect(jsonDecode(utf8.decode(bytes)), payload);
    },
  );

  test('fixture transport refuses unknown envelopes and oversized records', () {
    for (final captureId in ['bad id', List.filled(49, 'a').join()]) {
      expect(
        () => fixtureRecordLines(
          captureId: captureId,
          intent: 'why_promoted',
          kind: 'model_attempt',
          payload: {},
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => fixtureRecordLines(
        captureId: 'fixture-1',
        intent: 'owner_request',
        kind: 'model_attempt',
        payload: {},
      ),
      throwsArgumentError,
    );
    expect(
      () => fixtureRecordLines(
        captureId: 'fixture-1',
        intent: 'why_promoted',
        kind: 'raw_reasoning',
        payload: {},
      ),
      throwsArgumentError,
    );
    expect(
      () => fixtureRecordLines(
        captureId: 'fixture-1',
        intent: 'why_promoted',
        kind: 'model_attempt',
        payload: {'text': List.filled(16385, 'a').join()},
      ),
      throwsArgumentError,
    );
  });
}
