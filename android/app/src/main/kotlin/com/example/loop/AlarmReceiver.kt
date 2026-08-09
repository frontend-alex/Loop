package com.example.loop

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getStringExtra(alarmIdKey) ?: return
        val hour = intent.getIntExtra(hourKey, -1)
        val minute = intent.getIntExtra(minuteKey, -1)
        val weekday = intent.getIntExtra(weekdayKey, -1)
        val repeat = intent.getBooleanExtra(repeatKey, false)
        val label = intent.getStringExtra(labelKey) ?: "Loop alarm"

        if (hour !in 0..23 || minute !in 0..59) {
            return
        }

        if (repeat && weekday !in 1..7) {
            return
        }

        if (repeat) {
            AlarmScheduler(context).scheduleNextForDay(
                AlarmRequest(
                    id = alarmId,
                    hour = hour,
                    minute = minute,
                    repeat = true,
                    label = label,
                ),
                weekday,
            )
        } else {
            AlarmScheduler(context).clearSavedAlarm(alarmId)
        }

        val notificationManager = context.getSystemService(
            NotificationManager::class.java,
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager.createNotificationChannel(
                NotificationChannel(
                    channelId,
                    "Loop alarms",
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(com.example.loop.R.mipmap.ic_launcher)
            .setContentTitle(label)
            .setContentText("It is time to start your morning.")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(alarmId.hashCode(), notification)
    }

    companion object {
        const val alarmIdKey = "alarm_id"
        const val hourKey = "alarm_hour"
        const val minuteKey = "alarm_minute"
        const val weekdayKey = "alarm_weekday"
        const val repeatKey = "alarm_repeat"
        const val labelKey = "alarm_label"
        private const val channelId = "loop_alarm"
    }
}
