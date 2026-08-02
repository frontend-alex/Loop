import 'package:flutter/material.dart';
import 'package:loop/features/alarm/core/alarm_day.dart';

class AlarmDraft {
  const AlarmDraft({
    this.time = const TimeOfDay(hour: 7, minute: 0),
    this.repeatDays = const {
      AlarmDay.monday,
      AlarmDay.tuesday,
      AlarmDay.wednesday,
      AlarmDay.thursday,
      AlarmDay.friday,
    },
    this.enabled = true,
    this.label = 'Loop alarm',
  });

  final TimeOfDay time;
  final Set<AlarmDay> repeatDays;
  final bool enabled;
  final String label;

  bool get isValid {
    return repeatDays.isNotEmpty && label.trim().isNotEmpty;
  }

  AlarmDraft copyWith({
    TimeOfDay? time,
    Set<AlarmDay>? repeatDays,
    bool? enabled,
    String? label,
  }) {
    return AlarmDraft(
      time: time ?? this.time,
      repeatDays: repeatDays ?? this.repeatDays,
      enabled: enabled ?? this.enabled,
      label: label ?? this.label,
    );
  }

  Alarm toAlarm({required String id}) {
    return Alarm(
      id: id,
      time: time,
      repeatDays: Set.unmodifiable(repeatDays),
      enabled: enabled,
      label: label.trim(),
    );
  }
}

class Alarm {
  const Alarm({
    required this.id,
    required this.time,
    required this.repeatDays,
    required this.enabled,
    required this.label,
  });

  final String id;
  final TimeOfDay time;
  final Set<AlarmDay> repeatDays;
  final bool enabled;
  final String label;

  AlarmDraft toDraft() {
    return AlarmDraft(
      time: time,
      repeatDays: Set.unmodifiable(repeatDays),
      enabled: enabled,
      label: label,
    );
  }
}