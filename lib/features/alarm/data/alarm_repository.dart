import 'package:loop/features/alarm/core/alarm.dart';
import 'package:loop/features/alarm/data/interfaces/alarm_interface.dart';

final class AlarmRepository implements AlarmInterface {
  final Map<String, Alarm> _alarms = {};

  @override
  Future<Alarm> create(Alarm alarm) async {
    _alarms[alarm.id] = alarm;
    return alarm;
  }

  @override
  Future<Alarm> update(Alarm alarm) async {
    _alarms[alarm.id] = alarm;
    return alarm;
  }

  @override
  Future<void> delete(String id) async {
    _alarms.remove(id);
  }

  @override
  Future<Alarm?> getById(String id) async {
    return _alarms[id];
  }
}
