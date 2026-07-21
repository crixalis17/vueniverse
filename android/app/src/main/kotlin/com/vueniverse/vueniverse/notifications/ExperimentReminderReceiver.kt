package com.vueniverse.vueniverse.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.vueniverse.vueniverse.MainActivity

class ExperimentReminderReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    val channelId = "experiment_reminders"
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      manager.createNotificationChannel(
        NotificationChannel(
          channelId,
          "Experiment reminders",
          NotificationManager.IMPORTANCE_DEFAULT,
        ),
      )
    }
    val open = PendingIntent.getActivity(
      context,
      77,
      Intent(context, MainActivity::class.java),
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    val notification = NotificationCompat.Builder(context, channelId)
      .setSmallIcon(android.R.drawable.ic_popup_reminder)
      .setContentTitle(intent.getStringExtra("title") ?: "Vueniverse experiment")
      .setContentText(intent.getStringExtra("body") ?: "Your next observation is ready.")
      .setContentIntent(open)
      .setAutoCancel(true)
      .build()
    manager.notify((intent.getStringExtra("id") ?: "experiment").hashCode(), notification)
  }
}
