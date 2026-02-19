import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/error_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/auth/permissions_provider.dart';
import '../stars/providers/star_provider.dart';
import '../../core/widgets/tutorial_overlay.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_logo.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onNavTap(int index) {
    if (index == 1) {
      // Create tab - go to create post
      context.push('/create-post');
    } else if (index == 2) {
      // Alerts - show notifications
      context.push('/notifications');
    } else if (index == 3) {
      // Profile
      context.push('/profile');
    } else {
      setState(() => _currentNavIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/welcome');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final showTutorial = userProfile.when(
      data: (profile) => !(profile?.hasSeenFeedTutorial ?? true),
      loading: () => false,
      error: (_, __) => false,
    );

    return TutorialOverlay(
      showTutorial: showTutorial,
      onComplete: () async {
        await FirebaseService.markTutorialSeen(user.uid, 'hasSeenFeedTutorial');
      },
      steps: const [
        TutorialStep(
          icon: Icons.add_circle_outline,
          title: 'Tap + to share an achievement',
          description:
              'Celebrate your colleagues\' great work by sharing what they did.',
        ),
        TutorialStep(
          icon: Icons.security,
          title: 'Be specific and GDPR-safe',
          description:
              'Don\'t use names or identifying details. Focus on the action, not the person.',
        ),
        TutorialStep(
          icon: Icons.star,
          title: 'Colleagues can give you stars',
          description:
              'When others appreciate your post, they\'ll give you stars. Collect stars to level up!',
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 16,
          title: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A2C6B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'CareKudos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => context.push('/profile'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0A2C6B),
                  backgroundImage: userProfile.when(
                    data: (profile) => profile?.profilePictureUrl != null && profile!.profilePictureUrl!.isNotEmpty
                        ? NetworkImage(profile.profilePictureUrl!)
                        : null,
                    loading: () => null,
                    error: (_, __) => null,
                  ),
                  child: userProfile.when(
                    data: (profile) => profile?.profilePictureUrl == null || profile!.profilePictureUrl!.isEmpty
                        ? Text(
                            Formatters.getInitials(profile?.firstName ?? 'U'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                    loading: () => const Icon(Icons.person, color: Colors.white, size: 18),
                    error: (_, __) => const Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.postsCollection)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Loading feed...');
            }

            if (snapshot.hasError) {
              return ErrorView(
                title: 'Error Loading Feed',
                message: ErrorHandler.getGenericErrorMessage(snapshot.error),
                onRetry: () => setState(() {}),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;

                return PostCard(
                  postId: doc.id,
                  authorId: data['authorId'] ?? '',
                  authorName: data['authorName'] ?? 'Anonymous',
                  content: data['content'] ?? '',
                  category: data['category'] ?? 'General',
                  stars: data['stars'] ?? 0,
                  createdAt: data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp).toDate()
                      : DateTime.now(),
                );
              },
            );
          },
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentNavIndex,
          onTap: _onNavTap,
          notificationCount: 0,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/create-post'),
          backgroundColor: const Color(0xFFFFB300),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.article_outlined,
      title: 'No posts yet',
      subtitle: 'Be the first to share an achievement!\nBe specific and GDPR-safe.',
      action: FloatingActionButton.extended(
        onPressed: () => context.push('/create-post'),
        icon: const Icon(Icons.add),
        label: const Text('Create Post'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

// PostCard widget
class PostCard extends ConsumerStatefulWidget {
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final String category;
  final int stars;
  final DateTime createdAt;

  const PostCard({
    super.key,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.category,
    required this.stars,
    required this.createdAt,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _hasGivenStar = false;
  bool _isGivingStar = false;

  @override
  void initState() {
    super.initState();
    _checkIfStarred();
  }

  Future<void> _checkIfStarred() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.postsCollection)
        .doc(widget.postId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final starredBy = data['starredBy'] as List<dynamic>?;
      if (mounted) {
        setState(() {
          _hasGivenStar = starredBy?.contains(currentUser.uid) ?? false;
        });
      }
    }
  }

  Widget _getCategoryTag() {
    switch (widget.category.toLowerCase()) {
      case 'compassion':
        return CategoryTag.compassion();
      case 'teamwork':
        return CategoryTag.teamwork();
      case 'excellence':
        return CategoryTag.excellence();
      case 'leadership':
        return CategoryTag.leadership();
      case 'reliability':
        return CategoryTag.reliability();
      default:
        return CategoryTag(
          label: widget.category,
          color: AppColors.primary,
          backgroundColor: AppColors.primaryLight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGiveStars = ref.watch(canGiveStarsProvider);
    final multiplier = ref.watch(starMultiplierProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF0A2C6B),
                  child: Text(
                    Formatters.getInitials(widget.authorName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name, role, time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        widget.authorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Role and Category
                      Row(
                        children: [
                          const Text(
                            'Care Worker',
                            style: TextStyle(
                              fontSize: 12,
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
                              widget.category,
                              style: const TextStyle(
                                fontSize: 11,
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
                // Time
                Text(
                  Formatters.timeAgo(widget.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            Text(
              widget.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF424242),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            // Read more link
            GestureDetector(
              onTap: () {
                // TODO: Navigate to post detail
              },
              child: const Text(
                'Read more',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF00BCD4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Container(
              height: 1,
              color: const Color(0xFFEEEEEE),
            ),
            const SizedBox(height: 12),
            // Bottom row: Star count and Give Star button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Star count
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFB300),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.stars}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
                // Give Star button
                GestureDetector(
                  onTap: (!canGiveStars || _isGivingStar)
                      ? null
                      : () => _hasGivenStar
                            ? _removeStar(multiplier)
                            : _giveStar(multiplier),
                  child: Row(
                    children: [
                      Icon(
                        _hasGivenStar ? Icons.star : Icons.star_border,
                        size: 20,
                        color: _hasGivenStar
                            ? const Color(0xFFFFB300)
                            : const Color(0xFF757575),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Give Star',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _hasGivenStar
                              ? const Color(0xFFFFB300)
                              : const Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _giveStar(int multiplier) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isGivingStar = true);

    try {
      final starService = ref.read(starPostProvider);

      await starService.giveStarToPost(
        postId: widget.postId,
        postAuthorId: widget.authorId,
        multiplier: multiplier.toDouble(),
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .doc(widget.postId)
          .update({
            'starredBy': FieldValue.arrayUnion([currentUser.uid]),
          });

      if (mounted) {
        setState(() => _hasGivenStar = true);
        context.showSnackBar(
          '⭐ Gave $multiplier star${multiplier > 1 ? 's' : ''}!',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to give star: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGivingStar = false);
      }
    }
  }

  Future<void> _removeStar(int multiplier) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isGivingStar = true);

    try {
      final starService = ref.read(starPostProvider);

      await starService.removeStarFromPost(
        postId: widget.postId,
        postAuthorId: widget.authorId,
        multiplier: multiplier.toDouble(),
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .doc(widget.postId)
          .update({
            'starredBy': FieldValue.arrayRemove([currentUser.uid]),
          });

      if (mounted) {
        setState(() => _hasGivenStar = false);
        context.showSnackBar('Star removed');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to remove star: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGivingStar = false);
      }
    }
  }
}
