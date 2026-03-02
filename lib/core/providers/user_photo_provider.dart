import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory cache so we don't refetch for the same user within a session.
final _photoCache = <String, Uint8List?>{};

/// Provider family: given a userId, returns the decoded profile photo bytes
/// (or null if the user has no photo).
final userPhotoProvider =
    FutureProvider.family<Uint8List?, String>((ref, userId) async {
  if (userId.isEmpty) return null;

  // Return cached value if available
  if (_photoCache.containsKey(userId)) return _photoCache[userId];

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!doc.exists) {
      _photoCache[userId] = null;
      return null;
    }

    final data = doc.data()!;
    final base64Str =
        data['profilePhotoBase64'] as String? ?? data['profilePictureUrl'] as String?;

    if (base64Str == null || base64Str.isEmpty) {
      _photoCache[userId] = null;
      return null;
    }

    final bytes = base64Decode(base64Str);
    _photoCache[userId] = bytes;
    return bytes;
  } catch (_) {
    _photoCache[userId] = null;
    return null;
  }
});

/// Call this to clear the cached photo for a user (e.g. after they change it).
void invalidateUserPhoto(String userId) {
  _photoCache.remove(userId);
}
