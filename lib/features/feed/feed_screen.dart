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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.cardBackground,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: AppSpacing.all8,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.allLg,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              AppSpacing.horizontalGap8,
              Text(
                AppConstants.appName,
                style: AppTypography.headingH5.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          actions: [
            // User greeting
            userProfile.when(
              data: (profile) => Padding(
                padding: AppSpacing.horizontal8,
                child: Center(
                  child: Text(
                    'Hi, ${profile?.firstName ?? user.email?.split('@')[0] ?? 'User'}',
                    style: AppTypography.bodyB4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            IconButton(
              icon: const Icon(Icons.logout_outlined, color: AppColors.textSecondary),
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) context.go('/welcome');
              },
            ),
            AppSpacing.horizontalGap8,
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
              padding: AppSpacing.all16,
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (_, __) => AppSpacing.verticalGap12,
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
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.neutral0),
        ),
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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.all16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    Formatters.getInitials(widget.authorName),
                    style: AppTypography.bodyB4.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppSpacing.horizontalGap12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.authorName,
                        style: AppTypography.bodyB3.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        Formatters.timeAgo(widget.createdAt),
                        style: AppTypography.captionC1.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Star display
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    AppSpacing.horizontalGap4,
                    Text(
                      Formatters.formatStarCount(widget.stars),
                      style: AppTypography.bodyB4.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.verticalGap12,
            // Content
            Text(
              widget.content,
              style: AppTypography.bodyB3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.verticalGap12,
            // Category tag
            _getCategoryTag(),
            AppSpacing.verticalGap12,
            // Actions row
            Row(
              children: [
                // Star button
                InkWell(
                  onTap: (!canGiveStars || _isGivingStar)
                      ? null
                      : () => _hasGivenStar
                            ? _removeStar(multiplier)
                            : _giveStar(multiplier),
                  borderRadius: AppRadius.allSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasGivenStar ? Icons.star : Icons.star_border,
                          size: 20,
                          color: _hasGivenStar
                              ? AppColors.secondary
                              : AppColors.textTertiary,
                        ),
                        AppSpacing.horizontalGap4,
                        Text(
                          _hasGivenStar ? 'Starred' : 'Give Star',
                          style: AppTypography.captionC1.copyWith(
                            color: _hasGivenStar
                                ? AppColors.secondary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.horizontalGap16,
                // Comment button
                InkWell(
                  onTap: () {},
                  borderRadius: AppRadius.allSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                        AppSpacing.horizontalGap4,
                        Text(
                          'Comment',
                          style: AppTypography.captionC1.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
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
