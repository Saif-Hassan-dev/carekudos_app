import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  // Pagination
  static const _pageSize = 20;
  final _scrollController = ScrollController();
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loadingMore = false;
  List<QueryDocumentSnapshot> _allDocs = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_lastDoc == null || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final profile = ref.read(userProfileProvider).value;
      final user = ref.read(currentUserProvider);
      final orgId = profile?.organizationId;
      Query<Map<String, dynamic>> query;
      if (orgId != null && orgId.isNotEmpty) {
        query = FirebaseFirestore.instance
            .collection(AppConstants.postsCollection)
            .where('organizationId', isEqualTo: orgId)
            .orderBy('createdAt', descending: true)
            .startAfterDocument(_lastDoc!)
            .limit(_pageSize);
      } else {
        query = FirebaseFirestore.instance
            .collection(AppConstants.postsCollection)
            .where('authorId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .startAfterDocument(_lastDoc!)
            .limit(_pageSize);
      }
      final snap = await query.get();
      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last;
        setState(() {
          _allDocs.addAll(snap.docs);
          _hasMore = snap.docs.length == _pageSize;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('[Feed] Failed to load more: $e');
      setState(() => _loadingMore = false);
    }
  }

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
                    SvgPicture.asset(
                      'assets/images/smallLogo.svg',
                      width: 140,
                      fit: BoxFit.contain,
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

              // ── Feed List (achievements + my posts + feed all scroll together) ──
              Expanded(
                child: userProfile.when(
                  loading: () => const LoadingView(message: 'Loading feed...'),
                  error: (e, _) => ErrorView(
                    title: 'Error Loading Profile',
                    message: e.toString(),
                    onRetry: () => ref.invalidate(userProfileProvider),
                  ),
                  data: (profile) {
                    // Build org-filtered query
                    final orgId = profile?.organizationId;
                    final Query<Map<String, dynamic>> baseQuery;
                    if (orgId != null && orgId.isNotEmpty) {
                      // Show posts from same organisation
                      baseQuery = FirebaseFirestore.instance
                          .collection(AppConstants.postsCollection)
                          .where('organizationId', isEqualTo: orgId)
                          .orderBy('createdAt', descending: true)
                          .limit(_pageSize);
                    } else {
                      // Solo carer: show only own posts
                      baseQuery = FirebaseFirestore.instance
                          .collection(AppConstants.postsCollection)
                          .where('authorId', isEqualTo: user.uid)
                          .orderBy('createdAt', descending: true)
                          .limit(_pageSize);
                    }
                    return StreamBuilder<QuerySnapshot>(
                  stream: baseQuery.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _allDocs.isEmpty) {
                      return const LoadingView(message: 'Loading feed...');
                    }

                    if (snapshot.hasError && _allDocs.isEmpty) {
                      return ErrorView(
                        title: 'Error Loading Feed',
                        message:
                            ErrorHandler.getGenericErrorMessage(snapshot.error),
                        onRetry: () => setState(() {}),
                      );
                    }

                    // Merge stream data (first page, real-time) with paginated docs
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final streamDocs = snapshot.data!.docs;
                      _lastDoc = streamDocs.last;
                      _hasMore = streamDocs.length == _pageSize;
                      // Replace first page with stream data, keep extras
                      final extraDocs = _allDocs.length > streamDocs.length
                          ? _allDocs.sublist(streamDocs.length)
                          : <QueryDocumentSnapshot>[];
                      _allDocs = [...streamDocs, ...extraDocs];
                    }

                    if (_allDocs.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    // Filter to only approved posts
                    final approvedDocs = _allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['approvalStatus'] as String?;
                      final isActive = data['isActive'] as bool? ?? true;
                      final isDeleted = data['isDeleted'] as bool? ?? false;
                      if (isDeleted || !isActive) return false;
                      return status == 'approved' || status == null;
                    }).toList();

                    if (approvedDocs.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(children: [
                          _AchievementsSummary(userId: user.uid),
                          const _GdprGuideCard(),
                          _MyPostsSection(userId: user.uid),
                          _buildEmptyState(context),
                        ]),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        setState(() {
                          _allDocs.clear();
                          _lastDoc = null;
                          _hasMore = true;
                        });
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 0),
                        itemCount: approvedDocs.length + 3 + (_hasMore ? 1 : 0),
                        addAutomaticKeepAlives: true,
                        itemBuilder: (context, index) {
                          // Item 0: Achievements summary
                          if (index == 0) {
                            return _AchievementsSummary(userId: user.uid);
                          }
                          // Item 1: GDPR Guide quick access
                          if (index == 1) {
                            return const _GdprGuideCard();
                          }
                          // Item 2: My posts section
                          if (index == 2) {
                            return _MyPostsSection(userId: user.uid);
                          }
                          final postIndex = index - 3;
                          // Loading indicator at bottom
                          if (postIndex == approvedDocs.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          final doc = approvedDocs[postIndex];
                          final data = doc.data() as Map<String, dynamic>;

                          final currentUser = ref.read(currentUserProvider);
                          final starredBy = data['starredBy'] as List<dynamic>? ?? [];
                          final hasGivenStar = currentUser != null &&
                              starredBy.contains(currentUser.uid);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: RepaintBoundary(
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
                          ),
                          );
                        },
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
      ref.invalidate(starsGivenTodayProvider);
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

// ═══════════════════════════════════════════════════════════════
// GDPR GUIDE CARD
// ═══════════════════════════════════════════════════════════════

class _GdprGuideCard extends StatelessWidget {
  const _GdprGuideCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/gdpr-guidelines'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0A2C6B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GDPR Writing Guide',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A2C6B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Learn how to write recognition posts that protect privacy',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF0A2C6B), size: 22),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ACHIEVEMENTS SUMMARY (C-06 fix)
// ═══════════════════════════════════════════════════════════════

class _AchievementsSummary extends ConsumerWidget {
  final String userId;
  const _AchievementsSummary({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'My Achievements',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A2C6B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Stats row
              Row(
                children: [
                  _AchievementStat(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFFFB300),
                    value: '${profile.totalStars}',
                    label: 'Stars Received',
                  ),
                  _AchievementStat(
                    icon: Icons.create_rounded,
                    iconColor: const Color(0xFF0A2C6B),
                    value: '${profile.postCount}',
                    label: 'Posts Made',
                  ),
                  // Stars Given - live from Firestore
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('star_history')
                        .where('giverId', isEqualTo: profile.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int given = 0;
                      if (snapshot.hasData) {
                        for (final doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          given += (data['points'] as int?) ?? 1;
                        }
                      }
                      return _AchievementStat(
                        icon: Icons.star_border_rounded,
                        iconColor: const Color(0xFF00BCD4),
                        value: '$given',
                        label: 'Stars Given',
                      );
                    },
                  ),
                  // Quality Score - live
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(AppConstants.postsCollection)
                        .where('authorId', isEqualTo: profile.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int score = 0;
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final total = snapshot.data!.docs.length;
                        final avg = profile.totalStars / total;
                        score = ((avg / 5.0) * 100).round().clamp(0, 100);
                      }
                      return _AchievementStat(
                        icon: Icons.verified_rounded,
                        iconColor: const Color(0xFF4CAF50),
                        value: '$score%',
                        label: 'Quality',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Recent star history preview
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('star_history')
                    .where('receiverId', isEqualTo: profile.uid)
                    .limit(3)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final stars = snapshot.data!.docs.toList();
                  stars.sort((a, b) {
                    final aT = (a.data() as Map<String, dynamic>)['createdAt']
                        as Timestamp?;
                    final bT = (b.data() as Map<String, dynamic>)['createdAt']
                        as Timestamp?;
                    if (aT == null || bT == null) return 0;
                    return bT.compareTo(aT);
                  });
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 10),
                      const Text(
                        'Recent Stars',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...stars.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final giver = d['giverName'] as String? ?? 'Someone';
                        final points = (d['points'] as int?) ?? 1;
                        final category = d['category'] as String?;
                        final type = d['starType'] as String? ?? 'Peer';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                type == 'Manager'
                                    ? Icons.shield_rounded
                                    : type == 'Family'
                                        ? Icons.favorite_rounded
                                        : Icons.star_rounded,
                                color: const Color(0xFFD4AF37),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$giver gave you $points ${points == 1 ? "star" : "stars"}${category != null ? " for $category" : ""}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF424242),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _AchievementStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF757575),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MY POSTS SECTION
// ═══════════════════════════════════════════════════════════════

class _MyPostsSection extends StatelessWidget {
  final String userId;

  const _MyPostsSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        // Filter client-side to avoid needing a composite index
        final myPosts = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['approvalStatus'] as String?;
          final isActive = data['isActive'] as bool? ?? true;
          final isDeleted = data['isDeleted'] as bool? ?? false;
          if (isDeleted || !isActive) return false;
          return status == 'approved' || status == null;
        }).toList();

        if (myPosts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2C6B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.article_outlined,
                      size: 16,
                      color: Color(0xFF0A2C6B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'My Posts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3FB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${myPosts.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A2C6B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: myPosts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final data =
                      myPosts[index].data() as Map<String, dynamic>;
                  final postId = myPosts[index].id;
                  final content = data['content'] as String? ?? '';
                  final category = data['category'] as String? ?? 'General';
                  final stars = data['stars'] as int? ?? 0;
                  final createdAt = data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp).toDate()
                      : DateTime.now();
                  final status = data['approvalStatus'] as String?;

                  return GestureDetector(
                    onTap: () => context.push('/post/$postId'),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFE8EAED), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category + status row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _myPostCategoryBg(category),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _myPostCategoryFg(category),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (status == 'pending')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Content preview
                          Expanded(
                            child: Text(
                              content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF3C3C43),
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Footer: stars + time
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFD4AF37), size: 16),
                              const SizedBox(width: 3),
                              Text(
                                '$stars',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                Formatters.timeAgo(createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFB0B0B0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Color _myPostCategoryBg(String category) {
    switch (category.toLowerCase()) {
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

  Color _myPostCategoryFg(String category) {
    switch (category.toLowerCase()) {
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
}
