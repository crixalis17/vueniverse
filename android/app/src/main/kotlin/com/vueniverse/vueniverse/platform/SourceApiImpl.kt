package com.vueniverse.vueniverse.sources

import android.Manifest
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.CalendarContract
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.HealthConnectFeatures
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.changes.DeletionChange
import androidx.health.connect.client.changes.UpsertionChange
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.HeartRateVariabilityRmssdRecord
import androidx.health.connect.client.records.Record as HealthRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ChangesTokenRequest
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import com.vueniverse.vueniverse.MainActivity
import java.io.IOException
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import kotlin.math.max
import kotlin.reflect.KClass
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class SourceApiImpl(private val activity: MainActivity) : SourceApi {
  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
  private var pendingHealthPermission:
    ((Result<NativeHealthPermissionSnapshot>) -> Unit)? = null
  private var pendingCalendarPermission:
    ((Result<NativeCalendarPermissionSnapshot>) -> Unit)? = null

  private val healthPermissionLauncher = activity.registerForActivityResult(
    PermissionController.createRequestPermissionResultContract(),
  ) {
    val callback = pendingHealthPermission
    pendingHealthPermission = null
    if (callback != null) {
      scope.launch {
        callback(runCatching { healthPermissionSnapshot() })
      }
    }
  }

  private val calendarPermissionLauncher = activity.registerForActivityResult(
    ActivityResultContracts.RequestPermission(),
  ) {
    val callback = pendingCalendarPermission
    pendingCalendarPermission = null
    callback?.invoke(Result.success(calendarPermissionSnapshot()))
  }

  override fun getHealthAvailability(
    callback: (Result<NativeHealthAvailability>) -> Unit,
  ) {
    callback(runCatching { healthAvailability() })
  }

  override fun getHealthPermissionSnapshot(
    callback: (Result<NativeHealthPermissionSnapshot>) -> Unit,
  ) {
    scope.launch { callback(runCatching { healthPermissionSnapshot() }) }
  }

  override fun requestHealthPermissions(
    types: List<HealthDataType>,
    callback: (Result<NativeHealthPermissionSnapshot>) -> Unit,
  ) {
    if (pendingHealthPermission != null) {
      callback(Result.failure(IllegalStateException("A Health Connect request is already open.")))
      return
    }
    if (healthAvailability().status != HealthAvailabilityStatus.AVAILABLE) {
      scope.launch { callback(runCatching { healthPermissionSnapshot() }) }
      return
    }
    pendingHealthPermission = callback
    val permissions = types.map { healthReadPermission(it) }.toSet()
    activity.runOnUiThread { healthPermissionLauncher.launch(permissions) }
  }

  override fun readHealthPage(
    type: HealthDataType,
    startEpochMillis: Long,
    endEpochMillis: Long,
    pageToken: String?,
    pageSize: Long,
    callback: (Result<NativeHealthPageResult>) -> Unit,
  ) {
    scope.launch {
      callback(
        Result.success(
          try {
            NativeHealthPageResult(
              page = readHealthPageInternal(
                type,
                startEpochMillis,
                endEpochMillis,
                pageToken,
                pageSize.toInt().coerceIn(1, 1000),
              ),
            )
          } catch (error: Throwable) {
            NativeHealthPageResult(failure = sourceFailure(error, "health_read_failed"))
          },
        ),
      )
    }
  }

  override fun createHealthChangesToken(
    type: HealthDataType,
    callback: (Result<NativeHealthTokenResult>) -> Unit,
  ) {
    scope.launch {
      callback(
        Result.success(
          try {
            val token = healthClient().getChangesToken(
              ChangesTokenRequest(recordTypes = setOf(healthRecordClass(type))),
            )
            NativeHealthTokenResult(token = token)
          } catch (error: Throwable) {
            NativeHealthTokenResult(failure = sourceFailure(error, "health_token_failed"))
          },
        ),
      )
    }
  }

  override fun readHealthChanges(
    type: HealthDataType,
    changesToken: String,
    callback: (Result<NativeHealthChangesResult>) -> Unit,
  ) {
    scope.launch {
      callback(
        Result.success(
          try {
            val response = healthClient().getChanges(changesToken)
            val upserts = response.changes.mapNotNull { change ->
              (change as? UpsertionChange)?.record?.let(::nativeHealthRecord)
            }.filter { it.type == type }
            val deletions = response.changes.mapNotNull { change ->
              (change as? DeletionChange)?.recordId
            }
            NativeHealthChangesResult(
              changes = NativeHealthChanges(
                upserts = upserts,
                deletedRecordIds = deletions,
                nextChangesToken = response.nextChangesToken,
                hasMore = response.hasMore,
                tokenExpired = response.changesTokenExpired,
              ),
            )
          } catch (error: Throwable) {
            NativeHealthChangesResult(failure = sourceFailure(error, "health_changes_failed"))
          },
        ),
      )
    }
  }

  override fun getCalendarPermissionSnapshot(): NativeCalendarPermissionSnapshot =
    calendarPermissionSnapshot()

  override fun requestCalendarPermission(
    callback: (Result<NativeCalendarPermissionSnapshot>) -> Unit,
  ) {
    if (pendingCalendarPermission != null) {
      callback(Result.failure(IllegalStateException("A Calendar request is already open.")))
      return
    }
    if (calendarPermissionSnapshot().state == NativePermissionState.GRANTED) {
      callback(Result.success(calendarPermissionSnapshot()))
      return
    }
    pendingCalendarPermission = callback
    activity.runOnUiThread {
      calendarPermissionLauncher.launch(Manifest.permission.READ_CALENDAR)
    }
  }

  override fun discoverRecurringCalendarSeries(
    callback: (Result<NativeCalendarDiscoveryResult>) -> Unit,
  ) {
    scope.launch {
      callback(
        Result.success(
          try {
            NativeCalendarDiscoveryResult(series = discoverCalendarSeries())
          } catch (error: Throwable) {
            NativeCalendarDiscoveryResult(
              series = emptyList(),
              failure = sourceFailure(error, "calendar_discovery_failed"),
            )
          },
        ),
      )
    }
  }

  override fun readRecurringCalendarSnapshot(
    startEpochMillis: Long,
    endEpochMillis: Long,
    callback: (Result<NativeCalendarSnapshotResult>) -> Unit,
  ) {
    scope.launch {
      callback(
        Result.success(
          try {
            NativeCalendarSnapshotResult(
              instances = readCalendarInstances(startEpochMillis, endEpochMillis),
              complete = true,
            )
          } catch (error: Throwable) {
            NativeCalendarSnapshotResult(
              instances = emptyList(),
              complete = false,
              failure = sourceFailure(error, "calendar_snapshot_failed"),
            )
          },
        ),
      )
    }
  }

  override fun openSourceSettings(kind: SourcePlatformKind) {
    val intent = when (kind) {
      SourcePlatformKind.HEALTH_CONNECT ->
        HealthConnectClient.getHealthConnectManageDataIntent(activity)
      SourcePlatformKind.CALENDAR -> Intent(
        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
        Uri.parse("package:${activity.packageName}"),
      )
    }.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    activity.startActivity(intent)
  }

  fun dispose() {
    scope.cancel()
  }

  private fun healthAvailability(): NativeHealthAvailability {
    val sdkStatus = HealthConnectClient.getSdkStatus(activity)
    val status = when (sdkStatus) {
      HealthConnectClient.SDK_AVAILABLE -> HealthAvailabilityStatus.AVAILABLE
      HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED ->
        HealthAvailabilityStatus.UPDATE_REQUIRED
      else -> HealthAvailabilityStatus.UNAVAILABLE
    }
    val features = if (status == HealthAvailabilityStatus.AVAILABLE) {
      val client = HealthConnectClient.getOrCreate(activity)
      listOf(
        NativeFeatureState(
          "background_read",
          client.features.getFeatureStatus(
            HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_IN_BACKGROUND,
          ) == HealthConnectFeatures.FEATURE_STATUS_AVAILABLE,
        ),
        NativeFeatureState(
          "history_read",
          client.features.getFeatureStatus(
            HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_HISTORY,
          ) == HealthConnectFeatures.FEATURE_STATUS_AVAILABLE,
        ),
        NativeFeatureState("change_tokens", true),
        NativeFeatureState("hrv_rmssd", true),
      )
    } else {
      listOf(
        NativeFeatureState("background_read", false),
        NativeFeatureState("history_read", false),
        NativeFeatureState("change_tokens", false),
        NativeFeatureState("hrv_rmssd", false),
      )
    }
    return NativeHealthAvailability(
      status = status,
      features = features,
      providerPackage = if (status == HealthAvailabilityStatus.UNAVAILABLE) {
        null
      } else {
        "com.google.android.apps.healthdata"
      },
    )
  }

  private suspend fun healthPermissionSnapshot(): NativeHealthPermissionSnapshot {
    val availability = healthAvailability().status
    if (availability != HealthAvailabilityStatus.AVAILABLE) {
      return NativeHealthPermissionSnapshot(
        HealthDataType.entries.map {
          NativeHealthPermission(it, NativePermissionState.UNAVAILABLE)
        },
      )
    }
    val granted = healthClient().permissionController.getGrantedPermissions()
    return NativeHealthPermissionSnapshot(
      HealthDataType.entries.map { type ->
        NativeHealthPermission(
          type,
          if (granted.contains(healthReadPermission(type))) {
            NativePermissionState.GRANTED
          } else {
            NativePermissionState.DENIED
          },
        )
      },
    )
  }

  private fun healthClient(): HealthConnectClient {
    if (healthAvailability().status != HealthAvailabilityStatus.AVAILABLE) {
      throw IllegalStateException("Health Connect is unavailable.")
    }
    return HealthConnectClient.getOrCreate(activity)
  }

  private suspend fun readHealthPageInternal(
    type: HealthDataType,
    startEpochMillis: Long,
    endEpochMillis: Long,
    pageToken: String?,
    pageSize: Int,
  ): NativeHealthPage {
    require(endEpochMillis > startEpochMillis) { "The Health Connect range is invalid." }
    val filter = TimeRangeFilter.between(
      Instant.ofEpochMilli(startEpochMillis),
      Instant.ofEpochMilli(endEpochMillis),
    )
    return when (type) {
      HealthDataType.HEART_RATE -> {
        val response = healthClient().readRecords(
          ReadRecordsRequest(
            recordType = HeartRateRecord::class,
            timeRangeFilter = filter,
            ascendingOrder = true,
            pageSize = pageSize,
            pageToken = pageToken,
          ),
        )
        NativeHealthPage(response.records.map(::nativeHealthRecord), response.pageToken)
      }
      HealthDataType.SLEEP -> {
        val response = healthClient().readRecords(
          ReadRecordsRequest(
            recordType = SleepSessionRecord::class,
            timeRangeFilter = filter,
            ascendingOrder = true,
            pageSize = pageSize,
            pageToken = pageToken,
          ),
        )
        NativeHealthPage(response.records.map(::nativeHealthRecord), response.pageToken)
      }
      HealthDataType.STEPS -> {
        val response = healthClient().readRecords(
          ReadRecordsRequest(
            recordType = StepsRecord::class,
            timeRangeFilter = filter,
            ascendingOrder = true,
            pageSize = pageSize,
            pageToken = pageToken,
          ),
        )
        NativeHealthPage(response.records.map(::nativeHealthRecord), response.pageToken)
      }
      HealthDataType.EXERCISE -> {
        val response = healthClient().readRecords(
          ReadRecordsRequest(
            recordType = ExerciseSessionRecord::class,
            timeRangeFilter = filter,
            ascendingOrder = true,
            pageSize = pageSize,
            pageToken = pageToken,
          ),
        )
        NativeHealthPage(response.records.map(::nativeHealthRecord), response.pageToken)
      }
      HealthDataType.ACTIVITY -> {
        val response = healthClient().readRecords(
          ReadRecordsRequest(
            recordType = ActiveCaloriesBurnedRecord::class,
            timeRangeFilter = filter,
            ascendingOrder = true,
            pageSize = pageSize,
            pageToken = pageToken,
          ),
        )
        NativeHealthPage(response.records.map(::nativeHealthRecord), response.pageToken)
      }
      HealthDataType.HRV_RMSSD -> {
        val response = healthClient().readRecords(
          ReadRecordsRequest(
            recordType = HeartRateVariabilityRmssdRecord::class,
            timeRangeFilter = filter,
            ascendingOrder = true,
            pageSize = pageSize,
            pageToken = pageToken,
          ),
        )
        NativeHealthPage(response.records.map(::nativeHealthRecord), response.pageToken)
      }
    }
  }

  private fun nativeHealthRecord(record: HealthRecord): NativeHealthRecord = when (record) {
    is HeartRateRecord -> NativeHealthRecord(
      id = record.metadata.id,
      type = HealthDataType.HEART_RATE,
      startEpochMillis = record.startTime.toEpochMilli(),
      endEpochMillis = record.endTime.toEpochMilli(),
      startOffsetMinutes = offsetMinutes(record.startZoneOffset, record.startTime),
      endOffsetMinutes = offsetMinutes(record.endZoneOffset, record.endTime),
      lastModifiedEpochMillis = record.metadata.lastModifiedTime.toEpochMilli(),
      samples = record.samples.map {
        NativeNumericSample(
          it.time.toEpochMilli(),
          offsetMinutes(record.startZoneOffset, it.time),
          it.beatsPerMinute.toDouble(),
        )
      },
      segments = emptyList(),
      unit = "bpm",
    )
    is SleepSessionRecord -> NativeHealthRecord(
      id = record.metadata.id,
      type = HealthDataType.SLEEP,
      startEpochMillis = record.startTime.toEpochMilli(),
      endEpochMillis = record.endTime.toEpochMilli(),
      startOffsetMinutes = offsetMinutes(record.startZoneOffset, record.startTime),
      endOffsetMinutes = offsetMinutes(record.endZoneOffset, record.endTime),
      lastModifiedEpochMillis = record.metadata.lastModifiedTime.toEpochMilli(),
      samples = emptyList(),
      segments = if (record.stages.isEmpty()) {
        listOf(
          NativeIntervalSegment(
            record.startTime.toEpochMilli(),
            record.endTime.toEpochMilli(),
            "asleep",
          ),
        )
      } else {
        record.stages.map {
          NativeIntervalSegment(
            it.startTime.toEpochMilli(),
            it.endTime.toEpochMilli(),
            sleepCategory(it.stage),
          )
        }
      },
      category = "asleep",
    )
    is StepsRecord -> NativeHealthRecord(
      id = record.metadata.id,
      type = HealthDataType.STEPS,
      startEpochMillis = record.startTime.toEpochMilli(),
      endEpochMillis = record.endTime.toEpochMilli(),
      startOffsetMinutes = offsetMinutes(record.startZoneOffset, record.startTime),
      endOffsetMinutes = offsetMinutes(record.endZoneOffset, record.endTime),
      lastModifiedEpochMillis = record.metadata.lastModifiedTime.toEpochMilli(),
      samples = emptyList(),
      segments = emptyList(),
      value = record.count.toDouble(),
      unit = "count",
    )
    is ExerciseSessionRecord -> NativeHealthRecord(
      id = record.metadata.id,
      type = HealthDataType.EXERCISE,
      startEpochMillis = record.startTime.toEpochMilli(),
      endEpochMillis = record.endTime.toEpochMilli(),
      startOffsetMinutes = offsetMinutes(record.startZoneOffset, record.startTime),
      endOffsetMinutes = offsetMinutes(record.endZoneOffset, record.endTime),
      lastModifiedEpochMillis = record.metadata.lastModifiedTime.toEpochMilli(),
      samples = emptyList(),
      segments = emptyList(),
      category = exerciseCategory(record.exerciseType),
    )
    is ActiveCaloriesBurnedRecord -> NativeHealthRecord(
      id = record.metadata.id,
      type = HealthDataType.ACTIVITY,
      startEpochMillis = record.startTime.toEpochMilli(),
      endEpochMillis = record.endTime.toEpochMilli(),
      startOffsetMinutes = offsetMinutes(record.startZoneOffset, record.startTime),
      endOffsetMinutes = offsetMinutes(record.endZoneOffset, record.endTime),
      lastModifiedEpochMillis = record.metadata.lastModifiedTime.toEpochMilli(),
      samples = emptyList(),
      segments = emptyList(),
      value = record.energy.inKilocalories,
      unit = "kcal",
      category = "active",
    )
    is HeartRateVariabilityRmssdRecord -> NativeHealthRecord(
      id = record.metadata.id,
      type = HealthDataType.HRV_RMSSD,
      startEpochMillis = record.time.toEpochMilli(),
      endEpochMillis = record.time.toEpochMilli(),
      startOffsetMinutes = offsetMinutes(record.zoneOffset, record.time),
      endOffsetMinutes = offsetMinutes(record.zoneOffset, record.time),
      lastModifiedEpochMillis = record.metadata.lastModifiedTime.toEpochMilli(),
      samples = emptyList(),
      segments = emptyList(),
      value = record.heartRateVariabilityMillis,
      unit = "ms",
    )
    else -> throw IllegalArgumentException("Unsupported Health Connect record type.")
  }

  private fun healthRecordClass(type: HealthDataType): KClass<out HealthRecord> = when (type) {
    HealthDataType.HEART_RATE -> HeartRateRecord::class
    HealthDataType.SLEEP -> SleepSessionRecord::class
    HealthDataType.STEPS -> StepsRecord::class
    HealthDataType.EXERCISE -> ExerciseSessionRecord::class
    HealthDataType.ACTIVITY -> ActiveCaloriesBurnedRecord::class
    HealthDataType.HRV_RMSSD -> HeartRateVariabilityRmssdRecord::class
  }

  private fun healthReadPermission(type: HealthDataType): String =
    HealthPermission.getReadPermission(healthRecordClass(type))

  private fun calendarPermissionSnapshot(): NativeCalendarPermissionSnapshot {
    val granted = ContextCompat.checkSelfPermission(
      activity,
      Manifest.permission.READ_CALENDAR,
    ) == PackageManager.PERMISSION_GRANTED
    return NativeCalendarPermissionSnapshot(
      state = if (granted) NativePermissionState.GRANTED else NativePermissionState.DENIED,
      shouldShowRationale = !granted && ActivityCompat.shouldShowRequestPermissionRationale(
        activity,
        Manifest.permission.READ_CALENDAR,
      ),
    )
  }

  private fun discoverCalendarSeries(): List<NativeCalendarSeries> {
    requireCalendarPermission()
    val projection = arrayOf(
      CalendarContract.Events._ID,
      CalendarContract.Events.TITLE,
      CalendarContract.Events.RRULE,
      CalendarContract.Events.RDATE,
      CalendarContract.Events.EVENT_TIMEZONE,
    )
    val selection =
      "(${CalendarContract.Events.RRULE} IS NOT NULL OR ${CalendarContract.Events.RDATE} IS NOT NULL)" +
        " AND ${CalendarContract.Events.DELETED}=0"
    val cursor = activity.contentResolver.query(
      CalendarContract.Events.CONTENT_URI,
      projection,
      selection,
      null,
      "${CalendarContract.Events.TITLE} COLLATE NOCASE ASC",
    ) ?: throw IOException("Calendar provider returned no cursor.")
    return cursor.use {
      buildList {
        while (it.moveToNext()) {
          val id = it.getLong(0).toString()
          val title = it.getString(1)?.trim().orEmpty().ifEmpty { "Untitled recurring event" }
          val rule = it.getString(2) ?: it.getString(3) ?: "recurring"
          val timeZone = it.getString(4).orEmpty().ifEmpty { ZoneId.systemDefault().id }
          add(NativeCalendarSeries(id, title, rule, timeZone))
        }
      }
    }
  }

  private fun readCalendarInstances(
    startEpochMillis: Long,
    endEpochMillis: Long,
  ): List<NativeCalendarInstance> {
    requireCalendarPermission()
    require(endEpochMillis > startEpochMillis) { "The Calendar range is invalid." }
    val uri = CalendarContract.Instances.CONTENT_URI.buildUpon().also {
      ContentUris.appendId(it, startEpochMillis)
      ContentUris.appendId(it, endEpochMillis)
    }.build()
    val projection = arrayOf(
      CalendarContract.Instances.EVENT_ID,
      CalendarContract.Instances.BEGIN,
      CalendarContract.Instances.END,
      CalendarContract.Instances.EVENT_TIMEZONE,
      CalendarContract.Instances.RRULE,
      CalendarContract.Instances.RDATE,
      CalendarContract.Instances.ORIGINAL_ID,
      CalendarContract.Instances.STATUS,
    )
    val cursor = activity.contentResolver.query(
      uri,
      projection,
      null,
      null,
      "${CalendarContract.Instances.BEGIN} ASC",
    ) ?: throw IOException("Calendar provider returned no snapshot cursor.")
    return cursor.use {
      buildList {
        while (it.moveToNext()) {
          val rrule = it.getString(4)
          val rdate = it.getString(5)
          val originalId = if (it.isNull(6)) null else it.getLong(6)
          val status = if (it.isNull(7)) null else it.getInt(7)
          if (rrule == null && rdate == null && originalId == null) continue
          if (status == CalendarContract.Events.STATUS_CANCELED) continue
          val eventId = it.getLong(0)
          val begin = it.getLong(1)
          val end = it.getLong(2)
          if (end <= begin) continue
          val zoneName = it.getString(3).orEmpty().ifEmpty { ZoneId.systemDefault().id }
          val offset = try {
            ZoneId.of(zoneName).rules.getOffset(Instant.ofEpochMilli(begin)).totalSeconds / 60
          } catch (_: Exception) {
            ZoneId.systemDefault().rules.getOffset(Instant.ofEpochMilli(begin)).totalSeconds / 60
          }
          val seriesId = (originalId ?: eventId).toString()
          add(
            NativeCalendarInstance(
              instanceId = "$eventId:$begin:$end",
              seriesId = seriesId,
              startEpochMillis = begin,
              endEpochMillis = end,
              offsetMinutes = offset.toLong(),
            ),
          )
        }
      }
    }
  }

  private fun requireCalendarPermission() {
    if (calendarPermissionSnapshot().state != NativePermissionState.GRANTED) {
      throw SecurityException("Calendar permission is required.")
    }
  }

  private fun sourceFailure(error: Throwable, fallbackCode: String): NativeSourceFailure {
    val rateLimited = error.message?.contains("rate", ignoreCase = true) == true
    val permissionDenied = error is SecurityException
    val retryable = rateLimited || error is IOException || error is android.os.RemoteException
    return NativeSourceFailure(
      code = when {
        permissionDenied -> "permission_denied"
        rateLimited -> "rate_limited"
        retryable -> "provider_temporarily_unavailable"
        else -> fallbackCode
      },
      message = when {
        permissionDenied -> "Permission is required before this source can be read."
        retryable -> "The Android provider is temporarily unavailable."
        else -> "The Android provider could not complete this request."
      },
      retryable = retryable,
      openSettingsRecommended = permissionDenied,
      retryAfterMillis = if (rateLimited) 30_000 else null,
    )
  }

  private fun offsetMinutes(offset: ZoneOffset?, instant: Instant): Long =
    (offset ?: ZoneId.systemDefault().rules.getOffset(instant)).totalSeconds.toLong() / 60

  private fun sleepCategory(stage: Int): String = when (stage) {
    SleepSessionRecord.STAGE_TYPE_AWAKE,
    SleepSessionRecord.STAGE_TYPE_AWAKE_IN_BED,
    SleepSessionRecord.STAGE_TYPE_OUT_OF_BED -> "awake"
    SleepSessionRecord.STAGE_TYPE_LIGHT -> "light"
    SleepSessionRecord.STAGE_TYPE_DEEP -> "deep"
    SleepSessionRecord.STAGE_TYPE_REM -> "rem"
    SleepSessionRecord.STAGE_TYPE_SLEEPING -> "asleep"
    else -> "unknown"
  }

  private fun exerciseCategory(type: Int): String = when (type) {
    ExerciseSessionRecord.EXERCISE_TYPE_WALKING -> "walking"
    ExerciseSessionRecord.EXERCISE_TYPE_RUNNING,
    ExerciseSessionRecord.EXERCISE_TYPE_RUNNING_TREADMILL -> "running"
    ExerciseSessionRecord.EXERCISE_TYPE_BIKING,
    ExerciseSessionRecord.EXERCISE_TYPE_BIKING_STATIONARY -> "cycling"
    ExerciseSessionRecord.EXERCISE_TYPE_STRENGTH_TRAINING,
    ExerciseSessionRecord.EXERCISE_TYPE_WEIGHTLIFTING -> "strength"
    ExerciseSessionRecord.EXERCISE_TYPE_YOGA -> "yoga"
    else -> "other"
  }
}
