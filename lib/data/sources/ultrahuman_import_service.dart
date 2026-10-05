import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;
import 'package:vueniverse/data/database/vueniverse_database.dart';
import 'package:vueniverse/data/normalization/record_normalizer.dart';
import 'package:vueniverse/data/repositories/canonical_record_repository.dart';
import 'package:vueniverse/data/sources/source_repository.dart';
import 'package:vueniverse/data/sources/ultrahuman_client.dart';
import 'package:vueniverse/data/sources/ultrahuman_record_mapper.dart';
import 'package:vueniverse/domain/models/canonical_domain_models.dart';

/// Explicit foreground imports. The credential lives only in this call/session.
final class UltrahumanImportService {
  UltrahumanImportService(
    this.database, {
    UltrahumanClient? client,
    DateTime Function()? clock,
  }) : _client = client ?? UltrahumanClient(),
       _clock = clock ?? DateTime.now;
  final VueniverseDatabase database;
  final UltrahumanClient _client;
  final DateTime Function() _clock;
  static final _active = Expando<bool>('ultrahuman-import-active');

  Future<void> importRecentDays({
    required String token,
    required int days,
    String? endDate,
  }) async {
    if (_active[database] == true) {
      throw const UltrahumanException('import_in_progress');
    }
    _active[database] = true;
    try {
      await _importRecentDays(token: token, days: days, endDate: endDate);
    } finally {
      _active[database] = false;
    }
  }

