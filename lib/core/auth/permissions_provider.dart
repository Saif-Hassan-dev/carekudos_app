import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';

/// User profile data from Firestore
class UserProfile {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? jobTitle;
  final DateTime? createdAt;
  final int totalStars;
  final int starsThisMonth;
  final int postCount;
  final DateTime? lastPostDate;
  final String? organizationId;
  final String? teamId;
  final List<String> managerIds;
  final bool hasSeenFeedTutorial;
  final bool gdprConsentGiven;
  final DateTime? gdprConsentTimestamp;

  UserProfile({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.jobTitle,
    this.createdAt,
    this.totalStars = 0,
    this.starsThisMonth = 0,
    this.postCount = 0,
    this.lastPostDate,
    this.organizationId,
    this.teamId,
    this.managerIds = const [],
    this.hasSeenFeedTutorial = false,
    this.gdprConsentGiven = false,
    this.gdprConsentTimestamp,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      role: data['role'] ?? 'care_worker',
      jobTitle: data['jobTitle'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,

      totalStars: data['totalStars'] ?? 0,
      starsThisMonth: data['starsThisMonth'] ?? 0,
      postCount: data['postCount'] ?? 0,
      lastPostDate: data['lastPostDate'] != null
          ? (data['lastPostDate'] as Timestamp).toDate()
          : null,
      organizationId: data['organizationId'],
      hasSeenFeedTutorial: data['hasSeenFeedTutorial'] ?? false,
      teamId: data['teamId'],
      managerIds: data['managerIds'] != null
          ? List<String>.from(data['managerIds'])
          : [],
      gdprConsentGiven: data['gdprConsentGiven'] ?? false,
      gdprConsentTimestamp: data['gdprConsentTimestamp'] != null
          ? (data['gdprConsentTimestamp'] as Timestamp).toDate()
          : null,
    );
  }

  String get fullName => '$firstName $lastName';

  bool get isManager => role == 'manager';
  bool get isStaff =>
      role == 'care_worker' || role == 'senior_carer' || role == 'manager';
  bool get isSeniorCarer => role == 'senior_carer';
  bool get isCareWorker => role == 'care_worker';
  bool get isFamilyMember => role == 'family_member';
}

/// Fetch user profile from Firestore
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return UserProfile.fromFirestore(doc);
      });
});

/// Get user role (simple string)
final userRoleProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (profile) => profile?.role,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Check if current user is a manager
final isManagerProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (profile) => profile?.isManager ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Check if current user is staff (care worker or senior carer)
final isStaffProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (profile) => profile?.isStaff ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Check if current user is a family member
final isFamilyMemberProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (profile) => profile?.isFamilyMember ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Check if user can moderate posts (managers only)
final canModerateProvider = Provider<bool>((ref) {
  return ref.watch(isManagerProvider);
});

/// Check if user can give stars (staff and family)
final canGiveStarsProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (profile) {
      if (profile == null) return false;
      return profile.isStaff || profile.isFamilyMember;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Get star multiplier based on role
final starMultiplierProvider = Provider<int>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (profile) {
      if (profile == null) return 1;
      if (profile.isManager) return AppConstants.managerStarMultiplier;
      if (profile.isFamilyMember) return AppConstants.familyStarMultiplier;
      return 1; // Regular staff
    },
    loading: () => 1,
    error: (_, __) => 1,
  );
});
