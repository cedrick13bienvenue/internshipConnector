import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/application_model.dart';
import '../cubit/application_cubit.dart';

class ApplicationsTabPage extends StatefulWidget {
  const ApplicationsTabPage({super.key});

  @override
  State<ApplicationsTabPage> createState() => _ApplicationsTabPageState();
}

class _ApplicationsTabPageState extends State<ApplicationsTabPage> {
  ApplicationStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated && authState.user.role == UserRole.student) {
      context.read<ApplicationCubit>().watchMyApplications(authState.user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final isStudent =
        authState is AuthAuthenticated && authState.user.role == UserRole.student;

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: !isStudent
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, size: 48, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text(
                    'This section is for student accounts.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : BlocBuilder<ApplicationCubit, ApplicationState>(
              builder: (context, state) {
                if (state is ApplicationLoading || state is ApplicationInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ApplicationError) {
                  return Center(child: Text(state.message));
                }

                final loaded = state as ApplicationLoaded;
                final displayed = _filterStatus == null
                    ? loaded.applications
                    : loaded.applications
                        .where((a) => a.status == _filterStatus)
                        .toList();

                return Column(
                  children: [
                    SizedBox(
                      height: 56,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterChip(
                            label: 'All',
                            isSelected: _filterStatus == null,
                            onTap: () => setState(() => _filterStatus = null),
                          ),
                          const SizedBox(width: 8),
                          ...ApplicationStatus.values.map((s) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _FilterChip(
                                  label: _statusLabel(s),
                                  isSelected: _filterStatus == s,
                                  onTap: () => setState(() => _filterStatus = s),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: displayed.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.assignment_outlined,
                                    size: 56,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _filterStatus == null
                                        ? "You haven't applied to anything yet."
                                        : 'No applications with this status.',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: displayed.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) =>
                                  _ApplicationCard(application: displayed[i]),
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

String _statusLabel(ApplicationStatus s) => switch (s) {
      ApplicationStatus.applied => 'Applied',
      ApplicationStatus.underReview => 'Under Review',
      ApplicationStatus.shortlisted => 'Shortlisted',
      ApplicationStatus.interview => 'Interview',
      ApplicationStatus.accepted => 'Accepted',
      ApplicationStatus.rejected => 'Rejected',
      ApplicationStatus.closed => 'Closed',
    };

Color _statusColor(ApplicationStatus s) => switch (s) {
      ApplicationStatus.applied => AppColors.info,
      ApplicationStatus.underReview => AppColors.warning,
      ApplicationStatus.shortlisted => AppColors.primary,
      ApplicationStatus.interview => const Color(0xFF8B5CF6),
      ApplicationStatus.accepted => AppColors.success,
      ApplicationStatus.rejected => AppColors.error,
      ApplicationStatus.closed => AppColors.textHint,
    };

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  const _ApplicationCard({required this.application});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(application.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: application.startupLogoUrl != null
                  ? NetworkImage(application.startupLogoUrl!)
                  : null,
              child: application.startupLogoUrl == null
                  ? const Icon(Icons.business_rounded, color: AppColors.primary, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.opportunityTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    application.startupName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusLabel(application.status),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(application.appliedAt),
                        style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
