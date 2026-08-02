import 'package:flutter/material.dart';

class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    required this.progress,
    required this.child,
    required this.canContinue,
    required this.onContinue,
    this.buttonLabel = 'Continue',
    super.key,
  });

  final double progress;
  final Widget child;
  final bool canContinue;
  final VoidCallback onContinue;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                value: progress,
              ),
            ),

            Expanded(
              child: child,
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: canContinue ? onContinue : null,
            child: Text(buttonLabel),
          ),
        ),
      ),
    );
  }
}