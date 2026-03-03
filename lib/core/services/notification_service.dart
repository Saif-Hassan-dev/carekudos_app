import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

enum NotificationType {
  star,           // User received a star
  achievement,    // Achievement unlocked
  reminder,       // System reminder
  postApproved,   // Post approved by admin
  milestone,      // Milestone reached (e.g., 10 stars)
  system,         // System notifications
}

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Check if a user has this notification type enabled.
  /// Returns false (suppress) when the user explicitly turned it off.
  static Future<bool> _isNotificationEnabled(
    String userId,
    NotificationType type,
  ) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return true; // default allow
      final data = doc.data() as Map<String, dynamic>;

      switch (type) {
        case NotificationType.star:
          return data['notifyStarsReceived'] ?? true;
        case NotificationType.system:
        case NotificationType.reminder:
        case NotificationType.postApproved:
        case NotificationType.achievement:
        case NotificationType.milestone:
          return data['notifySystemUpdates'] ?? true;
      }
    } catch (e) {
      debugPrint('Error checking notification preference: $e');
      return true; // default allow on error
    }
  }

  /// Create a notification for a user (respects user preferences)
  static Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? relatedUserId,
    String? relatedPostId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if the user wants this type of notification
      final enabled = await _isNotificationEnabled(userId, type);
      if (!enabled) {
        debugPrint(
          'Notification suppressed for user $userId (type: ${type.name})',
        );
        return;
      }

      await _db.collection('notifications').add({
        'userId': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'relatedUserId': relatedUserId,
        'relatedPostId': relatedPostId,
        'metadata': metadata,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Create notification when user receives a star
  static Future<void> notifyStarReceived({
    required String recipientId,
    required String giverName,
    required String category,
    required String postId,
    required String giverId,
    int multiplier = 1,
  }) async {
    final starText = multiplier > 1 ? '$multiplier stars' : 'a star';
    await createNotification(
      userId: recipientId,
      type: NotificationType.star,
      title: 'New Star Received!',
      message: '$giverName gave you $starText for $category',
      relatedUserId: giverId,
      relatedPostId: postId,
      metadata: {
        'category': category,
        'multiplier': multiplier,
      },
    );
  }

  /// Create notification for achievement unlock
  static Future<void> notifyAchievement({
    required String userId,
    required String achievementName,
    required String description,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.achievement,
      title: 'Achievement Unlocked!',
      message: 'You earned the "$achievementName" badge',
      metadata: {
        'achievement': achievementName,
        'description': description,
      },
    );
  }

  /// Create notification when post is approved
  static Future<void> notifyPostApproved({
    required String userId,
    required String postId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.postApproved,
      title: 'Post Approved',
      message: 'Your post is now visible to the team',
      relatedPostId: postId,
    );
  }

  /// Create notification for milestone
  static Future<void> notifyMilestone({
    required String userId,
    required String milestone,
    required String message,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.milestone,
      title: 'Milestone Reached!',
      message: message,
      metadata: {'milestone': milestone},
    );
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _db.batch();
      final notifications = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Get unread notification count
  static Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get user's notifications stream
  static Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }
}
