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
    String? phone,
    String? postcode,
    String? organizationId,
    String? teamId,
    bool gdprConsent = false,
    // New fields
    DateTime? dateOfBirth,
    String? preferredContactMethod,
    String? fullAddress,
    String? professionalRegNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? profilePhotoBase64,
    bool agreeToUpdates = false,
  }) async {
    try {
      await _db.collection('users').doc(userId).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'jobTitle': jobTitle,
        'phone': phone,
        'postcode': postcode,
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

        // GDPR consent
        'gdprConsentGiven': gdprConsent,
        'gdprConsentTimestamp': gdprConsent ? FieldValue.serverTimestamp() : null,

        // New profile fields
        'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : null,
        'preferredContactMethod': preferredContactMethod,
        'fullAddress': fullAddress,
        'professionalRegNumber': professionalRegNumber,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'profilePhotoBase64': profilePhotoBase64,
        'agreeToUpdates': agreeToUpdates,
      });
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
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
