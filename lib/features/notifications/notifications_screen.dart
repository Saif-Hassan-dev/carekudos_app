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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: AppTypography.headingH2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await NotificationService.markAllAsRead(user.uid);
                    },
                    child: Image.asset(
                      'assets/icons/CareKudos (15)/vuesax/twotone/edit.png',
                      width: 24,
                      height: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Notification list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: NotificationService.getUserNotifications(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                          'Error loading notifications: ${snapshot.error}'),
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
                    final aTime = (aData['createdAt'] as Timestamp?)
                            ?.toDate() ??
                        DateTime(2000);
                    final bTime = (bData['createdAt'] as Timestamp?)
                            ?.toDate() ??
                        DateTime(2000);
                    return bTime
                        .compareTo(aTime); // Descending order (newest first)
                  });

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: notifications.length,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/CareKudos (16)/vuesax/twotone/notification.png',
            width: 80,
            height: 80,
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
    final isUnread = !(data['isRead'] as bool? ?? false);
    final createdAt = data['createdAt'] as Timestamp?;
    final timeAgo = createdAt != null
        ? Formatters.timeAgo(createdAt.toDate())
        : 'Just now';

    return InkWell(
      onTap: () async {
        // Mark as read
        await NotificationService.markAsRead(notificationId);

        // Navigate to related content if available
        final relatedPostId = data['relatedPostId'] as String?;
        if (relatedPostId != null && context.mounted) {
          context.push('/post/$relatedPostId');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFEEF3FB) : null,
          border: Border(
            bottom: BorderSide(
              color: AppColors.neutral200,
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            _buildIcon(type),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyB3.copyWith(
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: AppTypography.captionC1.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (isUnread)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 12),
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
    String iconPath;

    switch (type) {
      case NotificationType.star:
        iconPath = 'assets/icons/CareKudos (15)/vuesax/twotone/star.png';
      case NotificationType.comment:
        iconPath =
            'assets/icons/CareKudos (13)/vuesax/twotone/message.png';
      case NotificationType.achievement:
        iconPath =
            'assets/icons/CareKudos (15)/vuesax/twotone/medal-star.png';
      case NotificationType.reminder:
        iconPath =
            'assets/icons/CareKudos (16)/vuesax/twotone/clock.png';
      case NotificationType.postApproved:
        iconPath =
            'assets/icons/CareKudos (16)/vuesax/twotone/notification-status.png';
      case NotificationType.milestone:
        iconPath =
            'assets/icons/CareKudos (15)/vuesax/twotone/magic-star.png';
      case NotificationType.system:
        iconPath =
            'assets/icons/CareKudos (16)/vuesax/twotone/notification.png';
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          iconPath,
          width: 22,
          height: 22,
          color: AppColors.textSecondary,
        ),
      ),
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
