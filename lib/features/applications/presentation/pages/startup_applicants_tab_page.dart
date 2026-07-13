import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/application_repository.dart';
import '../../../startups/presentation/cubit/startup_cubit.dart';
import 'opportunity_applicants_page.dart';

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
                      Text('No applications yet.',
                          style: TextStyle(color: AppColors.textSecondary)),
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

              // Group by opportunityId
              final grouped = <String, List<ApplicationModel>>{};
              for (final app in applications) {
                grouped.putIfAbsent(app.opportunityId, () => []).add(app);
              }
              final entries = grouped.entries.toList();

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  final apps = entry.value;
                  final title = apps.first.opportunityTitle;
                  final starredCount = apps.where((a) => a.isStarred).length;

                  return _OpportunityGroupCard(
                    title: title,
                    totalCount: apps.length,
                    starredCount: starredCount,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OpportunityApplicantsPage(
                          opportunityId: entry.key,
                          opportunityTitle: title,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OpportunityGroupCard extends StatelessWidget {
  final String title;
  final int totalCount;
  final int starredCount;
  final VoidCallback onTap;

  const _OpportunityGroupCard({
    required this.title,
    required this.totalCount,
    required this.starredCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work_outline_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _badge(
                          icon: Icons.people_rounded,
                          label: '$totalCount applicant${totalCount == 1 ? '' : 's'}',
                          color: AppColors.primary,
                        ),
                        if (starredCount > 0) ...[
                          const SizedBox(width: 8),
                          _badge(
                            icon: Icons.star_rounded,
                            label: '$starredCount starred',
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
