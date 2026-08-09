import 'package:flutter/material.dart';

class Alarm {
  const Alarm({
    required this.id,
    required this.time,
    required this.repeats,
    required this.label,
  });

  final String id;
  final TimeOfDay time;
  final bool repeats;
  final String label;

  static Alarm initial({required String id}) {
    return Alarm(
      id: id,
      time: const TimeOfDay(hour: 7, minute: 0),
      repeats: true,
      label: 'Loop alarm',
    );
  }

  bool get isValid {
    return label.trim().isNotEmpty;
  }

  Alarm copyWith({TimeOfDay? time, bool? repeats, String? label}) {
    return Alarm(
      id: id,
      time: time ?? this.time,
      repeats: repeats ?? this.repeats,
      label: label ?? this.label,
    );
  }
}
