import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/permissions_provider.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/utils/constants.dart';
import 'providers/manager_dashboard_provider.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends ConsumerState<ManagerDashboardScreen> {
  int _currentNavIndex = 0;

  void _onNavTap(int index) {
    if (index == 0) {
      setState(() => _currentNavIndex = index);
    } else if (index == 1) {
      context.push('/create-post');
    } else if (index == 2) {
      context.push('/notifications');
    } else if (index == 3) {
      context.push('/profile');
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(pendingPostsProvider);
    ref.invalidate(coreValuesStatsProvider);
    ref.invalidate(risingStarsProvider);
    ref.invalidate(teamRecognitionProvider);
    ref.invalidate(topValueChampionsProvider);
    ref.invalidate(recognitionGapsProvider);
    ref.invalidate(valuesDistributionProvider);
    ref.invalidate(moraleTrendProvider);
    ref.invalidate(cultureHealthProvider);
    ref.invalidate(cqcReportProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _giveManagerStar(String staffUid, String staffName) async {
    final currentUser = ref.read(currentUserProvider);
    final profile = ref.read(userProfileProvider).value;
    if (currentUser == null) return;

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allXl),
        title: Text('Give Manager Star', style: AppTypography.headingH5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Give a 3× Manager Star to $staffName?',
              style: AppTypography.bodyB4,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gold50,
                borderRadius: AppRadius.allLg,
              ),
              child: Row(
                children: [
                  Icon(Icons.star, size: 18, color: AppColors.gold400),
                  const SizedBox(width: 6),
                  Text(
                    'Worth ${AppConstants.managerStarMultiplier} points (Manager multiplier)',
                    style: AppTypography.captionC1
                        .copyWith(color: AppColors.gold600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: Icon(Icons.star, size: 16),
            label: const Text('Give Star'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final postId = await giveManagerStarToUser(
        staffUid: staffUid,
        managerId: currentUser.uid,
        managerName: profile?.fullName ?? 'Manager',
      );
      if (postId != null) {
        ref.invalidate(teamRecognitionProvider);
        ref.invalidate(recognitionGapsProvider);
        ref.invalidate(risingStarsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('⭐ Gave ${AppConstants.managerStarMultiplier}× star to $staffName!'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$staffName has no posts to star yet'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to give star: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            _buildAppBar(profile),
            // ── Scrollable content ──
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatCards(),
                      const SizedBox(height: 24),
                      _buildNeedsReviewSection(),
                      const SizedBox(height: 24),
                      _buildCoreValuesSection(),
                      const SizedBox(height: 24),
                      _buildRisingStarsSection(),
                      const SizedBox(height: 24),
                      _buildTeamRecognitionSection(),
                      const SizedBox(height: 24),
                      _buildTopValueChampionsSection(),
                      const SizedBox(height: 24),
                      _buildCqcEvidenceReport(),
                      const SizedBox(height: 24),
                      _buildRecognitionGapsSection(),
                      const SizedBox(height: 24),
                      _buildValuesDistributionSection(),
                      const SizedBox(height: 24),
                      _buildMoraleTrendSection(),
                      const SizedBox(height: 24),
                      _buildCultureHealthSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
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
          onPressed: () => context.push('/create-post'),
          backgroundColor: AppColors.secondary,
          elevation: 6,
          shape: const CircleBorder(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.white, size: 20),
              Text('Kudos',
                  style: AppTypography.captionC2
                      .copyWith(color: Colors.white, fontSize: 8)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ═══════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════

  Widget _buildAppBar(AsyncValue<UserProfile?> profile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Image.asset(
            'assets/images/smallLogo.png',
            height: 30,
            errorBuilder: (_, __, ___) => Text(
              'CareKudos',
              style: AppTypography.headingH4
                  .copyWith(color: AppColors.primary),
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.navy50,
              borderRadius: AppRadius.allPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Manager',
                  style: AppTypography.captionC1
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push('/settings'),
            child: profile.when(
              data: (p) {
                if (p != null && p.hasProfilePhoto) {
                  return CircleAvatar(
                    radius: 18,
                    backgroundImage: MemoryImage(p.profilePhotoBytes!),
                  );
                }
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.neutral200,
                  child: Icon(Icons.person,
                      size: 20, color: AppColors.neutral600),
                );
              },
              loading: () => CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.neutral200,
              ),
              error: (_, __) => CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.neutral200,
                child: Icon(Icons.person,
                    size: 20, color: AppColors.neutral600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // STAT CARDS (2x2 grid)
  // ═══════════════════════════════════════════════════

  Widget _buildStatCards() {
    final stats = ref.watch(dashboardStatsProvider);

    return stats.when(
      data: (data) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DashStatCard(
                  value: data.pendingReviews.toString(),
                  label: 'Posts pending review',
                  icon: Icons.rate_review_outlined,
                  iconColor: AppColors.coral500,
                  iconBg: AppColors.coral50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashStatCard(
                  value: data.gdprFlags.toString(),
                  label: 'GDPR flags',
                  icon: Icons.flag_outlined,
                  iconColor: AppColors.red500,
                  iconBg: AppColors.red50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DashStatCard(
                  value: data.activeStaffToday.toString(),
                  label: 'Active staff today',
                  icon: Icons.people_outline,
                  iconColor: AppColors.blue500,
                  iconBg: AppColors.blue50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashStatCard(
                  value: data.totalRecognitionsWeek.toString(),
                  label: 'Total recognitions (week)',
                  icon: Icons.star_outline,
                  iconColor: AppColors.gold400,
                  iconBg: AppColors.gold50,
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _ErrorCard(message: 'Failed to load stats'),
    );
  }

  // ═══════════════════════════════════════════════════
  // NEEDS REVIEW (horizontal scroll)
  // ═══════════════════════════════════════════════════

  Widget _buildNeedsReviewSection() {
    final pending = ref.watch(pendingPostsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Needs review', style: AppTypography.headingH4),
            const Spacer(),
            pending.when(
              data: (posts) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.coral50,
                  borderRadius: AppRadius.allPill,
                ),
                child: Text(
                  '${posts.length}',
                  style: AppTypography.bodyB5
                      .copyWith(color: AppColors.coral500),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        pending.when(
          data: (posts) {
            if (posts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.allXl,
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 40, color: AppColors.success),
                    const SizedBox(height: 8),
                    Text('All caught up!',
                        style: AppTypography.bodyB3
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }
            return SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _ReviewCard(post: posts[index], ref: ref),
              ),
            );
          },
          loading: () =>
              const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => _ErrorCard(message: 'Failed to load reviews'),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // CORE VALUES
  // ═══════════════════════════════════════════════════

  Widget _buildCoreValuesSection() {
    final values = ref.watch(coreValuesStatsProvider);

    return _SectionCard(
      title: 'Core Values',
      child: values.when(
        data: (stats) {
          if (stats.isEmpty) {
            return Text('No data this week',
                style: AppTypography.bodyB4
                    .copyWith(color: AppColors.textSecondary));
          }
          final maxCount =
              stats.map((s) => s.count).reduce((a, b) => a > b ? a : b);
          return Column(
            children: stats.map((stat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ValueBar(
                  label: stat.name,
                  count: stat.count,
                  maxCount: maxCount > 0 ? maxCount : 1,
                  color: _valueColor(stat.name),
                ),
              );
            }).toList(),
          );
        },
        loading: () => const SizedBox(
            height: 100, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Failed to load',
            style:
                AppTypography.bodyB4.copyWith(color: AppColors.error)),
      ),
    );
  }

  Color _valueColor(String name) {
    switch (name.toLowerCase()) {
      case 'compassion':
        return AppColors.coral500;
      case 'teamwork':
        return AppColors.blue500;
      case 'excellence':
        return AppColors.teal500;
      default:
        return AppColors.navy400;
    }
  }

  // ═══════════════════════════════════════════════════
  // RISING STARS
  // ═══════════════════════════════════════════════════

  Widget _buildRisingStarsSection() {
    final stars = ref.watch(risingStarsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rising stars', style: AppTypography.headingH4),
        const SizedBox(height: 12),
        stars.when(
          data: (list) {
            if (list.isEmpty) {
              return _SectionCard(
                child: Text('No rising stars yet',
                    style: AppTypography.bodyB4
                        .copyWith(color: AppColors.textSecondary)),
              );
            }
            return Column(
              children: list
                  .map((star) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RisingStarCard(star: star),
                      ))
                  .toList(),
            );
          },
          loading: () =>
              const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => _ErrorCard(message: 'Failed to load rising stars'),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // TEAM RECOGNITION
  // ═══════════════════════════════════════════════════

  Widget _buildTeamRecognitionSection() {
    final team = ref.watch(teamRecognitionProvider);

    return _SectionCard(
      title: 'Team Recognition',
      child: team.when(
        data: (members) {
          if (members.isEmpty) {
            return Text('No team members yet',
                style: AppTypography.bodyB4
                    .copyWith(color: AppColors.textSecondary));
          }
          return Column(
            children: members
                .map((m) => _TeamMemberRow(
                      member: m,
                      onGiveStar: () => _giveManagerStar(m.uid, m.name),
                    ))
                .toList(),
          );
        },
        loading: () =>
            const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Failed to load',
            style:
                AppTypography.bodyB4.copyWith(color: AppColors.error)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TOP VALUE CHAMPIONS
  // ═══════════════════════════════════════════════════

  Widget _buildTopValueChampionsSection() {
    final champions = ref.watch(topValueChampionsProvider);

    return _SectionCard(
      title: 'Top Value Champions',
      child: champions.when(
        data: (members) {
          if (members.isEmpty) {
            return Text('No champions yet',
                style: AppTypography.bodyB4
                    .copyWith(color: AppColors.textSecondary));
          }
          return Column(
            children: members.asMap().entries.map((entry) {
              final index = entry.key;
              final m = entry.value;
              return _ChampionRow(member: m, rank: index + 1);
            }).toList(),
          );
        },
        loading: () =>
            const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Failed to load',
            style:
                AppTypography.bodyB4.copyWith(color: AppColors.error)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // CQC EVIDENCE REPORT
  // ═══════════════════════════════════════════════════

  Widget _buildCqcEvidenceReport() {
    final report = ref.watch(cqcReportProvider);

    return report.when(
      data: (data) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.allXl,
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.navy50,
                    borderRadius: AppRadius.allLg,
                  ),
                  child: Icon(Icons.description_outlined,
                      size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CQC Evidence Report',
                          style: AppTypography.headingH5),
                      Text('Monthly compliance overview',
                          style: AppTypography.captionC1
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navy50,
                borderRadius: AppRadius.allLg,
              ),
              child: Text(
                'Evidence of Values-Based Culture',
                style: AppTypography.bodyB5
                    .copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            _CqcMetricRow(
              label: 'Monthly values distribution',
              value: '${data.monthlyValuesDistribution} values',
            ),
            const Divider(height: 16),
            _CqcMetricRow(
              label: 'Tagged recognitions',
              value: '${data.taggedRecognitions}',
            ),
            const Divider(height: 16),
            _CqcMetricRow(
              label: 'Values alignment trend',
              value: '${data.valuesAlignmentTrend.toStringAsFixed(0)}%',
              valueColor: AppColors.success,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: generate full report
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Report generation coming soon')),
                  );
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.allLg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () =>
          const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ErrorCard(message: 'Failed to load CQC report'),
    );
  }

  // ═══════════════════════════════════════════════════
  // RECOGNITION GAPS
  // ═══════════════════════════════════════════════════

  Widget _buildRecognitionGapsSection() {
    final gaps = ref.watch(recognitionGapsProvider);

    return gaps.when(
      data: (list) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.allXl,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recognition Gaps', style: AppTypography.headingH5),
              const SizedBox(height: 4),
              Text(
                '${list.length} staff have received no recognition this week',
                style: AppTypography.bodyB6
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 20, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text('Everyone has been recognised!',
                          style: AppTypography.bodyB4
                              .copyWith(color: AppColors.success)),
                    ],
                  ),
                )
              else
                ...list.take(5).map((gap) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          _AvatarWidget(
                              name: gap.name,
                              photoBase64: gap.profilePhotoBase64,
                              radius: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(gap.name,
                                    style: AppTypography.bodyB5),
                                Text(gap.role,
                                    style: AppTypography.captionC2
                                        .copyWith(
                                            color:
                                                AppColors.textTertiary)),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 32,
                            child: ElevatedButton.icon(
                              onPressed: () => _giveManagerStar(gap.uid, gap.name),
                              icon: Icon(Icons.star, size: 14),
                              label: const Text('Give Star'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.allLg,
                                ),
                                textStyle: AppTypography.captionC1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        );
      },
      loading: () =>
          const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          _ErrorCard(message: 'Failed to load recognition gaps'),
    );
  }

  // ═══════════════════════════════════════════════════
  // VALUES DISTRIBUTION (bar chart)
  // ═══════════════════════════════════════════════════

  Widget _buildValuesDistributionSection() {
    final distribution = ref.watch(valuesDistributionProvider);

    return distribution.when(
      data: (data) {
        return _SectionCard(
          title: 'Values Distribution',
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: _ValuesBarChart(data: data),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: AppRadius.allPill,
                ),
                child: Text(
                  'Most active day: ${data.mostActiveDay}',
                  style: AppTypography.captionC1
                      .copyWith(color: AppColors.blue600),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const SizedBox(height: 260, child: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          _ErrorCard(message: 'Failed to load values distribution'),
    );
  }

  // ═══════════════════════════════════════════════════
  // MORALE TREND (line chart)
  // ═══════════════════════════════════════════════════

  Widget _buildMoraleTrendSection() {
    final trend = ref.watch(moraleTrendProvider);

    return _SectionCard(
      title: 'Morale Trend (Last 30 Days)',
      child: trend.when(
        data: (points) {
          if (points.isEmpty) {
            return Text('No data yet',
                style: AppTypography.bodyB4
                    .copyWith(color: AppColors.textSecondary));
          }
          return SizedBox(
            height: 200,
            child: _MoraleTrendChart(points: points),
          );
        },
        loading: () =>
            const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Text('Failed to load',
            style:
                AppTypography.bodyB4.copyWith(color: AppColors.error)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // CULTURE HEALTH SCORE (circular gauge)
  // ═══════════════════════════════════════════════════

  Widget _buildCultureHealthSection() {
    final health = ref.watch(cultureHealthProvider);

    return health.when(
      data: (data) => _SectionCard(
        title: 'Culture Health Score',
        child: Column(
          children: [
            SizedBox(
              height: 180,
              width: 180,
              child: _CultureGauge(score: data.score),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _HealthMetric(
                    label: 'Participation Rate',
                    value: '${data.participationRate.toStringAsFixed(0)}%',
                  ),
                ),
                Expanded(
                  child: _HealthMetric(
                    label: 'Avg Stars / Staff',
                    value: data.avgStarsPerStaff.toStringAsFixed(1),
                  ),
                ),
                Expanded(
                  child: _HealthMetric(
                    label: 'GDPR Clean Rate',
                    value: '${data.gdprCleanRate.toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () =>
          const SizedBox(height: 280, child: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          _ErrorCard(message: 'Failed to load culture health score'),
    );
  }
}

// ═══════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════

/// Dashboard stat card (compact version for dashboard)
class _DashStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _DashStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.allXl,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: AppRadius.allLg,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTypography.displayD3),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.captionC1
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Review card for pending posts (horizontal scroll)
class _ReviewCard extends StatelessWidget {
  final PendingPost post;
  final WidgetRef ref;

  const _ReviewCard({required this.post, required this.ref});

  /// Shows a dialog for entering a reason.
  /// Returns the reason string on submit (can be empty string for optional reasons).
  /// Returns null ONLY when dialog is cancelled.
  Future<String?> _showReasonDialog(
    BuildContext context, {
    required String title,
    required String hintText,
    bool isRequired = false,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allXl),
        title: Text(title, style: AppTypography.headingH5),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.hasGdprFlag)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  borderRadius: AppRadius.allLg,
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: AppColors.red500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This post has been flagged for potential GDPR issues.',
                        style: AppTypography.captionC1
                            .copyWith(color: AppColors.red500),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.bodyB6
                    .copyWith(color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.allLg,
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.allLg,
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.allLg,
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // returns null → cancelled
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (isRequired && text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              // Return empty string for "submitted with no text" vs null for "cancelled"
              Navigator.pop(ctx, text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.allXl,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarWidget(
                  name: post.authorName,
                  photoBase64: null,
                  radius: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName,
                        style: AppTypography.bodyB5,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      _formatRole(post.authorRole),
                      style: AppTypography.captionC2
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              if (post.hasGdprFlag)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.red50,
                    borderRadius: AppRadius.allPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 10, color: AppColors.red500),
                      const SizedBox(width: 2),
                      Text('GDPR',
                          style: AppTypography.captionC2
                              .copyWith(color: AppColors.red500, fontSize: 9)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              post.content,
              style: AppTypography.bodyB6
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          // ── Three action buttons: Reject / Request Edit / Approve ──
          Row(
            children: [
              // Reject button
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () async {
                      final reason = await _showReasonDialog(
                        context,
                        title: post.hasGdprFlag
                            ? 'Reject – GDPR Violation'
                            : 'Reject Post',
                        hintText: post.hasGdprFlag
                            ? 'Explain the GDPR violation…'
                            : 'Reason for rejection (optional)',
                        isRequired: post.hasGdprFlag,
                      );
                      // null means dialog was cancelled → do nothing
                      if (reason == null) return;
                      try {
                        await rejectPost(
                          post.postId,
                          ref.read(currentUserProvider)?.uid ?? '',
                          reason: reason.isEmpty ? null : reason,
                        );
                        ref.invalidate(pendingPostsProvider);
                        ref.invalidate(dashboardStatsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post rejected')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to reject: $e')),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red500,
                      side: BorderSide(color: AppColors.red300),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.allLg,
                      ),
                    ),
                    child: const Text('Reject',
                        style: TextStyle(fontSize: 11)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Request Edit button
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () async {
                      final reason = await _showReasonDialog(
                        context,
                        title: 'Request Edit',
                        hintText: 'What needs to be changed?',
                        isRequired: true,
                      );
                      if (reason == null) return; // cancelled
                      try {
                        await requestEditPost(
                          post.postId,
                          ref.read(currentUserProvider)?.uid ?? '',
                          reason: reason,
                        );
                        ref.invalidate(pendingPostsProvider);
                        ref.invalidate(dashboardStatsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit requested')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to request edit: $e')),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold600,
                      side: BorderSide(color: AppColors.gold300),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.allLg,
                      ),
                    ),
                    child: const Text('Edit',
                        style: TextStyle(fontSize: 11)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Approve button
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await approvePost(
                            post.postId,
                            ref.read(currentUserProvider)?.uid ?? '');
                        ref.invalidate(pendingPostsProvider);
                        ref.invalidate(dashboardStatsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post approved')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to approve: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.allLg,
                      ),
                    ),
                    child: const Text('Approve',
                        style: TextStyle(fontSize: 11)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'care_worker':
        return 'Care Worker';
      case 'senior_carer':
        return 'Senior Carer';
      case 'manager':
        return 'Manager';
      case 'family_member':
        return 'Family Member';
      default:
        return role;
    }
  }
}

/// Section card wrapper
class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.allXl,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTypography.headingH5),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

/// Core value progress bar
class _ValueBar extends StatelessWidget {
  final String label;
  final int count;
  final int maxCount;
  final Color color;

  const _ValueBar({
    required this.label,
    required this.count,
    required this.maxCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = count / maxCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyB5),
            Text(count.toString(),
                style:
                    AppTypography.bodyB5.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.allPill,
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.neutral100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

/// Rising star card
class _RisingStarCard extends StatelessWidget {
  final RisingStar star;

  const _RisingStarCard({required this.star});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.allXl,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarWidget(
                  name: star.name,
                  photoBase64: star.profilePhotoBase64,
                  radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(star.name, style: AppTypography.bodyB3),
                    Text(star.description,
                        style: AppTypography.captionC1
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatPill(
                icon: Icons.star,
                iconColor: AppColors.gold400,
                label: '${star.starsLast60Days} stars (60d)',
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.emoji_events,
                iconColor: AppColors.coral500,
                label: '${star.points} pts',
              ),
              const Spacer(),
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.allLg,
                    ),
                  ),
                  child: Text('View Full Profile',
                      style: AppTypography.captionC1
                          .copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small stat pill
class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: AppRadius.allPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.captionC2),
        ],
      ),
    );
  }
}

/// Team member row in Team Recognition
class _TeamMemberRow extends StatelessWidget {
  final TeamMember member;
  final VoidCallback? onGiveStar;

  const _TeamMemberRow({required this.member, this.onGiveStar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _AvatarWidget(
              name: member.name,
              photoBase64: member.profilePhotoBase64,
              radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(member.name, style: AppTypography.bodyB5),
          ),
          Icon(Icons.star, size: 16, color: AppColors.gold400),
          const SizedBox(width: 4),
          Text('${member.totalStars}',
              style: AppTypography.bodyB5
                  .copyWith(fontWeight: FontWeight.w600)),
          if (onGiveStar != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              width: 28,
              child: IconButton(
                onPressed: onGiveStar,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.star_outline,
                    size: 20, color: AppColors.gold400),
                tooltip: 'Give Manager Star',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Champion row in Top Value Champions
class _ChampionRow extends StatelessWidget {
  final TeamMember member;
  final int rank;

  const _ChampionRow({required this.member, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _AvatarWidget(
              name: member.name,
              photoBase64: member.profilePhotoBase64,
              radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(member.name, style: AppTypography.bodyB5),
          ),
          Icon(Icons.emoji_events,
              size: 16,
              color: rank <= 3 ? AppColors.gold400 : AppColors.neutral400),
          const SizedBox(width: 4),
          Text('${member.totalStars} pts',
              style: AppTypography.bodyB5
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// CQC metric row
class _CqcMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CqcMetricRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodyB6
                .copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTypography.bodyB5.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            )),
      ],
    );
  }
}

/// Avatar helper widget
class _AvatarWidget extends StatelessWidget {
  final String name;
  final String? photoBase64;
  final double radius;

  const _AvatarWidget({
    required this.name,
    this.photoBase64,
    required this.radius,
  });

  Uint8List? get _photoBytes {
    if (photoBase64 == null || photoBase64!.isEmpty) return null;
    try {
      return base64Decode(photoBase64!);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _photoBytes;
    return CircleAvatar(
      radius: radius,
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      backgroundColor: AppColors.neutral200,
      child: bytes == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTypography.bodyB5
                  .copyWith(fontSize: radius * 0.7),
            )
          : null,
    );
  }
}

/// Error placeholder card
class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: AppRadius.allXl,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.red500, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTypography.bodyB5
                    .copyWith(color: AppColors.red600)),
          ),
        ],
      ),
    );
  }
}

/// Health metric column
class _HealthMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HealthMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTypography.headingH5
                .copyWith(color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTypography.captionC2
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// CHART WIDGETS
// ═══════════════════════════════════════════════════════

/// Values distribution bar chart
class _ValuesBarChart extends StatelessWidget {
  final ValuesDistribution data;

  const _ValuesBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = ['Compassion', 'Teamwork', 'Excellence'];
    final colors = [AppColors.coral500, AppColors.blue500, AppColors.teal500];

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(values.length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(values[i], style: AppTypography.captionC2),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _maxY(),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < days.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(days[idx],
                              style: AppTypography.captionC2),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 24,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(),
                          style: AppTypography.captionC2
                              .copyWith(color: AppColors.textTertiary));
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.neutral100,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(days.length, (dayIdx) {
                final dayData = data.byDay[days[dayIdx]] ?? {};
                return BarChartGroupData(
                  x: dayIdx,
                  barRods: [
                    BarChartRodData(
                      toY: _dayTotal(dayData).toDouble(),
                      width: 14,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                      rodStackItems: _buildStack(dayData, colors, values),
                      color: Colors.transparent,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  double _maxY() {
    double maxVal = 4;
    for (final entry in data.byDay.values) {
      final total =
          entry.values.fold<int>(0, (sum, v) => sum + v).toDouble();
      if (total > maxVal) maxVal = total;
    }
    return maxVal + 2;
  }

  int _dayTotal(Map<String, int> dayData) {
    return dayData.values.fold(0, (a, b) => a + b);
  }

  List<BarChartRodStackItem> _buildStack(
      Map<String, int> dayData, List<Color> colors, List<String> values) {
    final items = <BarChartRodStackItem>[];
    double from = 0;
    for (int i = 0; i < values.length; i++) {
      final count = (dayData[values[i]] ?? 0).toDouble();
      if (count > 0) {
        items.add(BarChartRodStackItem(from, from + count, colors[i]));
        from += count;
      }
    }
    return items;
  }
}

/// Morale trend line chart
class _MoraleTrendChart extends StatelessWidget {
  final List<MoraleTrendPoint> points;

  const _MoraleTrendChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final maxY = points.map((p) => p.value).reduce(max) + 2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()} posts',
                  AppTypography.captionC2.copyWith(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 7,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < points.length) {
                  final d = points[idx].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${d.day}/${d.month}',
                      style: AppTypography.captionC2
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(),
                    style: AppTypography.captionC2
                        .copyWith(color: AppColors.textTertiary));
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.neutral100,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(points.length,
                (i) => FlSpot(i.toDouble(), points[i].value)),
            isCurved: true,
            color: AppColors.blue500,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.blue100.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular gauge for Culture Health Score
class _CultureGauge extends StatelessWidget {
  final double score;

  const _CultureGauge({required this.score});

  @override
  Widget build(BuildContext context) {
    final normalised = (score / 100).clamp(0.0, 1.0);

    return CustomPaint(
      painter: _GaugePainter(normalised),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${score.toInt()}%',
                style: AppTypography.displayD1
                    .copyWith(color: AppColors.primary)),
            Text('Health Score',
                style: AppTypography.captionC1
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraction;

  _GaugePainter(this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    const startAngle = 2.4; // ~137 degrees
    const sweepAngle = 4.0; // ~230 degrees

    // Background arc
    final bgPaint = Paint()
      ..color = AppColors.neutral100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Value arc
    Color arcColor;
    if (fraction >= 0.7) {
      arcColor = AppColors.success;
    } else if (fraction >= 0.4) {
      arcColor = AppColors.warning;
    } else {
      arcColor = AppColors.error;
    }

    final valuePaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
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
  bool shouldRepaint(covariant _GaugePainter old) => old.fraction != fraction;
}
