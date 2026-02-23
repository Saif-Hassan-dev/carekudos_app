import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service that handles push notifications using Firebase Cloud Messaging.
///
/// This service manages:
/// - Requesting notification permissions
/// - Saving / refreshing the FCM device token
/// - Handling foreground & background messages
/// - Subscribing to topics for broadcast notifications
///
/// NOTE: firebase_messaging is NOT yet added to pubspec.yaml.
/// To enable real push notifications, add `firebase_messaging: ^14.7.0`
/// to dependencies, then uncomment the FCM-specific lines below.
class PushNotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────────────────────────────
  //  Initialization
  // ──────────────────────────────────────

  /// Call once at app startup (e.g. in main.dart after Firebase.initializeApp).
  static Future<void> init(String userId) async {
    try {
      // 1. Request permission (iOS / Web)
      await _requestPermission();

      // 2. Get FCM token and save to Firestore
      final token = await _getFcmToken();
      if (token != null) {
        await _saveDeviceToken(userId, token);
      }

      // 3. Listen for token refresh
      _listenForTokenRefresh(userId);

      // 4. Configure foreground message handling
      _configureForegroundMessages();

      debugPrint('[PushNotificationService] Initialized for user $userId');
    } catch (e) {
      debugPrint('[PushNotificationService] init error: $e');
    }
  }

  // ──────────────────────────────────────
  //  Permission
  // ──────────────────────────────────────

  static Future<void> _requestPermission() async {
    // When firebase_messaging is added, uncomment:
    // final messaging = FirebaseMessaging.instance;
    // final settings = await messaging.requestPermission(
    //   alert: true,
    //   announcement: false,
    //   badge: true,
    //   carPlay: false,
    //   criticalAlert: false,
    //   provisional: false,
    //   sound: true,
    // );
    // debugPrint('Notification authorization: ${settings.authorizationStatus}');
    debugPrint('[PushNotificationService] Permission request placeholder');
  }

  // ──────────────────────────────────────
  //  Token Management
  // ──────────────────────────────────────

  static Future<String?> _getFcmToken() async {
    // When firebase_messaging is added, uncomment:
    // return await FirebaseMessaging.instance.getToken();
    debugPrint('[PushNotificationService] FCM token placeholder');
    return null;
  }

  static Future<void> _saveDeviceToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenRefresh': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // If the field doesn't exist, set it
      await _db.collection('users').doc(userId).set({
        'fcmTokens': [token],
        'lastTokenRefresh': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static void _listenForTokenRefresh(String userId) {
    // When firebase_messaging is added, uncomment:
    // FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    //   _saveDeviceToken(userId, newToken);
    // });
  }

  // ──────────────────────────────────────
  //  Message Handling
  // ──────────────────────────────────────

  static void _configureForegroundMessages() {
    // When firebase_messaging is added, uncomment:
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   debugPrint('Foreground message: ${message.notification?.title}');
    //   // Show local notification or in-app banner
    // });
  }

  /// Call this to handle a notification tap when the app opens from background.
  static Future<void> handleInitialMessage() async {
    // When firebase_messaging is added, uncomment:
    // final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    // if (initialMessage != null) {
    //   _handleMessage(initialMessage);
    // }
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  // static void _handleMessage(RemoteMessage message) {
  //   final data = message.data;
  //   final type = data['type'];
  //   final postId = data['postId'];
  //   // Navigate to relevant screen based on type
  //   debugPrint('Notification tapped: type=$type, postId=$postId');
  // }

  // ──────────────────────────────────────
  //  Topics
  // ──────────────────────────────────────

  /// Subscribe to a topic (e.g. organization-wide announcements)
  static Future<void> subscribeToTopic(String topic) async {
    // When firebase_messaging is added, uncomment:
    // await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('[PushNotificationService] Subscribed to $topic (placeholder)');
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    // When firebase_messaging is added, uncomment:
    // await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('[PushNotificationService] Unsubscribed from $topic (placeholder)');
  }

  // ──────────────────────────────────────
  //  Sending (via Firestore trigger / Cloud Function)
  // ──────────────────────────────────────

  /// Queue a push notification to be sent by a Cloud Function.
  /// This writes to a `push_notifications` collection, which a
  /// Cloud Function can watch and send real FCM messages.
  static Future<void> sendPushNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      await _db.collection('push_notifications').add({
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to queue push: $e');
    }
  }

  /// Send push notification when a star is received
  static Future<void> pushStarReceived({
    required String recipientId,
    required String giverName,
    required int points,
    required String postId,
  }) async {
    final starText = points > 1 ? '$points stars' : 'a star';
    await sendPushNotification(
      recipientId: recipientId,
      title: 'New Star Received! ⭐',
      body: '$giverName gave you $starText',
      data: {
        'type': 'star',
        'postId': postId,
      },
    );
  }

  /// Send push notification when a comment is received
  static Future<void> pushCommentReceived({
    required String recipientId,
    required String commenterName,
    required String postId,
  }) async {
    await sendPushNotification(
      recipientId: recipientId,
      title: 'New Comment 💬',
      body: '$commenterName commented on your post',
      data: {
        'type': 'comment',
        'postId': postId,
      },
    );
  }

  // ──────────────────────────────────────
  //  Cleanup
  // ──────────────────────────────────────

  /// Remove the current device token when user logs out
  static Future<void> removeDeviceToken(String userId) async {
    try {
      final token = await _getFcmToken();
      if (token != null) {
        await _db.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to remove token: $e');
    }
  }
}
