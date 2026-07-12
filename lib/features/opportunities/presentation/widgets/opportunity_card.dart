import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/opportunity_model.dart';

class OpportunityCard extends StatelessWidget {
  final OpportunityModel opportunity;
  final VoidCallback onTap;
  final Widget? trailing;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    required this.onTap,
    this.trailing,
  });

  String get _postedAgo {
    final diff = DateTime.now().difference(opportunity.postedAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: opportunity.startupLogoUrl != null
                        ? NetworkImage(opportunity.startupLogoUrl!)
                        : null,
                    child: opportunity.startupLogoUrl == null
                        ? const Icon(Icons.business_rounded, color: AppColors.primary, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opportunity.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          opportunity.startupName,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(opportunity.category),
                  _buildTag(opportunity.commitment),
                  _buildTag(opportunity.location),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(_postedAgo, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                  const Spacer(),
                  Icon(Icons.people_outline_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    '${opportunity.applicantsCount} applicants',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
