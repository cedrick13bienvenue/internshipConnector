import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/startup_model.dart';
import '../../data/repositories/startup_repository.dart';
import '../../../opportunities/data/models/opportunity_model.dart';
import '../../../opportunities/data/repositories/opportunity_repository.dart';
import '../../../opportunities/presentation/widgets/opportunity_card.dart';

class StartupProfilePage extends StatelessWidget {
  final String id;
  const StartupProfilePage({super.key, required this.id});

  Future<(StartupModel, List<OpportunityModel>)> _loadData() async {
    final startup = await StartupRepository().getById(id);
    final opportunities = await OpportunityRepository().getByStartup(id);
    return (startup, opportunities);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(StartupModel, List<OpportunityModel>)>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(snapshot.error?.toString() ?? 'Startup not found.'),
            ),
          );
        }
        final (startup, opportunities) = snapshot.data!;
        return _StartupProfileView(startup: startup, opportunities: opportunities);
      },
    );
  }
}

class _StartupProfileView extends StatelessWidget {
  final StartupModel startup;
  final List<OpportunityModel> opportunities;
  const _StartupProfileView({required this.startup, required this.opportunities});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: startup.logoUrl != null
                              ? NetworkImage(startup.logoUrl!)
                              : null,
                          child: startup.logoUrl == null
                              ? Text(
                                  startup.name.isNotEmpty
                                      ? startup.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
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
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      startup.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (startup.isVerified) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                startup.isVerified ? 'Verified startup' : 'Pending verification',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: startup.categories
                          .map((c) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  c,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(startup.description, style: Theme.of(context).textTheme.bodyMedium),
                  if (startup.websiteUrl != null && startup.websiteUrl!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.language_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            startup.websiteUrl!,
                            style: const TextStyle(color: AppColors.primary, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        'Open Opportunities',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${opportunities.length}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (opportunities.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No open opportunities at the moment.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              sliver: SliverList.builder(
                itemCount: opportunities.length,
                itemBuilder: (context, i) => OpportunityCard(
                  opportunity: opportunities[i],
                  onTap: () => context.push('/home/opportunity/${opportunities[i].id}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
