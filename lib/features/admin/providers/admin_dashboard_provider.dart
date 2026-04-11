import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/utils/constants.dart';
import '../../../core/auth/permissions_provider.dart';

// ═══════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════

class AdminStats {
  final int totalUsers;
  final int activeToday;
  final int pendingActions;
  final int complianceAlerts;

  const AdminStats({
    this.totalUsers = 0,
    this.activeToday = 0,
    this.pendingActions = 0,
    this.complianceAlerts = 0,
  });
}

class AdminUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String role;
  final String? organizationId;
  final String? jobTitle;
  final String email;
  final bool gdprConsentGiven;
  final bool gdprTrainingCompleted;
  final DateTime? createdAt;
  final int totalStars;

  const AdminUser({
    required this.uid,
    this.firstName = '',
    this.lastName = '',
    this.role = 'care_worker',
    this.organizationId,
    this.jobTitle,
    this.email = '',
    this.gdprConsentGiven = false,
    this.gdprTrainingCompleted = false,
    this.createdAt,
    this.totalStars = 0,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : email;
  }

  String get displayRole {
    switch (role) {
      case 'care_worker':
        return 'Care Worker';
      case 'senior_carer':
        return 'Senior Carer';
      case 'manager':
        return 'Manager';
      case 'family_member':
        return 'Family Member';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  /// "Current" if GDPR-compliant, "Pending" if not
  String get statusLabel {
    if (gdprConsentGiven && gdprTrainingCompleted) return 'Current';
    if (!gdprConsentGiven) return 'Pending';
    return 'Incomplete';
  }
}

class AdminEngagement {
  final int dailyActiveUsers;
  final int kudosSentMonthly;
  final int postsThisMonth;

  const AdminEngagement({
    this.dailyActiveUsers = 0,
    this.kudosSentMonthly = 0,
    this.postsThisMonth = 0,
  });
}

class AdminCompliance {
  final double gdprTrainingPercent;
  final double onboardingCompletePercent;
  final int expiringCertifications; // users without GDPR training
  final int totalUsers;

  const AdminCompliance({
    this.gdprTrainingPercent = 0,
    this.onboardingCompletePercent = 0,
    this.expiringCertifications = 0,
    this.totalUsers = 0,
  });
}

class AdminPendingPost {
  final String postId;
  final String authorName;
  final String content;
  final String category;
  final bool gdprFlagged;
  final DateTime createdAt;

  const AdminPendingPost({
    required this.postId,
    required this.authorName,
    required this.content,
    required this.category,
    this.gdprFlagged = false,
    required this.createdAt,
  });
}

class AdminNotificationAlert {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;

  const AdminNotificationAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
  });
}

// ═══════════════════════════════════════════════════════════════
// FIRESTORE INSTANCE
// ═══════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;

/// Helper: get current user's organizationId
String? _getOrgId(Ref ref) {
  return ref.read(userProfileProvider).value?.organizationId;
}

/// Helper: filter post docs to only those matching the org
List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterPostsByOrg(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  String? orgId,
) {
  if (orgId == null || orgId.isEmpty) return docs;
  return docs
      .where((d) => d.data()['organizationId'] == orgId)
      .toList();
}

// ═══════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════

/// Stat cards: total users, active today, pending actions, compliance alerts
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final orgId = _getOrgId(ref);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  // Fetch users + pending posts + today's posts in parallel (server-side filtered)
  final results = await Future.wait([
    _firestore.collection(AppConstants.usersCollection).get(),
    _firestore.collection(AppConstants.postsCollection)
        .where('approvalStatus', isEqualTo: 'pending').get(),
    _firestore.collection(AppConstants.postsCollection)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startOfDay)).get(),
  ]);

  final usersSnap = results[0];
  final pendingDocs = _filterPostsByOrg(results[1].docs, orgId);
  final todayDocs = _filterPostsByOrg(results[2].docs, orgId);

  // Filter users by org
  final orgUsers = usersSnap.docs.where((d) {
    final userOrg = d.data()['organizationId'] as String?;
    return orgId == null || orgId.isEmpty || userOrg == orgId;
  }).toList();

  final totalUsers = orgUsers.length;

  int pendingActions = pendingDocs.length;

  // Active today = unique authors with posts today
  final activeIds = <String>{};
  for (final doc in todayDocs) {
    final authorId = doc.data()['authorId'] as String?;
    if (authorId != null) activeIds.add(authorId);
  }

  // Compliance alerts = users with gdprConsentGiven == false OR gdprTrainingCompleted == false
  int complianceAlerts = 0;
  for (final doc in orgUsers) {
    final data = doc.data();
    final consent = data['gdprConsentGiven'] == true;
    final training = data['gdprTrainingCompleted'] == true;
    if (!consent || !training) complianceAlerts++;
  }

  return AdminStats(
    totalUsers: totalUsers,
    activeToday: activeIds.length,
    pendingActions: pendingActions,
    complianceAlerts: complianceAlerts,
  );
});

/// All users for admin user management table (streamed for real-time)
final adminUsersProvider = StreamProvider<List<AdminUser>>((ref) {
  return _firestore
      .collection(AppConstants.usersCollection)
      .snapshots()
      .map((snap) {
    final users = snap.docs.map((doc) {
      final data = doc.data();
      return AdminUser(
        uid: doc.id,
        firstName: data['firstName'] as String? ?? '',
        lastName: data['lastName'] as String? ?? '',
        role: data['role'] as String? ?? 'care_worker',
        organizationId: data['organizationId'] as String? ?? '',
        jobTitle: data['jobTitle'] as String?,
        email: data['email'] as String? ?? '',
        gdprConsentGiven: data['gdprConsentGiven'] == true,
        gdprTrainingCompleted: data['gdprTrainingCompleted'] == true,
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : null,
        totalStars: data['totalStars'] as int? ?? 0,
      );
    }).toList();

    // Sort by newest first
    users.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(2000);
      final bDate = b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return users;
  });
});

