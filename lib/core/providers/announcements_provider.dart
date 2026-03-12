import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppAnnouncement {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;

  const AppAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });
}

final latestAnnouncementProvider = StreamProvider<AppAnnouncement?>((ref) {
  return FirebaseFirestore.instance
      .collection('announcements')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snap) {
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final data = doc.data();
    return AppAnnouncement(
      id: doc.id,
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  });
});
