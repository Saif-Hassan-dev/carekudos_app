import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/constants.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/permissions_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/push_notification_service.dart';

// ─────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────

class DashboardStats {
  final int pendingReviews;
  final int gdprFlags;
  final int activeStaffToday;
  final int totalRecognitionsWeek;

  const DashboardStats({
    this.pendingReviews = 0,
    this.gdprFlags = 0,
    this.activeStaffToday = 0,
    this.totalRecognitionsWeek = 0,
  });
}

class PendingPost {
  final String postId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final String category;
  final bool hasGdprFlag;
  final DateTime createdAt;

  const PendingPost({
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.category,
    this.hasGdprFlag = false,
    required this.createdAt,
  });
}

class CoreValueStat {
  final String name;
  final int count;
  final double percentage;

  const CoreValueStat({
    required this.name,
    required this.count,
    required this.percentage,
  });
}

class RisingStar {
  final String uid;
  final String name;
  final String description;
  final int starsLast60Days;
  final int points;
  final String? profilePhotoBase64;

  const RisingStar({
    required this.uid,
    required this.name,
    required this.description,
    required this.starsLast60Days,
    required this.points,
    this.profilePhotoBase64,
  });
}

class TeamMember {
  final String uid;
  final String name;
  final int totalStars;
  final String? profilePhotoBase64;

  const TeamMember({
    required this.uid,
    required this.name,
    required this.totalStars,
    this.profilePhotoBase64,
  });
}

class RecognitionGap {
  final String uid;
  final String name;
  final String role;
  final String? profilePhotoBase64;

  const RecognitionGap({
    required this.uid,
    required this.name,
    required this.role,
    this.profilePhotoBase64,
  });
}

class ValuesDistribution {
  final Map<String, Map<String, int>> byDay; // day -> {value: count}
  final String mostActiveDay;

  const ValuesDistribution({
    required this.byDay,
    required this.mostActiveDay,
  });
}

class CultureHealthData {
  final double score;
  final double participationRate;
  final double avgStarsPerStaff;
  final double gdprCleanRate;

  const CultureHealthData({
    this.score = 0,
    this.participationRate = 0,
    this.avgStarsPerStaff = 0,
    this.gdprCleanRate = 100,
  });
}

class MoraleTrendPoint {
  final DateTime date;
  final double value;

  const MoraleTrendPoint({required this.date, required this.value});
}

class CqcReportData {
  final int monthlyValuesDistribution;
  final int taggedRecognitions;
  final double valuesAlignmentTrend;

  const CqcReportData({
    this.monthlyValuesDistribution = 0,
    this.taggedRecognitions = 0,
    this.valuesAlignmentTrend = 0,
  });
}

// ─────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────

final _firestore = FirebaseFirestore.instance;

/// The active company values — loaded from the manager's profile.
/// Falls back to AppConstants.careValues if none configured.
final companyValuesProvider = Provider<List<String>>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (p) {
      if (p != null && p.companyValues.isNotEmpty) return p.companyValues;
      return AppConstants.careValues;
    },
    loading: () => AppConstants.careValues,
    error: (_, __) => AppConstants.careValues,
  );
});

