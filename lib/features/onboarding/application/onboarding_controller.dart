import 'package:flutter/material.dart';
import 'package:loop/features/onboarding/core/onboarding_question.dart';
import 'package:loop/features/onboarding/core/onboarding_step.dart';
import 'package:loop/features/onboarding/data/onboarding_questions.dart';

class OnboardingController extends ChangeNotifier {
  final Map<OnboardingStep, Object?> _answers = {};

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  OnboardingStep get currentStep {
    return OnboardingStep.values[_currentIndex];
  }

  double get progress {
    return (_currentIndex + 1) / OnboardingStep.values.length;
  }

  Object? answerFor(OnboardingStep step) {
    return _answers[step];
  }

  Map<OnboardingStep, Object?> get answers {
    return Map.unmodifiable(_answers);
  }

  void setAnswer(OnboardingStep step, Object? answer) {
    _answers[step] = answer;

    notifyListeners();
  }

  void moveTo(int index) {
    if (index < 0 || index >= OnboardingStep.values.length) {
      return;
    }

    if (_currentIndex == index) {
      return;
    }

    _currentIndex = index;

    notifyListeners();
  }

  bool get canContinue {
    if (_currentIndex >= OnboardingQuestions.baseline.length) return true;

    final question = OnboardingQuestions.baseline[_currentIndex];
    final answer = _answers[question.step];

    if (!question.isRequired) return true;

    return switch (question.type) {
      OnboardingQuestionType.input =>
        answer is String && answer.trim().isNotEmpty,

      OnboardingQuestionType.time => answer is TimeOfDay,

      OnboardingQuestionType.select => answer is String && answer.isNotEmpty,

      OnboardingQuestionType.mutliSelect =>
        answer is Set<String> && answer.isNotEmpty,
    };
  }
}
