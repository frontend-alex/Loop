import 'package:loop/features/alarm/core/alarm.dart';

abstract interface class AlarmInterface {
  Future<Alarm> create(Alarm alarm);
  Future<Alarm> update(Alarm alarm);
  Future<void> delete(String id);
  Future<Alarm?> getById(String id);
}
