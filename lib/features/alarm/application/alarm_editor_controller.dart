import 'package:flutter/material.dart';
import 'package:loop/features/alarm/core/alarm.dart';
import 'package:loop/features/alarm/core/alarm_day.dart';

class AlarmEditorController extends ChangeNotifier {
  AlarmEditorController({
    AlarmDraft initialDraft = const AlarmDraft(),
  }) : _draft = initialDraft;

  AlarmDraft _draft;

  AlarmDraft get draft => _draft;

  void setTime(TimeOfDay time) {
    _update(_draft.copyWith(time: time));
  }

  void toggleDay(AlarmDay day) {
    final nextDays = Set<AlarmDay>.from(_draft.repeatDays);

    if (!nextDays.add(day)) {
      nextDays.remove(day);
    }

    _update(_draft.copyWith(repeatDays: nextDays));
  }

  void setEnabled(bool enabled) {
    _update(_draft.copyWith(enabled: enabled));
  }

  void setLabel(String label) {
    _update(_draft.copyWith(label: label));
  }

  void _update(AlarmDraft nextDraft) {
    _draft = nextDraft;
    notifyListeners();
  }
}