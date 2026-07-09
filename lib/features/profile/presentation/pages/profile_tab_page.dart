import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../startups/presentation/cubit/startup_cubit.dart';

class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({super.key});

  String _roleLabel(UserRole role) => switch (role) {
        UserRole.student => 'Student',
        UserRole.startup => 'Startup',
        UserRole.admin => 'Admin',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/home/edit-profile'),
            tooltip: 'Edit profile',
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) return const SizedBox.shrink();
          final user = state.user;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primaryLight,
                  child: user.photoUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user.photoUrl!,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.fullName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Center(child: Chip(label: Text(_roleLabel(user.role)))),
              if (user.role == UserRole.student) ...[
                if (user.program != null) ...[
                  const SizedBox(height: 20),
                  _InfoRow(label: 'Program', value: user.program!),
                ],
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Bio', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(user.bio!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (user.skills.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Skills', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.skills.map((s) => Chip(label: Text(s))).toList(),
                  ),
                ],
              ],
              if (user.role == UserRole.startup) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                BlocBuilder<StartupCubit, StartupState>(
                  builder: (context, startupState) {
                    if (startupState is! StartupOwnerLoaded || startupState.startup == null) {
                      return const SizedBox.shrink();
                    }
                    final startup = startupState.startup!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Your Startup',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => context.push('/home/edit-startup'),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                startup.name.isNotEmpty ? startup.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    startup.name,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        startup.isVerified
                                            ? Icons.verified_rounded
                                            : Icons.hourglass_top_rounded,
                                        size: 14,
                                        color: startup.isVerified
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        startup.isVerified
                                            ? 'Verified'
                                            : 'Pending verification',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: startup.isVerified
                                              ? AppColors.success
                                              : AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (startup.categories.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: startup.categories
                                .map((c) => Chip(
                                      label: Text(c, style: const TextStyle(fontSize: 11)),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ))
                                .toList(),
                          ),
                        ],
                        if (startup.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            startup.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () => context.read<AuthCubit>().signOut(),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Sign Out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
