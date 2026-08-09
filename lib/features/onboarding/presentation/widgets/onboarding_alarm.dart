import 'package:flutter/material.dart';
import 'package:loop/features/alarm/core/alarm.dart';
import 'package:loop/features/alarm/presentation/widgets/alarm_editor.dart';

class OnboardingAlarm extends StatelessWidget {
  const OnboardingAlarm({
    required this.alarm,
    required this.onChanged,
    super.key,
  });

  final Alarm alarm;
  final ValueChanged<Alarm> onChanged;

  @override
  Widget build(BuildContext context) {
    return AlarmEditor(
      initialAlarm: alarm,
      onChanged: onChanged,
    );
  }
}
