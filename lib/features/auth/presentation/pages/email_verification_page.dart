import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../cubit/auth_cubit.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  Timer? _pollTimer;
  bool _resentEmail = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      context.read<AuthCubit>().checkEmailVerification();
    });
  }

  void _resendEmail() async {
    await context.read<AuthCubit>().resendVerificationEmail();
    setState(() {
      _resentEmail = true;
      _resendCooldown = 30;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  void _startOver() {
    context.read<AuthCubit>().signOut();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String get _userEmail {
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) return state.user.email;
    return 'your email';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && state.user.isEmailVerified) {
          context.go(
            state.user.isOnboarded ? AppRoutes.home : AppRoutes.onboarding,
          );
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              _buildIllustration(),
              const SizedBox(height: 40),
              _buildContent(),
              const SizedBox(height: 48),
              _buildActions(),
              const Spacer(),
              _buildStartOver(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildIllustration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(36),
      ),
      child: const Icon(
        Icons.mark_email_unread_rounded,
        size: 64,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Text(
          'Verify your email',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a verification link to',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _userEmail,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Click the link in the email to activate your account. This page will update automatically.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (_resentEmail) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                const Text('Verification email resent!',
                    style: TextStyle(color: AppColors.success, fontSize: 13)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    final canResend = _resendCooldown == 0;
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text("Didn't receive it?",
                  style: TextStyle(color: AppColors.textHint, fontSize: 13)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: canResend ? _resendEmail : null,
          child: Text(
            canResend ? 'Resend Email' : 'Resend in ${_resendCooldown}s',
          ),
        ),
        const SizedBox(height: 12),
        const _PollingIndicator(),
      ],
    );
  }

  Widget _buildStartOver() {
    return GestureDetector(
      onTap: _startOver,
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          text: 'Wrong email? ',
          style: TextStyle(color: AppColors.textHint, fontSize: 13),
          children: [
            TextSpan(
              text: 'Start over',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollingIndicator extends StatefulWidget {
  const _PollingIndicator();

  @override
  State<_PollingIndicator> createState() => _PollingIndicatorState();
}

class _PollingIndicatorState extends State<_PollingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Waiting for verification...',
          style: TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
      ],
    );
  }
}
