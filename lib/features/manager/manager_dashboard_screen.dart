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
import 'widgets/quick_recognition_sheet.dart';
import 'widgets/edit_company_values_dialog.dart';

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

    QuickRecognitionSheet.show(
      context,
      preselectedUid: staffUid,
      preselectedName: staffName,
      onSend: (uid, name, starPoints, comment) async {
        try {
          final postId = await giveManagerStarToUser(
            staffUid: uid,
            managerId: currentUser.uid,
            managerName: profile?.fullName ?? 'Manager',
            note: comment,
            starPoints: starPoints,
          );
          if (postId != null) {
            ref.invalidate(teamRecognitionProvider);
            ref.invalidate(recognitionGapsProvider);
            ref.invalidate(risingStarsProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gave $starPoints star${starPoints > 1 ? 's' : ''} to $name!'),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name has no posts to star yet'),
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
      },
    );
  }

  /// Open Quick Recognition sheet without a pre-selected staff member.
  void _openQuickRecognition() {
    final currentUser = ref.read(currentUserProvider);
    final profile = ref.read(userProfileProvider).value;
    if (currentUser == null) return;

    QuickRecognitionSheet.show(
      context,
      onSend: (uid, name, starPoints, comment) async {
        try {
          final postId = await giveManagerStarToUser(
            staffUid: uid,
            managerId: currentUser.uid,
            managerName: profile?.fullName ?? 'Manager',
            note: comment,
            starPoints: starPoints,
          );
          if (postId != null) {
            ref.invalidate(teamRecognitionProvider);
            ref.invalidate(recognitionGapsProvider);
            ref.invalidate(risingStarsProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gave $starPoints star${starPoints > 1 ? 's' : ''} to $name!'),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name has no posts to star yet'),
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
      },
    );
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
                      const SizedBox(height: 32),
                      // ── Company Culture header ──
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text('Company Culture',
                            style: AppTypography.headingH4
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                      _buildMoraleTrendSection(),
                      const SizedBox(height: 24),
                      _buildCultureHealthSection(),
                      const SizedBox(height: 24),
                      _buildRecognitionGapsSection(),
                      const SizedBox(height: 24),
                      _buildValuesDistributionSection(),
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
              height: 260,
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
    final profile = ref.watch(userProfileProvider).value;
    final currentUser = ref.read(currentUserProvider);

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
          Row(
            children: [
              Expanded(
                child: Text('Core Values', style: AppTypography.headingH5),
              ),
              GestureDetector(
                onTap: () {
                  if (currentUser == null || profile == null) return;
                  EditCompanyValuesDialog.show(
                    context,
                    currentValues: profile.companyValues.isNotEmpty
                        ? profile.companyValues
                        : AppConstants.careValues,
                    userId: currentUser.uid,
                    onSaved: (_) {
                      ref.invalidate(coreValuesStatsProvider);
                      ref.invalidate(valuesDistributionProvider);
                    },
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0A2C6B).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 14, color: const Color(0xFF0A2C6B)),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A2C6B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          values.when(
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
                    padding: const EdgeInsets.only(bottom: 18),
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
        ],
      ),
    );
  }

  Color _valueColor(String name) {
    final colors = [
      AppColors.coral500,
      AppColors.blue500,
      AppColors.teal500,
      AppColors.navy400,
      const Color(0xFF9333EA),
      const Color(0xFFEA580C),
      const Color(0xFF16A34A),
    ];
    switch (name.toLowerCase()) {
      case 'compassion':
        return const Color(0xFFEF4444);
      case 'teamwork':
        return const Color(0xFF0A2C6B);
      case 'excellence':
        return const Color(0xFF0D9488);
      default:
        return colors[name.hashCode.abs() % colors.length];
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
        Row(
          children: [
            Text('Rising stars',
                style: AppTypography.headingH4
                    .copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _openQuickRecognition,
              icon: const Icon(Icons.star_rounded, size: 16),
              label: const Text('Give Kudos Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                elevation: 2,
              ),
            ),
          ],
        ),
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
              Text('Recognition Gaps',
                  style: AppTypography.headingH5
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '${list.length} staff have received no recognition this week.',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3),
              ),
              const SizedBox(height: 16),
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
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          _AvatarWidget(
                              name: gap.name,
                              photoBase64: gap.profilePhotoBase64,
                              radius: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(gap.name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _giveManagerStar(gap.uid, gap.name),
                            icon: const Icon(Icons.star_rounded, size: 16),
                            label: const Text('Give Kudos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A2C6B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              elevation: 0,
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
              Text('Values Distribution',
                  style: AppTypography.headingH5
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Values Distribution',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.3)),
              const SizedBox(height: 20),
              _SimpleWeekChart(data: data),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 18, color: const Color(0xFF0A2C6B)),
                    const SizedBox(width: 10),
                    Text(
                      'Most active day: ${data.mostActiveDay}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A2C6B)),
                    ),
                  ],
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
          Text('Morale Trend (Last 30 Days)',
              style: AppTypography.headingH5
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Recognition activity increased 12% compared to last month.',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4),
          ),
          const SizedBox(height: 16),
          trend.when(
            data: (points) {
              if (points.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No data yet',
                        style: AppTypography.bodyB4
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                );
              }
              return SizedBox(
                height: 200,
                child: _MoraleTrendChart(points: points),
              );
            },
            loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Failed to load',
                style: AppTypography.bodyB4
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // CULTURE HEALTH SCORE (circular gauge)
  // ═══════════════════════════════════════════════════

  Widget _buildCultureHealthSection() {
    final health = ref.watch(cultureHealthProvider);

    return health.when(
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
            Text('Culture Health Score',
                style: AppTypography.headingH5
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Overall Culture Health Score',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3)),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                height: 180,
                width: 180,
                child: _CultureGauge(score: data.score),
              ),
            ),
            const SizedBox(height: 24),
            _HealthMetricRow(
                label: 'Participation Rate:',
                value: '${data.participationRate.toStringAsFixed(0)}%'),
            const SizedBox(height: 8),
            _HealthMetricRow(
                label: 'Average Stars per Staff:',
                value: data.avgStarsPerStaff.toStringAsFixed(1)),
            const SizedBox(height: 8),
            _HealthMetricRow(
                label: 'GDPR Clean Rate:',
                value: '${data.gdprCleanRate.toStringAsFixed(0)}%'),
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
            onPressed: () => Navigator.pop(ctx),
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
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          // ── Author row ──
          Row(
            children: [
              _AvatarWidget(
                  name: post.authorName,
                  photoBase64: null,
                  radius: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _formatRole(post.authorRole),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        if (post.hasGdprFlag) ...[
                          const SizedBox(width: 6),
                          const Text(
                            '\u2022',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    size: 12,
                                    color: const Color(0xFFEA580C)),
                                const SizedBox(width: 3),
                                const Text(
                                  'GDPR',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Content ──
          Expanded(
            child: Text(
              post.content,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 14),

          // ── Two buttons: Reject + Approve ──
          Row(
            children: [
              // Reject button
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () async {
                      final reason = await _showReasonDialog(
                        context,
                        title: post.hasGdprFlag
                            ? 'Reject \u2013 GDPR Violation'
                            : 'Reject Post',
                        hintText: post.hasGdprFlag
                            ? 'Explain the GDPR violation\u2026'
                            : 'Reason for rejection (optional)',
                        isRequired: post.hasGdprFlag,
                      );
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
                            SnackBar(content: Text('Failed to reject: \$e')),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Reject',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Approve button
              Expanded(
                child: SizedBox(
                  height: 56,
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
                            SnackBar(content: Text('Failed to approve: \$e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2C6B),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Approve',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
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

  IconData _valueIcon(String name) {
    switch (name.toLowerCase()) {
      case 'compassion':
        return Icons.favorite_rounded;
      case 'teamwork':
        return Icons.people_rounded;
      case 'excellence':
        return Icons.auto_awesome_rounded;
      case 'respect':
        return Icons.handshake_rounded;
      case 'kindness':
        return Icons.volunteer_activism_rounded;
      case 'integrity':
        return Icons.shield_rounded;
      case 'empowerment':
        return Icons.bolt_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fraction = count / maxCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _valueIcon(label),
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            // Label
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            // Count
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Blue left accent strip
            Container(width: 4, color: const Color(0xFF3B82F6)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Name + Description
          Row(
            children: [
              _AvatarWidget(
                  name: star.name,
                  photoBase64: star.profilePhotoBase64,
                  radius: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(star.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 2),
                    Text(star.description,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Star count + Points
          Row(
            children: [
              Icon(Icons.star_rounded,
                  size: 18, color: const Color(0xFFD4AF37)),
              const SizedBox(width: 4),
              Text('${star.starsLast60Days} stars (60d)',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(width: 20),
              Icon(Icons.emoji_events_outlined,
                  size: 18, color: const Color(0xFFD4AF37)),
              const SizedBox(width: 4),
              Text('${star.points} pts',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 14),
          // Full-width View Full Profile button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/user-profile/${star.uid}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2C6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('View Full Profile',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
              ),
            ),
          ],
        ),
        ),
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
    return GestureDetector(
      onTap: onGiveStar,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _AvatarWidget(
                name: member.name,
                photoBase64: member.profilePhotoBase64,
                radius: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                member.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const Icon(
              Icons.star_rounded,
              size: 20,
              color: Color(0xFFD4AF37),
            ),
            const SizedBox(width: 6),
            Text(
              '${member.totalStars}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD4AF37),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _AvatarWidget(
              name: member.name,
              photoBase64: member.profilePhotoBase64,
              radius: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              member.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const Icon(
            Icons.emoji_events_rounded,
            size: 20,
            color: Color(0xFFD4AF37),
          ),
          const SizedBox(width: 6),
          Text(
            '${member.totalStars} pts',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD4AF37),
            ),
          ),
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
class _HealthMetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _HealthMetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E))),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
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

/// Simple week activity chart – colored blocks per day
class _SimpleWeekChart extends StatelessWidget {
  final ValuesDistribution data;

  const _SimpleWeekChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Calculate totals per day
    final totals = days.map((d) {
      final dayData = data.byDay[d] ?? {};
      return dayData.values.fold<int>(0, (sum, v) => sum + v);
    }).toList();

    final maxTotal = totals.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(days.length, (i) {
        final ratio = totals[i] / maxTotal;
        // Navy shades: darker = more activity, lighter = less
        final color = ratio > 0
            ? Color.lerp(
                const Color(0xFFB0C4DE), const Color(0xFF0A2C6B), ratio)!
            : const Color(0xFFE0E0E0);

        return Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(days[i],
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        );
      }),
    );
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
        child: Text('${score.toInt()}%',
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A2C6B))),
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

    // Value arc – always navy blue per design
    const arcColor = Color(0xFF0A2C6B);

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
