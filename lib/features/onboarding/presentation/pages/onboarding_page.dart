import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loop/features/alarm/core/alarm.dart';
import 'package:loop/features/alarm/data/alarm_bridge.dart';
import 'package:loop/features/alarm/data/alarm_repository.dart';
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
  late Alarm _alarm;
  late final AlarmBridge _alarmBridge;
  late final AlarmRepository _alarmRepository;
  late final PageController _pageController;
  late final OnboardingController _onboardingController;

  @override
  void initState() {
    super.initState();

    _alarm = Alarm.initial(id: '00000000-0000-0000-0000-000000000001');
    _alarmBridge = AlarmBridge();
    _alarmRepository = AlarmRepository();
    _pageController = PageController();
    _onboardingController = OnboardingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _onboardingController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_onboardingController.canContinue) {
      return;
    }

    if (_onboardingController.currentStep == OnboardingStep.alarm) {
      try {
        await _alarmRepository.update(_alarm);

        final authorized = await _alarmBridge.requestAuthorization();

        if (!authorized) {
          throw StateError('Alarm permission was not granted.');
        }

        await _alarmBridge.schedule(_alarm);
        
      } on PlatformException catch (error) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to set alarm.')),
        );

        return;
        
      } on StateError catch (error) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
        return;
      }
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
      OnboardingStep.alarm => OnboardingAlarm(
        alarm: _alarm,
        onChanged: (alarm) {
          _alarm = alarm;
        },
      ),

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
