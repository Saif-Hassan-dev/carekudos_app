import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/constants.dart';
import '../../../core/auth/auth_provider.dart';

// Provider to give stars to a post
final starPostProvider = Provider((ref) => StarService());

/// Provider that returns how many stars the current user has given today.
final starsGivenTodayProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  try {
    // Query only by giverId (single field – no composite index needed).
    // Filter by date client-side.
    final snapshot = await FirebaseFirestore.instance
        .collection('star_history')
        .where('giverId', isEqualTo: user.uid)
        .get();

    int count = 0;
    for (final doc in snapshot.docs) {
      final ts = doc.data()['createdAt'] as Timestamp?;
      if (ts != null && ts.toDate().isAfter(startOfDay)) {
        count++;
      }
    }
    return count;
  } catch (e) {
    debugPrint('[StarProvider] Failed to fetch stars given today: $e');
    return 0;
  }
});

/// Provider that returns the number of stars left today for the current user.
final starsLeftTodayProvider = Provider<int>((ref) {
  final asyncValue = ref.watch(starsGivenTodayProvider);
  final givenToday = asyncValue.whenOrNull(data: (v) => v) ?? 0;
  return (AppConstants.maxStarsPerDay - givenToday)
      .clamp(0, AppConstants.maxStarsPerDay);
});

class StarService {
  Future<void> giveStarToPost({
    required String postId,
    required String postAuthorId,
    required double multiplier,
    String? giverName,
    String? giverId,
    String? category,
    String? starType,
    String? note,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Increment post stars
    final postRef = FirebaseFirestore.instance
        .collection(AppConstants.postsCollection)
        .doc(postId);
    batch.update(postRef, {'stars': FieldValue.increment(multiplier.toInt())});

    // 2. Increment user's total stars
    final userRef = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(postAuthorId);
    batch.update(userRef, {
      'totalStars': FieldValue.increment(multiplier.toInt()),
      'starsThisMonth': FieldValue.increment(multiplier.toInt()),
    });

    // 3. Record in star_history for daily limit tracking & profile history
    if (giverId != null) {
      final historyRef =
          FirebaseFirestore.instance.collection('star_history').doc();
      batch.set(historyRef, {
        'giverId': giverId,
        'receiverId': postAuthorId,
        'postId': postId,
        'starType': starType ?? 'Peer',
        'points': multiplier.toInt(),
        'note': note,
        'category': category,
        'giverName': giverName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Remove stars from a post
  Future<void> removeStarFromPost({
    required String postId,
    required String postAuthorId,
    required double multiplier,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    final postRef = FirebaseFirestore.instance
        .collection(AppConstants.postsCollection)
        .doc(postId);
    batch.update(postRef, {'stars': FieldValue.increment(-multiplier.toInt())});

    final userRef = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(postAuthorId);
    batch.update(userRef, {
      'totalStars': FieldValue.increment(-multiplier.toInt()),
      'starsThisMonth': FieldValue.increment(-multiplier.toInt()),
    });

    await batch.commit();
  }
}
