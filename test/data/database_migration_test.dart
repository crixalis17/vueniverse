import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:vueniverse/data/database/vueniverse_database.dart';

void main() {
  test('schema 1 explanation rows migrate with safe cache defaults', () async {
    final directory = await Directory.systemTemp.createTemp(
      'vueniverse-migration-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/store.sqlite');
    final raw = sqlite3.open(file.path);
    raw.execute('''
      CREATE TABLE explanations (
        id TEXT NOT NULL PRIMARY KEY,
        evidence_bundle_id TEXT NOT NULL,
        runtime TEXT NOT NULL,
        content TEXT NOT NULL,
        safety_state TEXT NOT NULL,
        prompt_version INTEGER NOT NULL,
        output_guard_version INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
    raw.execute(
      '''
      INSERT INTO explanations (
        id, evidence_bundle_id, runtime, content, safety_state,
        prompt_version, output_guard_version, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        'legacy-row',
        'evidence-v1',
        'deterministic',
        '{}',
        'accepted',
        1,
        1,
        DateTime.utc(2026, 7, 16).toIso8601String(),
      ],
    );
    raw.execute('PRAGMA user_version = 1;');
    raw.close();

    final database = VueniverseDatabase.forTesting(NativeDatabase(file));
    addTearDown(database.close);
    final row = await database.select(database.explanations).getSingle();

    expect(row.evidenceHash, isEmpty);
    expect(row.intent, 'why_promoted');
    expect(row.requestHash, isNull);
    expect(row.modelName, 'legacy');
    expect(row.safetyFailuresJson, '[]');
    expect(row.failureCode, isNull);
    expect(row.latencyMillis, 0);
    expect(row.schemaValid, isFalse);
  });
}
