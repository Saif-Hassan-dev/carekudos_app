import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

class PushNotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ─────────────────────────────────────
  //  Initialization
  // ─────────────────────────────────────

  static Future<void> init(String userId) async {
    try {
      // Skip FCM on web (not needed for mobile push)
      if (kIsWeb) return;

      await _requestPermission();

      final token = await _getFcmToken();
      if (token != null) {
        await _saveDeviceToken(userId, token);
      }

      _listenForTokenRefresh(userId);
      _configureForegroundMessages();

      // Subscribe to broadcast topics
      await subscribeToTopic('announcements');
      await subscribeToTopic('all_users');

      debugPrint('[PushNotificationService] Initialized for user $userId');
    } catch (e) {
      debugPrint('[PushNotificationService] init error: $e');
    }
  }

  // ─────────────────────────────────────
  //  Permission
  // ─────────────────────────────────────

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('[FCM] Authorization: ${settings.authorizationStatus}');
  }

  // ─────────────────────────────────────
  //  Token Management
  // ─────────────────────────────────────

  static Future<String?> _getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  static Future<void> _saveDeviceToken(String userId, String token) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenRefresh': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await _db.collection('users').doc(userId).set({
        'fcmTokens': [token],
        'lastTokenRefresh': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static void _listenForTokenRefresh(String userId) {
    _messaging.onTokenRefresh.listen((newToken) {
      _saveDeviceToken(userId, newToken);
    });
  }

  // ─────────────────────────────────────
  //  Message Handling
  // ─────────────────────────────────────

  static void _configureForegroundMessages() {
    // Show heads-up notifications while app is in foreground
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    });
  }

  static Future<void> handleInitialMessage() async {
    if (kIsWeb) return;
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  static void _handleMessage(RemoteMessage message) {
    final type = message.data['type'];
    debugPrint('[FCM] Notification tapped: type=$type');
    // Navigation logic can be added here
  }

  // ─────────────────────────────────────
  //  Topics
  // ─────────────────────────────────────

  static Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] subscribeToTopic error: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('[FCM] unsubscribeFromTopic error: $e');
    }
  }

  // ─────────────────────────────────────
  //  Queue Push (processed by Cloud Function)
  // ─────────────────────────────────────

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
      debugPrint('[FCM] Failed to queue push: $e');
    }
  }

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
      data: {'type': 'star', 'postId': postId},
    );
  }

  static Future<void> pushPostApproved({
    required String recipientId,
    required String approverName,
    required String postId,
  }) async {
    await sendPushNotification(
      recipientId: recipientId,
      title: 'Your post was approved ✅',
      body: '$approverName approved your recognition post',
      data: {'type': 'post_approved', 'postId': postId},
    );
  }

  static Future<void> pushPostRejected({
    required String recipientId,
    required String reason,
    required String postId,
  }) async {
    await sendPushNotification(
      recipientId: recipientId,
      title: 'Post needs revision',
      body: reason.isNotEmpty ? reason : 'Your post was rejected',
      data: {'type': 'post_rejected', 'postId': postId},
    );
  }

  // ─────────────────────────────────────
  //  Cleanup
  // ─────────────────────────────────────

  static Future<void> removeDeviceToken(String userId) async {
    if (kIsWeb) return;
    try {
      final token = await _getFcmToken();
      if (token != null) {
        await _db.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
      await unsubscribeFromTopic('announcements');
      await unsubscribeFromTopic('all_users');
    } catch (e) {
      debugPrint('[FCM] removeDeviceToken error: $e');
    }
  }
}
