import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/main_shell_page.dart';
import '../../features/opportunities/presentation/pages/opportunity_detail_page.dart';
import '../../features/opportunities/presentation/pages/post_opportunity_page.dart';
import '../../features/applications/presentation/pages/application_form_page.dart';
import '../../features/startups/presentation/pages/startup_profile_page.dart';
import '../../features/startups/presentation/pages/startup_registration_page.dart';
import '../../features/startups/presentation/pages/edit_startup_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/profile/presentation/pages/edit_student_profile_page.dart';
import '../../features/opportunities/presentation/pages/edit_opportunity_page.dart';
import '../../features/opportunities/data/models/opportunity_model.dart';
import '../../features/applications/data/models/application_model.dart';
import '../../features/applications/presentation/pages/applicant_detail_page.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const admin = '/admin';
  static const opportunityDetail = '/opportunity/:id';
  static const postOpportunity = '/post-opportunity';
  static const applicationForm = '/apply/:opportunityId';
  static const startupProfile = '/startup/:id';
  static const startupRegistration = '/startup/register';
}

class _RouterRefreshStream extends ChangeNotifier {
  _RouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter buildRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _RouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final loc = state.matchedLocation;
      final isOnAuthPage = loc == AppRoutes.login ||
          loc == AppRoutes.signup ||
          loc == AppRoutes.forgotPassword;

      if (authState is AuthInitial) return null;

      if (authState is AuthAuthenticated) {
        final isAdmin = authState.user.role == UserRole.admin;
        if (!isAdmin && !authState.user.isEmailVerified) {
          if (loc == AppRoutes.verifyEmail) return null;
          return AppRoutes.verifyEmail;
        }
        if (!isAdmin && !authState.user.isOnboarded) return AppRoutes.onboarding;
        if (isAdmin) {
          if (loc.startsWith(AppRoutes.admin)) return null;
          return AppRoutes.admin;
        }
        if (isOnAuthPage || loc == AppRoutes.splash || loc == AppRoutes.onboarding) return AppRoutes.home;
      } else if (authState is AuthUnauthenticated) {
        if (loc == AppRoutes.splash) return null;
        if (!isOnAuthPage) return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupPage()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordPage()),
      GoRoute(path: AppRoutes.verifyEmail, builder: (_, __) => const EmailVerificationPage()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingPage()),
      GoRoute(path: AppRoutes.admin, builder: (_, __) => const AdminDashboardPage()),
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
          GoRoute(path: 'edit-profile', builder: (_, __) => const EditStudentProfilePage()),
          GoRoute(path: 'edit-startup', builder: (_, __) => const EditStartupPage()),
          GoRoute(
            path: 'applicant/:id',
            builder: (_, state) => ApplicantDetailPage(
              application: state.extra as ApplicationModel,
            ),
          ),
          GoRoute(
            path: 'edit-opportunity/:id',
            builder: (_, state) => EditOpportunityPage(
              opportunity: state.extra as OpportunityModel,
            ),
          ),
        ],
      ),
    ],
  );
}