  Future<void> _importRecentDays({
    required String token,
    required int days,
    String? endDate,
  }) async {
    if (!const {1, 7, 14}.contains(days)) {
      throw ArgumentError('Unsupported import period');
    }
    final now = _clock();
    final requestedEndDate =
        endDate ??
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    validateUltrahumanDate(requestedEndDate);
    final end = DateTime.parse('${requestedEndDate}T00:00:00Z');
    final earliest = end.subtract(Duration(days: days - 1));
    validateUltrahumanDate(earliest.toIso8601String().substring(0, 10));
    // The provider can be one calendar day ahead of UTC (+14 zone).
    // Do not compare requested daily dates to the phone's local midnight.
    final utc = now.toUtc();
    final latestPossibleDate = DateTime.utc(utc.year, utc.month, utc.day + 1);
    if (end.isAfter(latestPossibleDate)) {
      throw const UltrahumanException('future_requested_date');
    }
    final kind = await (database.select(
      database.storeMetadata,
    )..where((row) => row.key.equals('store_kind'))).getSingleOrNull();
    if (kind?.value != 'live') {
      throw StateError('Personal imports require the Live store');
    }
    timezone_data.initializeTimeZones();
    final sources = SourceRepository(database);
    await sources.initializeLiveSources();
    final initialState = (await sources.loadState(SourceIds.ultrahuman))!;
    if (const {'paused', 'deleting'}.contains(initialState.status)) {
      throw const UltrahumanException('source_paused');
    }
    final generation = initialState.configuration['collectionGeneration'] ?? 0;
    final normalizer = RecordNormalizer(
      identityKey: await database.getOrCreateSourceIdentityKey(),
    );
    final binding = Hmac(
      sha256,
      await database.getOrCreateSourceIdentityKey(),
    ).convert(utf8.encode(token)).toString();
    final claimError = await database.transaction<String?>(() async {
      final state = (await sources.loadState(SourceIds.ultrahuman))!;
      if ((state.configuration['collectionGeneration'] ?? 0) != generation ||
          const {'paused', 'deleting'}.contains(state.status)) {
        return 'source_changed';
      }
      final existingBinding = state.configuration['credentialBinding'];
      if (existingBinding != null && existingBinding != binding) {
        await sources.setStatus(
          SourceIds.ultrahuman,
          'error',
          configurationPatch: {
            'lastErrorCode': 'credential_changed',
            'lastErrorMessage':
                'A different API key cannot merge into this health history. Use the original key, or delete this source data before changing owner or key.',
          },
        );
        // Return rather than throw so this diagnostic commits atomically.
        return 'credential_changed';
      }
      await sources.setStatus(SourceIds.ultrahuman, 'syncing');
      return null;
    });
    if (claimError != null) throw UltrahumanException(claimError);
    final records = CanonicalRecordRepository(database);
    final importId = 'ultrahuman:${DateTime.now().microsecondsSinceEpoch}';
    final skipped = <String>{};
    for (var index = days - 1; index >= 0; index--) {
      final day = end.subtract(Duration(days: index));
      final date =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final runId = '$importId:$date';
      final started = DateTime.now().toUtc();
      try {
        final response = await _client.fetchDay(localDate: date, token: token);
        final mapped = UltrahumanRecordMapper(
          offsetResolver: (name, instant) {
            try {
              return timezone.TZDateTime.from(
                instant,
                timezone.getLocation(name),
              ).timeZoneOffset.inMinutes;
            } on Object {
              return null;
            }
          },
        ).mapDay(response, observedAt: _clock().toUtc());
        skipped.addAll(
          mapped.skippedMetricTypes.where(const {'hrv', 'steps'}.contains),
        );
        await database.transaction(() async {
          final state = (await sources.loadState(SourceIds.ultrahuman))!;
          if ((state.configuration['collectionGeneration'] ?? 0) !=
                  generation ||
              const {
                'paused',
                'disconnected',
                'deleting',
              }.contains(state.status)) {
            throw const UltrahumanException('source_changed');
          }
          final currentBinding = state.configuration['credentialBinding'];
          if (currentBinding != null && currentBinding != binding) {
            throw const UltrahumanException('credential_changed');
          }
          // Binding and canonical records commit together, never after one another.
          await sources.setStatus(
            SourceIds.ultrahuman,
            'syncing',
            configurationPatch: {
              'credentialBinding': binding,
              'reportedTimezone': response.timezoneName,
              'timezonePolicy': 'api_latest_zone_not_historical_travel',
              'requestedDatePolicy': endDate == null
                  ? 'device_date_default_provider_timezone_unconfirmed'
                  : 'explicit_provider_daily_dates',
              'requestedEndDate': requestedEndDate,
              'requestedStartDate': earliest.toIso8601String().substring(0, 10),
              'requestedDays': days,
              'unsupportedMetricTypes': skipped.toList()..sort(),
            },
          );
          final report = await records.importRecords(
            sourceConnectionId: SourceIds.ultrahuman,
            sourceKind: SourceKind.ultrahuman,
            records: mapped.records,
            normalizer: normalizer,
            syncRunId: runId,
          );
          final rejectionCounts = <String, int>{...report.rejectedCounts};
          for (final entry in mapped.rejectedCounts.entries) {
            rejectionCounts.update(
              entry.key,
              (count) => count + entry.value,
              ifAbsent: () => entry.value,
            );
          }
          final rejected = mapped.rejectedObservationCount + report.rejected;
          await (database.update(
            database.syncRuns,
          )..where((row) => row.id.equals(runId))).write(
            SyncRunsCompanion(
              recordsSeen: Value(mapped.inputObservationCount),
              recordsRejected: Value(rejected),
              errorDetails: Value(
                jsonEncode({
                  'receipt_schema': 1,
                  'rejections': rejectionCounts,
                  'inserted': report.inserted,
                  'changed': report.changed,
                  'duplicates':
                      report.duplicates + mapped.duplicateObservationCount,
                  'reportedTimezone': response.timezoneName,
                  'requestedLocalDate': date,
                }),
              ),
            ),
          );
        });
      } on Object catch (error) {
        final code = error is UltrahumanException
            ? error.safeCode
            : 'import_failed';
        final existing = await (database.select(
          database.syncRuns,
        )..where((row) => row.id.equals(runId))).getSingleOrNull();
        if (existing == null) {
          await database
              .into(database.syncRuns)
              .insert(
                SyncRunsCompanion.insert(
                  id: runId,
                  sourceConnectionId: SourceIds.ultrahuman,
                  status: 'failed',
                  startedAt: started,
                  finishedAt: Value(DateTime.now().toUtc()),
                  errorCode: Value(code),
                ),
              );
        } else {
          await (database.update(
            database.syncRuns,
          )..where((row) => row.id.equals(runId))).write(
            SyncRunsCompanion(
              status: const Value('failed'),
              finishedAt: Value(DateTime.now().toUtc()),
              errorCode: Value(code),
            ),
          );
        }
        await database.transaction(() async {
          final currentState = await sources.loadState(SourceIds.ultrahuman);
          if ((currentState?.configuration['collectionGeneration'] ?? 0) ==
                  generation &&
              !const {
                'paused',
                'disconnected',
                'deleting',
              }.contains(currentState?.status)) {
            await sources.setStatus(
              SourceIds.ultrahuman,
              'error',
              configurationPatch: {
                'lastErrorCode': code,
                'lastErrorMessage':
                    'The import stopped. Earlier successful days remain saved. Check collection history and retry.',
              },
            );
          }
        });
        throw const UltrahumanException('import_incomplete');
      }
    }
    await database.transaction(() async {
      final state = (await sources.loadState(SourceIds.ultrahuman))!;
      if ((state.configuration['collectionGeneration'] ?? 0) != generation ||
          const {'paused', 'disconnected', 'deleting'}.contains(state.status)) {
        throw const UltrahumanException('source_changed');
      }
      await sources.markSyncComplete(SourceIds.ultrahuman);
      await sources.setStatus(
        SourceIds.ultrahuman,
        (await sources.loadState(SourceIds.ultrahuman))!.status,
        configurationPatch: {
          'unsupportedMetricTypes': skipped.toList()..sort(),
          'timezonePolicy': 'api_latest_zone_not_historical_travel',
        },
      );
    });
  }
}
