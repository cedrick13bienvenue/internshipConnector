import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../startups/data/models/startup_model.dart';
import '../../../startups/data/repositories/startup_repository.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sign out',
              onPressed: () => context.read<AuthCubit>().signOut(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'All Startups'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingTab(),
            _AllStartupsTab(),
          ],
        ),
      ),
    );
  }
}

class _PendingTab extends StatelessWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StartupModel>>(
      stream: StartupRepository().watchPending(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final startups = snapshot.data ?? [];
        if (startups.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 56, color: AppColors.success),
                SizedBox(height: 12),
                Text(
                  'No pending startups to review.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: startups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _StartupAdminCard(
            startup: startups[i],
            showActions: true,
          ),
        );
      },
    );
  }
}

class _AllStartupsTab extends StatelessWidget {
  const _AllStartupsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StartupModel>>(
      stream: StartupRepository().watchAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final startups = snapshot.data ?? [];
        if (startups.isEmpty) {
          return const Center(
            child: Text(
              'No startups registered yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: startups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _StartupAdminCard(
            startup: startups[i],
            showActions: startups[i].verificationStatus == StartupVerificationStatus.pending,
          ),
        );
      },
    );
  }
}

class _StartupAdminCard extends StatelessWidget {
  final StartupModel startup;
  final bool showActions;
  const _StartupAdminCard({required this.startup, required this.showActions});

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _verify(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verify Startup'),
        content: Text(
          'Verify "${startup.name}"? It will become visible to all students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await StartupRepository().updateVerification(
        startup.id,
        StartupVerificationStatus.verified,
      );
      if (context.mounted) {
        AppToast.showSuccess(context, '${startup.name} has been verified.');
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Startup'),
        content: Text('Reject "${startup.name}"? This action can be reversed later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await StartupRepository().updateVerification(
        startup.id,
        StartupVerificationStatus.rejected,
      );
      if (context.mounted) {
        AppToast.showError(context, '${startup.name} has been rejected.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (startup.verificationStatus) {
      StartupVerificationStatus.verified => ('Verified', AppColors.success),
      StartupVerificationStatus.rejected => ('Rejected', AppColors.error),
      StartupVerificationStatus.pending => ('Pending', AppColors.warning),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: startup.logoUrl != null
                      ? NetworkImage(startup.logoUrl!)
                      : null,
                  child: startup.logoUrl == null
                      ? Text(
                          startup.name.isNotEmpty
                              ? startup.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(startup.name, style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        'Registered ${_formatDate(startup.createdAt)}',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              startup.description,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (startup.categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: startup.categories
                    .map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            c,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
            if (startup.websiteUrl != null && startup.websiteUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.language_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      startup.websiteUrl!,
                      style: const TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(context),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _verify(context),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
