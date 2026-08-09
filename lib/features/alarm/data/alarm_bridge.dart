import 'package:flutter/services.dart';
import 'package:loop/features/alarm/core/alarm.dart';
import 'package:loop/features/alarm/data/interfaces/alarm_bridge_interface.dart';

final class AlarmBridge implements AlarmBridgeInterface {
  static const MethodChannel _channel = MethodChannel('loop/alarm');

  @override
  Future<bool> requestAuthorization() async {
    final result = await _channel.invokeMethod<bool>(
      'requestAlarmAuthorization',
    );
    return result ?? false;
  }

  @override
  Future<void> schedule(Alarm alarm) async {
    await _channel.invokeMethod<void>('scheduleAlarm', <String, Object?>{
      'id': alarm.id,
      'minute': alarm.time.minute,
      'hour': alarm.time.hour,
      'repeat': alarm.repeats,
      'label': alarm.label,
    });
  }

  @override
  Future<void> cancel(String alarmId) async {
    await _channel.invokeMethod<void>('cancelAlarm', <String, Object?>{
      'id': alarmId,
    });
  }
}
