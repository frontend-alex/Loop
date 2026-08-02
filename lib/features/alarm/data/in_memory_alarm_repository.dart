import 'package:loop/features/alarm/core/alarm.dart';
import 'package:loop/features/alarm/data/alarm_repository.dart';

class InMemoryAlarmRepository implements AlarmRepository {
  final Map<String, Alarm> _alarms = {};

  @override
  Future<List<Alarm>> getAll() async {
    return List.unmodifiable(_alarms.values);
  }

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
}