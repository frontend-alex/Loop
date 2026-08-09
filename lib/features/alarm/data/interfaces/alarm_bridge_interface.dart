import 'package:loop/features/alarm/core/alarm.dart';

abstract interface class AlarmBridgeInterface {
  Future<bool> requestAuthorization();
  Future<void> schedule(Alarm alarm);
  Future<void> cancel(String alarmId);
}
