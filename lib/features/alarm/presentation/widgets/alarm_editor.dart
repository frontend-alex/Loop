import 'package:flutter/material.dart';
import 'package:loop/features/alarm/core/alarm.dart';
import 'package:loop/features/shared/presentation/widgets/cupertino_time_picker.dart';

class AlarmEditor extends StatefulWidget {
  const AlarmEditor({required this.initialAlarm, this.onChanged, super.key});

  final Alarm initialAlarm;
  final ValueChanged<Alarm>? onChanged;

  @override
  State<AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends State<AlarmEditor> {
  late Alarm _alarm;

  @override
  void initState() {
    super.initState();
    _alarm = widget.initialAlarm;
  }

  void _update(Alarm alarm) {
    setState(() {
      _alarm = alarm;
    });

    widget.onChanged?.call(alarm);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set your Loop alarm',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('Choose when Loop should help you start your morning.'),
          const SizedBox(height: 32),
          CupertinoTimePicker(
            time: _alarm.time,
            onChanged: (time) {
              _update(_alarm.copyWith(time: time));
            },
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Repeat alarm'),
            value: _alarm.repeats,
            onChanged: (repeats) {
              _update(_alarm.copyWith(repeats: repeats));
            },
          ),
        ],
      ),
    );
  }
}
