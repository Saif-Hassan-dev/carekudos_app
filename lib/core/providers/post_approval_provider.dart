import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../auth/auth_provider.dart';

class PostApprovalLogic {
  /// Check if user needs manager approval
  static Future<bool> needsApproval(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (!userDoc.exists) return true;

    final postCount = userDoc.data()?['postCount'] ?? 0;

    // First 5 posts need approval
    return postCount < 5;
  }

  /// Get approval status text
  static String getApprovalStatusText(bool needsApproval) {
    return needsApproval
        ? 'Sent for manager approval'
        : 'Post published immediately';
  }
}

// Provider to check if current user needs approval
final needsApprovalProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentUserProvider)?.uid;
  if (userId == null) return true;

  return PostApprovalLogic.needsApproval(userId);
});
