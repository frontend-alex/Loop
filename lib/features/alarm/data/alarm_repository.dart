import 'package:loop/features/alarm/core/alarm.dart';

abstract interface class AlarmRepository {
  Future<List<Alarm>> getAll();

  Future<Alarm> create(Alarm alarm);

  Future<Alarm> update(Alarm alarm);

  Future<void> delete(String id);
}