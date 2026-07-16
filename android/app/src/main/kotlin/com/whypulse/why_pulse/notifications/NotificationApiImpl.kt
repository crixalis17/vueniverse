package com.whypulse.why_pulse.notifications

import android.Manifest
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import com.whypulse.why_pulse.MainActivity

class NotificationApiImpl(private val activity: MainActivity) : NotificationApi {
  private val requestCode = 4107

  override fun requestPermission(callback: (Result<Boolean>) -> Unit) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
      ActivityCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS) ==
        PackageManager.PERMISSION_GRANTED
    ) {
      callback(Result.success(true))
      return
    }
    ActivityCompat.requestPermissions(
      activity,
      arrayOf(Manifest.permission.POST_NOTIFICATIONS),
      requestCode,
    )
    callback(Result.success(false))
  }

  override fun schedule(schedule: NotificationSchedule) {
    val intent = Intent(activity, ExperimentReminderReceiver::class.java).apply {
      putExtra("id", schedule.id)
      putExtra("title", schedule.title)
      putExtra("body", schedule.body)
    }
    val pending = PendingIntent.getBroadcast(
      activity,
      schedule.id.hashCode(),
      intent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    val alarm = activity.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, schedule.atEpochMillis, pending)
  }

  override fun cancel(id: String) {
    val intent = Intent(activity, ExperimentReminderReceiver::class.java)
    val pending = PendingIntent.getBroadcast(
      activity,
      id.hashCode(),
      intent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    val alarm = activity.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    alarm.cancel(pending)
    pending.cancel()
  }
}
