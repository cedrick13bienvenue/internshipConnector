import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../opportunities/presentation/cubit/opportunity_cubit.dart';
import '../../../opportunities/data/repositories/opportunity_repository.dart';
import '../../../opportunities/presentation/widgets/opportunity_card.dart';
import '../../../startups/presentation/cubit/startup_cubit.dart';

class HomeTabPage extends StatefulWidget {
  final VoidCallback onExploreTap;
  const HomeTabPage({super.key, required this.onExploreTap});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    if (authState.user.role == UserRole.startup) {
      context.read<StartupCubit>().loadMyStartup(authState.user.uid);
    } else {
      context.read<OpportunityCubit>().watchAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();
        return state.user.role == UserRole.startup
            ? _StartupHome(user: state.user)
            : _StudentHome(
                user: state.user,
                selectedCategory: _selectedCategory,
                onCategoryTap: _onCategoryTap,
                onExploreTap: widget.onExploreTap,
              );
      },
    );
  }

  void _onCategoryTap(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
        context.read<OpportunityCubit>().watchAll();
      } else {
        _selectedCategory = category;
        context.read<OpportunityCubit>().watchByCategory(category);
      }
    });
  }
}

class _StudentHome extends StatelessWidget {
  final UserModel user;
  final String? selectedCategory;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onExploreTap;

  const _StudentHome({
    required this.user,
    required this.selectedCategory,
    required this.onCategoryTap,
    required this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${user.fullName.split(' ').first} 👋',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Find your next opportunity',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: onExploreTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search_rounded, color: AppColors.textHint),
                          SizedBox(width: 10),
                          Text(
                            'Search opportunities...',
                            style: TextStyle(color: AppColors.textHint, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.opportunityCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final category = AppConstants.opportunityCategories[i];
                  final isSelected = category == selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => onCategoryTap(category),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.surface : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            sliver: SliverToBoxAdapter(
              child: Text('Latest Opportunities', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          BlocBuilder<OpportunityCubit, OpportunityState>(
            builder: (context, state) {
              if (state is OpportunityLoading || state is OpportunityInitial) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is OpportunityError) {
                return SliverFillRemaining(
                  child: Center(child: Text(state.message)),
                );
              }
              final opportunities = (state as OpportunityLoaded).displayed;
              if (opportunities.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No opportunities posted yet.')),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverList.builder(
                  itemCount: opportunities.length,
                  itemBuilder: (context, i) => OpportunityCard(
                    opportunity: opportunities[i],
                    onTap: () => context.push('/home/opportunity/${opportunities[i].id}'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StartupHome extends StatelessWidget {
  final UserModel user;
  const _StartupHome({required this.user});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocConsumer<StartupCubit, StartupState>(
        listener: (context, state) {
          if (state is StartupOwnerLoaded && state.startup != null) {
            context.read<OpportunityCubit>().watchMine(state.startup!.id);
          }
        },
        builder: (context, state) {
          if (state is StartupLoading || state is StartupInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StartupError) {
            return Center(child: Text(state.message));
          }
          final startup = (state as StartupOwnerLoaded).startup;
          if (startup == null) {
            return _NoStartupYet(user: user);
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(startup.name, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      if (!startup.isVerified)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Your startup is pending verification.',
                                  style: const TextStyle(color: AppColors.warning, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${startup.activeOpportunities}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Text(
                                    'Active Opportunities',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Tooltip(
                              message: startup.isVerified
                                  ? ''
                                  : 'Verification required to post',
                              child: ElevatedButton(
                                onPressed: startup.isVerified
                                    ? () => context.push('/home/post-opportunity')
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                ),
                                child: const Text('Post New'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Your Opportunities', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              BlocBuilder<OpportunityCubit, OpportunityState>(
                builder: (context, oppState) {
                  if (oppState is OpportunityLoading || oppState is OpportunityInitial) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (oppState is! OpportunityLoaded || oppState.opportunities.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('You haven\'t posted any opportunities yet.')),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    sliver: SliverList.builder(
                      itemCount: oppState.opportunities.length,
                      itemBuilder: (context, i) {
                        final opp = oppState.opportunities[i];
                        return OpportunityCard(
                          opportunity: opp,
                          onTap: () => context.push('/home/opportunity/${opp.id}'),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded,
                                size: 20, color: AppColors.textHint),
                            onSelected: (v) async {
                              if (v == 'edit') {
                                context.push('/home/edit-opportunity/${opp.id}', extra: opp);
                              } else if (v == 'close') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Close Opportunity'),
                                    content: const Text(
                                        'This stops new applications. Cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.error),
                                        child: const Text('Close It'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await OpportunityRepository().close(opp.id);
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_rounded),
                                  title: Text('Edit'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'close',
                                child: ListTile(
                                  leading: Icon(Icons.close_rounded, color: AppColors.error),
                                  title: Text('Close',
                                      style: TextStyle(color: AppColors.error)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoStartupYet extends StatelessWidget {
  final UserModel user;
  const _NoStartupYet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_rounded, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Set up your startup profile',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your startup registration to start posting opportunities.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/home/startup/register'),
              child: const Text('Register Startup'),
            ),
          ],
        ),
      ),
    );
  }
}
