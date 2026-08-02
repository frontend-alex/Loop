import 'package:flutter/material.dart';
import 'package:loop/features/alarm/application/alarm_editor_controller.dart';
import 'package:loop/features/alarm/core/alarm_day.dart';
import 'package:loop/features/shared/presentation/widgets/cupertino_time_picker.dart';

class AlarmEditor extends StatelessWidget {
  const AlarmEditor({required this.controller, super.key});

  final AlarmEditorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final draft = controller.draft;

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
              const Text(
                'Choose when Loop should help you start your morning.',
              ),
              const SizedBox(height: 32),
              CupertinoTimePicker(
                time: draft.time,
                onChanged: controller.setTime,
              ),
              const SizedBox(height: 32),
              Text('Repeat', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _RepeatDays(
                selectedDays: draft.repeatDays,
                onDaySelected: controller.toggleDay,
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Alarm enabled'),
                value: draft.enabled,
                onChanged: controller.setEnabled,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.time, required this.onChanged});

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  Future<void> _selectTime(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: time,
    );

    if (selectedTime != null) {
      onChanged(selectedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () => _selectTime(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          time.format(context),
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ),
    );
  }
}

class _RepeatDays extends StatelessWidget {
  const _RepeatDays({required this.selectedDays, required this.onDaySelected});

  final Set<AlarmDay> selectedDays;
  final ValueChanged<AlarmDay> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AlarmDay.values.map((day) {
        return ChoiceChip(
          label: Text(day.shortLabel),
          tooltip: day.fullLabel,
          selected: selectedDays.contains(day),
          onSelected: (_) => onDaySelected(day),
        );
      }).toList(),
    );
  }
}
