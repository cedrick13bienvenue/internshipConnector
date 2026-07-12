import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/opportunity_model.dart';
import '../../data/repositories/opportunity_repository.dart';
import '../cubit/opportunity_cubit.dart';
import '../widgets/bookmark_button.dart';
import '../widgets/opportunity_card.dart';

class ExploreTabPage extends StatefulWidget {
  const ExploreTabPage({super.key});

  @override
  State<ExploreTabPage> createState() => _ExploreTabPageState();
}

class _ExploreTabPageState extends State<ExploreTabPage> {
  late final OpportunityCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _selectedCategory;
  bool _showSaved = false;

  @override
  void initState() {
    super.initState();
    _cubit = OpportunityCubit(OpportunityRepository());
    _cubit.watchAll();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () {
        if (mounted) setState(() => _query = _searchController.text.trim().toLowerCase());
      },
    );
  }

  void _onCategoryTap(String category) {
    setState(() => _selectedCategory = _selectedCategory == category ? null : category);
  }

  List<OpportunityModel> _applyFilters(List<OpportunityModel> all, List<String> savedIds) {
    return all.where((o) {
      final matchesQuery = _query.isEmpty ||
          o.title.toLowerCase().contains(_query) ||
          o.startupName.toLowerCase().contains(_query) ||
          o.skillsRequired.any((s) => s.toLowerCase().contains(_query));
      final matchesCategory = _selectedCategory == null || o.category == _selectedCategory;
      final matchesSaved = !_showSaved || savedIds.contains(o.id);
      return matchesQuery && matchesCategory && matchesSaved;
    }).toList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final savedIds = authState is AuthAuthenticated
        ? authState.user.savedOpportunities
        : <String>[];

    final oppState = _cubit.state;
    final isLoading = oppState is OpportunityLoading || oppState is OpportunityInitial;
    final opportunities = oppState is OpportunityLoaded
        ? _applyFilters(oppState.opportunities, savedIds)
        : <OpportunityModel>[];
    final hasError = oppState is OpportunityError;
    final errorMessage = hasError ? oppState.message : '';

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(listener: (_, __) => setState(() {})),
        BlocListener<OpportunityCubit, OpportunityState>(
          bloc: _cubit,
          listener: (_, __) => setState(() {}),
        ),
      ],
      child: BlocProvider.value(
        value: _cubit,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Explore', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Discover opportunities from ALU startups',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by title, startup, or skill...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
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
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.bookmark_rounded, size: 14),
                        label: const Text('Saved'),
                        selected: _showSaved,
                        onSelected: (_) => setState(() {
                          _showSaved = !_showSaved;
                          _selectedCategory = null;
                        }),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _showSaved ? AppColors.surface : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              color: _showSaved ? AppColors.primary : AppColors.divider),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...AppConstants.opportunityCategories.map((cat) {
                        final isSelected = cat == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) {
                              _onCategoryTap(cat);
                              setState(() => _showSaved = false);
                            },
                            backgroundColor: AppColors.surface,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.surface : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                  color: isSelected ? AppColors.primary : AppColors.divider),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (hasError)
                SliverFillRemaining(
                    child: Center(child: Text(errorMessage)))
              else if (opportunities.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text(
                          'No opportunities match your search.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverList.builder(
                    itemCount: opportunities.length,
                    itemBuilder: (context, i) {
                      final opp = opportunities[i];
                      return OpportunityCard(
                        opportunity: opp,
                        onTap: () => context.push('/home/opportunity/${opp.id}'),
                        trailing: BookmarkButton(opportunityId: opp.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

