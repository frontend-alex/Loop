package com.example.loop

import android.Manifest
import android.app.AlarmManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "loop/alarm"
    private val notificationPermissionRequestCode = 1001
    private var authorizationResult: MethodChannel.Result? = null
    private var waitingForExactAlarmSettings = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestAlarmAuthorization" -> {
                    requestAlarmAuthorization(result)
                }

                "scheduleAlarm" -> {
                    runCatching {
                        AlarmScheduler(this).schedule(
                            AlarmRequest.from(call.arguments),
                        )
                    }.onSuccess {
                        result.success(null)
                    }.onFailure { error ->
                        result.error(
                            "SCHEDULE_ALARM_ERROR",
                            error.message,
                            null,
                        )
                    }
                }

                "cancelAlarm" -> {
                    val id = call.argument<String>("id")

                    if (id == null) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "Alarm id is required.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    runCatching {
                        AlarmScheduler(this).cancel(id)
                    }.onSuccess {
                        result.success(null)
                    }.onFailure { error ->
                        result.error(
                            "CANCEL_ALARM_ERROR",
                            error.message,
                            null,
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun requestAlarmAuthorization(result: MethodChannel.Result) {
        if (authorizationResult != null) {
            result.error(
                "AUTHORIZATION_IN_PROGRESS",
                "Alarm authorization is already being requested.",
                null,
            )
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(AlarmManager::class.java)

            if (!alarmManager.canScheduleExactAlarms()) {
                authorizationResult = result
                waitingForExactAlarmSettings = true
                startActivity(
                    Intent(
                        Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                        Uri.parse("package:$packageName"),
                    ),
                )
                return
            }
        }

        completeAlarmAuthorization(result)
    }

    override fun onResume() {
        super.onResume()

        if (!waitingForExactAlarmSettings) {
            return
        }

        waitingForExactAlarmSettings = false
        val result = authorizationResult ?: return
        authorizationResult = null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(AlarmManager::class.java)

            if (!alarmManager.canScheduleExactAlarms()) {
                result.success(false)
                return
            }
        }

        completeAlarmAuthorization(result)
    }

    private fun completeAlarmAuthorization(result: MethodChannel.Result) {
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            authorizationResult = result
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                notificationPermissionRequestCode,
            )
            return
        }

        result.success(true)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != notificationPermissionRequestCode) {
            return
        }

        val result = authorizationResult ?: return
        authorizationResult = null
        result.success(
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED,
        )
    }
}

data class AlarmRequest(
    val id: String,
    val hour: Int,
    val minute: Int,
    val repeat: Boolean,
    val label: String,
) {
    companion object {
        fun from(arguments: Any?): AlarmRequest {
            val values = arguments as? Map<*, *>
                ?: error("Alarm arguments are invalid.")

            val hour = values["hour"] as? Int
                ?: error("Alarm hour is required.")
            val minute = values["minute"] as? Int
                ?: error("Alarm minute is required.")
            val repeat = values["repeat"] as? Boolean
                ?: error("Alarm repeat setting is required.")

            require(hour in 0..23) { "Alarm hour is invalid." }
            require(minute in 0..59) { "Alarm minute is invalid." }

            return AlarmRequest(
                id = values["id"] as? String
                    ?: error("Alarm id is required."),
                hour = hour,
                minute = minute,
                repeat = repeat,
                label = values["label"] as? String
                    ?: error("Alarm label is required."),
            )
        }
    }
}