/// Dashboard stats (pending, GDPR flags, active staff, weekly recognitions)
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));

  // All posts (single fetch, filter client-side)
  final allPostsSnap = await _firestore
      .collection(AppConstants.postsCollection)
      .get();

  int pendingReviews = 0;
  int gdprFlags = 0;
  int weeklyApproved = 0;
  final activeStaffIds = <String>{};

  for (final doc in allPostsSnap.docs) {
    final data = doc.data();
    final status = data['approvalStatus'] as String?;
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;

    if (status == 'pending') {
      pendingReviews++;
      if (data['gdprFlagged'] == true) gdprFlags++;
    }

    if (createdAt != null) {
      if (createdAt.isAfter(startOfDay)) {
        final authorId = data['authorId'] as String?;
        if (authorId != null) activeStaffIds.add(authorId);
      }
      if (createdAt.isAfter(startOfWeek) && status == 'approved') {
        weeklyApproved++;
      }
    }
  }

  // Total staff count as fallback
  int activeStaff = activeStaffIds.length;
  if (activeStaff == 0) {
    final allStaffSnap = await _firestore
        .collection(AppConstants.usersCollection)
        .get();
    activeStaff = allStaffSnap.docs
        .where((d) {
          final role = d.data()['role'] as String?;
          return role == 'care_worker' || role == 'senior_carer' || role == 'manager';
        })
        .length;
  }

  return DashboardStats(
    pendingReviews: pendingReviews,
    gdprFlags: gdprFlags,
    activeStaffToday: activeStaff,
    totalRecognitionsWeek: weeklyApproved,
  );
});

/// Pending posts for review
final pendingPostsProvider = FutureProvider<List<PendingPost>>((ref) async {
  final snap = await _firestore
      .collection(AppConstants.postsCollection)
      .where('approvalStatus', isEqualTo: 'pending')
      .get();

  final posts = snap.docs.map((doc) {
    final data = doc.data();
    return PendingPost(
      postId: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorRole: data['authorRole'] ?? 'care_worker',
      content: data['content'] ?? '',
      category: data['category'] ?? 'General',
      hasGdprFlag: data['gdprFlagged'] == true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }).toList();

  // Sort client-side (newest first) and limit to 10
  posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return posts.take(10).toList();
});

/// Core values stats
final coreValuesStatsProvider =
    FutureProvider<List<CoreValueStat>>((ref) async {
  final now = DateTime.now();
  final startOfWeek =
      DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

  // Single-field query, filter approvalStatus client-side
  final snap = await _firestore
      .collection(AppConstants.postsCollection)
      .where('approvalStatus', isEqualTo: 'approved')
      .get();

  final activeValues = ref.read(companyValuesProvider);
  final counts = <String, int>{};
  for (final value in activeValues) {
    counts[value] = 0;
  }
  for (final doc in snap.docs) {
    final data = doc.data();
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    if (createdAt == null || createdAt.isBefore(startOfWeek)) continue;

    final category = data['category'] as String? ?? '';
    if (counts.containsKey(category)) {
      counts[category] = counts[category]! + 1;
    }
  }

  final total = counts.values.fold(0, (a, b) => a + b);
  return counts.entries
      .map((e) => CoreValueStat(
            name: e.key,
            count: e.value,
            percentage: total > 0 ? (e.value / total * 100) : 0,
          ))
      .toList();
});

/// Rising stars (top performers last 60 days)
final risingStarsProvider = FutureProvider<List<RisingStar>>((ref) async {
  final cutoff = DateTime.now().subtract(const Duration(days: 60));

  // Single-field query, filter date client-side
  final postSnap = await _firestore
      .collection(AppConstants.postsCollection)
      .where('approvalStatus', isEqualTo: 'approved')
      .get();

  // Filter to last 60 days client-side
  final recentDocs = postSnap.docs.where((doc) {
    final data = doc.data();
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    return createdAt != null && createdAt.isAfter(cutoff);
  });

  // Count stars per author
  final starsByAuthor = <String, int>{};
  for (final doc in recentDocs) {
    final authorId = doc.data()['authorId'] as String? ?? '';
    final stars = doc.data()['stars'] as int? ?? 1;
    starsByAuthor[authorId] = (starsByAuthor[authorId] ?? 0) + stars;
  }

  // Sort by stars desc, take top 3
  final sortedEntries = starsByAuthor.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topEntries = sortedEntries.take(3);

  final results = <RisingStar>[];
  for (final entry in topEntries) {
    final userDoc =
        await _firestore.collection(AppConstants.usersCollection).doc(entry.key).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      results.add(RisingStar(
        uid: entry.key,
        name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
        description: data['jobTitle'] ?? data['role'] ?? 'Care Worker',
        starsLast60Days: entry.value,
        points: data['totalStars'] ?? 0,
        profilePhotoBase64: data['profilePhotoBase64'],
      ));
    }
  }
  return results;
});

