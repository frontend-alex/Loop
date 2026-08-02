import 'package:loop/features/onboarding/core/onboarding_question.dart';
import 'package:loop/features/onboarding/core/onboarding_step.dart';

abstract final class OnboardingQuestions {
  static const baseline = <OnboardingQuestion>[
    OnboardingQuestion(
      step: OnboardingStep.wakeTime,
      type: OnboardingQuestionType.time,
      title: 'What time do you usually wake up?',
      description: 'This helps Loop personalize your alarm defaults.',
    ),

    OnboardingQuestion(
      step: OnboardingStep.getOutOfBed,
      type: OnboardingQuestionType.select,
      title: 'How hard is it to get out of bed after your alarm?',
      description: 'This helps Loop choose your first task difficulty.',
      options: [
        OnboardingOptions(value: 'very_easy', label: 'Very easy'),
        OnboardingOptions(value: 'somewhat_easy', label: 'Somewhat easy'),
        OnboardingOptions(value: 'somewhat_hard', label: 'Somewhat hard'),
        OnboardingOptions(value: 'very_hard', label: 'Very hard'),
      ],
    ),

    OnboardingQuestion(
      step: OnboardingStep.firstPhoneCheck,
      type: OnboardingQuestionType.select,
      title: 'How soon after waking do you check your phone?',
      description: 'This helps Loop understand your critical morning window.',
      options: [
        OnboardingOptions(value: 'immediately', label: 'Immediately'),
        OnboardingOptions(value: 'within_5_minutes', label: 'Within 5 minutes'),
        OnboardingOptions(
          value: 'within_15_minutes',
          label: 'Within 15 minutes',
        ),
        OnboardingOptions(
          value: 'within_30_minutes',
          label: 'Within 30 minutes',
        ),
        OnboardingOptions(value: 'after_30_minutes', label: 'After 30 minutes'),
      ],
    ),

    OnboardingQuestion(
      step: OnboardingStep.autopilot,
      type: OnboardingQuestionType.select,
      title: 'How often do you open distracting apps without thinking?',
      description: 'This helps Loop understand your automatic phone behavior.',
      options: [
        OnboardingOptions(value: 'never', label: 'Never'),
        OnboardingOptions(value: 'rarely', label: 'Rarely'),
        OnboardingOptions(value: 'sometimes', label: 'Sometimes'),
        OnboardingOptions(value: 'often', label: 'Often'),
        OnboardingOptions(value: 'almost_always', label: 'Almost always'),
      ],
    ),

    OnboardingQuestion(
      step: OnboardingStep.commitment,
      type: OnboardingQuestionType.select,
      title: 'How badly do you want to change this?',
      description: 'Be honest. There is no wrong answer.',
      options: [
        OnboardingOptions(value: '1', label: 'Not much yet'),
        OnboardingOptions(value: '2', label: 'A little'),
        OnboardingOptions(value: '3', label: 'Somewhat'),
        OnboardingOptions(value: '4', label: 'A lot'),
        OnboardingOptions(value: '5', label: 'I am fully committed'),
      ],
    ),
  ];
}
