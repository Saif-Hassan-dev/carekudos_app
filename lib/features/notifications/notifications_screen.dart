import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/formatters.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications')),
      );
    }

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
            onPressed: () async {
              await NotificationService.markAllAsRead(user.uid);
            },
            child: Text(
              'Mark all read',
              style: AppTypography.actionA2.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading notifications: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Sort notifications by createdAt in-memory (client-side)
          final notifications = snapshot.data!.docs.toList();
          notifications.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime); // Descending order (newest first)
          });

          return ListView.separated(
            padding: AppSpacing.vertical16,
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              return _NotificationTile(
                notificationId: doc.id,
                data: data,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
}

class _NotificationTile extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> data;

  const _NotificationTile({
    required this.notificationId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final type = _getNotificationType(data['type'] as String?);
    final title = data['title'] as String? ?? 'Notification';
    final message = data['message'] as String? ?? '';
    final isUnread = !(data['isRead'] as bool? ?? false);
    final createdAt = data['createdAt'] as Timestamp?;
    final timeAgo = createdAt != null
        ? Formatters.timeAgo(createdAt.toDate())
        : 'Just now';

    return Container(
      color: isUnread
          ? AppColors.primaryLight.withValues(alpha: 0.3)
          : null,
      child: ListTile(
        contentPadding: AppSpacing.horizontal16,
        leading: _buildIcon(type),
        title: Text(
          title,
          style: AppTypography.bodyB3.copyWith(
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.verticalGap4,
            Text(
              message,
              style: AppTypography.captionC1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.verticalGap4,
            Text(
              timeAgo,
              style: AppTypography.captionC2.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () async {
          // Mark as read
          await NotificationService.markAsRead(notificationId);
          // TODO: Navigate to related content if applicable
        },
      ),
    );
  }

  NotificationType _getNotificationType(String? typeStr) {
    switch (typeStr) {
      case 'star':
        return NotificationType.star;
      case 'comment':
        return NotificationType.comment;
      case 'achievement':
        return NotificationType.achievement;
      case 'reminder':
        return NotificationType.reminder;
      case 'postApproved':
        return NotificationType.postApproved;
      case 'milestone':
        return NotificationType.milestone;
      default:
        return NotificationType.system;
    }
  }

  Widget _buildIcon(NotificationType type) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (type) {
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
      case NotificationType.postApproved:
        icon = Icons.check_circle;
        color = AppColors.success;
        bgColor = AppColors.successLight;
      case NotificationType.milestone:
        icon = Icons.military_tech;
        color = AppColors.secondary;
        bgColor = AppColors.secondaryLight;
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

enum NotificationType {
  star,
  comment,
  achievement,
  reminder,
  postApproved,
  milestone,
  system,
}
