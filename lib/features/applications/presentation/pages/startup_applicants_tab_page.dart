import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/application_repository.dart';
import '../../../startups/presentation/cubit/startup_cubit.dart';

class StartupApplicantsTabPage extends StatelessWidget {
  const StartupApplicantsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applicants')),
      body: BlocBuilder<StartupCubit, StartupState>(
        builder: (context, state) {
          if (state is StartupLoading || state is StartupInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StartupError) {
            return Center(child: Text(state.message));
          }
          final startup = (state as StartupOwnerLoaded).startup;
          if (startup == null) {
            return const Center(
              child: Text(
                'Register your startup first to see applicants.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            );
          }
          return StreamBuilder<List<ApplicationModel>>(
            stream: ApplicationRepository().watchByStartup(startup.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              final applications = snapshot.data ?? [];
              if (applications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text(
                        'No applications yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Applications will appear here once students apply.',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: applications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _ApplicantCard(application: applications[i]),
              );
            },
          );
        },
      ),
    );
  }
}

Color _statusColor(ApplicationStatus s) => switch (s) {
      ApplicationStatus.applied => AppColors.info,
      ApplicationStatus.underReview => AppColors.warning,
      ApplicationStatus.shortlisted => AppColors.primary,
      ApplicationStatus.interview => const Color(0xFF8B5CF6),
      ApplicationStatus.accepted => AppColors.success,
      ApplicationStatus.rejected => AppColors.error,
      ApplicationStatus.closed => AppColors.textHint,
    };

String _statusLabel(ApplicationStatus s) => switch (s) {
      ApplicationStatus.applied => 'Applied',
      ApplicationStatus.underReview => 'Under Review',
      ApplicationStatus.shortlisted => 'Shortlisted',
      ApplicationStatus.interview => 'Interview',
      ApplicationStatus.accepted => 'Accepted',
      ApplicationStatus.rejected => 'Rejected',
      ApplicationStatus.closed => 'Closed',
    };

class _ApplicantCard extends StatelessWidget {
  final ApplicationModel application;
  const _ApplicantCard({required this.application});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    application.applicantName.isNotEmpty
                        ? application.applicantName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.applicantName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'for ${application.opportunityTitle}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  _timeAgo(application.appliedAt),
                  style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ),
            if (application.coverNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                application.coverNote,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }
}