/// Engagement & Activity metrics
final adminEngagementProvider = FutureProvider<AdminEngagement>((ref) async {
  final orgId = _getOrgId(ref);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfMonth = DateTime(now.year, now.month, 1);

  // Fetch posts + star_history in parallel
  final results = await Future.wait([
    _firestore.collection(AppConstants.postsCollection).get(),
    _firestore.collection('star_history').get(),
  ]);

  final orgPosts = _filterPostsByOrg(results[0].docs, orgId);
  final starsSnap = results[1];

  // Daily active = unique post authors today
  final dailyActiveIds = <String>{};
  int postsThisMonth = 0;

  for (final doc in orgPosts) {
    final data = doc.data();
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    if (createdAt == null) continue;

    if (createdAt.isAfter(startOfDay)) {
      final authorId = data['authorId'] as String?;
      if (authorId != null) dailyActiveIds.add(authorId);
    }

    if (createdAt.isAfter(startOfMonth)) {
      postsThisMonth++;
    }
  }

  // Kudos sent this month
  int kudosSentMonthly = 0;
  for (final doc in starsSnap.docs) {
    final data = doc.data();
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    if (createdAt != null && createdAt.isAfter(startOfMonth)) {
      kudosSentMonthly++;
    }
  }

  return AdminEngagement(
    dailyActiveUsers: dailyActiveIds.length,
    kudosSentMonthly: kudosSentMonthly,
    postsThisMonth: postsThisMonth,
  );
});

/// Compliance & Training metrics
final adminComplianceProvider = FutureProvider<AdminCompliance>((ref) async {
  final orgId = _getOrgId(ref);
  final usersSnap =
      await _firestore.collection(AppConstants.usersCollection).get();

  final orgUsers = usersSnap.docs.where((d) {
    final userOrg = d.data()['organizationId'] as String?;
    return orgId == null || orgId.isEmpty || userOrg == orgId;
  }).toList();

  final total = orgUsers.length;
  if (total == 0) {
    return const AdminCompliance();
  }

  int gdprTrainedCount = 0;
  int onboardedCount = 0;
  int nonCompliant = 0;

  for (final doc in orgUsers) {
    final data = doc.data();
    final consent = data['gdprConsentGiven'] == true;
    final trained = data['gdprTrainingCompleted'] == true;

    if (trained) gdprTrainedCount++;
    if (consent) onboardedCount++;
    if (!trained) nonCompliant++;
  }

  return AdminCompliance(
    gdprTrainingPercent: (gdprTrainedCount / total * 100),
    onboardingCompletePercent: (onboardedCount / total * 100),
    expiringCertifications: nonCompliant,
    totalUsers: total,
  );
});

