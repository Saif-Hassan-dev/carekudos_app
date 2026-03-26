// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/permissions_provider.dart';
import '../../core/utils/constants.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/utils/pdf_export.dart';
import '../manager/providers/manager_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════

Widget _avatar(String name, String? base64, {double radius = 18}) {
  if (base64 != null && base64.isNotEmpty) {
    try {
      final bytes = const Base64Decoder().convert(
          base64.contains(',') ? base64.split(',').last : base64);
      return CircleAvatar(
          radius: radius, backgroundImage: MemoryImage(bytes));
    } catch (_) {}
  }
  final initials = name.trim().isNotEmpty
      ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
      : '?';
  return CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFF1E3A8A),
    child: Text(
      initials.toUpperCase(),
      style: GoogleFonts.inter(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w600,
          color: Colors.white),
    ),
  );
}

const _cardDecor = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(12)),
  border: Border.fromBorderSide(BorderSide(color: Color(0xFFE5E7EB))),
);

TextStyle _inter(double size,
        {FontWeight weight = FontWeight.w400, Color color = const Color(0xFF374151)}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

// ═══════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════

class WebManagerDashboardScreen extends ConsumerWidget {
  const WebManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Title(
      title: 'Manager Dashboard — CareKudos',
      color: const Color(0xFF1E3A8A),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        body: Column(
          children: [
            _TopBar(),
            const Expanded(child: _Body()),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════

class _TopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const AppLogo(size: LogoSize.md, showText: true),
          const Spacer(),
          PopupMenuButton<String>(
            offset: const Offset(0, 44),
            onSelected: (v) async {
              if (v == 'logout') {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) context.go('/admin/login');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'logout',
                child: Text('Sign Out', style: _inter(14)),
              ),
            ],
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE5E7EB),
              child: Icon(Icons.person, size: 20, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BODY
// ═══════════════════════════════════════════════════════════════

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats ──
          const _StatsRow(),
          const SizedBox(height: 20),

          // ── Main two-column ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left ~60%
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _ValuesDistributionCard(),
                    SizedBox(height: 16),
                    _CqcReportCard(),
                    SizedBox(height: 16),
                    _EvidenceCultureCard(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right ~40%
              const Expanded(flex: 4, child: _NeedsReviewPanel()),
            ],
          ),
          const SizedBox(height: 20),

          // ── Three-column ──
          const _ThreeColumnRow(),
          const SizedBox(height: 20),

          // ── Company culture ──
          const _CompanyCultureSection(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STATS ROW
// ═══════════════════════════════════════════════════════════════

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardStatsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (s) => Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.pending_outlined,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFF59E0B),
              value: '${s.pendingReviews}',
              label: 'Posts pending review',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.warning_amber_rounded,
              iconBg: const Color(0xFFFEE2E2),
              iconColor: const Color(0xFFEF4444),
              value: '${s.gdprFlags}',
              label: 'GDPR flags',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.people_alt_outlined,
              iconBg: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF3B82F6),
              value: '${s.activeStaffToday}',
              label: 'Active staff today',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.star_rounded,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFF59E0B),
              value: '${s.totalRecognitionsWeek}',
              label: 'Total recognitions (week)',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: _inter(26,
                  weight: FontWeight.w700, color: const Color(0xFF111827))),
          const SizedBox(height: 4),
          Text(value.length > 0 ? label : label,
              style: _inter(12, color: const Color(0xFF6B7280)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// VALUES DISTRIBUTION CARD
// ═══════════════════════════════════════════════════════════════

class _ValuesDistributionCard extends ConsumerWidget {
  const _ValuesDistributionCard();

  static const _valueColors = [
    Color(0xFFF97316), // orange – Compassion
    Color(0xFF3B82F6), // blue – Teamwork
    Color(0xFF22C55E), // green – Excellence
    Color(0xFF8B5CF6), // purple – 4th value
    Color(0xFF14B8A6), // teal – 5th value
  ];

  static const _valueIcons = [
    Icons.favorite_outline,
    Icons.people_outline,
    Icons.emoji_events_outlined,
    Icons.lightbulb_outline,
    Icons.handshake_outlined,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(coreValuesStatsProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Values Distribution',
              style: _inter(16,
                  weight: FontWeight.w600, color: const Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('Recognition activity by core value this week',
              style: _inter(12, color: const Color(0xFF9CA3AF))),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (stats) {
              final total = stats.fold(0, (sum, s) => sum + s.count);
              // Show empty state if no activity this week
              if (total == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      const Icon(Icons.bar_chart_rounded,
                          size: 36, color: Color(0xFFD1D5DB)),
                      const SizedBox(height: 8),
                      Text('No recognition activity this week',
                          style:
                              _inter(13, color: const Color(0xFF9CA3AF))),
                    ],
                  ),
                );
              }
              final maxCount =
                  stats.map((s) => s.count).fold(0, (a, b) => a > b ? a : b);
              return Column(
                children: stats.asMap().entries.map((entry) {
                  final i = entry.key;
                  final stat = entry.value;
                  final color = _valueColors[i % _valueColors.length];
                  final icon = _valueIcons[i % _valueIcons.length];
                  // Bar width is relative to the highest value
                  final ratio =
                      maxCount > 0 ? stat.count / maxCount : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 18, color: color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(stat.name,
                                  style: _inter(13.5,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFF374151))),
                            ),
                            Text('${stat.count}',
                                style: _inter(13.5,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF111827))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CQC EVIDENCE REPORT CARD
// ═══════════════════════════════════════════════════════════════

class _CqcReportCard extends ConsumerWidget {
  const _CqcReportCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamRecognitionProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_outlined,
                size: 22, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CQC Evidence Report',
                    style: _inter(14,
                        weight: FontWeight.w600,
                        color: const Color(0xFF111827))),
                const SizedBox(height: 2),
                Text('Export recognition activity for inspection',
                    style: _inter(12.5, color: const Color(0xFF6B7280))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              final team = teamAsync.valueOrNull ?? [];
              PdfExport.exportRecognitionReport(
                users: team.map((m) => {
                  'name': m.name,
                  'role': 'Care Worker',
                  'stars': '${m.totalStars}',
                  'posts': '0',
                  'status': 'Active',
                }).toList(),
                totalKudos: team.fold<int>(0, (sum, m) => sum + m.totalStars),
                totalPosts: 0,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Generate Report',
                style: _inter(13,
                    weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EVIDENCE OF VALUES-BASED CULTURE
// ═══════════════════════════════════════════════════════════════

class _EvidenceCultureCard extends ConsumerWidget {
  const _EvidenceCultureCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cqcAsync = ref.watch(cqcReportDataProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evidence of Values-Based Culture',
              style: _inter(14,
                  weight: FontWeight.w600, color: const Color(0xFF111827))),
          const SizedBox(height: 14),
          cqcAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (cqc) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monthly values distribution:',
                        style: _inter(13, color: const Color(0xFF6B7280))),
                    Text('${cqc.taggedRecognitions} tagged recognitions',
                        style: _inter(13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF1E3A8A))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Values alignment trend',
                        style: _inter(13, color: const Color(0xFF6B7280))),
                    Text(
                      '+${cqc.valuesAlignmentTrend.abs().toStringAsFixed(0)}% this month',
                      style: _inter(13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF16A34A)),
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
}

// ═══════════════════════════════════════════════════════════════
// NEEDS REVIEW PANEL
// ═══════════════════════════════════════════════════════════════

class _NeedsReviewPanel extends ConsumerStatefulWidget {
  const _NeedsReviewPanel();

  @override
  ConsumerState<_NeedsReviewPanel> createState() => _NeedsReviewPanelState();
}

class _NeedsReviewPanelState extends ConsumerState<_NeedsReviewPanel> {
  static const _pageSize = 10;
  int _limit = _pageSize;
  List<PendingPost> _posts = [];
  bool _loading = true;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool reset = false}) async {
    if (reset) {
      setState(() {
        _limit = _pageSize;
        _loading = true;
      });
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .where('approvalStatus', isEqualTo: 'pending')
          .get();

      final all = snap.docs.map((doc) {
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

      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _hasMore = all.length > _limit;
          _posts = all.take(_limit).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[WebManager] Failed to fetch posts: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadMore() {
    setState(() => _limit += _pageSize);
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Needs review',
                    style: _inter(15,
                        weight: FontWeight.w600,
                        color: const Color(0xFF111827))),
                if (_posts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${_posts.length}',
                        style: _inter(12,
                            weight: FontWeight.w600,
                            color: const Color(0xFFEF4444))),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Scrollable posts list ──
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_posts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 40, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 8),
                    Text('All caught up!',
                        style: _inter(14,
                            weight: FontWeight.w600,
                            color: const Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    Text('No posts pending review',
                        style: _inter(12, color: const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 560),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: _posts.length,
                itemBuilder: (_, i) => _PostReviewCard(
                  post: _posts[i],
                  onRefresh: () => _fetch(reset: true),
                ),
              ),
            ),

          // ── Load More ──
          if (_hasMore && !_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _loadMore,
                  child: Text('Load more',
                      style: _inter(13,
                          weight: FontWeight.w500,
                          color: const Color(0xFF1E3A8A))),
                ),
              ),
            ),

          // ── Give Kudos Now ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  barrierColor: Colors.black54,
                  builder: (_) => const _QuickRecognitionDialog(),
                ),
                icon: const Icon(Icons.star_rounded, size: 18),
                label: Text('Give Kudos Now',
                    style: _inter(14,
                        weight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostReviewCard extends ConsumerStatefulWidget {
  final PendingPost post;
  final VoidCallback onRefresh;
  const _PostReviewCard({required this.post, required this.onRefresh});

  @override
  ConsumerState<_PostReviewCard> createState() => _PostReviewCardState();
}

class _PostReviewCardState extends ConsumerState<_PostReviewCard> {
  bool _loading = false;

  Future<void> _activate() async {
    setState(() => _loading = true);
    await activatePost(
      widget.post.postId,
      ref.read(currentUserProvider)?.uid ?? '',
    );
    ref.invalidate(dashboardStatsProvider);
    widget.onRefresh();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deactivate() async {
    setState(() => _loading = true);
    await deactivatePost(
      widget.post.postId,
      ref.read(currentUserProvider)?.uid ?? '',
    );
    ref.invalidate(dashboardStatsProvider);
    widget.onRefresh();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Post', style: _inter(16, weight: FontWeight.w600)),
        content: Text(
            'This will permanently delete the post. This cannot be undone.',
            style: _inter(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: _inter(14)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text('Delete', style: _inter(14, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loading = true);
    await deletePost(
      widget.post.postId,
      ref.read(currentUserProvider)?.uid ?? '',
    );
    ref.invalidate(dashboardStatsProvider);
    widget.onRefresh();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatar(p.authorName, null, radius: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.authorName,
                        style: _inter(13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF111827))),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      children: [
                        _roleBadge(_displayRole(p.authorRole)),
                        if (p.hasGdprFlag) _gdprBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Content — max 3 lines
          Text(
            p.content,
            style: _inter(12.5, color: const Color(0xFF374151)),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Actions
          if (_loading)
            const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Row(
              children: [
                // Delete icon button
                OutlinedButton(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                  ),
                  child: const Icon(Icons.delete_outline, size: 16),
                ),
                const SizedBox(width: 8),
                // Deactivate button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _deactivate,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Deactivate',
                        style: _inter(12, weight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 8),
                // Activate button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _activate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Activate',
                        style: _inter(12,
                            weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _displayRole(String role) {
    switch (role) {
      case 'care_worker':
        return 'Care Worker';
      case 'senior_carer':
        return 'Senior Carer';
      case 'manager':
        return 'Manager';
      default:
        return role;
    }
  }

  Widget _roleBadge(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: _inter(11, color: const Color(0xFF6B7280))),
      );

  Widget _gdprBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined,
                size: 11, color: Color(0xFFEF4444)),
            const SizedBox(width: 3),
            Text('GDPR',
                style: _inter(11,
                    weight: FontWeight.w600, color: const Color(0xFFEF4444))),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// THREE-COLUMN ROW
// ═══════════════════════════════════════════════════════════════

class _ThreeColumnRow extends ConsumerWidget {
  const _ThreeColumnRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Expanded(child: _RisingStarsCard()),
          SizedBox(width: 16),
          Expanded(child: _TeamRecognitionCard()),
          SizedBox(width: 16),
          Expanded(child: _TopChampionsCard()),
        ],
      ),
    );
  }
}

// ── Rising Stars ──
class _RisingStarsCard extends ConsumerWidget {
  const _RisingStarsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(risingStarsProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rising Stars',
              style: _inter(15,
                  weight: FontWeight.w600, color: const Color(0xFF111827))),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (stars) {
              if (stars.isEmpty) {
                return Text('No data yet',
                    style: _inter(13, color: const Color(0xFF9CA3AF)));
              }
              return Column(
                children: stars.map((s) => _RisingStarRow(star: s)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _mapRole(String raw) {
  switch (raw) {
    case 'care_worker':
      return 'Care Worker';
    case 'senior_carer':
      return 'Senior Carer';
    case 'manager':
      return 'Manager';
    case 'family_member':
      return 'Family Member';
    default:
      return raw.isNotEmpty
          ? raw[0].toUpperCase() + raw.substring(1).replaceAll('_', ' ')
          : raw;
  }
}

class _RisingStarRow extends StatelessWidget {
  final RisingStar star;
  const _RisingStarRow({required this.star});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(star.name, star.profilePhotoBase64, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(star.name,
                        style: _inter(13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF111827))),
                    Text(_mapRole(star.description),
                        style: _inter(11.5,
                            color: const Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text('${star.starsLast60Days} stars (60d)',
                  style:
                      _inter(12, color: const Color(0xFF6B7280))),
              const Spacer(),
              const Icon(Icons.emoji_events_outlined,
                  size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text('${star.points} pts',
                  style: _inter(12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF374151))),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showStaffProfile(
                context,
                star.uid,
                star.name,
                role: star.description,
                photoBase64: star.profilePhotoBase64,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
                side: const BorderSide(color: Color(0xFF1E3A8A)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('View Full Profile',
                  style: _inter(12,
                      weight: FontWeight.w600,
                      color: const Color(0xFF1E3A8A))),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Team Recognition ──
class _TeamRecognitionCard extends ConsumerWidget {
  const _TeamRecognitionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamRecognitionProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Team Recognition',
              style: _inter(15,
                  weight: FontWeight.w600, color: const Color(0xFF111827))),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (members) {
              if (members.isEmpty) {
                return Text('No data yet',
                    style: _inter(13, color: const Color(0xFF9CA3AF)));
              }
              return Column(
                children: members
                    .take(6)
                    .map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _showStaffProfile(
                              context, m.uid, m.name,
                              photoBase64: m.profilePhotoBase64),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                            children: [
                              _avatar(m.name, m.profilePhotoBase64,
                                  radius: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(m.name,
                                    style: _inter(13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF111827))),
                              ),
                              const Icon(Icons.star_rounded,
                                  size: 16, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Text('${m.totalStars}',
                                  style: _inter(13,
                                      weight: FontWeight.w600,
                                      color: const Color(0xFF374151))),
                            ],
                          ),
                        ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Top Value Champions ──
class _TopChampionsCard extends ConsumerWidget {
  const _TopChampionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topValueChampionsProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Value Champions',
              style: _inter(15,
                  weight: FontWeight.w600, color: const Color(0xFF111827))),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (members) {
              if (members.isEmpty) {
                return Text('No data yet',
                    style: _inter(13, color: const Color(0xFF9CA3AF)));
              }
              return Column(
                children: members
                    .map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _showStaffProfile(
                              context, m.uid, m.name,
                              photoBase64: m.profilePhotoBase64),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                            children: [
                              _avatar(m.name, m.profilePhotoBase64,
                                  radius: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(m.name,
                                    style: _inter(13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF111827))),
                              ),
                              const Icon(Icons.emoji_events_outlined,
                                  size: 16, color: Color(0xFF6B7280)),
                              const SizedBox(width: 4),
                              Text('${m.totalStars} pts',
                                  style: _inter(13,
                                      weight: FontWeight.w600,
                                      color: const Color(0xFF374151))),
                            ],
                          ),
                        ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COMPANY CULTURE SECTION
// ═══════════════════════════════════════════════════════════════

class _CompanyCultureSection extends ConsumerWidget {
  const _CompanyCultureSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Company Culture',
            style: _inter(18,
                weight: FontWeight.w700, color: const Color(0xFF111827))),
        const SizedBox(height: 16),

        // Morale + Culture Health
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(child: _MoraleTrendCard()),
              SizedBox(width: 16),
              Expanded(child: _CultureHealthCard()),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CQC KLOE Scores: Well-Led & Caring
        const _CqcKloeCard(),
        const SizedBox(height: 16),

        // Values by day + Recognition Gaps
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(child: _ValuesByDayCard()),
              SizedBox(width: 16),
              Expanded(child: _RecognitionGapsCard()),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Morale Trend Chart ──
class _MoraleTrendCard extends ConsumerWidget {
  const _MoraleTrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(moraleTrendProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Morale Trend (Last 30 Days)',
              style: _inter(14,
                  weight: FontWeight.w600, color: const Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('Recognition activity increased 12% compared to last month.',
              style: _inter(12, color: const Color(0xFF6B7280))),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (points) {
                if (points.isEmpty) {
                  return Center(
                      child: Text('No data',
                          style: _inter(13,
                              color: const Color(0xFF9CA3AF))));
                }
                final spots = points.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.value);
                }).toList();
                final maxY = points
                        .map((p) => p.value)
                        .fold(0.0, (a, b) => a > b ? a : b) +
                    2;
                return LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY < 10 ? 10 : maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: const Color(0xFFE5E7EB),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}',
                            style: _inter(10,
                                color: const Color(0xFF9CA3AF)),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 7,
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx >= points.length) return const SizedBox();
                            return Text(
                              DateFormat('MMM d').format(points[idx].date),
                              style: _inter(10,
                                  color: const Color(0xFF9CA3AF)),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: const Color(0xFF1E3A8A),
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF1E3A8A).withOpacity(0.08),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Culture Health Score ──
class _CultureHealthCard extends ConsumerWidget {
  const _CultureHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cultureHealthProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Culture Health Score',
              style: _inter(14,
                  weight: FontWeight.w600, color: const Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('Overall Culture Health Score',
              style: _inter(12, color: const Color(0xFF6B7280))),
          const SizedBox(height: 20),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (health) {
              final score = health.score.clamp(0.0, 100.0);
              return Column(
                children: [
                  // Gauge
                  Center(
                    child: SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: 18,
                              backgroundColor: const Color(0xFFE5E7EB),
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF1E3A8A)),
                            ),
                          ),
                          Text(
                            '${score.round()}%',
                            style: _inter(28,
                                weight: FontWeight.w700,
                                color: const Color(0xFF111827)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Metrics
                  _HealthMetricRow(
                      label: 'Participation Rate:',
                      value:
                          '${health.participationRate.round()}%'),
                  const SizedBox(height: 8),
                  _HealthMetricRow(
                      label: 'Average Stars per Staff:',
                      value: health.avgStarsPerStaff.toStringAsFixed(1)),
                  const SizedBox(height: 8),
                  _HealthMetricRow(
                      label: 'GDPR Clean Rate:',
                      value: '${health.gdprCleanRate.round()}%'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HealthMetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _HealthMetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _inter(13, color: const Color(0xFF6B7280))),
        Text(value,
            style: _inter(13,
                weight: FontWeight.w600, color: const Color(0xFF111827))),
      ],
    );
  }
}

// ── Values by Day ──
class _ValuesByDayCard extends ConsumerWidget {
  const _ValuesByDayCard();

  static const _dayColors = [
    Color(0xFF93C5FD),
    Color(0xFF60A5FA),
    Color(0xFF3B82F6),
    Color(0xFF1D4ED8),
    Color(0xFF1E3A8A),
    Color(0xFFDBEAFE),
    Color(0xFFBFDBFE),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(valuesDistributionProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Values Distribution',
              style: _inter(14,
                  weight: FontWeight.w600, color: const Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('Values Distribution',
              style: _inter(12, color: const Color(0xFF6B7280))),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (dist) {
              final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              final counts = days.map((d) {
                final dayData = dist.byDay[d] ?? {};
                return dayData.values.fold(0, (a, b) => a + b);
              }).toList();
              final maxCount =
                  counts.fold(0, (a, b) => a > b ? a : b);

              return Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: days.asMap().entries.map((entry) {
                        final i = entry.key;
                        final day = entry.value;
                        final count = counts[i];
                        final ratio = maxCount > 0
                            ? count / maxCount
                            : 0.0;
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: FractionallySizedBox(
                                      heightFactor: ratio < 0.05
                                          ? 0.05
                                          : ratio,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _dayColors[
                                              i % _dayColors.length],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(day,
                                    style: _inter(10,
                                        color:
                                            const Color(0xFF9CA3AF))),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 8),
                        Text(
                          'Most active day: ${dist.mostActiveDay}',
                          style: _inter(13,
                              weight: FontWeight.w500,
                              color: const Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Recognition Gaps ──
class _RecognitionGapsCard extends ConsumerWidget {
  const _RecognitionGapsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recognitionGapsProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recognition Gaps',
              style: _inter(14,
                  weight: FontWeight.w600, color: const Color(0xFF111827))),
          const SizedBox(height: 4),
          async.when(
            loading: () => const SizedBox(),
            error: (e, _) => const SizedBox(),
            data: (gaps) => Text(
              '${gaps.length} staff have received no recognition this week.',
              style: _inter(12, color: const Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (gaps) {
              if (gaps.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 20, color: Color(0xFF16A34A)),
                      const SizedBox(width: 10),
                      Text('All staff recognised this week!',
                          style: _inter(13,
                              weight: FontWeight.w500,
                              color: const Color(0xFF16A34A))),
                    ],
                  ),
                );
              }
              return Column(
                children: gaps
                    .take(5)
                    .map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showStaffProfile(
                                  context, g.uid, g.name,
                                  role: g.role,
                                  photoBase64: g.profilePhotoBase64),
                                child: _avatar(g.name, g.profilePhotoBase64,
                                    radius: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showStaffProfile(
                                    context, g.uid, g.name,
                                    role: g.role,
                                    photoBase64: g.profilePhotoBase64),
                                  child: Text(g.name,
                                    style: _inter(13,
                                        weight: FontWeight.w500,
                                        color:
                                            const Color(0xFF111827))),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => showDialog(
                                  context: context,
                                  barrierColor: Colors.black54,
                                  builder: (_) => _QuickRecognitionDialog(
                                    preselectedUid: g.uid,
                                    preselectedName: g.name,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  minimumSize: const Size(110, 40),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(6)),
                                ),
                                child: Text('Give Kudos',
                                    style: _inter(13,
                                        weight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CQC REPORT DATA PROVIDER (helper)
// ═══════════════════════════════════════════════════════════════

final cqcReportDataProvider = FutureProvider<CqcReportData>((ref) async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  final snap = await FirebaseFirestore.instance
      .collection(AppConstants.postsCollection)
      .where('approvalStatus', isEqualTo: 'approved')
      .get();

  int tagged = 0;
  int prevMonth = 0;
  int thisMonth = 0;

  for (final doc in snap.docs) {
    final data = doc.data();
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    if (createdAt == null) continue;
    if (createdAt.isAfter(startOfMonth)) {
      tagged++;
      thisMonth++;
    } else if (createdAt.isAfter(
        DateTime(now.year, now.month - 1, 1))) {
      prevMonth++;
    }
  }

  final trend = prevMonth > 0
      ? ((thisMonth - prevMonth) / prevMonth * 100)
      : (thisMonth > 0 ? 100.0 : 0.0);

  return CqcReportData(
    taggedRecognitions: tagged,
    valuesAlignmentTrend: trend,
    monthlyValuesDistribution: tagged,
  );
});

// ═══════════════════════════════════════════════════════════════
// STAFF PROFILE DIALOG
// ═══════════════════════════════════════════════════════════════

void _showStaffProfile(BuildContext context, String uid, String name,
    {String? role, String? photoBase64}) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _StaffProfileDialog(
      uid: uid,
      name: name,
      role: role,
      photoBase64: photoBase64,
    ),
  );
}

class _StaffProfileDialog extends ConsumerStatefulWidget {
  final String uid;
  final String name;
  final String? role;
  final String? photoBase64;

  const _StaffProfileDialog({
    required this.uid,
    required this.name,
    this.role,
    this.photoBase64,
  });

  @override
  ConsumerState<_StaffProfileDialog> createState() => _StaffProfileDialogState();
}

class _StaffProfileDialogState extends ConsumerState<_StaffProfileDialog> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _recentPosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(widget.uid)
          .get();

      final postsSnap = await FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .where('authorId', isEqualTo: widget.uid)
          .where('isActive', isEqualTo: true)
          .get();

      final posts = postsSnap.docs.map((d) => d.data()).toList();
      posts.sort((a, b) {
        final at = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bt = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bt.compareTo(at);
      });

      if (mounted) {
        setState(() {
          _userData = userDoc.data();
          _recentPosts = posts.take(3).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[WebManager] Failed to load user profile: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _displayRole(String? role) {
    switch (role) {
      case 'care_worker': return 'Care Worker';
      case 'senior_carer': return 'Senior Carer';
      case 'manager': return 'Manager';
      case 'admin': return 'Admin';
      default: return role ?? 'Staff';
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final totalStars = _userData?['totalStars'] as int? ?? 0;
    final starsThisMonth = _userData?['starsThisMonth'] as int? ?? 0;
    final role = _userData?['role'] as String? ?? widget.role;
    final photoB64 = _userData?['profilePhotoBase64'] as String? ?? widget.photoBase64;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  _avatar(widget.name, photoB64, radius: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.name,
                            style: _inter(16,
                                weight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(_displayRole(role),
                            style: _inter(13, color: Colors.white70)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )
            else ...[
              // ── Stats row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    _profileStat('Total Stars', '$totalStars',
                        Icons.star_rounded, const Color(0xFFF59E0B)),
                    const SizedBox(width: 12),
                    _profileStat('This Month', '$starsThisMonth',
                        Icons.calendar_month_outlined, const Color(0xFF3B82F6)),
                    const SizedBox(width: 12),
                    _profileStat('Posts', '${_recentPosts.length}+',
                        Icons.article_outlined, const Color(0xFF10B981)),
                  ],
                ),
              ),

              // ── Recent posts ──
              if (_recentPosts.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Recent Posts',
                        style: _inter(13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF374151))),
                  ),
                ),
                ...(_recentPosts.map((post) => Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  post['category'] ?? 'General',
                                  style: _inter(11,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFF1E3A8A)),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _timeAgo(post['createdAt'] as Timestamp?),
                                style: _inter(11, color: const Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            post['content'] ?? '',
                            style: _inter(12.5, color: const Color(0xFF374151)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ))),
              ] else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text('No active posts yet.',
                      style: _inter(13, color: const Color(0xFF9CA3AF))),
                ),

              // ── Give Kudos button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        barrierColor: Colors.black54,
                        builder: (_) => _QuickRecognitionDialog(
                          preselectedUid: widget.uid,
                          preselectedName: widget.name,
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: Text('Give Kudos',
                        style: _inter(14,
                            weight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _profileStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value,
                style: _inter(18,
                    weight: FontWeight.w700, color: const Color(0xFF111827))),
            const SizedBox(height: 2),
            Text(label,
                style: _inter(11, color: const Color(0xFF6B7280)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUICK RECOGNITION DIALOG
// ═══════════════════════════════════════════════════════════════

class _QuickRecognitionDialog extends ConsumerStatefulWidget {
  final String? preselectedUid;
  final String? preselectedName;

  const _QuickRecognitionDialog({this.preselectedUid, this.preselectedName});

  @override
  ConsumerState<_QuickRecognitionDialog> createState() =>
      _QuickRecognitionDialogState();
}

class _QuickRecognitionDialogState
    extends ConsumerState<_QuickRecognitionDialog> {
  // ── Star tier selection (1/3/5) ──
  int _selectedStars = 1;

  // ── Staff search ──
  final _searchCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  List<_StaffSearchResult> _results = [];
  _StaffSearchResult? _selected;
  bool _searching = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedUid != null && widget.preselectedName != null) {
      _selected = _StaffSearchResult(
          uid: widget.preselectedUid!,
          name: widget.preselectedName!,
          role: '');
      _searchCtrl.text = widget.preselectedName!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() { _results = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .get();
      final lower = q.toLowerCase();
      final results = snap.docs
          .where((d) {
            final data = d.data();
            final role = data['role'] as String? ?? '';
            if (role != 'care_worker' && role != 'senior_carer') return false;
            final name =
                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                    .trim()
                    .toLowerCase();
            return name.contains(lower);
          })
          .map((d) {
            final data = d.data();
            return _StaffSearchResult(
              uid: d.id,
              name:
                  '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
              role: _fmtRole(data['role'] as String? ?? ''),
              photo: data['profilePhotoBase64'] as String?,
            );
          })
          .take(8)
          .toList();
      if (mounted) setState(() { _results = results; _searching = false; });
    } catch (e) {
      debugPrint('[WebManager] Staff search failed: $e');
      if (mounted) setState(() { _results = []; _searching = false; });
    }
  }

  String _fmtRole(String r) => r
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  void _selectStaff(_StaffSearchResult s) {
    setState(() {
      _selected = s;
      _searchCtrl.text = s.name;
      _results = [];
    });
  }

  Future<void> _send() async {
    if (_selected == null || _sending) return;
    final currentUser = ref.read(currentUserProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (currentUser == null) return;

    setState(() { _sending = true; _error = null; });
    try {
      final postId = await giveManagerStarToUser(
        staffUid: _selected!.uid,
        managerId: currentUser.uid,
        managerName: profile?.fullName ?? 'Manager',
        note: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
        starPoints: _selectedStars,
      );
      if (postId != null) {
        ref.invalidate(teamRecognitionProvider);
        ref.invalidate(risingStarsProvider);
        ref.invalidate(topValueChampionsProvider);
        ref.invalidate(dashboardStatsProvider);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gave $_selectedStars star${_selectedStars > 1 ? 's' : ''} to ${_selected!.name}!'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title ──
              Center(
                child: Column(
                  children: [
                    Text('Quick Recognition',
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827))),
                    const SizedBox(height: 6),
                    Text('Send recognition instantly to a team member.',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: const Color(0xFF6B7280))),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Select Staff Member ──
              Text('Select Staff Member',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    if (_selected != null && v != _selected!.name) {
                      setState(() => _selected = null);
                    }
                    _search(v);
                  },
                  style: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.person_outline,
                        size: 20, color: Color(0xFF9CA3AF)),
                    suffixIcon: _selected != null
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: Color(0xFF9CA3AF)),
                            onPressed: () => setState(() {
                              _selected = null;
                              _searchCtrl.clear();
                              _results = [];
                            }),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),

              // ── Search results ──
              if (_searching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                ),
              if (_results.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (_, i) {
                      final s = _results[i];
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        leading: _staffAvatar(s),
                        title: Text(s.name,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827))),
                        subtitle: Text(s.role,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6B7280))),
                        onTap: () => _selectStaff(s),
                      );
                    },
                  ),
                ),

              // ── Selected chip ──
              if (_selected != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E3A8A)),
                  ),
                  child: Row(
                    children: [
                      _staffAvatar(_selected!, radius: 14),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(_selected!.name,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E3A8A)))),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selected = null;
                          _searchCtrl.clear();
                        }),
                        child: const Icon(Icons.close,
                            size: 16, color: Color(0xFF1E3A8A)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Star tier selection ──
              Text('Send a recognition star',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151))),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StarTile(stars: 1, points: 1, selected: _selectedStars == 1,
                      onTap: () => setState(() => _selectedStars = 1)),
                  const SizedBox(width: 10),
                  _StarTile(stars: 3, points: 3, selected: _selectedStars == 3,
                      onTap: () => setState(() => _selectedStars = 3)),
                  const SizedBox(width: 10),
                  _StarTile(stars: 5, points: 5, selected: _selectedStars == 5,
                      onTap: () => setState(() => _selectedStars = 5)),
                ],
              ),

              const SizedBox(height: 24),

              // ── Comment ──
              Text('Add Comment',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151))),
              const SizedBox(height: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _commentCtrl,
                builder: (_, val, __) => Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _commentCtrl,
                        maxLines: 3,
                        maxLength: 250,
                        maxLengthEnforcement:
                            MaxLengthEnforcement.enforced,
                        style: GoogleFonts.inter(
                            fontSize: 14, color: const Color(0xFF111827)),
                        decoration: InputDecoration(
                          hintText:
                              'Add a short message (optional but recommended).',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                          counterText: '',
                          prefixIcon: const Padding(
                            padding:
                                EdgeInsets.fromLTRB(12, 12, 0, 0),
                            child: Icon(Icons.chat_bubble_outline,
                                size: 18, color: Color(0xFF9CA3AF)),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(maxWidth: 40),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${val.text.length}/250 characters',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.red)),
              ],

              const SizedBox(height: 24),

              // ── Send button ──
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_selected != null && !_sending) ? _send : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white)))
                      : Text('Send Recognition',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),

              // ── Cancel ──
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: const Color(0xFF6B7280))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staffAvatar(_StaffSearchResult s, {double radius = 18}) {
    if (s.photo != null && s.photo!.isNotEmpty) {
      try {
        final bytes = const Base64Decoder().convert(
            s.photo!.contains(',') ? s.photo!.split(',').last : s.photo!);
        return CircleAvatar(
            radius: radius, backgroundImage: MemoryImage(bytes));
      } catch (_) {}
    }
    final initials = s.name.trim().isNotEmpty
        ? s.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF1E3A8A),
      child: Text(initials.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: radius * 0.7,
              fontWeight: FontWeight.w600,
              color: Colors.white)),
    );
  }
}

// ── Star tier tile ──
class _StarTile extends StatelessWidget {
  final int stars;
  final int points;
  final bool selected;
  final VoidCallback onTap;

  const _StarTile(
      {required this.stars,
      required this.points,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEFF6FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '$stars Star${stars > 1 ? 's' : ''}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827)),
                    ),
                  ),
                  const SizedBox(width: 2),
                  ...List.generate(
                      stars,
                      (_) => const Icon(Icons.star_rounded,
                          size: 12, color: Color(0xFFF59E0B))),
                  const Spacer(),
                  if (selected)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E3A8A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          size: 10, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text('$points point${points > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Staff search result model ──
class _StaffSearchResult {
  final String uid;
  final String name;
  final String role;
  final String? photo;

  const _StaffSearchResult(
      {required this.uid,
      required this.name,
      required this.role,
      this.photo});
}

// ═══════════════════════════════════════════════════════
// CQC KLOE SCORES CARD
// ═══════════════════════════════════════════════════════

class _CqcKloeCard extends ConsumerWidget {
  const _CqcKloeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kloe = ref.watch(cqcKloeScoresProvider);

    return kloe.when(
      data: (data) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CQC KLOE Scores',
                style: _inter(16,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111827))),
            const SizedBox(height: 4),
            Text('Auto-calculated from recognition data',
                style: _inter(13, color: const Color(0xFF6B7280))),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _WebKloeGauge(
                    title: 'Well-Led',
                    score: data.wellLedScore,
                    color: const Color(0xFF1E3A8A),
                    metrics: {
                      'Staff Participation': '${data.staffParticipationRate.toStringAsFixed(0)}%',
                      'Manager Engagement': '${data.managerEngagementRate.toStringAsFixed(0)}%',
                      'Recognition Frequency': '${data.recognitionFrequency.toStringAsFixed(0)}%',
                      'Values Alignment': '${data.valuesAlignmentPercent.toStringAsFixed(0)}%',
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _WebKloeGauge(
                    title: 'Caring',
                    score: data.caringScore,
                    color: const Color(0xFF16A34A),
                    metrics: {
                      'Compassion Tags': '${data.compassionTagPercent.toStringAsFixed(0)}%',
                      'Peer Recognition': '${data.peerRecognitionRate.toStringAsFixed(0)}%',
                      'Stars per Staff': data.recognitionPerStaff.toStringAsFixed(1),
                      'Morale Consistency': '${data.moraleTrendScore.toStringAsFixed(0)}%',
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text('Failed to load CQC KLOE scores',
            style: _inter(13, color: const Color(0xFFDC2626))),
      ),
    );
  }
}

class _WebKloeGauge extends StatelessWidget {
  final String title;
  final double score;
  final Color color;
  final Map<String, String> metrics;

  const _WebKloeGauge({
    required this.title,
    required this.score,
    required this.color,
    required this.metrics,
  });

  String get _rating {
    if (score >= 80) return 'Outstanding';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Requires Improvement';
    return 'Inadequate';
  }

  Color get _ratingColor {
    if (score >= 80) return const Color(0xFF16A34A);
    if (score >= 60) return const Color(0xFF2563EB);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final normalised = (score / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(title,
              style: _inter(15, weight: FontWeight.w700, color: color)),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            width: 110,
            child: CustomPaint(
              painter: _WebKloeGaugePainter(normalised, color),
              child: Center(
                child: Text('${score.toInt()}',
                    style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _ratingColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_rating,
                style: _inter(11,
                    weight: FontWeight.w600, color: _ratingColor)),
          ),
          const SizedBox(height: 14),
          ...metrics.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: _inter(12, color: const Color(0xFF6B7280))),
                    Text(e.value,
                        style: _inter(12,
                            weight: FontWeight.w600, color: color)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _WebKloeGaugePainter extends CustomPainter {
  final double fraction;
  final Color color;

  _WebKloeGaugePainter(this.fraction, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = 2.4;
    const sweepAngle = 4.0;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * fraction,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WebKloeGaugePainter old) =>
      old.fraction != fraction || old.color != color;
}
