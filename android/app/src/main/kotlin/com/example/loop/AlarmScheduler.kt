package com.example.loop

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import java.util.Calendar

class AlarmScheduler(
    private val context: Context,
) {
    private val alarmManager = context.getSystemService(AlarmManager::class.java)
    private val preferences = context.getSharedPreferences(
        preferencesName,
        Context.MODE_PRIVATE,
    )

    fun schedule(alarm: AlarmRequest) {
        cancel()
        save(alarm)
        if (alarm.repeat) {
            (1..7).forEach { weekday ->
                scheduleNextForDay(alarm, weekday)
            }
        } else {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                nextTrigger(alarm),
                pendingIntent(alarm, 0),
            )
        }
    }

    fun scheduleNextForDay(alarm: AlarmRequest, weekday: Int) {
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            nextTrigger(alarm, weekday),
            pendingIntent(alarm, weekday),
        )
    }

    fun cancel(alarmId: String? = null) {
        val savedId = preferences.getString(alarmIdKey, null)

        if (alarmId != null && savedId != null && savedId != alarmId) {
            return
        }

        (0..7).forEach { weekday ->
            cancelWeekday(weekday)
        }
        preferences.edit().clear().apply()
    }

    fun restore() {
        val id = preferences.getString(alarmIdKey, null) ?: return
        val hour = preferences.getInt(hourKey, -1)
        val minute = preferences.getInt(minuteKey, -1)
        val repeat = preferences.getBoolean(repeatKey, false)
        val label = preferences.getString(labelKey, null) ?: return

        if (hour !in 0..23 || minute !in 0..59) {
            return
        }

        schedule(
            AlarmRequest(
                id = id,
                hour = hour,
                minute = minute,
                repeat = repeat,
                label = label,
            ),
        )
    }

    fun clearSavedAlarm(alarmId: String) {
        if (preferences.getString(alarmIdKey, null) == alarmId) {
            preferences.edit().clear().apply()
        }
    }

    private fun cancelWeekday(weekday: Int) {
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode(weekday),
            Intent(context, AlarmReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE,
        )

        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    private fun nextTrigger(
        alarm: AlarmRequest,
        weekday: Int,
    ): Long {
        val now = Calendar.getInstance()
        val trigger = Calendar.getInstance()

        trigger.set(Calendar.DAY_OF_WEEK, androidWeekday(weekday))
        trigger.set(Calendar.HOUR_OF_DAY, alarm.hour)
        trigger.set(Calendar.MINUTE, alarm.minute)
        trigger.set(Calendar.SECOND, 0)
        trigger.set(Calendar.MILLISECOND, 0)

        if (trigger.timeInMillis <= now.timeInMillis) {
            trigger.add(Calendar.DAY_OF_YEAR, 7)
        }

        return trigger.timeInMillis
    }

    private fun nextTrigger(alarm: AlarmRequest): Long {
        val now = Calendar.getInstance()
        val trigger = Calendar.getInstance()

        trigger.set(Calendar.HOUR_OF_DAY, alarm.hour)
        trigger.set(Calendar.MINUTE, alarm.minute)
        trigger.set(Calendar.SECOND, 0)
        trigger.set(Calendar.MILLISECOND, 0)

        if (trigger.timeInMillis <= now.timeInMillis) {
            trigger.add(Calendar.DAY_OF_YEAR, 1)
        }

        return trigger.timeInMillis
    }

    private fun pendingIntent(
        alarm: AlarmRequest,
        weekday: Int,
    ): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java)
            .putExtra(AlarmReceiver.alarmIdKey, alarm.id)
            .putExtra(AlarmReceiver.hourKey, alarm.hour)
            .putExtra(AlarmReceiver.minuteKey, alarm.minute)
            .putExtra(AlarmReceiver.weekdayKey, weekday)
            .putExtra(AlarmReceiver.repeatKey, alarm.repeat)
            .putExtra(AlarmReceiver.labelKey, alarm.label)

        return PendingIntent.getBroadcast(
            context,
            requestCode(weekday),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun requestCode(weekday: Int): Int {
        return weekday
    }

    private fun androidWeekday(weekday: Int): Int {
        return if (weekday == 7) Calendar.SUNDAY else weekday + 1
    }

    private fun save(alarm: AlarmRequest) {
        preferences.edit()
            .putString(alarmIdKey, alarm.id)
            .putInt(hourKey, alarm.hour)
            .putInt(minuteKey, alarm.minute)
            .putBoolean(repeatKey, alarm.repeat)
            .putString(labelKey, alarm.label)
            .apply()
    }

    companion object {
        private const val preferencesName = "loop_alarm"
        private const val alarmIdKey = "alarm_id"
        private const val hourKey = "alarm_hour"
        private const val minuteKey = "alarm_minute"
        private const val repeatKey = "alarm_repeat"
        private const val labelKey = "alarm_label"
    }
}