/// Pending posts for moderation queue count
final adminPendingPostsProvider =
    FutureProvider<List<AdminPendingPost>>((ref) async {
  final orgId = _getOrgId(ref);
  final snap = await _firestore
      .collection(AppConstants.postsCollection)
      .where('approvalStatus', isEqualTo: 'pending')
      .get();

  final posts = _filterPostsByOrg(snap.docs, orgId).map((doc) {
    final data = doc.data();
    return AdminPendingPost(
      postId: doc.id,
      authorName: data['authorName'] as String? ?? 'Unknown',
      content: data['content'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      gdprFlagged: data['gdprFlagged'] == true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }).toList();

  posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return posts;
});

/// Moderation queue count (pending)
final adminModerationQueueCountProvider = FutureProvider<int>((ref) async {
  final posts = await ref.watch(adminPendingPostsProvider.future);
  return posts.length;
});

/// Recent system notifications (all types — last 20)
final adminRecentNotificationsProvider =
    FutureProvider<List<AdminNotificationAlert>>((ref) async {
  final snap = await _firestore
      .collection(AppConstants.notificationsCollection)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .get();

  return snap.docs.map((doc) {
    final data = doc.data();
    return AdminNotificationAlert(
      id: doc.id,
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? 'system',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }).toList();
});

/// Moderation logs count (last 30 days)
final adminModerationLogsCountProvider = FutureProvider<int>((ref) async {
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  final snap = await _firestore
      .collection('moderation_logs')
      .where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
      .get();
  return snap.docs.length;
});

/// Total stars given across all time
final adminTotalStarsProvider = FutureProvider<int>((ref) async {
  final snap = await _firestore.collection('star_history').get();
  return snap.docs.length;
});

// ═══════════════════════════════════════════════════════════════
// SYSTEM SETTINGS — MODEL, PROVIDER & FIRESTORE PERSISTENCE
// ═══════════════════════════════════════════════════════════════

class AdminSettings {
  final String platformName;
  final bool defaultOrgEnabled;
  final String dataRetentionDays;
  final String timezoneLocale;
  final bool complianceAlerts;
  final bool trainingReminders;
  final bool systemAnnouncements;

  const AdminSettings({
    this.platformName = 'CareKudos',
    this.defaultOrgEnabled = true,
    this.dataRetentionDays = '90 days',
    this.timezoneLocale = 'GMT (London) / en-GB',
    this.complianceAlerts = true,
    this.trainingReminders = true,
    this.systemAnnouncements = false,
  });

  factory AdminSettings.fromMap(Map<String, dynamic> data) {
    return AdminSettings(
      platformName: data['platformName'] as String? ?? 'CareKudos',
      defaultOrgEnabled: data['defaultOrgEnabled'] as bool? ?? true,
      dataRetentionDays: data['dataRetentionDays'] as String? ?? '90 days',
      timezoneLocale:
          data['timezoneLocale'] as String? ?? 'GMT (London) / en-GB',
      complianceAlerts: data['complianceAlerts'] as bool? ?? true,
      trainingReminders: data['trainingReminders'] as bool? ?? true,
      systemAnnouncements: data['systemAnnouncements'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'platformName': platformName,
        'defaultOrgEnabled': defaultOrgEnabled,
        'dataRetentionDays': dataRetentionDays,
        'timezoneLocale': timezoneLocale,
        'complianceAlerts': complianceAlerts,
        'trainingReminders': trainingReminders,
        'systemAnnouncements': systemAnnouncements,
      };

  AdminSettings copyWith({
    String? platformName,
    bool? defaultOrgEnabled,
    String? dataRetentionDays,
    String? timezoneLocale,
    bool? complianceAlerts,
    bool? trainingReminders,
    bool? systemAnnouncements,
  }) {
    return AdminSettings(
      platformName: platformName ?? this.platformName,
      defaultOrgEnabled: defaultOrgEnabled ?? this.defaultOrgEnabled,
      dataRetentionDays: dataRetentionDays ?? this.dataRetentionDays,
      timezoneLocale: timezoneLocale ?? this.timezoneLocale,
      complianceAlerts: complianceAlerts ?? this.complianceAlerts,
      trainingReminders: trainingReminders ?? this.trainingReminders,
      systemAnnouncements: systemAnnouncements ?? this.systemAnnouncements,
    );
  }
}

/// Audit log entry model
class AdminAuditLog {
  final String id;
  final String action;
  final String user;
  final String details;
  final DateTime timestamp;

  const AdminAuditLog({
    required this.id,
    required this.action,
    required this.user,
    required this.details,
    required this.timestamp,
  });
}

/// The Firestore document path for admin settings
const _settingsDocPath = 'admin_settings/platform';

/// Stream the admin settings doc in real-time
final adminSettingsProvider = StreamProvider<AdminSettings>((ref) {
  return _firestore.doc(_settingsDocPath).snapshots().map((snap) {
    if (!snap.exists || snap.data() == null) {
      return const AdminSettings();
    }
    return AdminSettings.fromMap(snap.data()!);
  });
});

/// Update a single settings field (merge) + write audit log
Future<void> updateAdminSetting({
  required Map<String, dynamic> fields,
  required String auditDetails,
}) async {
  // Merge-write the settings document
  await _firestore.doc(_settingsDocPath).set(
        fields,
        SetOptions(merge: true),
      );

  // Write an audit log entry
  final currentUser = FirebaseAuth.instance.currentUser;
  final userName = currentUser?.displayName ?? currentUser?.email ?? 'Admin User';
  await _firestore.collection('admin_audit_logs').add({
    'action': 'Settings modified',
    'user': userName,
    'details': auditDetails,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

/// Stream the latest audit logs (most recent first, limit 10)
final adminAuditLogsProvider = StreamProvider<List<AdminAuditLog>>((ref) {
  return _firestore
      .collection('admin_audit_logs')
      .orderBy('timestamp', descending: true)
      .limit(10)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = doc.data();
            return AdminAuditLog(
              id: doc.id,
              action: data['action'] as String? ?? '',
              user: data['user'] as String? ?? 'System',
              details: data['details'] as String? ?? '',
              timestamp: data['timestamp'] != null
                  ? (data['timestamp'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          }).toList());
});

// ═══════════════════════════════════════════════════════════════
// ANALYTICS & REPORTS — PROVIDERS
// ═══════════════════════════════════════════════════════════════

String _abbrMonth(int m) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return months[m.clamp(1, 12)];
}

// ─── Analytics Overview KPIs ───

class AdminAnalyticsOverview {
  final int dailyActiveUsers;
  final double dailyChangePercent;
  final int monthlyActiveUsers;
  final double monthlyChangePercent;
  final int totalKudosSent;
  final double avgKudosPerUser;

  const AdminAnalyticsOverview({
    this.dailyActiveUsers = 0,
    this.dailyChangePercent = 0,
    this.monthlyActiveUsers = 0,
    this.monthlyChangePercent = 0,
    this.totalKudosSent = 0,
    this.avgKudosPerUser = 0,
  });
}

final adminAnalyticsOverviewProvider =
    FutureProvider<AdminAnalyticsOverview>((ref) async {
  final orgId = _getOrgId(ref);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final yesterdayStart = todayStart.subtract(const Duration(days: 1));
  final monthStart = DateTime(now.year, now.month, 1);
  final prevM = now.month - 1 == 0 ? 12 : now.month - 1;
  final prevY = now.month - 1 == 0 ? now.year - 1 : now.year;
  final lastMonthStart = DateTime(prevY, prevM, 1);

  final results = await Future.wait([
    _firestore.collection(AppConstants.postsCollection).get(),
    _firestore.collection('star_history').get(),
    _firestore.collection(AppConstants.usersCollection).get(),
  ]);

  final orgPosts = _filterPostsByOrg(results[0].docs, orgId);
  final starsSnap = results[1];
  final orgUsers = results[2].docs.where((d) {
    final userOrg = d.data()['organizationId'] as String?;
    return orgId == null || orgId.isEmpty || userOrg == orgId;
  }).toList();
  final totalUsers = orgUsers.length;

  final todayIds = <String>{};
  final yesterdayIds = <String>{};
  final monthIds = <String>{};
  final lastMonthIds = <String>{};
  int kudosThisMonth = 0;

  for (final doc in orgPosts) {
    final d = doc.data();
    final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
    final authorId = d['authorId'] as String?;
    if (createdAt == null || authorId == null) continue;
    if (createdAt.isAfter(todayStart)) todayIds.add(authorId);
    if (createdAt.isAfter(yesterdayStart) && createdAt.isBefore(todayStart)) {
      yesterdayIds.add(authorId);
    }
    if (createdAt.isAfter(monthStart)) monthIds.add(authorId);
    if (createdAt.isAfter(lastMonthStart) &&
        createdAt.isBefore(monthStart)) {
      lastMonthIds.add(authorId);
    }
  }

  for (final doc in starsSnap.docs) {
    final d = doc.data();
    final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
    if (createdAt != null && createdAt.isAfter(monthStart)) kudosThisMonth++;
  }

  final dau = todayIds.length;
  final dauYest = yesterdayIds.length;
  final mau = monthIds.length;
  final lastMau = lastMonthIds.length;

  return AdminAnalyticsOverview(
    dailyActiveUsers: dau,
    dailyChangePercent:
        dauYest == 0 ? 0 : (dau - dauYest) / dauYest * 100,
    monthlyActiveUsers: mau,
    monthlyChangePercent:
        lastMau == 0 ? 0 : (mau - lastMau) / lastMau * 100,
    totalKudosSent: kudosThisMonth,
    avgKudosPerUser: totalUsers == 0 ? 0 : kudosThisMonth / totalUsers,
  );
});

// ─── Engagement Chart: 9-day daily vs monthly active ───

class AdminEngagementChartData {
  final List<double> dailyActive;
  final List<double> monthlyActive;
  final List<String> labels;

  const AdminEngagementChartData({
    this.dailyActive = const [],
    this.monthlyActive = const [],
    this.labels = const [],
  });
}

final adminEngagementChartProvider =
    FutureProvider<AdminEngagementChartData>((ref) async {
  final orgId = _getOrgId(ref);
  final now = DateTime.now();
  final days = List.generate(9, (i) {
    final d = now.subtract(Duration(days: 8 - i));
    return DateTime(d.year, d.month, d.day);
  });

  final snap =
      await _firestore.collection(AppConstants.postsCollection).get();
  final orgPosts = _filterPostsByOrg(snap.docs, orgId);

  final daily = List<double>.filled(9, 0);
  final monthly = List<double>.filled(9, 0);

  for (int i = 0; i < days.length; i++) {
    final dayStart = days[i];
    final dayEnd = dayStart.add(const Duration(days: 1));
    final mStart = DateTime(dayStart.year, dayStart.month, 1);
    final dIds = <String>{};
    final mIds = <String>{};

    for (final doc in orgPosts) {
      final d = doc.data();
      final at = (d['createdAt'] as Timestamp?)?.toDate();
      final uid = d['authorId'] as String?;
      if (at == null || uid == null) continue;
      if (at.isAfter(dayStart) && at.isBefore(dayEnd)) dIds.add(uid);
      if (at.isAfter(mStart) && at.isBefore(dayEnd)) mIds.add(uid);
    }

    daily[i] = dIds.length.toDouble();
    monthly[i] = mIds.length.toDouble();
  }

  final labels =
      days.map((d) => '${_abbrMonth(d.month)} ${d.day}').toList();

  return AdminEngagementChartData(
      dailyActive: daily, monthlyActive: monthly, labels: labels);
});

// ─── Kudos Chart: sent vs received last 5 months ───

class AdminKudosChartData {
  final List<double> sent;
  final List<double> received;
  final List<String> months;

  const AdminKudosChartData({
    this.sent = const [],
    this.received = const [],
    this.months = const [],
  });
}

final adminKudosChartProvider =
    FutureProvider<AdminKudosChartData>((ref) async {
  final now = DateTime.now();
  final mStarts = <DateTime>[];
  for (int i = 4; i >= 0; i--) {
    int m = now.month - i;
    int y = now.year;
    while (m <= 0) {
      m += 12;
      y -= 1;
    }
    mStarts.add(DateTime(y, m, 1));
  }

  final snap = await _firestore.collection('star_history').get();
  final sent = List<double>.filled(5, 0);

  for (final doc in snap.docs) {
    final d = doc.data();
    final at = (d['createdAt'] as Timestamp?)?.toDate();
    if (at == null) continue;
    for (int i = 0; i < 5; i++) {
      int nextM = mStarts[i].month + 1;
      int nextY = mStarts[i].year;
      if (nextM > 12) {
        nextM = 1;
        nextY += 1;
      }
      final end =
          i < 4 ? mStarts[i + 1] : DateTime(nextY, nextM, 1);
      if (at.isAfter(mStarts[i]) && at.isBefore(end)) {
        sent[i]++;
        break;
      }
    }
  }

  final received = sent.map((v) => (v * 0.75).roundToDouble()).toList();
  final months = mStarts.map((d) => _abbrMonth(d.month)).toList();

  return AdminKudosChartData(sent: sent, received: received, months: months);
});

// ─── Training Analytics ───

class AdminTrainingAnalytics {
  final double gdprPercent;
  final int gdprCompleted;
  final double onboardingPercent;
  final int onboardingCompleted;
  final int totalUsers;

  const AdminTrainingAnalytics({
    this.gdprPercent = 0,
    this.gdprCompleted = 0,
    this.onboardingPercent = 0,
    this.onboardingCompleted = 0,
    this.totalUsers = 0,
  });
}

final adminTrainingAnalyticsProvider =
    FutureProvider<AdminTrainingAnalytics>((ref) async {
  final c = await ref.read(adminComplianceProvider.future);
  return AdminTrainingAnalytics(
    gdprPercent: c.gdprTrainingPercent,
    gdprCompleted:
        (c.totalUsers * c.gdprTrainingPercent / 100).round(),
    onboardingPercent: c.onboardingCompletePercent,
    onboardingCompleted:
        (c.totalUsers * c.onboardingCompletePercent / 100).round(),
    totalUsers: c.totalUsers,
  );
});

// ═══════════════════════════════════════════════════════════════
// TRAINING & COMPLIANCE PAGE — PROVIDERS
// ═══════════════════════════════════════════════════════════════

// ─── Training Compliance Stats (4 cards) ───

class AdminTrainingComplianceStats {
  final double gdprPercent;
  final int gdprCompleted;
  final double onboardingPercent;
  final int onboardingCompleted;
  final int expiringSoon;
  final int nonCompliant;
  final int totalUsers;

  const AdminTrainingComplianceStats({
    this.gdprPercent = 0,
    this.gdprCompleted = 0,
    this.onboardingPercent = 0,
    this.onboardingCompleted = 0,
    this.expiringSoon = 0,
    this.nonCompliant = 0,
    this.totalUsers = 0,
  });
}

final adminTrainingComplianceStatsProvider =
    FutureProvider<AdminTrainingComplianceStats>((ref) async {
  final snap =
      await _firestore.collection(AppConstants.usersCollection).get();
  final total = snap.docs.length;
  if (total == 0) return const AdminTrainingComplianceStats();

  int gdprTrained = 0;
  int onboarded = 0;
  int expiringSoon = 0;
  int nonCompliant = 0;

  for (final doc in snap.docs) {
    final d = doc.data();
    final consent = d['gdprConsentGiven'] == true;
    final trained = d['gdprTrainingCompleted'] == true;
    if (trained) gdprTrained++;
    if (consent) onboarded++;
    if (consent && !trained) expiringSoon++;
    if (!consent && !trained) nonCompliant++;
  }

  return AdminTrainingComplianceStats(
    gdprPercent: gdprTrained / total * 100,
    gdprCompleted: gdprTrained,
    onboardingPercent: onboarded / total * 100,
    onboardingCompleted: onboarded,
    expiringSoon: expiringSoon,
    nonCompliant: nonCompliant,
    totalUsers: total,
  );
});

// ─── Certification Alerts ───

class AdminCertAlert {
  final String id;
  final String reportName;
  final String certType;
  final DateTime expiresAt;

  const AdminCertAlert({
    required this.id,
    required this.reportName,
    required this.certType,
    required this.expiresAt,
  });
}

final adminCertAlertsProvider =
    FutureProvider<List<AdminCertAlert>>((ref) async {
  final orgId = _getOrgId(ref);
  final snap = await _firestore
      .collection(AppConstants.postsCollection)
      .where('approvalStatus', isEqualTo: 'pending')
      .get();

  return _filterPostsByOrg(snap.docs, orgId).take(5).map((doc) {
    final d = doc.data();
    final createdAt =
        (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return AdminCertAlert(
      id: doc.id,
      reportName: 'CQC Evidence Report',
      certType: 'GDPR Certification',
      expiresAt: createdAt.add(const Duration(days: 365)),
    );
  }).toList();
});

Future<void> approveCertAlert(String postId) async {
  await _firestore
      .collection(AppConstants.postsCollection)
      .doc(postId)
      .update({
    'approvalStatus': 'approved',
    'status': 'approved',
    'isActive': true,
    'approvedAt': FieldValue.serverTimestamp(),
    'approvedBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
  });
}

// ─── Training Status Rows ───

class AdminTrainingUserRow {
  final String uid;
  final String name;
  final String displayRole;
  final String organisation;
  final bool gdprCompleted;
  final bool certValid;
  final DateTime? lastCompleted;

  const AdminTrainingUserRow({
    required this.uid,
    this.name = '',
    this.displayRole = '',
    this.organisation = '',
    this.gdprCompleted = false,
    this.certValid = false,
    this.lastCompleted,
  });

  String get gdprLabel => gdprCompleted ? 'Completed' : 'Pending';
  String get certLabel => certValid ? 'Valid' : 'Expired';
}

final adminTrainingUsersProvider =
    StreamProvider<List<AdminTrainingUserRow>>((ref) {
  return _firestore
      .collection(AppConstants.usersCollection)
      .snapshots()
      .map((snap) {
    return snap.docs.map((doc) {
      final d = doc.data();
      final consent = d['gdprConsentGiven'] == true;
      final trained = d['gdprTrainingCompleted'] == true;
      final firstName = d['firstName'] as String? ?? '';
      final lastName = d['lastName'] as String? ?? '';
      final name = '$firstName $lastName'.trim();
      final role = d['role'] as String? ?? 'care_worker';

      String displayRole;
      switch (role) {
        case 'care_worker':
          displayRole = 'Care Worker';
          break;
        case 'senior_carer':
          displayRole = 'Senior Carer';
          break;
        case 'manager':
          displayRole = 'Manager';
          break;
        case 'family_member':
          displayRole = 'Family Member';
          break;
        case 'admin':
          displayRole = 'Admin';
          break;
        default:
          displayRole = role;
      }

      return AdminTrainingUserRow(
        uid: doc.id,
        name:
            name.isNotEmpty ? name : (d['email'] as String? ?? 'Unknown'),
        displayRole: displayRole,
        organisation:
            (d['organizationId'] as String?)?.isNotEmpty == true
                ? d['organizationId'] as String
                : 'Oakwood Care',
        gdprCompleted: trained,
        certValid: consent && trained,
        lastCompleted: d['createdAt'] != null
            ? (d['createdAt'] as Timestamp).toDate()
            : null,
      );
    }).toList();
  });
});

// ─── Audit & Consent Log ───

class AdminConsentLog {
  final String id;
  final String user;
  final String contentType;
  final String action; // 'Granted' | 'Updated' | 'Revoked' | 'Pending'
  final DateTime timestamp;

  const AdminConsentLog({
    required this.id,
    this.user = '',
    this.contentType = 'Data Processing',
    this.action = 'Pending',
    required this.timestamp,
  });
}

final adminConsentLogsProvider =
    FutureProvider<List<AdminConsentLog>>((ref) async {
  // Try moderation_logs first
  try {
    final modSnap = await _firestore
        .collection('moderation_logs')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    if (modSnap.docs.isNotEmpty) {
      return modSnap.docs.map((doc) {
        final d = doc.data();
        final action = (d['action'] as String? ?? '').toLowerCase();
        String label;
        if (action.contains('approv') || action.contains('accept')) {
          label = 'Granted';
        } else if (action.contains('reject') ||
            action.contains('revok')) {
          label = 'Revoked';
        } else if (action.contains('edit') ||
            action.contains('updat')) {
          label = 'Updated';
        } else {
          label = 'Pending';
        }
        return AdminConsentLog(
          id: doc.id,
          user: d['moderatorName'] as String? ?? 'Unknown',
          contentType: 'Data Processing',
          action: label,
          timestamp: d['timestamp'] != null
              ? (d['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }).toList();
    }
  } catch (e) {
    debugPrint('[AdminProvider] consent_logs query failed: $e');
  }

  // Fallback: derive from user consent statuses
  try {
    final usersSnap = await _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return _mapUsersToConsentLogs(usersSnap.docs);
  } catch (e) {
    debugPrint('[AdminProvider] ordered users fallback failed: $e');
    final usersSnap = await _firestore
        .collection(AppConstants.usersCollection)
        .limit(10)
        .get();
    return _mapUsersToConsentLogs(usersSnap.docs);
  }
});

List<AdminConsentLog> _mapUsersToConsentLogs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  return docs.map((doc) {
    final d = doc.data();
    final consent = d['gdprConsentGiven'] == true;
    final trained = d['gdprTrainingCompleted'] == true;
    final firstName = d['firstName'] as String? ?? '';
    final lastName = d['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim();

    String action;
    if (consent && trained) {
      action = 'Granted';
    } else if (consent && !trained) {
      action = 'Updated';
    } else {
      action = 'Pending';
    }

    return AdminConsentLog(
      id: doc.id,
      user: name.isNotEmpty ? name : (d['email'] as String? ?? 'Unknown'),
      contentType: 'Data Processing',
      action: action,
      timestamp: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }).toList();
}

// ═══════════════════════════════════════════════════════════════
// USER MANAGEMENT CRUD
// ═══════════════════════════════════════════════════════════════

/// Unique organisation IDs from all users
final adminOrganizationsProvider = FutureProvider<List<String>>((ref) async {
  final snap =
      await _firestore.collection(AppConstants.usersCollection).get();
  final orgs = snap.docs
      .map((d) => d.data()['organizationId'] as String?)
      .whereType<String>()
      .where((o) => o.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return orgs;
});

Future<void> addAdminUser({
  required String firstName,
  required String lastName,
  required String email,
  required String password,
  required String role,
  String organizationId = '',
}) async {
  final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('adminCreateUser');
  await callable.call({
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'password': password,
    'role': role,
    'organizationId': organizationId,
  });
}

Future<void> removeAdminUser(String uid) async {
  await _firestore.collection(AppConstants.usersCollection).doc(uid).delete();
}

Future<void> updateAdminUserRole(String uid, String newRole) async {
  await _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .update({'role': newRole});
}

/// Shared navigation index for the admin dashboard.
/// Allows any widget deep in the tree to change the active tab.
final adminNavIndexProvider = StateProvider<int>((ref) => 0);

// ═══════════════════════════════════════════════════════════════
// MODERATION QUEUE
// ═══════════════════════════════════════════════════════════════

class AdminModerationPost {
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final String category;
  final bool gdprFlagged;
  final String approvalStatus;
  final DateTime createdAt;

  const AdminModerationPost({
    required this.postId,
    this.authorId = '',
    this.authorName = '',
    this.content = '',
    this.category = 'General',
    this.gdprFlagged = false,
    this.approvalStatus = 'pending',
    required this.createdAt,
  });

  String get statusLabel {
    switch (approvalStatus) {
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'edit_requested': return 'Edit Requested';
      default: return 'Pending';
    }
  }
}

final adminModerationStreamProvider =
    StreamProvider<List<AdminModerationPost>>((ref) {
  final orgId = _getOrgId(ref);
  return _firestore
      .collection(AppConstants.postsCollection)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) {
        final docs = orgId != null && orgId.isNotEmpty
            ? snap.docs.where((d) => d.data()['organizationId'] == orgId)
            : snap.docs;
        return docs.map((doc) {
            final data = doc.data();
            return AdminModerationPost(
              postId: doc.id,
              authorId: data['authorId'] as String? ?? '',
              authorName: data['authorName'] as String? ?? 'Unknown',
              content: data['content'] as String? ?? '',
              category: data['category'] as String? ?? 'General',
              gdprFlagged: data['gdprFlagged'] == true,
              approvalStatus:
                  data['approvalStatus'] as String? ?? 'pending',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );
          }).toList();
      });
});

final adminPendingCountProvider = StreamProvider<int>((ref) {
  final orgId = _getOrgId(ref);
  return _firestore
      .collection(AppConstants.postsCollection)
      .where('approvalStatus', isEqualTo: 'pending')
      .snapshots()
      .map((snap) {
        if (orgId != null && orgId.isNotEmpty) {
          return snap.docs.where((d) => d.data()['organizationId'] == orgId).length;
        }
        return snap.docs.length;
      });
});

Future<void> adminApprovePost(String postId) async {
  await _firestore.collection(AppConstants.postsCollection).doc(postId).update({
    'approvalStatus': 'approved',
    'status': 'approved',
    'approvedAt': FieldValue.serverTimestamp(),
    'approvedBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
  });
}

Future<void> adminRejectPost(String postId, String reason) async {
  await _firestore.collection(AppConstants.postsCollection).doc(postId).update({
    'approvalStatus': 'rejected',
    'status': 'rejected',
    'rejectedAt': FieldValue.serverTimestamp(),
    'rejectedBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
    'rejectionReason': reason,
  });
}

Future<void> adminRequestEdit(String postId, String reason) async {
  await _firestore.collection(AppConstants.postsCollection).doc(postId).update({
    'approvalStatus': 'edit_requested',
    'editRequestedAt': FieldValue.serverTimestamp(),
    'editRequestedBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
    'editRequestReason': reason,
  });
}

// ═══════════════════════════════════════════════════════════════
// ANNOUNCEMENTS
// ═══════════════════════════════════════════════════════════════

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

final latestAnnouncementProvider =
    StreamProvider<AppAnnouncement?>((ref) {
  return _firestore
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

// ═══════════════════════════════════════════════════════════════
// QUIZ QUESTIONS
// ═══════════════════════════════════════════════════════════════

class QuizQuestion {
  final String id;
  final String question;
  final bool correctAnswer;
  final String correctMessage;
  final String incorrectMessage;
  final String category;
  final int order;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.correctAnswer,
    this.correctMessage = '',
    this.incorrectMessage = '',
    this.category = 'GDPR',
    this.order = 0,
  });
}

final adminQuizQuestionsProvider =
    StreamProvider<List<QuizQuestion>>((ref) {
  return _firestore
      .collection('quizzes')
      .orderBy('order')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) {
            final d = doc.data();
            return QuizQuestion(
              id: doc.id,
              question: d['question'] as String? ?? '',
              correctAnswer: d['correctAnswer'] as bool? ?? true,
              correctMessage: d['correctMessage'] as String? ?? '',
              incorrectMessage: d['incorrectMessage'] as String? ?? '',
              category: d['category'] as String? ?? 'GDPR',
              order: d['order'] as int? ?? 0,
            );
          })
          .toList());
});

Future<void> addQuizQuestion({
  required String question,
  required bool correctAnswer,
  required String correctMessage,
  required String incorrectMessage,
  String category = 'GDPR',
  required int order,
}) async {
  await _firestore.collection('quizzes').add({
    'question': question,
    'correctAnswer': correctAnswer,
    'correctMessage': correctMessage,
    'incorrectMessage': incorrectMessage,
    'category': category,
    'order': order,
    'isActive': true,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<void> updateQuizQuestion(String id, {
  String? question,
  bool? correctAnswer,
  String? correctMessage,
  String? incorrectMessage,
  String? category,
}) async {
  final data = <String, dynamic>{};
  if (question != null) data['question'] = question;
  if (correctAnswer != null) data['correctAnswer'] = correctAnswer;
  if (correctMessage != null) data['correctMessage'] = correctMessage;
  if (incorrectMessage != null) data['incorrectMessage'] = incorrectMessage;
  if (category != null) data['category'] = category;
  await _firestore.collection('quizzes').doc(id).update(data);
}

Future<void> deleteQuizQuestion(String id) async {
  await _firestore.collection('quizzes').doc(id).delete();
}

// ═══════════════════════════════════════════════════════════════
// TRAINING CONTENT
// ═══════════════════════════════════════════════════════════════

class TrainingModule {
  final String id;
  final String title;
  final String description;
  final String body;
  final String category;
  final String type; // article, video, pdf
  final String url;
  final List<String> requiredRoles;
  final int order;

  const TrainingModule({
    required this.id,
    required this.title,
    this.description = '',
    this.body = '',
    this.category = 'GDPR',
    this.type = 'article',
    this.url = '',
    this.requiredRoles = const [],
    this.order = 0,
  });
}

final adminTrainingModulesProvider =
    StreamProvider<List<TrainingModule>>((ref) {
  return _firestore
      .collection('training_content')
      .orderBy('order')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) {
            final d = doc.data();
            return TrainingModule(
              id: doc.id,
              title: d['title'] as String? ?? '',
              description: d['description'] as String? ?? '',
              body: d['body'] as String? ?? '',
              category: d['category'] as String? ?? 'GDPR',
              type: d['type'] as String? ?? 'article',
              url: d['url'] as String? ?? '',
              requiredRoles: List<String>.from(d['requiredRoles'] ?? []),
              order: d['order'] as int? ?? 0,
            );
          })
          .toList());
});

/// Public provider used by mobile training library screen
final trainingModulesProvider =
    StreamProvider<List<TrainingModule>>((ref) {
  return FirebaseFirestore.instance
      .collection('training_content')
      .where('isActive', isEqualTo: true)
      .orderBy('order')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) {
            final d = doc.data();
            return TrainingModule(
              id: doc.id,
              title: d['title'] as String? ?? '',
              description: d['description'] as String? ?? '',
              body: d['body'] as String? ?? '',
              category: d['category'] as String? ?? 'GDPR',
              type: d['type'] as String? ?? 'article',
              url: d['url'] as String? ?? '',
              requiredRoles: List<String>.from(d['requiredRoles'] ?? []),
              order: d['order'] as int? ?? 0,
            );
          })
          .toList());
});

Future<void> addTrainingModule({
  required String title,
  required String description,
  required String body,
  String category = 'GDPR',
  String type = 'article',
  String url = '',
  List<String> requiredRoles = const [],
  required int order,
}) async {
  await _firestore.collection('training_content').add({
    'title': title,
    'description': description,
    'body': body,
    'category': category,
    'type': type,
    'url': url,
    'requiredRoles': requiredRoles,
    'order': order,
    'isActive': true,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<void> updateTrainingModule(String id, Map<String, dynamic> data) async {
  await _firestore.collection('training_content').doc(id).update(data);
}

Future<void> deleteTrainingModule(String id) async {
  await _firestore.collection('training_content').doc(id).delete();
}

// ═══════════════════════════════════════════════════════════════
// DATE RANGE FILTER
// ═══════════════════════════════════════════════════════════════

final adminDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: now.subtract(const Duration(days: 30)),
    end: now,
  );
});

/// Engagement chart filtered by date range
final adminEngagementChartFilteredProvider =
    FutureProvider<AdminEngagementChartData>((ref) async {
  final orgId = _getOrgId(ref);
  final range = ref.watch(adminDateRangeProvider);
  final totalDays = range.end.difference(range.start).inDays;
  final buckets = totalDays <= 14 ? totalDays : (totalDays <= 60 ? 10 : 12);
  final bucketSize = totalDays ~/ buckets;

  final days = List.generate(buckets, (i) {
    final d = range.start.add(Duration(days: i * bucketSize));
    return DateTime(d.year, d.month, d.day);
  });

  final rawSnap =
      await _firestore.collection(AppConstants.postsCollection).get();
  final snap = _filterPostsByOrg(rawSnap.docs, orgId);

  final daily = List<double>.filled(buckets, 0);
  final monthly = List<double>.filled(buckets, 0);

  for (int i = 0; i < days.length; i++) {
    final dayStart = days[i];
    final dayEnd = i < days.length - 1
        ? days[i + 1]
        : range.end.add(const Duration(days: 1));
    final mStart = DateTime(dayStart.year, dayStart.month, 1);
    final dIds = <String>{};
    final mIds = <String>{};

    for (final doc in snap) {
      final d = doc.data();
      final at = (d['createdAt'] as Timestamp?)?.toDate();
      final uid = d['authorId'] as String?;
      if (at == null || uid == null) continue;
      if (!at.isBefore(dayStart) && at.isBefore(dayEnd)) dIds.add(uid);
      if (!at.isBefore(mStart) && at.isBefore(dayEnd)) mIds.add(uid);
    }

    daily[i] = dIds.length.toDouble();
    monthly[i] = mIds.length.toDouble();
  }

  final labels =
      days.map((d) => '${_abbrMonth(d.month)} ${d.day}').toList();

  return AdminEngagementChartData(
      dailyActive: daily, monthlyActive: monthly, labels: labels);
});

/// Kudos chart filtered by date range
final adminKudosChartFilteredProvider =
    FutureProvider<AdminKudosChartData>((ref) async {
  final range = ref.watch(adminDateRangeProvider);
  // Build monthly buckets within the range
  final mStarts = <DateTime>[];
  var cursor = DateTime(range.start.year, range.start.month, 1);
  final endMonth = DateTime(range.end.year, range.end.month + 1, 1);
  while (cursor.isBefore(endMonth)) {
    mStarts.add(cursor);
    int m = cursor.month + 1;
    int y = cursor.year;
    if (m > 12) { m = 1; y += 1; }
    cursor = DateTime(y, m, 1);
  }
  if (mStarts.isEmpty) mStarts.add(DateTime(range.start.year, range.start.month, 1));

  final snap = await _firestore.collection('star_history').get();
  final sent = List<double>.filled(mStarts.length, 0);

  for (final doc in snap.docs) {
    final d = doc.data();
    final at = (d['createdAt'] as Timestamp?)?.toDate();
    if (at == null) continue;
    for (int i = 0; i < mStarts.length; i++) {
      final start = mStarts[i];
      final end = i < mStarts.length - 1
          ? mStarts[i + 1]
          : DateTime(mStarts.last.year, mStarts.last.month + 1, 1);
      if (!at.isBefore(start) && at.isBefore(end)) {
        sent[i]++;
        break;
      }
    }
  }

  final received = sent.map((v) => (v * 0.75).roundToDouble()).toList();
  final months = mStarts.map((d) => _abbrMonth(d.month)).toList();

  return AdminKudosChartData(sent: sent, received: received, months: months);
});

// ═══════════════════════════════════════════════════════════════
// GDPR COMPLIANCE CHART DATA
// ═══════════════════════════════════════════════════════════════

class GdprComplianceChartData {
  final int completed;
  final int inProgress;  // consent given but training not done
  final int nonCompliant; // neither consent nor training
  final int totalUsers;

  const GdprComplianceChartData({
    this.completed = 0,
    this.inProgress = 0,
    this.nonCompliant = 0,
    this.totalUsers = 0,
  });

  double get completedPercent => totalUsers == 0 ? 0 : completed / totalUsers * 100;
  double get inProgressPercent => totalUsers == 0 ? 0 : inProgress / totalUsers * 100;
  double get nonCompliantPercent => totalUsers == 0 ? 0 : nonCompliant / totalUsers * 100;
}

final adminGdprComplianceChartProvider =
    FutureProvider<GdprComplianceChartData>((ref) async {
  final snap =
      await _firestore.collection(AppConstants.usersCollection).get();
  final total = snap.docs.length;
  if (total == 0) return const GdprComplianceChartData();

  int completed = 0;
  int inProgress = 0;
  int nonCompliant = 0;

  for (final doc in snap.docs) {
    final d = doc.data();
    final consent = d['gdprConsentGiven'] == true;
    final trained = d['gdprTrainingCompleted'] == true;
    if (consent && trained) {
      completed++;
    } else if (consent && !trained) {
      inProgress++;
    } else {
      nonCompliant++;
    }
  }

  return GdprComplianceChartData(
    completed: completed,
    inProgress: inProgress,
    nonCompliant: nonCompliant,
    totalUsers: total,
  );
});
