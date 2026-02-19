import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

enum NotificationType {
  star,           // User received a star
  comment,        // Comment on user's post
  achievement,    // Achievement unlocked
  reminder,       // System reminder
  postApproved,   // Post approved by admin
  milestone,      // Milestone reached (e.g., 10 stars)
  system,         // System notifications
}

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create a notification for a user
  static Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? relatedUserId,
    String? relatedPostId,
    String? relatedCommentId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'relatedUserId': relatedUserId,
        'relatedPostId': relatedPostId,
        'relatedCommentId': relatedCommentId,
        'metadata': metadata,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating notification: $e');
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

  /// Create notification when user's post is commented on
  static Future<void> notifyNewComment({
    required String postAuthorId,
    required String commenterName,
    required String commenterId,
    required String postId,
    required String commentId,
  }) async {
    await createNotification(
      userId: postAuthorId,
      type: NotificationType.comment,
      title: 'New Comment',
      message: '$commenterName commented on your post',
      relatedUserId: commenterId,
      relatedPostId: postId,
      relatedCommentId: commentId,
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
      print('Error marking notification as read: $e');
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
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
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
