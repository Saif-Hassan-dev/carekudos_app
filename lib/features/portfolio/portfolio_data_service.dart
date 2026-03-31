import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/constants.dart';

/// Aggregated portfolio data for a single care worker.
class PortfolioData {
  final String uid;
  final String fullName;
  final String role;
  final String? jobTitle;
  final String? organizationId;
  final DateTime? memberSince;
  final int totalStars;
  final int totalPosts;

  /// Value name → count of posts tagged with that value.
  final Map<String, int> valuesBreakdown;

  /// Month key (e.g. "2026-03") → star count received that month.
  final Map<String, int> monthlyStars;

  /// Star type (Peer/Manager/Family) → count.
  final Map<String, int> recognitionBySource;

  /// Giver name → count of stars they gave this user.
  final Map<String, int> topRecognisers;

  /// Top posts sorted by star count (highest first).
  final List<PortfolioPost> topPosts;

  PortfolioData({
    required this.uid,
    required this.fullName,
    required this.role,
    this.jobTitle,
    this.organizationId,
    this.memberSince,
    this.totalStars = 0,
    this.totalPosts = 0,
    this.valuesBreakdown = const {},
    this.monthlyStars = const {},
    this.recognitionBySource = const {},
    this.topRecognisers = const {},
    this.topPosts = const [],
  });

  /// Values breakdown as percentages.
  Map<String, double> get valuesPercentages {
    final total = valuesBreakdown.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return {};
    return valuesBreakdown.map((k, v) => MapEntry(k, (v / total) * 100));
  }
}

/// A single post for the portfolio.
class PortfolioPost {
  final String postId;
  final String content;
  final String category;
  final int stars;
  final DateTime createdAt;

  PortfolioPost({
    required this.postId,
    required this.content,
    required this.category,
    required this.stars,
    required this.createdAt,
  });
}

/// Service that fetches and aggregates all portfolio data for a user.
class PortfolioDataService {
  final FirebaseFirestore _firestore;

  PortfolioDataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch complete portfolio data for [uid].
  /// [topN] controls how many top posts to include.
  Future<PortfolioData> fetchPortfolio(String uid, {int topN = 10}) async {
    // Run queries in parallel
    final results = await Future.wait([
      _firestore.collection(AppConstants.usersCollection).doc(uid).get(),
      _firestore
          .collection(AppConstants.postsCollection)
          .where('authorId', isEqualTo: uid)
          .where('isDeleted', isEqualTo: false)
          .get(),
      _firestore
          .collection('star_history')
          .where('receiverId', isEqualTo: uid)
          .get(),
    ]);

    final userDoc = results[0] as DocumentSnapshot;
    final postsSnap = results[1] as QuerySnapshot;
    final starsSnap = results[2] as QuerySnapshot;

    // ── User profile ──
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    final fullName =
        '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
    final role = userData['role'] ?? 'care_worker';
    final jobTitle = userData['jobTitle'] as String?;
    final organizationId = userData['organizationId'] as String?;
    final createdAt = userData['createdAt'] as Timestamp?;

    // ── Posts aggregation ──
    final valuesBreakdown = <String, int>{};
    final posts = <PortfolioPost>[];

    for (final doc in postsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] as String? ?? 'Other';
      final stars = data['stars'] as int? ?? 0;
      final ts = data['createdAt'] as Timestamp?;
      final approved = data['approvalStatus'] as String?;

      // Only include approved posts
      if (approved == 'rejected') continue;

      valuesBreakdown[category] = (valuesBreakdown[category] ?? 0) + 1;

      posts.add(PortfolioPost(
        postId: doc.id,
        content: data['content'] ?? '',
        category: category,
        stars: stars,
        createdAt: ts?.toDate() ?? DateTime.now(),
      ));
    }

    // Sort by stars descending, take top N
    posts.sort((a, b) => b.stars.compareTo(a.stars));
    final topPosts = posts.take(topN).toList();

    // ── Stars aggregation ──
    final monthlyStars = <String, int>{};
    final recognitionBySource = <String, int>{};
    final topRecognisers = <String, int>{};

    for (final doc in starsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'] as Timestamp?;
      final starType = data['starType'] as String? ?? 'Peer';
      final giverName = data['giverName'] as String? ?? 'Unknown';
      final points = data['points'] as int? ?? 1;

      // Monthly breakdown
      if (ts != null) {
        final date = ts.toDate();
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyStars[key] = (monthlyStars[key] ?? 0) + points;
      }

      // By source
      recognitionBySource[starType] =
          (recognitionBySource[starType] ?? 0) + points;

      // Top recognisers
      topRecognisers[giverName] =
          (topRecognisers[giverName] ?? 0) + points;
    }

    // Sort top recognisers, keep top 5
    final sortedRecognisers = Map.fromEntries(
      topRecognisers.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
    final top5Recognisers = Map.fromEntries(
      sortedRecognisers.entries.take(5),
    );

    return PortfolioData(
      uid: uid,
      fullName: fullName,
      role: role,
      jobTitle: jobTitle,
      organizationId: organizationId,
      memberSince: createdAt?.toDate(),
      totalStars: userData['totalStars'] as int? ?? 0,
      totalPosts: posts.length,
      valuesBreakdown: valuesBreakdown,
      monthlyStars: monthlyStars,
      recognitionBySource: recognitionBySource,
      topRecognisers: top5Recognisers,
      topPosts: topPosts,
    );
  }
}
