import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../cubit/auth_cubit.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Student fields
  final _bioController = TextEditingController();
  String? _selectedProgram;
  final Set<String> _selectedSkills = {};

  // Startup fields
  final _startupNameController = TextEditingController();
  final _startupDescController = TextEditingController();
  final _websiteController = TextEditingController();
  final Set<String> _selectedCategories = {};

  @override
  void dispose() {
    _bioController.dispose();
    _startupNameController.dispose();
    _startupDescController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  UserRole get _role {
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) return state.user.role;
    return UserRole.student;
  }

  String get _firstName {
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      return state.user.fullName.split(' ').first;
    }
    return 'there';
  }

  void _next() {
    final totalSteps = _role == UserRole.student ? 2 : 2;
    if (_currentStep < totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    final cubit = context.read<AuthCubit>();
    if (_role == UserRole.student) {
      await cubit.completeStudentOnboarding(
        bio: _bioController.text.trim(),
        skills: _selectedSkills.toList(),
        program: _selectedProgram,
      );
    } else {
      await cubit.completeStartupOnboarding(
        startupName: _startupNameController.text.trim(),
        description: _startupDescController.text.trim(),
        categories: _selectedCategories.toList(),
        websiteUrl: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildProgressBar(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentStep = i),
                    children: _role == UserRole.student
                        ? [_buildStudentStep1(), _buildStudentStep2()]
                        : [_buildStartupStep1(), _buildStartupStep2()],
                  ),
                ),
                _buildBottomBar(isLoading),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: _back,
              child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            )
          else
            const SizedBox(width: 24),
          const Spacer(),
          Text(
            'Step ${_currentStep + 1} of 2',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (_currentStep + 1) / 2,
          backgroundColor: AppColors.divider,
          color: AppColors.primary,
          minHeight: 4,
        ),
      ),
    );
  }

  // ─── Student Step 1: About you ───────────────────────────────────────────
  Widget _buildStudentStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Hey, $_firstName! 👋', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Tell us a bit about yourself.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            value: _selectedProgram,
            decoration: const InputDecoration(
              labelText: 'Program',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: AppConstants.programs
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() => _selectedProgram = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Short Bio',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.edit_note_rounded),
              ),
              hintText: 'What are you passionate about?',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Student Step 2: Skills ───────────────────────────────────────────────
  Widget _buildStudentStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Your Skills', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Select skills that match what you can contribute.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.skills.map((skill) {
              final selected = _selectedSkills.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: selected,
                onSelected: (_) => setState(() {
                  selected
                      ? _selectedSkills.remove(skill)
                      : _selectedSkills.add(skill);
                }),
                selectedColor: AppColors.primaryLight,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.divider,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Startup Step 1: About startup ───────────────────────────────────────
  Widget _buildStartupStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('About Your Startup', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text("Tell us about the startup you're building.",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          TextFormField(
            controller: _startupNameController,
            decoration: const InputDecoration(
              labelText: 'Startup Name',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _startupDescController,
            maxLines: 4,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.edit_note_rounded),
              ),
              hintText: 'What problem does your startup solve?',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Startup Step 2: Categories & website ────────────────────────────────
  Widget _buildStartupStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Details', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('What areas does your startup operate in?',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.opportunityCategories.map((cat) {
              final selected = _selectedCategories.contains(cat);
              return FilterChip(
                label: Text(cat),
                selected: selected,
                onSelected: (_) => setState(() {
                  selected
                      ? _selectedCategories.remove(cat)
                      : _selectedCategories.add(cat);
                }),
                selectedColor: AppColors.primaryLight,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.divider,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Website URL (optional)',
              prefixIcon: Icon(Icons.link_rounded),
              hintText: 'https://yourstartup.com',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, color: AppColors.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your startup will be reviewed by an ALU admin before going live.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.info,
                          fontSize: 12,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isLoading) {
    final isLastStep = _currentStep == 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: isLoading ? null : _next,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(isLastStep ? 'Get Started 🚀' : 'Continue'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.read<AuthCubit>().signOut(),
            child: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.textHint, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
