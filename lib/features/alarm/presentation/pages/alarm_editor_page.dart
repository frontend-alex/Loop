import 'package:flutter/material.dart';
import 'package:loop/features/alarm/application/alarm_editor_controller.dart';
import 'package:loop/features/alarm/core/alarm.dart';
import 'package:loop/features/alarm/presentation/widgets/alarm_editor.dart';

class AlarmEditorPage extends StatelessWidget {
  const AlarmEditorPage({
    required this.controller,
    required this.onSave,
    super.key,
  });

  final AlarmEditorController controller;
  final Future<void> Function(AlarmDraft draft) onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm'),
      ),
      body: AlarmEditor(controller: controller),
      bottomNavigationBar: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: controller.draft.isValid
                    ? () => onSave(controller.draft)
                    : null,
                child: const Text('Save alarm'),
              ),
            ),
          );
        },
      ),
    );
  }
}