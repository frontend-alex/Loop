import 'package:awesome_datetime_picker/awesome_datetime_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loop/features/onboarding/core/onboarding_question.dart';

class OnboardingQuestionRenderer extends StatelessWidget {
  const OnboardingQuestionRenderer({
    required this.question,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final OnboardingQuestion question;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            question.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          if (question.description != null) ...[
            const SizedBox(height: 8),
            Text(question.description!),
          ],

          const SizedBox(height: 24),

          _buildInput(context),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    switch (question.type) {
      case OnboardingQuestionType.input:
        return TextFormField(
          initialValue: value is String ? value as String : '',
          decoration: InputDecoration(hintText: question.placeholder),
          onChanged: (text) {
            onChanged(text);
          },
        );

      case OnboardingQuestionType.time:
        final initialTime = AwesomeTime(hour: 7, minute: 0);

        return SizedBox(
          child: CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hm,
            initialTimerDuration: Duration(
              hours: initialTime.hour,
              minutes: initialTime.minute,
            ),
            onTimerDurationChanged: (duration) {
              final time = AwesomeTime(
                hour: duration.inHours,
                minute: duration.inMinutes % 60,
              );

              onChanged('${time.hour}:${time.minute}');
            },
          ),
        );

      case OnboardingQuestionType.select:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: question.options.map((option) {
            return ChoiceChip(
              label: Text(option.label),
              selected: value == option.value,
              onSelected: (_) {
                onChanged(option.value);
              },
            );
          }).toList(),
        );

      case OnboardingQuestionType.mutliSelect:
        final selectedValues = value is Set<String>
            ? Set<String>.from(value as Set<String>)
            : <String>{};

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: question.options.map((option) {
            return FilterChip(
              label: Text(option.label),
              selected: selectedValues.contains(option.value),
              onSelected: (_) {
                final nextValues = Set<String>.from(selectedValues);

                if (!nextValues.add(option.value)) {
                  nextValues.remove(option.value);
                }

                onChanged(nextValues);
              },
            );
          }).toList(),
        );
    }
  }
}
