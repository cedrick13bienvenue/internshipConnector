import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/application_repository.dart';

enum _Sort { newestFirst, oldestFirst }

class OpportunityApplicantsPage extends StatefulWidget {
  final String opportunityId;
  final String opportunityTitle;

  const OpportunityApplicantsPage({
    super.key,
    required this.opportunityId,
    required this.opportunityTitle,
  });

  @override
  State<OpportunityApplicantsPage> createState() => _OpportunityApplicantsPageState();
}

class _OpportunityApplicantsPageState extends State<OpportunityApplicantsPage> {
  _Sort _sort = _Sort.newestFirst;
  ApplicationStatus? _statusFilter;
  bool _starredOnly = false;

  List<ApplicationModel> _applyFilters(List<ApplicationModel> all) {
    var list = all.where((a) {
      if (_starredOnly && !a.isStarred) return false;
      if (_statusFilter != null && a.status != _statusFilter) return false;
      return true;
    }).toList();

    list.sort((a, b) => _sort == _Sort.newestFirst
        ? b.appliedAt.compareTo(a.appliedAt)
        : a.appliedAt.compareTo(b.appliedAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.opportunityTitle, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: _Sort.newestFirst,
                checked: _sort == _Sort.newestFirst,
                child: const Text('Newest first'),
              ),
              CheckedPopupMenuItem(
                value: _Sort.oldestFirst,
                checked: _sort == _Sort.oldestFirst,
                child: const Text('Oldest first'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<ApplicationModel>>(
        stream: ApplicationRepository().watchByOpportunity(widget.opportunityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final all = snapshot.data ?? [];
          final displayed = _applyFilters(all);

          return Column(
            children: [
              _FilterBar(
                all: all,
                starredOnly: _starredOnly,
                statusFilter: _statusFilter,
                onStarredTap: () => setState(() {
                  _starredOnly = !_starredOnly;
                  if (_starredOnly) _statusFilter = null;
                }),
                onStatusTap: (s) => setState(() {
                  _statusFilter = _statusFilter == s ? null : s;
                  if (_statusFilter != null) _starredOnly = false;
                }),
              ),
              Expanded(
                child: displayed.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              all.isEmpty
                                  ? 'No applicants yet.'
                                  : 'No applicants match this filter.',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayed.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _ApplicantCard(
                          application: displayed[i],
                          onTap: () => context.push(
                            '/home/applicant/${displayed[i].id}',
                            extra: displayed[i],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<ApplicationModel> all;
  final bool starredOnly;
  final ApplicationStatus? statusFilter;
  final VoidCallback onStarredTap;
  final ValueChanged<ApplicationStatus> onStatusTap;

  const _FilterBar({
    required this.all,
    required this.starredOnly,
    required this.statusFilter,
    required this.onStarredTap,
    required this.onStatusTap,
  });

  int _countFor(ApplicationStatus s) => all.where((a) => a.status == s).length;
  int get _starredCount => all.where((a) => a.isStarred).length;

  @override
  Widget build(BuildContext context) {
    final statuses = ApplicationStatus.values.where((s) => _countFor(s) > 0).toList();
    return SizedBox(
      height: 52,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: '⭐ Starred',
            count: _starredCount,
            selected: starredOnly,
            onTap: onStarredTap,
            selectedColor: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          ...statuses.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label: _statusLabel(s),
                  count: _countFor(s),
                  selected: statusFilter == s,
                  onTap: () => onStatusTap(s),
                  selectedColor: _statusColor(s),
                ),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? selectedColor : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? selectedColor : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? selectedColor : AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatefulWidget {
  final ApplicationModel application;
  final VoidCallback onTap;
  const _ApplicantCard({required this.application, required this.onTap});

  @override
  State<_ApplicantCard> createState() => _ApplicantCardState();
}

class _ApplicantCardState extends State<_ApplicantCard> {
  bool _togglingstar = false;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  Future<void> _toggleStar() async {
    setState(() => _togglingstar = true);
    try {
      await ApplicationRepository()
          .toggleStar(widget.application.id, !widget.application.isStarred);
    } catch (_) {
      if (mounted) AppToast.showError(context, 'Failed to update.');
    } finally {
      if (mounted) setState(() => _togglingstar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final color = _statusColor(app.status);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  app.applicantName.isNotEmpty ? app.applicantName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.applicantName, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _statusLabel(app.status),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(app.appliedAt),
                          style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _togglingstar
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: Icon(
                        app.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                        color: app.isStarred ? const Color(0xFFF59E0B) : AppColors.textHint,
                      ),
                      tooltip: app.isStarred ? 'Unmark' : 'Mark for review',
                      onPressed: _toggleStar,
                    ),
            ],
          ),
        ),
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
