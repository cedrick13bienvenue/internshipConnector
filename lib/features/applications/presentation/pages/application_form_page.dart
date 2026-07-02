import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/application_repository.dart';
import '../../../opportunities/data/models/opportunity_model.dart';
import '../../../opportunities/data/repositories/opportunity_repository.dart';

class ApplicationFormPage extends StatefulWidget {
  final String opportunityId;
  const ApplicationFormPage({super.key, required this.opportunityId});

  @override
  State<ApplicationFormPage> createState() => _ApplicationFormPageState();
}

class _ApplicationFormPageState extends State<ApplicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _coverNoteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _coverNoteController.dispose();
    super.dispose();
  }

  Future<void> _submit(OpportunityModel opp) async {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    final user = authState.user;

    setState(() => _isSubmitting = true);

    final application = ApplicationModel(
      id: '',
      opportunityId: opp.id,
      opportunityTitle: opp.title,
      startupId: opp.startupId,
      startupName: opp.startupName,
      startupLogoUrl: opp.startupLogoUrl,
      applicantId: user.uid,
      applicantName: user.fullName,
      coverNote: _coverNoteController.text.trim(),
      status: ApplicationStatus.applied,
      appliedAt: DateTime.now(),
    );

    try {
      await ApplicationRepository().submit(application);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpportunityModel>(
      future: OpportunityRepository().getById(widget.opportunityId),
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

        return Scaffold(
          appBar: AppBar(title: const Text('Apply')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _OpportunitySummary(opp: opp),
                const SizedBox(height: 28),
                Text('Cover note', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  "Tell the startup why you're a great fit for this role.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _coverNoteController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Write your cover note here...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Cover note is required.';
                    if (v.trim().length < 20) return 'Please write at least 20 characters.';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submit(opp),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Application', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OpportunitySummary extends StatelessWidget {
  final OpportunityModel opp;
  const _OpportunitySummary({required this.opp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage:
                opp.startupLogoUrl != null ? NetworkImage(opp.startupLogoUrl!) : null,
            child: opp.startupLogoUrl == null
                ? Text(
                    opp.startupName.isNotEmpty ? opp.startupName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opp.title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(opp.startupName, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _pill(opp.commitment),
                    const SizedBox(width: 6),
                    _pill(opp.location),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