/// Team recognition list (all staff sorted by stars)
final teamRecognitionProvider = FutureProvider<List<TeamMember>>((ref) async {
  // Simple query without compound index, sort client-side
  final snap = await _firestore
      .collection(AppConstants.usersCollection)
      .get();

  final members = snap.docs
      .where((doc) {
        final role = doc.data()['role'] as String?;
        return role == 'care_worker' || role == 'senior_carer';
      })
      .map((doc) {
        final data = doc.data();
        return TeamMember(
          uid: doc.id,
          name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          totalStars: data['totalStars'] ?? 0,
          profilePhotoBase64: data['profilePhotoBase64'],
        );
      })
      .toList();

  members.sort((a, b) => b.totalStars.compareTo(a.totalStars));
  return members.take(10).toList();
});

/// Top Value Champions (highest recognition scorers)
final topValueChampionsProvider = FutureProvider<List<TeamMember>>((ref) async {
  // Fetch all, sort client-side to avoid index requirement
  final snap = await _firestore
      .collection(AppConstants.usersCollection)
      .get();

  final members = snap.docs.map((doc) {
    final data = doc.data();
    return TeamMember(
      uid: doc.id,
      name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
      totalStars: data['totalStars'] ?? 0,
      profilePhotoBase64: data['profilePhotoBase64'],
    );
  }).toList();

  members.sort((a, b) => b.totalStars.compareTo(a.totalStars));
  return members.take(5).toList();
});

/// Recognition gaps (staff who received 0 recognitions this week)
final recognitionGapsProvider =
    FutureProvider<List<RecognitionGap>>((ref) async {
  final now = DateTime.now();
  final startOfWeek =
      DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

  // All staff
  final staffSnap = await _firestore
      .collection(AppConstants.usersCollection)
      .where('role', whereIn: ['care_worker', 'senior_carer'])
      .get();

  // Posts this week – collect unique recipient authors
  final weekPostsSnap = await _firestore
      .collection(AppConstants.postsCollection)
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
      .get();

  final recognisedIds = <String>{};
  for (final doc in weekPostsSnap.docs) {
    recognisedIds.add(doc.data()['authorId'] as String? ?? '');
  }

  final gaps = <RecognitionGap>[];
  for (final doc in staffSnap.docs) {
    if (!recognisedIds.contains(doc.id)) {
      final data = doc.data();
      gaps.add(RecognitionGap(
        uid: doc.id,
        name: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
        role: data['jobTitle'] ?? data['role'] ?? 'Care Worker',
        profilePhotoBase64: data['profilePhotoBase64'],
      ));
    }
  }
  return gaps;
});

/// Values distribution by day of week
final valuesDistributionProvider =
    FutureProvider<ValuesDistribution>((ref) async {
  final now = DateTime.now();
  final startOfWeek =
      DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

  // Single-field query, filter date client-side
  final snap = await _firestore
      .collection(AppConstants.postsCollection)
      .where('approvalStatus', isEqualTo: 'approved')
      .get();

  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final activeValues = ref.read(companyValuesProvider);
  final byDay = <String, Map<String, int>>{};
  for (final d in days) {
    byDay[d] = {for (final v in activeValues) v: 0};
  }

  final dayCounts = <String, int>{};
  for (final d in days) {
    dayCounts[d] = 0;
  }

  for (final doc in snap.docs) {
    final data = doc.data();
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    if (createdAt == null || createdAt.isBefore(startOfWeek)) continue;
    final dayIndex = createdAt.weekday - 1; // 0=Mon
    if (dayIndex >= 0 && dayIndex < 7) {
      final dayName = days[dayIndex];
      final category = data['category'] as String? ?? '';
      if (byDay[dayName]!.containsKey(category)) {
        byDay[dayName]![category] = byDay[dayName]![category]! + 1;
      }
      dayCounts[dayName] = (dayCounts[dayName] ?? 0) + 1;
    }
  }

  String mostActive = 'Wednesday';
  int maxCount = 0;
  dayCounts.forEach((day, count) {
    if (count > maxCount) {
      maxCount = count;
      mostActive = day;
    }
  });

  // Expand short name to full
  const fullNames = {
    'Mon': 'Monday',
    'Tue': 'Tuesday',
    'Wed': 'Wednesday',
    'Thu': 'Thursday',
    'Fri': 'Friday',
    'Sat': 'Saturday',
    'Sun': 'Sunday',
  };

  return ValuesDistribution(
    byDay: byDay,
    mostActiveDay: fullNames[mostActive] ?? mostActive,
  );
});

