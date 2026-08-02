import 'package:go_router/go_router.dart';
import 'package:loop/app/router/app_routes.dart';
import 'package:loop/features/onboarding/presentation/pages/onboarding_page.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.onboarding,
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) {
        return OnboardingPage(
          onComplete: () {
            context.go(AppRoutes.onboarding);
          },
        );
      },
    ),
  ],
);
