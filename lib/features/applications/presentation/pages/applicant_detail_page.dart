import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'resume_viewer_page.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/application_repository.dart';

class ApplicantDetailPage extends StatefulWidget {
  final ApplicationModel application;
  const ApplicantDetailPage({super.key, required this.application});

  @override
  State<ApplicantDetailPage> createState() => _ApplicantDetailPageState();
}

class _ApplicantDetailPageState extends State<ApplicantDetailPage> {
  late Future<UserModel> _profileFuture;
  bool _updating = false;

  ApplicationModel get _app => widget.application;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthRepository().getUserById(_app.applicantId);
  }

  Future<void> _updateStatus(ApplicationStatus newStatus) async {
    setState(() => _updating = true);
    try {
      await ApplicationRepository().updateStatus(
        _app.id,
        newStatus,
        applicantId: _app.applicantId,
        opportunityTitle: _app.opportunityTitle,
      );
      if (mounted) AppToast.showSuccess(context, 'Status updated.');
    } catch (_) {
      if (mounted) AppToast.showError(context, 'Failed to update status.');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _showStatusSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Update Status',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          ...ApplicationStatus.values
              .where((s) => s != ApplicationStatus.closed)
              .map((s) => RadioListTile<ApplicationStatus>(
                    title: Text(_statusLabel(s)),
                    value: s,
                    groupValue: _app.status,
                    activeColor: _statusColor(s),
                    onChanged: (v) async {
                      Navigator.pop(ctx);
                      if (v != null && v != _app.status) await _updateStatus(v);
                    },
                  )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _copyEmail(String email) {
    Clipboard.setData(ClipboardData(text: email));
    AppToast.showSuccess(context, 'Email copied!');
  }

  void _openResume(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResumeViewerPage(
          url: url,
          applicantName: _app.applicantName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_app.status);

    return Scaffold(
      body: FutureBuilder<UserModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            backgroundImage: profile?.photoUrl != null
                                ? CachedNetworkImageProvider(profile!.photoUrl!)
                                : null,
                            child: profile?.photoUrl == null
                                ? Text(
                                    _app.applicantName.isNotEmpty
                                        ? _app.applicantName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _app.applicantName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (profile?.program != null)
                            Text(
                              profile!.program!,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _Section(
                        title: 'Contact',
                        child: Row(
                          children: [
                            const Icon(Icons.email_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                profile?.email ?? '—',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            if (profile?.email != null)
                              IconButton(
                                icon: const Icon(Icons.copy_rounded,
                                    size: 18, color: AppColors.textHint),
                                tooltip: 'Copy email',
                                onPressed: () => _copyEmail(profile!.email),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (profile?.bio?.isNotEmpty == true) ...[
                        _Section(
                          title: 'About',
                          child: Text(
                            profile!.bio!,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (profile?.skills.isNotEmpty == true) ...[
                        _Section(
                          title: 'Skills',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile!.skills
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        s,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _Section(
                        title: 'Application',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'for ${_app.opportunityTitle}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Cover Note',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _app.coverNote,
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                            ),
                            if (_app.resumeUrl != null) ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => _openResume(_app.resumeUrl!),
                                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                label: const Text('View Resume'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 44),
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Section(
                        title: 'Status',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _statusLabel(_app.status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Spacer(),
                            _updating
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : TextButton.icon(
                                    onPressed: _showStatusSheet,
                                    icon: const Icon(Icons.edit_rounded, size: 16),
                                    label: const Text('Update'),
                                  ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

Color _statusColor(ApplicationStatus s) => switch (s) {
      ApplicationStatus.applied => AppColors.info,
      ApplicationStatus.underReview => AppColors.warning,
      ApplicationStatus.shortlisted => AppColors.primary,
      ApplicationStatus.interview => const Color(0xFF8B5CF6),
      ApplicationStatus.accepted => AppColors.success,
      ApplicationStatus.rejected => AppColors.error,
      ApplicationStatus.closed => AppColors.textHint,
    };

String _statusLabel(ApplicationStatus s) => switch (s) {
      ApplicationStatus.applied => 'Applied',
      ApplicationStatus.underReview => 'Under Review',
      ApplicationStatus.shortlisted => 'Shortlisted',
      ApplicationStatus.interview => 'Interview',
      ApplicationStatus.accepted => 'Accepted',
      ApplicationStatus.rejected => 'Rejected',
      ApplicationStatus.closed => 'Closed',
    };
