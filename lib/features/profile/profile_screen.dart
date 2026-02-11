import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/custom_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: Text(
          'Profile',
          style: AppTypography.headingH5,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              AppSpacing.verticalGap16,
              Text('Error loading profile', style: AppTypography.bodyB3),
              AppSpacing.verticalGap8,
              AppButton.secondary(
                label: 'Retry',
                onPressed: () => ref.invalidate(userProfileProvider),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          return SingleChildScrollView(
            padding: AppSpacing.all16,
            child: Column(
              children: [
                // Profile card
                _ProfileHeader(
                  name: profile.fullName,
                  email: user?.email ?? '',
                  role: profile.role,
                  avatarUrl: profile.avatarUrl ?? '',
                  starsReceived: profile.starsReceived,
                  starsGiven: profile.starsGiven,
                ),
                AppSpacing.verticalGap24,

                // Stats section
                Text(
                  'Your Stats',
                  style: AppTypography.headingH5,
                ),
                AppSpacing.verticalGap16,
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        value: profile.postCount.toString(),
                        label: 'Posts',
                        icon: Icons.article_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    AppSpacing.horizontalGap12,
                    Expanded(
                      child: StatCard(
                        value: profile.starsReceived.toString(),
                        label: 'Stars Received',
                        icon: Icons.star,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalGap12,
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        value: profile.starsGiven.toString(),
                        label: 'Stars Given',
                        icon: Icons.star_border,
                        color: AppColors.tertiary,
                      ),
                    ),
                    AppSpacing.horizontalGap12,
                    Expanded(
                      child: StatCard(
                        value: _getLevelName(profile.level),
                        label: 'Level',
                        icon: Icons.emoji_events_outlined,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalGap24,

                // Achievements section
                _SectionHeader(
                  title: 'Achievements',
                  onSeeAll: () {},
                ),
                AppSpacing.verticalGap12,
                _AchievementsGrid(),
                AppSpacing.verticalGap24,

                // Recent activity section
                _SectionHeader(
                  title: 'Recent Activity',
                  onSeeAll: () {},
                ),
                AppSpacing.verticalGap12,
                _RecentActivityList(),
                AppSpacing.verticalGap32,

                // Logout button
                AppButton.text(
                  label: 'Sign Out',
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go('/welcome');
                  },
                  isFullWidth: true,
                ),
                AppSpacing.verticalGap16,
              ],
            ),
          );
        },
      ),
    );
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return 'Starter';
      case 2:
        return 'Rising';
      case 3:
        return 'Star';
      case 4:
        return 'Champion';
      case 5:
        return 'Legend';
      default:
        return 'Level $level';
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String avatarUrl;
  final int starsReceived;
  final int starsGiven;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
    required this.avatarUrl,
    required this.starsReceived,
    required this.starsGiven,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.all20,
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              backgroundColor: AppColors.primaryLight,
              child: avatarUrl.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: AppTypography.displayD2.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            AppSpacing.verticalGap16,
            Text(
              name,
              style: AppTypography.headingH4,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalGap4,
            Text(
              email,
              style: AppTypography.bodyB4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.verticalGap8,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.allPill,
              ),
              child: Text(
                _formatRole(role),
                style: AppTypography.captionC1.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AppSpacing.verticalGap20,
            // Star stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StarStat(
                  icon: Icons.star,
                  value: starsReceived,
                  label: 'Received',
                  color: AppColors.secondary,
                ),
                Container(
                  height: 40,
                  width: 1,
                  margin: AppSpacing.horizontal24,
                  color: AppColors.divider,
                ),
                _StarStat(
                  icon: Icons.star_border,
                  value: starsGiven,
                  label: 'Given',
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
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

class _StarStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StarStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            AppSpacing.horizontalGap4,
            Text(
              value.toString(),
              style: AppTypography.headingH4,
            ),
          ],
        ),
        AppSpacing.verticalGap4,
        Text(
          label,
          style: AppTypography.captionC1.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.headingH5),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: AppTypography.bodyB4.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder achievements
    final achievements = [
      {'icon': Icons.celebration, 'label': 'First Star', 'unlocked': true},
      {'icon': Icons.local_fire_department, 'label': '5 Day Streak', 'unlocked': true},
      {'icon': Icons.favorite, 'label': 'Compassion Pro', 'unlocked': false},
      {'icon': Icons.groups, 'label': 'Team Player', 'unlocked': false},
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        separatorBuilder: (_, __) => AppSpacing.horizontalGap12,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          final unlocked = achievement['unlocked'] as bool;
          return _AchievementBadge(
            icon: achievement['icon'] as IconData,
            label: achievement['label'] as String,
            unlocked: unlocked,
          );
        },
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool unlocked;

  const _AchievementBadge({
    required this.icon,
    required this.label,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: unlocked ? AppColors.secondaryLight : AppColors.neutral200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: unlocked ? AppColors.secondary : AppColors.textTertiary,
            size: 28,
          ),
        ),
        AppSpacing.verticalGap8,
        Text(
          label,
          style: AppTypography.captionC2.copyWith(
            color: unlocked ? AppColors.textPrimary : AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder activities
    return Column(
      children: [
        NotificationCard(
          title: 'You received a star!',
          subtitle: 'For showing compassion',
          timeAgo: '2h ago',
          icon: Icons.star,
          iconColor: AppColors.secondary,
          iconBgColor: AppColors.secondaryLight,
        ),
        AppSpacing.verticalGap8,
        NotificationCard(
          title: 'Post approved',
          subtitle: 'Your post is now visible',
          timeAgo: '1d ago',
          icon: Icons.check_circle,
          iconColor: AppColors.success,
          iconBgColor: AppColors.successLight,
        ),
      ],
    );
  }
}
