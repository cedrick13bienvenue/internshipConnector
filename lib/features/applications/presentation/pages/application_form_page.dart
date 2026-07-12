import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
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
  late final Future<OpportunityModel> _opportunityFuture;
  final _repo = ApplicationRepository();

  Uint8List? _resumeBytes;
  String? _resumeFileName;
  bool _isSubmitting = false;
  bool _isUploadingResume = false;

  static const int _maxResumeBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _opportunityFuture = OpportunityRepository().getById(widget.opportunityId);
  }

  @override
  void dispose() {
    _coverNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    final completer = Completer<void>();
    final input = html.FileUploadInputElement()
      ..accept = 'application/pdf,.pdf';
    input.click();

    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete();
        return;
      }
      final file = files.first;
      if (file.size > _maxResumeBytes) {
        if (mounted) AppToast.showError(context, 'Resume must be under 5 MB.');
        completer.complete();
        return;
      }
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoad.listen((_) {
        final result = reader.result;
        if (result is List<int> && mounted) {
          setState(() {
            _resumeBytes = Uint8List.fromList(result);
            _resumeFileName = file.name;
          });
        }
        completer.complete();
      });
      reader.onError.listen((_) => completer.complete());
    });

    await completer.future;
  }

  void _removeResume() => setState(() {
        _resumeBytes = null;
        _resumeFileName = null;
      });

  Future<void> _submit(OpportunityModel opp) async {
    if (!_formKey.currentState!.validate()) return;
    if (_resumeBytes == null) {
      AppToast.showError(context, 'Please upload your resume before submitting.');
      return;
    }
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    final user = authState.user;

    setState(() => _isSubmitting = true);

    try {
      String? resumeUrl;
      if (_resumeBytes != null) {
        setState(() => _isUploadingResume = true);
        resumeUrl = await _repo.uploadResume(user.uid, opp.id, _resumeBytes!);
        if (mounted) setState(() => _isUploadingResume = false);
      }

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
        resumeUrl: resumeUrl,
        status: ApplicationStatus.applied,
        appliedAt: DateTime.now(),
      );

      await _repo.submit(application);
      if (mounted) {
        AppToast.showSuccess(context, 'Application submitted!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadingResume = false;
        });
        AppToast.showError(context, 'Failed to submit. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply')),
      body: FutureBuilder<OpportunityModel>(
        future: _opportunityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(snapshot.error?.toString() ?? 'Opportunity not found.'),
            );
          }

          final opp = snapshot.data!;

          return Form(
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
                const SizedBox(height: 24),
                Text('Resume', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'PDF only · Max 5 MB · Required',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                if (_resumeFileName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _resumeFileName!,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textHint, size: 18),
                          onPressed: _removeResume,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _pickResume,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Upload Resume (PDF)'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: AppColors.divider),
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submit(opp),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isUploadingResume
                                    ? 'Uploading resume...'
                                    : 'Submitting...',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                        : const Text('Submit Application', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
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
                ? const Icon(Icons.business_rounded, color: AppColors.primary, size: 20)
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
        style: const TextStyle(
            color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
