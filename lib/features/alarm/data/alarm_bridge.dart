import 'dart:io';

import 'package:alarm/alarm.dart' as fallback_alarm;
import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart'
    show FlutterAlarmkit, Weekday;
import 'package:loop/features/alarm/core/alarm.dart';
import 'package:loop/features/alarm/data/interfaces/alarm_bridge_interface.dart';
import 'package:permission_handler/permission_handler.dart';

final class AlarmBridge implements AlarmBridgeInterface {
  static final FlutterAlarmkit _alarmKit = FlutterAlarmkit();
  static Future<void>? _fallbackInitialization;
  bool? _alarmKitSupported;

  @override
  Future<bool> requestAuthorization() async {
    if (Platform.isIOS && _alarmKitSupported != false) {
      try {
        final authorized = await _alarmKit.requestAuthorization();
        _alarmKitSupported = true;
        return authorized;
      } on PlatformException catch (error) {
        if (error.code != 'UNSUPPORTED_VERSION') {
          rethrow;
        }
        _alarmKitSupported = false;
      }
    }

    return _requestFallbackAuthorization();
  }

  @override
  Future<void> schedule(Alarm alarm) async {
    final useAlarmKit = await _usesAlarmKit();

    if (useAlarmKit) {
      await _alarmKit.cancelAll();
      await _alarmKit.scheduleRecurrentAlarm(
        weekdays: alarm.repeats ? Weekday.everyday : const <Weekday>{},
        hour: alarm.time.hour,
        minute: alarm.time.minute,
        label: alarm.label,
      );
      return;
    }

    await _initializeFallback();
    await fallback_alarm.Alarm.stopAll();
    await Future.wait(
      _fallbackSettings(
        alarm,
      ).map((settings) => fallback_alarm.Alarm.set(alarmSettings: settings)),
    );
  }

  @override
  Future<void> cancel(String alarmId) async {
    if (await _usesAlarmKit()) {
      await _alarmKit.cancelAll();
      return;
    }

    await _initializeFallback();
    await fallback_alarm.Alarm.stopAll();
  }

  Future<bool> _usesAlarmKit() async {
    if (_alarmKitSupported != null) {
      return _alarmKitSupported!;
    }

    final authorized = await requestAuthorization();
    if (!authorized) {
      throw StateError('Alarm permission was not granted.');
    }

    return _alarmKitSupported == true;
  }

  Future<void> _initializeFallback() {
    return _fallbackInitialization ??= fallback_alarm.Alarm.init();
  }

  Future<bool> _requestFallbackAuthorization() async {
    await _initializeFallback();

    if (!Platform.isAndroid) {
      return true;
    }

    final exactAlarm = await Permission.scheduleExactAlarm.request();
    final notifications = await Permission.notification.request();

    return exactAlarm.isGranted && notifications.isGranted;
  }

  List<fallback_alarm.AlarmSettings> _fallbackSettings(Alarm alarm) {
    final weekdays = alarm.repeats && Platform.isAndroid
        ? List<int>.generate(7, (index) => index + 1)
        : <int?>[null];

    return weekdays
        .map(
          (weekday) => fallback_alarm.AlarmSettings(
            id: _fallbackId('${alarm.id}:$weekday'),
            dateTime: _nextOccurrence(alarm, weekday: weekday),
            volumeSettings: const fallback_alarm.VolumeSettings.fixed(),
            assetAudioPath: null,
            loopAudio: true,
            vibrate: true,
            androidFullScreenIntent: true,
            notificationSettings: fallback_alarm.NotificationSettings(
              title: alarm.label,
              body: 'It is time to start your morning.',
              stopButton: 'Stop',
            ),
          ),
        )
        .toList(growable: false);
  }

  DateTime _nextOccurrence(Alarm alarm, {int? weekday}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final occurrence = today.add(
      Duration(days: weekday == null ? 0 : (weekday - now.weekday + 7) % 7),
    );
    final scheduled = DateTime(
      occurrence.year,
      occurrence.month,
      occurrence.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    if (scheduled.isAfter(now)) {
      return scheduled;
    }

    return scheduled.add(Duration(days: weekday == null ? 1 : 7));
  }

  int _fallbackId(String alarmId) {
    final hash = alarmId.codeUnits.fold<int>(
      17,
      (value, codeUnit) => (value * 31 + codeUnit) & 0x7fffffff,
    );

    return hash == 0 ? 1 : hash;
  }
}
