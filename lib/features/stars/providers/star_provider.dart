import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/constants.dart';

// Provider to give stars to a post
final starPostProvider = Provider((ref) => StarService());

class StarService {
  Future<void> giveStarToPost({
    required String postId,
    required String postAuthorId,
    required double multiplier,
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

    await batch.commit();
  }

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
