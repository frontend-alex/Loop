import 'package:flutter/material.dart';
import 'package:loop/features/alarm/application/alarm_editor_controller.dart';
import 'package:loop/features/onboarding/application/onboarding_controller.dart';
import 'package:loop/features/onboarding/core/onboarding_step.dart';
import 'package:loop/features/onboarding/data/onboarding_questions.dart';
import 'package:loop/features/onboarding/presentation/widgets/onboarding_layout.dart';
import 'package:loop/features/onboarding/presentation/widgets/onboarding_question_renderer.dart';
import 'package:loop/features/onboarding/presentation/widgets/onboarding_alarm.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() {
    return _OnboardingPageState();
  }
}

class _OnboardingPageState extends State<OnboardingPage> {

  late final AlarmEditorController _alarmEditorController;
  late final PageController _pageController;
  late final OnboardingController _onboardingController;

  @override
  void initState() {
    super.initState();

    _alarmEditorController = AlarmEditorController();
    _pageController = PageController();
    _onboardingController = OnboardingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _onboardingController.dispose();
    _alarmEditorController.dispose();

    super.dispose();
  }

  Future<void> _continue() async {
    if (!_onboardingController.canContinue) {
      return;
    }

    final isLastStep =
        _onboardingController.currentIndex == OnboardingStep.values.length - 1;

    if (isLastStep) {
      widget.onComplete();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goBack() async {
    if (_onboardingController.currentIndex == 0) {
      return;
    }

    await _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _onboardingController,
      builder: (context, child) {
        return OnboardingLayout(
          progress: _onboardingController.progress,
          canContinue: _onboardingController.canContinue,
          onContinue: _continue,
          buttonLabel:
              _onboardingController.currentStep == OnboardingStep.confirmation
              ? 'Finish'
              : 'Continue',

          child: GestureDetector(
            behavior: HitTestBehavior.opaque,

            // A right swipe moves backward.
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;

              if (velocity > 250) {
                _goBack();
              }
            },

            child: PageView.builder(
              controller: _pageController,

              // Prevent forward swiping.
              physics: const NeverScrollableScrollPhysics(),

              itemCount: OnboardingStep.values.length,

              onPageChanged: (index) {
                _onboardingController.moveTo(index);
              },

              itemBuilder: (context, index) {
                return _buildStep(index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(int index) {
    if (index < OnboardingQuestions.baseline.length) {
      final question = OnboardingQuestions.baseline[index];

      return OnboardingQuestionRenderer(
        question: question,
        value: _onboardingController.answerFor(question.step),
        onChanged: (answer) {
          _onboardingController.setAnswer(question.step, answer);
        },
      );
    }

    final step = OnboardingStep.values[index];

    return switch (step) {
      OnboardingStep.alarm => OnboardingAlarm(controller: _alarmEditorController),

      OnboardingStep.distractingApps => const Center(
        child: Text('Select distracting apps'),
      ),

      OnboardingStep.wakeTask => const Center(
        child: Text('Select Wake-up Task'),
      ),

      OnboardingStep.confirmation => const Center(
        child: Text('Confirm commitment'),
      ),

      _ => const SizedBox.shrink(),
    };
  }
}
