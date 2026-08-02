import 'package:flutter/material.dart';
import 'package:loop/features/alarm/application/alarm_editor_controller.dart';
import 'package:loop/features/alarm/presentation/widgets/alarm_editor.dart';

class OnboardingAlarm extends StatelessWidget {
  const OnboardingAlarm({
    required this.controller,
    super.key,
  });

  final AlarmEditorController controller;

  @override
  Widget build(BuildContext context) {
    return AlarmEditor(controller: controller);
  }
}