import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/auth/permissions_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/constants.dart';
import '../stars/providers/star_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF212121)),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading profile'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF0A2C6B),
                        backgroundImage: profile.profilePictureUrl != null && profile.profilePictureUrl!.isNotEmpty
                            ? NetworkImage(profile.profilePictureUrl!)
                            : null,
                        child: profile.profilePictureUrl == null || profile.profilePictureUrl!.isEmpty
                            ? Text(
                                Formatters.getInitials(profile.firstName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        profile.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Role
                      Text(
                        _formatRole(profile.role),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Email
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.star,
                              iconColor: const Color(0xFFFFB300),
                              value: '${profile.totalStars}',
                              label: 'Stars Received',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.create,
                              iconColor: const Color(0xFF0A2C6B),
                              value: '${profile.postCount}',
                              label: 'Posts made',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('star_history')
                                  .where('giverId', isEqualTo: profile.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int starsGiven = 0;
                                if (snapshot.hasData) {
                                  for (final doc in snapshot.data!.docs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    starsGiven += (data['points'] as int?) ?? 1;
                                  }
                                }
                                return _buildStatCard(
                                  icon: Icons.star_border,
                                  iconColor: const Color(0xFF00BCD4),
                                  value: '$starsGiven',
                                  label: 'Stars Given',
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection(AppConstants.postsCollection)
                                  .where('authorId', isEqualTo: profile.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int totalPosts = 0;
                                if (snapshot.hasData) {
                                  totalPosts = snapshot.data!.docs.length;
                                }
                                // Quality score: average stars per post, scaled to 100%
                                // Uses a log-based formula capped at 100:
                                //   score = min(100, (avgStars / targetAvg) * 100)
                                // where targetAvg = 5 stars per post is considered "perfect"
                                int qualityScore;
                                if (totalPosts == 0) {
                                  qualityScore = 0;
                                } else {
                                  final avgStarsPerPost = profile.totalStars / totalPosts;
                                  const targetAvg = 5.0; // 5 stars/post = 100%
                                  qualityScore = ((avgStarsPerPost / targetAvg) * 100)
                                      .round()
                                      .clamp(0, 100);
                                }
                                return _buildStatCard(
                                  icon: Icons.verified,
                                  iconColor: const Color(0xFF4CAF50),
                                  value: '$qualityScore%',
                                  label: 'Quality Score',
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Recognition Message
                      const Text(
                        'You are recognized for these traits',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Trait Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTraitBadge('Compassion', const Color(0xFFFFCDD2)),
                          _buildTraitBadge('Teamwork', const Color(0xFFBBDEFB)),
                          _buildTraitBadge('Excellence', const Color(0xFFC8E6C9)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Additional Information Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.phone_outlined, 'Phone number', profile.phone ?? 'Not provided'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.location_on_outlined, 'Address', profile.postcode ?? 'Not provided'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.badge_outlined, 'Emergency contact', 'Not provided'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.phone_outlined, 'Professional reg. number', 'Not provided'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.email_outlined, 'Preferred contact method', 'Email'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Star History Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFD4AF37), size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Star History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${profile.totalStars} total',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('star_history')
                            .where('receiverId', isEqualTo: profile.uid)
                            .limit(10)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.star_border,
                                      color: Color(0xFFBDBDBD), size: 36),
                                  SizedBox(height: 8),
                                  Text(
                                    'No stars received yet',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final stars = snapshot.data!.docs.toList();
                          stars.sort((a, b) {
                            final aData =
                                a.data() as Map<String, dynamic>;
                            final bData =
                                b.data() as Map<String, dynamic>;
                            final aTime =
                                aData['createdAt'] as Timestamp?;
                            final bTime =
                                bData['createdAt'] as Timestamp?;
                            if (aTime == null && bTime == null) return 0;
                            if (aTime == null) return 1;
                            if (bTime == null) return -1;
                            return bTime.compareTo(aTime);
                          });

                          return Column(
                            children: stars.map((doc) {
                              final data =
                                  doc.data() as Map<String, dynamic>;
                              return _buildStarHistoryItem(
                                giverName:
                                    data['giverName'] ?? 'Someone',
                                starType:
                                    data['starType'] ?? 'Peer',
                                points: data['points'] ?? 1,
                                note: data['note'],
                                category: data['category'],
                                createdAt: data['createdAt'] != null
                                    ? (data['createdAt'] as Timestamp)
                                        .toDate()
                                    : DateTime.now(),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // My Posts Section
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Posts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection(AppConstants.postsCollection)
                            .where('authorId', isEqualTo: profile.uid)
                            .limit(3)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          
                          if (snapshot.hasError) {
                            return Text(
                              'Error loading posts: ${snapshot.error}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFE65100),
                              ),
                            );
                          }
                          
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Text(
                              'No posts yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF757575),
                              ),
                            );
                          }

                          // Sort posts by createdAt in descending order
                          final posts = snapshot.data!.docs.toList();
                          posts.sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>;
                            final bData = b.data() as Map<String, dynamic>;
                            final aTime = aData['createdAt'] as Timestamp?;
                            final bTime = bData['createdAt'] as Timestamp?;
                            if (aTime == null && bTime == null) return 0;
                            if (aTime == null) return 1;
                            if (bTime == null) return -1;
                            return bTime.compareTo(aTime);
                          });

                          return Column(
                            children: posts.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return _buildPostItem(
                                profile: profile,
                                content: data['content'] ?? '',
                                category: data['category'] ?? 'General',
                                stars: data['stars'] ?? 0,
                                createdAt: data['createdAt'] != null
                                    ? (data['createdAt'] as Timestamp).toDate()
                                    : DateTime.now(),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStarHistoryItem({
    required String giverName,
    required String starType,
    required int points,
    required String? note,
    required String? category,
    required DateTime createdAt,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFF0BF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  points.clamp(1, 3),
                  (_) => const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFD4AF37),
                    size: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF424242),
                      fontFamily: 'Inter',
                    ),
                    children: [
                      TextSpan(
                        text: giverName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' gave you $points star${points > 1 ? 's' : ''}'),
                      if (category != null)
                        TextSpan(
                          text: ' for $category',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF757575),
                          ),
                        ),
                    ],
                  ),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"$note"',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF757575),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF3FB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        starType,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0A2C6B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.timeAgo(createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF212121),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF757575)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostItem({
    required UserProfile profile,
    required String content,
    required String category,
    required int stars,
    required DateTime createdAt,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF0A2C6B),
                backgroundImage: profile.profilePictureUrl != null && profile.profilePictureUrl!.isNotEmpty
                    ? NetworkImage(profile.profilePictureUrl!)
                    : null,
                child: profile.profilePictureUrl == null || profile.profilePictureUrl!.isEmpty
                    ? Text(
                        Formatters.getInitials(profile.firstName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _formatRole(profile.role),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFF757575),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE0B2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.timeAgo(createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF424242),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Read more',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF00BCD4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFB300), size: 16),
              const SizedBox(width: 4),
              Text(
                '$stars',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: const Color(0xFFEEEEEE),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}