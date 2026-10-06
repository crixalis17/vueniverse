import 'package:flutter_test/flutter_test.dart';
import 'package:vueniverse/data/demo/demo_content.dart';
import 'package:vueniverse/data/sources/source_repository.dart';
import 'package:vueniverse/domain/models/app_models.dart';
import 'package:vueniverse/main.dart';

void main() {
  test('fresh Live source rows do not inherit Snapshot sync or coverage', () {
    for (final template in seedSources.where((row) => row.id != 'demo')) {
      final projected = projectLiveSource(
        template: template,
        persisted: PersistedSourceState(
          id: template.id,
          sourceType: 'fixture',
          status: 'connected_empty',
          configuration: {},
          recordCount: 0,
          updatedAtUtc: DateTime.utc(2026, 10, 6),
        ),
        permissions: {},
      );
      expect(projected.name, template.name);
      expect(projected.status, SourceStatus.connectedEmpty);
      expect(projected.recordCount, 0);
      expect(projected.lastSync, isNull);
      expect(projected.statusDetail, isNull);
      expect(projected.completeness, 0);
      expect(projected.permissionsTotal, 0);
    }
  });

  test('Live source metadata comes only from persisted facts', () {
    final projected = projectLiveSource(
      template: seedSources.singleWhere((row) => row.id == 'checkins'),
      persisted: PersistedSourceState(
        id: SourceIds.manual,
        sourceType: 'manual',
        status: 'connected_data',
        configuration: {'lastSyncUtc': '2020-01-01T00:00:00Z'},
        recordCount: 1,
        updatedAtUtc: DateTime.utc(2026, 10, 6),
      ),
      permissions: {'one': 'granted', 'two': 'denied'},
    );
    expect(projected.status, SourceStatus.connectedData);
    expect(projected.recordCount, 1);
    expect(projected.lastSync, startsWith('1/1 · '));
    expect(projected.lastSync, isNot('Today, 8:05 AM'));
    expect(projected.completeness, 0);
    expect(projected.permissionsGranted, 1);
    expect(projected.permissionsTotal, 2);
    expect(projected.statusDetail, isNull);
  });
}
