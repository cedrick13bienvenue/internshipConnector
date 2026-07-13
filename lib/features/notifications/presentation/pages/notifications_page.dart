import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationsPage extends StatelessWidget {
  final String userId;
  const NotificationsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final repo = NotificationRepository();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => repo.markAllRead(userId),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: repo.watchForUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No notifications yet.', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = notifications[i];
              return _NotificationTile(notification: n, repo: repo);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final NotificationRepository repo;
  const _NotificationTile({required this.notification, required this.repo});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return InkWell(
      onTap: () {
        if (isUnread) repo.markAsRead(notification.id);
      },
      child: Container(
        color: isUnread ? AppColors.primaryLight.withValues(alpha: 0.5) : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUnread ? AppColors.primary : AppColors.divider,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_outline_rounded,
                size: 20,
                color: isUnread ? Colors.white : AppColors.textHint,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
