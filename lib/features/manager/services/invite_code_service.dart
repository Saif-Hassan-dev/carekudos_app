import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class InviteCodeService {
  /// Generate unique invite code for manager
  static Future<String> generateInviteCode(String managerId) async {
    final code = _generateRandomCode(8);

    await FirebaseFirestore.instance.collection('invite_codes').doc(code).set({
      'managerId': managerId,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(Duration(days: 30)),
      'used': false,
    });

    return code;
  }

  /// Verify invite code and link family member
  static Future<String?> verifyInviteCode(String code) async {
    final codeDoc = await FirebaseFirestore.instance
        .collection('invite_codes')
        .doc(code)
        .get();

    if (!codeDoc.exists) return null;

    final data = codeDoc.data()!;
    if (data['used'] == true) return null;

    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) return null;

    return data['managerId'];
  }

  static String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (_) => chars[Random().nextInt(chars.length)],
    ).join();
  }
}
