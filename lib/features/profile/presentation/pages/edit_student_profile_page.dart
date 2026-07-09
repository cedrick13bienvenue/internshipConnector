import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class EditStudentProfilePage extends StatefulWidget {
  const EditStudentProfilePage({super.key});

  @override
  State<EditStudentProfilePage> createState() => _EditStudentProfilePageState();
}

class _EditStudentProfilePageState extends State<EditStudentProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  String? _selectedProgram;
  final Set<String> _selectedSkills = {};
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = (context.read<AuthCubit>().state as AuthAuthenticated).user;
    _nameController = TextEditingController(text: user.fullName);
    _bioController = TextEditingController(text: user.bio ?? '');
    _selectedProgram = user.program;
    _selectedSkills.addAll(user.skills);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final mimeType = picked.mimeType ?? 'image/jpeg';
      if (!mounted) return;
      await context.read<AuthCubit>().uploadProfilePhoto(bytes, mimeType);
      if (mounted) AppToast.showSuccess(context, 'Photo updated!');
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Failed to upload photo.');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    await context.read<AuthCubit>().updateStudentProfile(
      fullName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      skills: _selectedSkills.toList(),
      program: _selectedProgram,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (!_saving) return;
        if (state is AuthAuthenticated) {
          setState(() => _saving = false);
          AppToast.showSuccess(context, 'Profile updated successfully!');
          context.pop();
        } else if (state is AuthError) {
          setState(() => _saving = false);
          AppToast.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _AvatarPicker(
              onTap: _uploadingPhoto ? null : _pickPhoto,
              uploading: _uploadingPhoto,
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedProgram,
              decoration: const InputDecoration(labelText: 'Program'),
              items: AppConstants.programs
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedProgram = v),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Bio',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Text('Skills', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.skills.map((s) {
                final selected = _selectedSkills.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (v) =>
                      setState(() => v ? _selectedSkills.add(s) : _selectedSkills.remove(s)),
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
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final VoidCallback? onTap;
  final bool uploading;
  const _AvatarPicker({required this.onTap, required this.uploading});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final photoUrl = state is AuthAuthenticated ? state.user.photoUrl : null;
        final name = state is AuthAuthenticated ? state.user.fullName : '';

        return Center(
          child: GestureDetector(
            onTap: onTap,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.primaryLight,
                  child: uploading
                      ? const CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2)
                      : photoUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: photoUrl,
                                width: 104,
                                height: 104,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2),
                                errorWidget: (_, __, ___) => _initials(name),
                              ),
                            )
                          : _initials(name),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _initials(String name) => Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 36,
          fontWeight: FontWeight.w700,
        ),
      );
}
