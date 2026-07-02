import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/opportunity_model.dart';
import '../../data/repositories/opportunity_repository.dart';
import '../cubit/opportunity_cubit.dart';
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

  List<OpportunityModel> _applyFilters(List<OpportunityModel> all) {
    return all.where((o) {
      final matchesQuery = _query.isEmpty ||
          o.title.toLowerCase().contains(_query) ||
          o.startupName.toLowerCase().contains(_query) ||
          o.skillsRequired.any((s) => s.toLowerCase().contains(_query));
      final matchesCategory = _selectedCategory == null || o.category == _selectedCategory;
      return matchesQuery && matchesCategory;
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
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<OpportunityCubit, OpportunityState>(
        builder: (context, state) {
          final isLoading = state is OpportunityLoading || state is OpportunityInitial;
          final opportunities = state is OpportunityLoaded
              ? _applyFilters(state.opportunities)
              : <OpportunityModel>[];

          return SafeArea(
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
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: AppConstants.opportunityCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = AppConstants.opportunityCategories[i];
                        final isSelected = cat == _selectedCategory;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) => _onCategoryTap(cat),
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
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (isLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (state is OpportunityError)
                  SliverFillRemaining(child: Center(child: Text(state.message)))
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
                      itemBuilder: (context, i) => OpportunityCard(
                        opportunity: opportunities[i],
                        onTap: () => context.push('/home/opportunity/${opportunities[i].id}'),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