/// Morale trend (last 30 days – posts per day as proxy)
final moraleTrendProvider =
    FutureProvider<List<MoraleTrendPoint>>((ref) async {
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  // Single-field query, filter date client-side
  final snap = await _firestore
      .collection(AppConstants.postsCollection)
      .where('approvalStatus', isEqualTo: 'approved')
      .get();

  // Group by day (filter to last 30 days client-side)
  final countByDay = <String, int>{};
  for (final doc in snap.docs) {
    final data = doc.data();
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    if (createdAt == null || createdAt.isBefore(thirtyDaysAgo)) continue;
    final key = '${createdAt.year}-${createdAt.month}-${createdAt.day}';
    countByDay[key] = (countByDay[key] ?? 0) + 1;
  }

  // Build 30-day series
  final points = <MoraleTrendPoint>[];
  for (int i = 29; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final key = '${day.year}-${day.month}-${day.day}';
    points.add(MoraleTrendPoint(
      date: DateTime(day.year, day.month, day.day),
      value: (countByDay[key] ?? 0).toDouble(),
    ));
  }
  return points;
});

/// Culture health score
final cultureHealthProvider = FutureProvider<CultureHealthData>((ref) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  // All staff (simple fetch, filter client-side)
  final staffSnap = await _firestore
      .collection(AppConstants.usersCollection)
      .get();
  final totalStaff = staffSnap.docs
      .where((d) {
        final role = d.data()['role'] as String?;
        return role == 'care_worker' || role == 'senior_carer' || role == 'manager';
      })
      .length;
  if (totalStaff == 0) {
    return const CultureHealthData(score: 0);
  }

  // All posts (single fetch, filter client-side)
  final allPostsSnap = await _firestore
      .collection(AppConstants.postsCollection)
      .get();

  // Unique approved authors this month
  final authorIds = <String>{};
  int totalStarsMonth = 0;
  int flaggedCount = 0;
  int totalPostsThisMonth = 0;

  for (final doc in allPostsSnap.docs) {
    final data = doc.data();
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    if (createdAt == null || createdAt.isBefore(startOfMonth)) continue;

    totalPostsThisMonth++;
    if (data['gdprFlagged'] == true) flaggedCount++;

    if (data['approvalStatus'] == 'approved') {
      authorIds.add(data['authorId'] as String? ?? '');
      totalStarsMonth += (data['stars'] as int?) ?? 1;
    }
  }

  final participationRate = (authorIds.length / totalStaff * 100).clamp(0, 100);
  final avgStarsPerStaff = totalStarsMonth / totalStaff;

  final totalPosts = totalPostsThisMonth;
  final gdprCleanRate =
      totalPosts > 0 ? ((totalPosts - flaggedCount) / totalPosts * 100) : 100.0;

  // Culture health score = weighted average
  final score = (participationRate * 0.4 +
          (avgStarsPerStaff * 10).clamp(0, 100) * 0.3 +
          gdprCleanRate * 0.3)
      .clamp(0, 100);

  return CultureHealthData(
    score: score.toDouble(),
    participationRate: participationRate.toDouble(),
    avgStarsPerStaff: avgStarsPerStaff,
    gdprCleanRate: gdprCleanRate,
  );
});

