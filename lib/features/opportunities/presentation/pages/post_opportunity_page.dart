import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../startups/presentation/cubit/startup_cubit.dart';
import '../../data/models/opportunity_model.dart';
import '../../data/repositories/opportunity_repository.dart';

class PostOpportunityPage extends StatefulWidget {
  const PostOpportunityPage({super.key});

  @override
  State<PostOpportunityPage> createState() => _PostOpportunityPageState();
}

class _PostOpportunityPageState extends State<PostOpportunityPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _category = AppConstants.opportunityCategories.first;
  String _commitment = AppConstants.commitmentTypes.first;
  String _location = AppConstants.locationTypes.first;
  final Set<String> _selectedSkills = {};
  DateTime? _deadline;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final startupState = context.read<StartupCubit>().state;
    if (startupState is! StartupOwnerLoaded || startupState.startup == null) return;
    final startup = startupState.startup!;

    setState(() => _isSubmitting = true);

    final opportunity = OpportunityModel(
      id: '',
      startupId: startup.id,
      startupName: startup.name,
      startupLogoUrl: startup.logoUrl,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      skillsRequired: _selectedSkills.toList(),
      commitment: _commitment,
      location: _location,
      postedAt: DateTime.now(),
      deadline: _deadline,
      status: OpportunityStatus.open,
    );

    try {
      await OpportunityRepository().create(opportunity);
      if (mounted) {
        AppToast.showSuccess(context, 'Opportunity posted successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppToast.showError(context, 'Failed to post: $e');
      }
    }
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
    final startupState = context.read<StartupCubit>().state;
    final startup = startupState is StartupOwnerLoaded ? startupState.startup : null;

    if (startup == null || !startup.isVerified) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Opportunity')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_outlined, size: 56, color: AppColors.warning),
                const SizedBox(height: 16),
                Text(
                  'Verification required',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your startup must be verified by an ALU admin before you can post opportunities.',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Post Opportunity')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Role title *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: AppConstants.opportunityCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _commitment,
              decoration: const InputDecoration(labelText: 'Commitment *'),
              items: AppConstants.commitmentTypes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _commitment = v!),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _location,
              decoration: const InputDecoration(labelText: 'Location *'),
              items: AppConstants.locationTypes
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => _location = v!),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (v) => v == null || v.trim().length < 20
                  ? 'Please describe the opportunity (min 20 chars)'
                  : null,
            ),
            const SizedBox(height: 28),
            Text('Skills required', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.skills.map((s) {
                final isSelected = _selectedSkills.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: isSelected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedSkills.add(s);
                    } else {
                      _selectedSkills.remove(s);
                    }
                  }),
                  selectedColor: AppColors.primaryLight,
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text('Deadline', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (_deadline != null)
                  TextButton(
                    onPressed: () => setState(() => _deadline = null),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                    child: const Text('Remove'),
                  ),
                TextButton.icon(
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    _deadline == null ? 'Add deadline' : _formatDate(_deadline!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Post Opportunity', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
