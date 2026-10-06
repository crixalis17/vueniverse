import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/emulator_semantic_replay.dart';

void main() {
  final file = File(
    'experiments/readiness/emulator-semantic-v1/app-projections.jsonl',
  );
  late List<int> bytes;
  late String digest;
  setUp(() {
    bytes = file.readAsBytesSync();
    digest = sha256.convert(bytes).toString();
  });
  test(
    'loads exactly sealed matrix without rebuilding analytical identities',
    () {
      final cases = parseSemanticReplayBytes(bytes, digest);
      expect(cases, hasLength(15));
      expect(cases.first.id, 'supported_negative__why_promoted');
      expect(cases.last.id, 'mixed_direction__observe_next');
      expect(
        cases.first.request.metricsJson,
        contains('"median_difference_bpm":-10.0'),
      );
      expect(cases.first.guardContext.liveStore, isFalse);
      expect(
        cases.first.guardContext.evidenceVersion,
        cases.first.request.evidenceVersion,
      );
    },
  );
  test(
    'requires an external exact full-file SHA and rejects altered bytes',
    () {
      expect(() => parseSemanticReplayBytes(bytes, ''), throwsFormatException);
      expect(
        () => parseSemanticReplayBytes([...bytes, 32], digest),
        throwsFormatException,
      );
    },
  );
  test(
    'rejects matrix changes even if a caller supplies its changed file hash',
    () {
      final rows = const LineSplitter().convert(utf8.decode(bytes));
      final changed = utf8.encode(
        [rows[1], rows[0], ...rows.skip(2)].join('\n'),
      );
      expect(
        () => parseSemanticReplayBytes(
          changed,
          sha256.convert(changed).toString(),
        ),
        throwsFormatException,
      );
    },
  );
  test('rejects request-wire mismatch independently of full file hash', () {
    final rows = const LineSplitter().convert(utf8.decode(bytes));
    final row = jsonDecode(rows.first) as Map<String, dynamic>;
    row['request_wire_sha256'] = '0' * 64;
    final changed = utf8.encode([jsonEncode(row), ...rows.skip(1)].join('\n'));
    expect(
      () =>
          parseSemanticReplayBytes(changed, sha256.convert(changed).toString()),
      throwsFormatException,
    );
  });
  test(
    'file loader refuses arbitrary, owner-store and relative paths',
    () async {
      await expectLater(
        loadSemanticReplayFile(file.path, digest),
        throwsArgumentError,
      );
      await expectLater(
        loadSemanticReplayFile(
          '/data/user/0/com.vueniverse.vueniverse/databases/live.sqlite',
          digest,
        ),
        throwsArgumentError,
      );
    },
  );
}