/// CQC Evidence Report data
final cqcReportProvider = FutureProvider<CqcReportData>((ref) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  // Single-field query, filter date client-side
  final snap = await _firestore
      .collection(AppConstants.postsCollection)
      .where('approvalStatus', isEqualTo: 'approved')
      .get();

  // Count posts with category tags (filtered to this month)
  int taggedCount = 0;
  final valueCounts = <String, int>{};
  for (final doc in snap.docs) {
    final data = doc.data();
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    if (createdAt == null || createdAt.isBefore(startOfMonth)) continue;
    final cat = data['category'] as String? ?? '';
    final activeValues = ref.read(companyValuesProvider);
    if (activeValues.contains(cat)) {
      taggedCount++;
      valueCounts[cat] = (valueCounts[cat] ?? 0) + 1;
    }
  }

  final totalValues = ref.read(companyValuesProvider).length;
  final coveredValues = valueCounts.length;
  final alignmentTrend =
      totalValues > 0 ? (coveredValues / totalValues * 100) : 0.0;

  return CqcReportData(
    monthlyValuesDistribution: valueCounts.length,
    taggedRecognitions: taggedCount,
    valuesAlignmentTrend: alignmentTrend,
  );
});

// ─────────────────────────────────────────────────────
// Moderation Log model
// ─────────────────────────────────────────────────────

class ModerationLog {
  final String postId;
  final String managerId;
  final String action; // 'approved', 'rejected', 'edit_requested'
  final String? reason;
  final DateTime timestamp;

  const ModerationLog({
    required this.postId,
    required this.managerId,
    required this.action,
    this.reason,
    required this.timestamp,
  });
}

