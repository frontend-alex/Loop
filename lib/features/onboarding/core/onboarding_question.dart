import 'package:loop/features/onboarding/core/onboarding_step.dart';

enum OnboardingQuestionType {
  input, 
  time,
  select,
  mutliSelect,
}

class OnboardingOptions {
  const OnboardingOptions({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class OnboardingQuestion {
  const OnboardingQuestion({
    required this.step,
    required this.type,
    required this.title,
    this.description,
    this.placeholder,
    this.options = const [],
    this.isRequired = true,
    this.minSelections = 1,
  });

  final OnboardingStep step;
  final OnboardingQuestionType type;

  final String title;
  final String? description;
  final String? placeholder;

  final List<OnboardingOptions> options;

  final bool isRequired;
  final int minSelections;
}
