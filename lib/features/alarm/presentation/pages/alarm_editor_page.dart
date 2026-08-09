import 'package:flutter/material.dart';
import 'package:loop/features/alarm/core/alarm.dart';
import 'package:loop/features/alarm/presentation/widgets/alarm_editor.dart';

class AlarmEditorPage extends StatefulWidget {
  const AlarmEditorPage({
    required this.initialAlarm,
    required this.onSave,
    super.key,
  });

  final Alarm initialAlarm;
  final Future<void> Function(Alarm alarm) onSave;

  @override
  State<AlarmEditorPage> createState() => _AlarmEditorPageState();
}

class _AlarmEditorPageState extends State<AlarmEditorPage> {
  late Alarm _alarm;

  @override
  void initState() {
    super.initState();
    _alarm = widget.initialAlarm;
  }

  Future<void> _save() async {
    await widget.onSave(_alarm);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarm')),
      body: AlarmEditor(
        initialAlarm: _alarm,
        onChanged: (alarm) {
          _alarm = alarm;
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _alarm.isValid ? _save : null,
            child: const Text('Save alarm'),
          ),
        ),
      ),
    );
  }
}
