import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/startup_repository.dart';
import '../cubit/startup_cubit.dart';

class EditStartupPage extends StatefulWidget {
  const EditStartupPage({super.key});

  @override
  State<EditStartupPage> createState() => _EditStartupPageState();
}

class _EditStartupPageState extends State<EditStartupPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _websiteController;
  final Set<String> _selectedCategories = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final startup = (context.read<StartupCubit>().state as StartupOwnerLoaded).startup!;
    _nameController = TextEditingController(text: startup.name);
    _descController = TextEditingController(text: startup.description);
    _websiteController = TextEditingController(text: startup.websiteUrl ?? '');
    _selectedCategories.addAll(startup.categories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final startup = (context.read<StartupCubit>().state as StartupOwnerLoaded).startup!;
      final updated = startup.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        websiteUrl: _websiteController.text.trim().isEmpty
            ? startup.websiteUrl
            : _websiteController.text.trim(),
        categories: _selectedCategories.toList(),
      );
      await StartupRepository().update(updated);
      if (!mounted) return;
      final uid = (context.read<AuthCubit>().state as AuthAuthenticated).user.uid;
      await context.read<StartupCubit>().loadMyStartup(uid);
      if (mounted) {
        AppToast.showSuccess(context, 'Startup profile updated!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppToast.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Startup')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Startup Name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _descController,
            maxLines: 4,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Website URL (optional)',
              prefixIcon: Icon(Icons.link_rounded),
              hintText: 'https://yourstartup.com',
            ),
          ),
          const SizedBox(height: 24),
          Text('Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.opportunityCategories.map((cat) {
              final selected = _selectedCategories.contains(cat);
              return FilterChip(
                label: Text(cat),
                selected: selected,
                onSelected: (v) => setState(
                    () => v ? _selectedCategories.add(cat) : _selectedCategories.remove(cat)),
                selectedColor: AppColors.primaryLight,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12,
                ),
                side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
