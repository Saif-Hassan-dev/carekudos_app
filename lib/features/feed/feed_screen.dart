import 'dart:typed_data';
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
import '../../core/providers/user_photo_provider.dart';
import '../../core/providers/announcements_provider.dart';
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
  String? _dismissedAnnouncementId;

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
                                profile?.hasProfilePhoto == true &&
                                        profile!.profilePhotoBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(
                                            profile.profilePhotoBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                            loading: () => null,
                            error: (_, __) => null,
                          ),
                        ),
                        child: userProfile.when(
                          data: (profile) =>
                              profile?.hasProfilePhoto != true
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

              // ── Announcement Banner ──
              Builder(builder: (context) {
                final announcement =
                    ref.watch(latestAnnouncementProvider).valueOrNull;
                if (announcement == null) return const SizedBox.shrink();
                if (announcement.id == _dismissedAnnouncementId) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.campaign_rounded,
                          color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            if (announcement.message.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                announcement.message,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() =>
                            _dismissedAnnouncementId = announcement.id),
                        child: const Icon(Icons.close,
                            size: 16, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                );
              }),

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

                    // Filter to only approved posts (avoids composite index)
                    // Also exclude deactivated and deleted posts
                    final approvedDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['approvalStatus'] as String?;
                      final isActive = data['isActive'] as bool? ?? true;
                      final isDeleted = data['isDeleted'] as bool? ?? false;
                      if (isDeleted || !isActive) return false;
                      // Show approved posts, plus legacy posts without status
                      return status == 'approved' || status == null;
                    }).toList();

                    if (approvedDocs.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        setState(() {});
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: approvedDocs.length,
                        addAutomaticKeepAlives: true,
                        itemBuilder: (context, index) {
                          final doc = approvedDocs[index];
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
                      ),
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
      action: SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/create-post'),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Create Post'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
  final VoidCallback? onPostChanged;

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
    this.onPostChanged,
  });

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard>
    with AutomaticKeepAliveClientMixin {
  late bool _hasGivenStar;
  bool _isGivingStar = false;
  int _lastGivenPoints = 0; // Track actual points given for correct removal

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

    return GestureDetector(
      onTap: () => context.push('/post/${widget.postId}'),
      child: Container(
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
                // Avatar – show profile photo if available
                Consumer(
                  builder: (context, ref, _) {
                    final photoAsync =
                        ref.watch(userPhotoProvider(widget.authorId));
                    final Uint8List? photoBytes = photoAsync.valueOrNull;

                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0A2C6B),
                        image: photoBytes != null
                            ? DecorationImage(
                                image: MemoryImage(photoBytes),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photoBytes == null
                          ? Center(
                              child: Text(
                                Formatters.getInitials(widget.authorName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
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
                          Flexible(
                            child: Container(
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
                                  Flexible(
                                    child: Text(
                                      widget.category,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _categoryFg(),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
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
                Text(
                  Formatters.timeAgo(widget.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB0B0B0),
                  ),
                ),
                // ── Post owner actions menu ──
                if (_isOwnPost) ...[
                  const SizedBox(width: 4),
                  _buildPostActionsMenu(),
                ],
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
                          ? _removeStar(_lastGivenPoints > 0 ? _lastGivenPoints : multiplier)
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
    ),
    );
  }

  // ── Post owner actions popup menu ──
  Widget _buildPostActionsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF8E8E93)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'deactivate':
            _togglePostActive(false);
            break;
          case 'activate':
            _togglePostActive(true);
            break;
          case 'delete':
            _showDeleteConfirmation();
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'deactivate',
          child: Row(
            children: [
              Icon(Icons.visibility_off, size: 18, color: Color(0xFFF57C00)),
              SizedBox(width: 10),
              Text('Deactivate Post',
                  style: TextStyle(fontSize: 14, color: Color(0xFF1A1A2E))),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_forever, size: 18, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text('Delete Post',
                  style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _togglePostActive(bool active) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .doc(widget.postId)
          .update({'isActive': active});
      if (mounted) {
        context.showSnackBar(
            active ? 'Post activated' : 'Post deactivated');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to update post: $e');
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 26),
            SizedBox(width: 10),
            Text('Delete Post',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
          ],
        ),
        content: const Text(
          'This post is going to be deleted from the whole system.\n\nAre you sure you want to delete it?',
          style: TextStyle(fontSize: 14, color: Color(0xFF3C3C43), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePost();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Delete',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .doc(widget.postId)
          .update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        context.showSnackBar('Post deleted');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to delete post: $e');
      }
    }
  }

  Future<void> _openGiveStarSheet() async {
    // Prevent self-starring
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && currentUser.uid == widget.authorId) {
      if (mounted) context.showErrorSnackBar('You cannot give stars to your own post');
      return;
    }
    final starsLeft = ref.read(starsLeftTodayProvider);
    final userProfile = ref.read(userProfileProvider).value;
    final userRole = userProfile?.role ?? 'care_worker';
    final result = await GiveStarBottomSheet.show(
      context: context,
      postId: widget.postId,
      postAuthorId: widget.authorId,
      category: widget.category,
      starsLeftToday: starsLeft,
      maxStarsPerDay: AppConstants.maxStarsPerDay,
      userRole: userRole,
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
        setState(() {
          _hasGivenStar = true;
          _lastGivenPoints = points;
        });
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
