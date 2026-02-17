import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Initialize Firebase with options
  static Future<void> init(FirebaseOptions options) async {
    await Firebase.initializeApp(options: options);
  }

  /// Save user role to Firestore (creates document if doesn't exist)
  static Future<void> saveUserRole(String userId, String role) async {
    try {
      await _db.collection('users').doc(userId).set({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save role: $e');
    }
  }

  /// Create user profile in Firestore
  static Future<void> createUserProfile({
    required String userId,
    required String email,
    required String firstName,
    required String lastName,
    required String role,
    String? jobTitle,
    String? organizationId,
    String? teamId,
  }) async {
    try {
      await _db.collection('users').doc(userId).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'jobTitle': jobTitle,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        //stars
        'totalStars': 0,
        'starsThisMonth': 0,
        'postCount': 0,
        'lastPostDate': null,

        //organization & team
        'organizationId': organizationId,
        'teamId': teamId,
        'managerIds': [],

        // GDPR consent (initially false, set during onboarding)
        'gdprConsentGiven': false,
        'gdprConsentTimestamp': null,
      });
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  static Future<void> markTutorialSeen(
    String userId,
    String tutorialKey,
  ) async {
    await _db.collection('users').doc(userId).update({tutorialKey: true});
  }

  /// Record GDPR consent with timestamp
  static Future<void> recordGdprConsent(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'gdprConsentGiven': true,
        'gdprConsentTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to record GDPR consent: $e');
    }
  }
}
