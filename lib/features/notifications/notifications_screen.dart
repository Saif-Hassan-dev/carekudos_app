import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: AppTypography.headingH5,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all as read
            },
            child: Text(
              'Mark all read',
              style: AppTypography.actionA2.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: _buildNotificationsList(),
    );
  }

  Widget _buildNotificationsList() {
    // Sample notifications - in production, this would come from a provider
    final notifications = <_NotificationItem>[
      _NotificationItem(
        type: NotificationType.star,
        title: 'New Star Received!',
        message: 'Sarah Johnson gave you a star for Compassion',
        time: '2 hours ago',
        isUnread: true,
      ),
      _NotificationItem(
        type: NotificationType.comment,
        title: 'New Comment',
        message: 'Mike Chen commented on your post',
        time: '5 hours ago',
        isUnread: true,
      ),
      _NotificationItem(
        type: NotificationType.achievement,
        title: 'Achievement Unlocked!',
        message: 'You earned the "Team Player" badge',
        time: '1 day ago',
        isUnread: false,
      ),
      _NotificationItem(
        type: NotificationType.reminder,
        title: 'Weekly Reminder',
        message: 'Don\'t forget to recognize your colleagues',
        time: '2 days ago',
        isUnread: false,
      ),
    ];

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: AppColors.neutral300,
            ),
            AppSpacing.verticalGap16,
            Text(
              'No notifications yet',
              style: AppTypography.headingH5.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.verticalGap8,
            Text(
              'You\'ll see updates here when\nsomeone interacts with you',
              style: AppTypography.bodyB3.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: AppSpacing.vertical16,
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationTile(notification: notification);
      },
    );
  }
}

enum NotificationType { star, comment, achievement, reminder, system }

class _NotificationItem {
  final NotificationType type;
  final String title;
  final String message;
  final String time;
  final bool isUnread;

  _NotificationItem({
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isUnread = false,
  });
}

class _NotificationTile extends StatelessWidget {
  final _NotificationItem notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isUnread
          ? AppColors.primaryLight.withValues(alpha: 0.3)
          : null,
      child: ListTile(
        contentPadding: AppSpacing.horizontal16,
        leading: _buildIcon(),
        title: Text(
          notification.title,
          style: AppTypography.bodyB3.copyWith(
            fontWeight:
                notification.isUnread ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.verticalGap4,
            Text(
              notification.message,
              style: AppTypography.captionC1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.verticalGap4,
            Text(
              notification.time,
              style: AppTypography.captionC2.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        trailing: notification.isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          // Handle notification tap
        },
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;
    Color bgColor;

    switch (notification.type) {
      case NotificationType.star:
        icon = Icons.star;
        color = AppColors.secondary;
        bgColor = AppColors.secondaryLight;
      case NotificationType.comment:
        icon = Icons.chat_bubble_outline;
        color = AppColors.primary;
        bgColor = AppColors.primaryLight;
      case NotificationType.achievement:
        icon = Icons.emoji_events;
        color = AppColors.success;
        bgColor = AppColors.successLight;
      case NotificationType.reminder:
        icon = Icons.schedule;
        color = AppColors.tertiary;
        bgColor = AppColors.tertiaryLight;
      case NotificationType.system:
        icon = Icons.info_outline;
        color = AppColors.textSecondary;
        bgColor = AppColors.surfaceVariant;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
