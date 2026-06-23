import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/main_shell_page.dart';
import '../../features/opportunities/presentation/pages/opportunity_detail_page.dart';
import '../../features/opportunities/presentation/pages/post_opportunity_page.dart';
import '../../features/applications/presentation/pages/application_form_page.dart';
import '../../features/startups/presentation/pages/startup_profile_page.dart';
import '../../features/startups/presentation/pages/startup_registration_page.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const opportunityDetail = '/opportunity/:id';
  static const postOpportunity = '/post-opportunity';
  static const applicationForm = '/apply/:opportunityId';
  static const startupProfile = '/startup/:id';
  static const startupRegistration = '/startup/register';
}

GoRouter buildRouter(BuildContext context) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final authState = context.read<AuthCubit>().state;
      final isOnAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      if (authState is AuthAuthenticated) {
        if (!authState.user.isOnboarded) return AppRoutes.onboarding;
        if (isOnAuthPage || state.matchedLocation == AppRoutes.splash) {
          return AppRoutes.home;
        }
      } else if (authState is AuthUnauthenticated) {
        if (!isOnAuthPage && state.matchedLocation != AppRoutes.splash) {
          return AppRoutes.login;
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupPage()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingPage()),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const MainShellPage(),
        routes: [
          GoRoute(
            path: 'opportunity/:id',
            builder: (_, state) => OpportunityDetailPage(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'apply/:opportunityId',
            builder: (_, state) => ApplicationFormPage(
              opportunityId: state.pathParameters['opportunityId']!,
            ),
          ),
          GoRoute(
            path: 'startup/:id',
            builder: (_, state) => StartupProfilePage(id: state.pathParameters['id']!),
          ),
          GoRoute(path: 'post-opportunity', builder: (_, __) => const PostOpportunityPage()),
          GoRoute(path: 'startup/register', builder: (_, __) => const StartupRegistrationPage()),
        ],
      ),
    ],
  );
}