/// Provider for moderation logs (recent 50)
final moderationLogsProvider = FutureProvider<List<ModerationLog>>((ref) async {
  final snap = await _firestore
      .collection('moderation_logs')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .get();

  return snap.docs.map((doc) {
    final data = doc.data();
    return ModerationLog(
      postId: data['postId'] ?? '',
      managerId: data['managerId'] ?? '',
      action: data['action'] ?? '',
      reason: data['reason'] as String?,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }).toList();
});

// ─────────────────────────────────────────────────────
// Actions
// ─────────────────────────────────────────────────────

/// Write a moderation log entry (non-blocking – never throws)
Future<void> _logModerationAction({
  required String postId,
  required String managerId,
  required String action,
  String? reason,
}) async {
  try {
    await _firestore.collection('moderation_logs').add({
      'postId': postId,
      'managerId': managerId,
      'action': action,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('[ModerationLog] Failed to log action: $e');
  }
}

/// Approve a post and notify the author
Future<void> approvePost(String postId, String managerId) async {
  // 1. Update the post status (the core action)
  await _firestore.collection(AppConstants.postsCollection).doc(postId).update({
    'approvalStatus': 'approved',
    'approvedBy': managerId,
    'approvedAt': FieldValue.serverTimestamp(),
  });

  // 2. Log moderation action (non-blocking)
  await _logModerationAction(
    postId: postId,
    managerId: managerId,
    action: 'approved',
  );

  // 3. Notify the post author (best-effort)
  try {
    final postDoc = await _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .get();
    final authorId = postDoc.data()?['authorId'] as String?;
    if (authorId != null && authorId.isNotEmpty) {
      await NotificationService.createNotification(
        userId: authorId,
        type: NotificationType.postApproved,
        title: 'Post Approved!',
        message: 'Your post has been approved and is now live in the feed.',
        relatedPostId: postId,
        relatedUserId: managerId,
      );
      await PushNotificationService.sendPushNotification(
        recipientId: authorId,
        title: 'Post Approved!',
        body: 'Your post has been approved and is now live in the feed.',
        data: {'type': 'postApproved', 'postId': postId},
      );
    }
  } catch (e) {
    debugPrint('[ApprovePost] Notification failed: $e');
  }
}

/// Reject a post (with GDPR violation explanation)
Future<void> rejectPost(String postId, String managerId, {String? reason}) async {
  await _firestore.collection(AppConstants.postsCollection).doc(postId).update({
    'approvalStatus': 'rejected',
    'rejectedBy': managerId,
    'rejectedAt': FieldValue.serverTimestamp(),
    if (reason != null && reason.isNotEmpty) 'rejectionReason': reason,
  });
  await _logModerationAction(
    postId: postId,
    managerId: managerId,
    action: 'rejected',
    reason: reason,
  );
}

/// Request edits on a post
Future<void> requestEditPost(String postId, String managerId, {String? reason}) async {
  await _firestore.collection(AppConstants.postsCollection).doc(postId).update({
    'approvalStatus': 'edit_requested',
    'editRequestedBy': managerId,
    'editRequestedAt': FieldValue.serverTimestamp(),
    if (reason != null && reason.isNotEmpty) 'editRequestReason': reason,
  });
  await _logModerationAction(
    postId: postId,
    managerId: managerId,
    action: 'edit_requested',
    reason: reason,
  );

  // Notify the author that edits are needed (best-effort)
  try {
    final postDoc = await _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .get();
    final authorId = postDoc.data()?['authorId'] as String?;
    if (authorId != null && authorId.isNotEmpty) {
      await NotificationService.createNotification(
        userId: authorId,
        type: NotificationType.system,
        title: 'Edits Requested',
        message: reason != null && reason.isNotEmpty
            ? 'A manager has requested edits on your post: $reason'
            : 'A manager has requested edits on your post. Please review and update it.',
        relatedPostId: postId,
        relatedUserId: managerId,
      );
    }
  } catch (e) {
    debugPrint('[RequestEdit] Notification failed: $e');
  }
}

/// Give a manager star to a staff member.
/// Finds their latest approved post and gives a 3x star to it.
/// Returns the postId that was starred, or null if no post found.
Future<String?> giveManagerStarToUser({
  required String staffUid,
  required String managerId,
  required String managerName,
  String? note,
  int? starPoints,
}) async {
  final points = starPoints ?? AppConstants.managerStarMultiplier;
  // Find user's latest approved post
  final snap = await _firestore
      .collection(AppConstants.postsCollection)
      .where('authorId', isEqualTo: staffUid)
      .get();

  // Filter to approved, sort by createdAt desc, take first
  final approvedDocs = snap.docs.where((doc) {
    final data = doc.data();
    return data['approvalStatus'] == 'approved' || data['approvalStatus'] == null;
  }).toList();
  approvedDocs.sort((a, b) {
    final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
    final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
    return bTime.compareTo(aTime);
  });

  if (approvedDocs.isEmpty) return null;

  final postDoc = approvedDocs.first;
  final postData = postDoc.data();
  final postId = postDoc.id;
  final category = postData['category'] as String? ?? 'General';

  final batch = _firestore.batch();

  // 1. Increment post stars
  batch.update(
    _firestore.collection(AppConstants.postsCollection).doc(postId),
    {
      'stars': FieldValue.increment(points),
      'starredBy': FieldValue.arrayUnion([managerId]),
    },
  );

  // 2. Increment user's total stars
  batch.update(
    _firestore.collection(AppConstants.usersCollection).doc(staffUid),
    {
      'totalStars': FieldValue.increment(points),
      'starsThisMonth': FieldValue.increment(points),
    },
  );

  // 3. Record in star_history
  final historyRef = _firestore.collection('star_history').doc();
  batch.set(historyRef, {
    'giverId': managerId,
    'receiverId': staffUid,
    'postId': postId,
    'starType': 'Manager',
    'points': points,
    'note': note,
    'category': category,
    'giverName': managerName,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await batch.commit();
  return postId;
}
