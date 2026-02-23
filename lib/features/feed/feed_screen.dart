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
import '../stars/widgets/give_star_bottom_sheet.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/push_notification_service.dart';
import 'widgets/app_hero_section.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  int _currentNavIndex = 0;
  bool _showSuccessBanner = false;
  bool _showStarGivenBanner = false;
  bool _showHeroSection = true;

  void _onNavTap(int index) {
    if (index == 1) {
      _navigateToCreatePost();
      return;
    } else if (index == 2) {
      context.push('/notifications');
    } else if (index == 3) {
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

    return Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/smallLogo.png',
                      height: 28,
                      width: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'CareKudos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A2C6B),
                          image: userProfile.when(
                            data: (profile) =>
                                profile?.profilePictureUrl != null &&
                                        profile!.profilePictureUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(
                                            profile.profilePictureUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                            loading: () => null,
                            error: (_, __) => null,
                          ),
                        ),
                        child: userProfile.when(
                          data: (profile) =>
                              profile?.profilePictureUrl == null ||
                                      profile!.profilePictureUrl!.isEmpty
                                  ? Center(
                                      child: Text(
                                        Formatters.getInitials(
                                            profile?.firstName ?? 'U'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : null,
                          loading: () => const Icon(Icons.person,
                              color: Colors.white, size: 18),
                          error: (_, __) => const Icon(Icons.person,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Success Banner ──
              if (_showSuccessBanner)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF81C784)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Your recognition has been shared',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Star Given Success Banner ──
              if (_showStarGivenBanner)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF81C784)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Star given successfully',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Hero / Features Section ──
              if (_showHeroSection)
                AppHeroSection(
                  onDismiss: () => setState(() => _showHeroSection = false),
                  onCreatePost: _navigateToCreatePost,
                ),

              // ── Feed List ──
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
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
                        message:
                            ErrorHandler.getGenericErrorMessage(snapshot.error),
                        onRetry: () => setState(() {}),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: snapshot.data!.docs.length,
                      addAutomaticKeepAlives: true,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final currentUser = ref.read(currentUserProvider);
                        final starredBy = data['starredBy'] as List<dynamic>? ?? [];
                        final hasGivenStar = currentUser != null &&
                            starredBy.contains(currentUser.uid);

                        return RepaintBoundary(
                          child: _PostCard(
                          key: ValueKey(doc.id),
                          postId: doc.id,
                          authorId: data['authorId'] ?? '',
                          authorName: data['authorName'] ?? 'Anonymous',
                          authorRole: data['authorRole'] ?? 'care_worker',
                          content: data['content'] ?? '',
                          category: data['category'] ?? 'General',
                          stars: data['stars'] ?? 0,
                          createdAt: data['createdAt'] != null
                              ? (data['createdAt'] as Timestamp).toDate()
                              : DateTime.now(),
                          initialHasGivenStar: hasGivenStar,
                          onStarGiven: _showStarGivenSuccess,
                        ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentNavIndex,
          onTap: _onNavTap,
          notificationCount:
              ref.watch(unreadNotificationCountProvider).value ?? 0,
        ),
        floatingActionButton: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            onPressed: _navigateToCreatePost,
            backgroundColor: const Color(0xFFD4AF37),
            elevation: 6,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
  }

  Future<void> _navigateToCreatePost() async {
    final result = await context.push<bool>('/create-post');
    if (result == true && mounted) {
      setState(() => _showSuccessBanner = true);
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showSuccessBanner = false);
      });
    }
  }

  void _showStarGivenSuccess() {
    setState(() => _showStarGivenBanner = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showStarGivenBanner = false);
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.article_outlined,
      title: 'No posts yet',
      subtitle:
          'Be the first to share an achievement!\nBe specific and GDPR-safe.',
      action: FloatingActionButton.extended(
        onPressed: () => context.push('/create-post'),
        icon: const Icon(Icons.add),
        label: const Text('Create Post'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  final String postId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final String category;
  final int stars;
  final DateTime createdAt;
  final bool initialHasGivenStar;
  final VoidCallback? onStarGiven;

  const _PostCard({
    super.key,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.category,
    required this.stars,
    required this.createdAt,
    this.initialHasGivenStar = false,
    this.onStarGiven,
  });

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard>
    with AutomaticKeepAliveClientMixin {
  late bool _hasGivenStar;
  bool _isGivingStar = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _hasGivenStar = widget.initialHasGivenStar;
  }

  // ── Category badge helpers ──
  Color _categoryBg() {
    switch (widget.category.toLowerCase()) {
      case 'compassion':
        return const Color(0xFFFFE0E6);
      case 'teamwork':
        return const Color(0xFFE0F0FF);
      case 'excellence':
        return const Color(0xFFE0FFF4);
      case 'leadership':
        return const Color(0xFFFFF8E0);
      case 'reliability':
        return const Color(0xFFEEF3FB);
      case 'above & beyond':
        return const Color(0xFFF3E8FF);
      default:
        return const Color(0xFFEEF3FB);
    }
  }

  Color _categoryFg() {
    switch (widget.category.toLowerCase()) {
      case 'compassion':
        return const Color(0xFFE53E5C);
      case 'teamwork':
        return const Color(0xFF2196F3);
      case 'excellence':
        return const Color(0xFF2FB9A3);
      case 'leadership':
        return const Color(0xFFB8962E);
      case 'reliability':
        return const Color(0xFF0A2C6B);
      case 'above & beyond':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF0A2C6B);
    }
  }

  IconData _categoryIcon() {
    switch (widget.category.toLowerCase()) {
      case 'compassion':
        return Icons.favorite;
      case 'teamwork':
        return Icons.groups;
      case 'excellence':
        return Icons.star;
      case 'leadership':
        return Icons.workspace_premium;
      case 'reliability':
        return Icons.verified;
      case 'above & beyond':
        return Icons.rocket_launch;
      default:
        return Icons.label;
    }
  }

  bool get _isOwnPost {
    final currentUser = ref.read(currentUserProvider);
    return currentUser != null && currentUser.uid == widget.authorId;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final canGiveStars = ref.watch(canGiveStarsProvider) && !_isOwnPost;
    final multiplier = ref.watch(starMultiplierProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0A2C6B),
                  ),
                  child: Center(
                    child: Text(
                      Formatters.getInitials(widget.authorName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.authorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            _formatRole(widget.authorRole),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF8E8E93)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _categoryBg(),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_categoryIcon(),
                                    size: 12, color: _categoryFg()),
                                const SizedBox(width: 4),
                                Text(
                                  widget.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _categoryFg(),
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
                Text(
                  Formatters.timeAgo(widget.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Content ──
            Text(
              widget.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF3C3C43),
                height: 1.5,
              ),
            ),

            // Read more
            if (widget.content.length > 100) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => context.push('/post/${widget.postId}'),
                child: const Text(
                  'Read more',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00BCD4),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // ── Divider ──
            Container(height: 1, color: const Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

            // ── Footer ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFD4AF37), size: 22),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.stars}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: (!canGiveStars || _isGivingStar)
                      ? null
                      : () => _hasGivenStar
                          ? _removeStar(multiplier)
                          : _openGiveStarSheet(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _hasGivenStar
                          ? const Color(0xFFFFF8E0)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _hasGivenStar
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFFE0E0E0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasGivenStar
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 18,
                          color: _hasGivenStar
                              ? const Color(0xFFD4AF37)
                              : const Color(0xFF555555),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Give Star',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _hasGivenStar
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFF1A1A2E),
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

  Future<void> _openGiveStarSheet() async {
    // Prevent self-starring
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && currentUser.uid == widget.authorId) {
      if (mounted) context.showErrorSnackBar('You cannot give stars to your own post');
      return;
    }
    final starsLeft = ref.read(starsLeftTodayProvider);
    final result = await GiveStarBottomSheet.show(
      context: context,
      postId: widget.postId,
      postAuthorId: widget.authorId,
      category: widget.category,
      starsLeftToday: starsLeft,
      maxStarsPerDay: AppConstants.maxStarsPerDay,
      onGiveStar: ({
        required String starType,
        required int points,
        required String? note,
      }) async {
        await _giveStarWithType(
          starType: starType,
          points: points,
          note: note,
        );
      },
    );
    if (result == true && mounted) {
      widget.onStarGiven?.call();
    }
  }

  Future<void> _giveStarWithType({
    required String starType,
    required int points,
    required String? note,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    setState(() => _isGivingStar = true);
    try {
      final starService = ref.read(starPostProvider);
      final currentUserProfile = ref.read(userProfileProvider).value;
      await starService.giveStarToPost(
        postId: widget.postId,
        postAuthorId: widget.authorId,
        multiplier: points.toDouble(),
        giverName: currentUserProfile?.fullName,
        giverId: currentUser.uid,
        category: widget.category,
        starType: starType,
        note: note,
      );
      await FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .doc(widget.postId)
          .update({
        'starredBy': FieldValue.arrayUnion([currentUser.uid]),
      });
      if (currentUser.uid != widget.authorId) {
        await NotificationService.notifyStarReceived(
          recipientId: widget.authorId,
          giverName: currentUserProfile?.fullName ?? 'Someone',
          category: widget.category,
          postId: widget.postId,
          giverId: currentUser.uid,
          multiplier: points,
        );
        // Queue push notification for the post author
        await PushNotificationService.pushStarReceived(
          recipientId: widget.authorId,
          giverName: currentUserProfile?.fullName ?? 'Someone',
          points: points,
          postId: widget.postId,
        );
      }
      // Invalidate the stars-given-today cache
      ref.invalidate(starsGivenTodayProvider);
      if (mounted) {
        setState(() => _hasGivenStar = true);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to give star: $e');
      }
    } finally {
      if (mounted) setState(() => _isGivingStar = false);
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
      if (mounted) setState(() => _isGivingStar = false);
    }
  }

  String _formatRole(String role) {
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
