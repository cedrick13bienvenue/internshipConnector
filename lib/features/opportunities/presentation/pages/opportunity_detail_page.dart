import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/opportunity_model.dart';
import '../../data/repositories/opportunity_repository.dart';

class OpportunityDetailPage extends StatelessWidget {
  final String id;
  const OpportunityDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpportunityModel>(
      future: OpportunityRepository().getById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(snapshot.error?.toString() ?? 'Opportunity not found.'),
            ),
          );
        }

        final opp = snapshot.data!;
        final authState = context.read<AuthCubit>().state;
        final isStudent =
            authState is AuthAuthenticated && authState.user.role == UserRole.student;

        return Scaffold(
          appBar: AppBar(
            title: Text(opp.title, overflow: TextOverflow.ellipsis),
          ),
          body: ListView(
            children: [
              _Header(opp: opp),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetaRow(opp: opp),
                    const SizedBox(height: 24),
                    Text(
                      'About this opportunity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(opp.description, style: Theme.of(context).textTheme.bodyMedium),
                    if (opp.skillsRequired.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Skills required', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: opp.skillsRequired.map((s) => Chip(label: Text(s))).toList(),
                      ),
                    ],
                    const SizedBox(height: 32),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/home/startup/${opp.startupId}'),
                      icon: const Icon(Icons.storefront_rounded, size: 18),
                      label: Text('View ${opp.startupName}'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    if (isStudent) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.push('/home/apply/${opp.id}'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: const Text('Apply Now', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final OpportunityModel opp;
  const _Header({required this.opp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: opp.startupLogoUrl != null
                    ? NetworkImage(opp.startupLogoUrl!)
                    : null,
                child: opp.startupLogoUrl == null
                    ? Text(
                        opp.startupName.isNotEmpty ? opp.startupName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opp.startupName,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opp.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tag(opp.category),
              _tag(opp.commitment),
              _tag(opp.location),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final OpportunityModel opp;
  const _MetaRow({required this.opp});

  String get _postedAgo {
    final diff = DateTime.now().difference(opp.postedAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textHint),
            const SizedBox(width: 5),
            Text(
              '${opp.applicantsCount} applicants',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textHint),
            const SizedBox(width: 5),
            Text(
              _postedAgo,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        if (opp.deadline != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: 5),
              Text(
                'Deadline: ${_formatDate(opp.deadline!)}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
