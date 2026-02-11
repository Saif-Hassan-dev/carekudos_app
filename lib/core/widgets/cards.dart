import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Selection card used in role selection
class SelectionCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final Widget? leading;
  final bool isSelected;
  final VoidCallback? onTap;

  const SelectionCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.leading,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryLight : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.allXl,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allXl,
        child: Padding(
          padding: AppSpacing.all16,
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                AppSpacing.horizontalGap16,
              ] else if (icon != null) ...[
                Container(
                  padding: AppSpacing.all12,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.neutral100,
                    borderRadius: AppRadius.allLg,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.neutral0 : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                AppSpacing.horizontalGap16,
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headingH5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (description != null) ...[
                      AppSpacing.verticalGap4,
                      Text(
                        description!,
                        style: AppTypography.bodyB4.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: AppSpacing.all4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.neutral0,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feed post card for the main feed
class FeedPostCard extends StatelessWidget {
  final String authorName;
  final String authorAvatarUrl;
  final String recipientName;
  final String timeAgo;
  final String message;
  final List<Widget>? categoryTags;
  final int starCount;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onTap;

  const FeedPostCard({
    super.key,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.recipientName,
    required this.timeAgo,
    required this.message,
    this.categoryTags,
    this.starCount = 1,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.onLike,
    this.onComment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allXl,
        child: Padding(
          padding: AppSpacing.all16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Author avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: authorAvatarUrl.isNotEmpty
                        ? NetworkImage(authorAvatarUrl)
                        : null,
                    backgroundColor: AppColors.neutral200,
                    child: authorAvatarUrl.isEmpty
                        ? Text(
                            authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                            style: AppTypography.headingH6,
                          )
                        : null,
                  ),
                  AppSpacing.horizontalGap12,
                  // Names and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: AppTypography.bodyB3,
                            children: [
                              TextSpan(
                                text: authorName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const TextSpan(text: ' gave a star to '),
                              TextSpan(
                                text: recipientName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.verticalGap2,
                        Text(
                          timeAgo,
                          style: AppTypography.captionC1.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Stars
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      starCount,
                      (index) => const Icon(
                        Icons.star,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalGap12,
              // Message
              Text(
                message,
                style: AppTypography.bodyB3.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              // Category tags
              if (categoryTags != null && categoryTags!.isNotEmpty) ...[
                AppSpacing.verticalGap12,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryTags!,
                ),
              ],
              AppSpacing.verticalGap12,
              // Actions row
              Row(
                children: [
                  _ActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: likeCount > 0 ? likeCount.toString() : 'Like',
                    isActive: isLiked,
                    onTap: onLike,
                  ),
                  AppSpacing.horizontalGap16,
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: commentCount > 0 ? commentCount.toString() : 'Comment',
                    onTap: onComment,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.error : AppColors.textTertiary,
            ),
            AppSpacing.horizontalGap4,
            Text(
              label,
              style: AppTypography.captionC1.copyWith(
                color: isActive ? AppColors.error : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Star rating input for giving stars
class StarRatingInput extends StatelessWidget {
  final int rating;
  final int maxRating;
  final ValueChanged<int>? onRatingChanged;
  final double size;

  const StarRatingInput({
    super.key,
    this.rating = 0,
    this.maxRating = 5,
    this.onRatingChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged?.call(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starIndex <= rating ? Icons.star : Icons.star_border,
              size: size,
              color: AppColors.secondary,
            ),
          ),
        );
      }),
    );
  }
}

/// Profile info card
class ProfileInfoCard extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String avatarUrl;
  final int starsReceived;
  final int starsGiven;
  final VoidCallback? onTap;

  const ProfileInfoCard({
    super.key,
    required this.name,
    this.subtitle,
    required this.avatarUrl,
    this.starsReceived = 0,
    this.starsGiven = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allXl,
        child: Padding(
          padding: AppSpacing.all16,
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                backgroundColor: AppColors.neutral200,
                child: avatarUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: AppTypography.displayD2,
                      )
                    : null,
              ),
              AppSpacing.verticalGap12,
              Text(
                name,
                style: AppTypography.headingH4,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                AppSpacing.verticalGap4,
                Text(
                  subtitle!,
                  style: AppTypography.bodyB4.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              AppSpacing.verticalGap16,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatItem(
                    icon: Icons.star,
                    value: starsReceived.toString(),
                    label: 'Received',
                    iconColor: AppColors.secondary,
                  ),
                  AppSpacing.horizontalGap32,
                  _StatItem(
                    icon: Icons.star_border,
                    value: starsGiven.toString(),
                    label: 'Given',
                    iconColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            AppSpacing.horizontalGap4,
            Text(value, style: AppTypography.headingH5),
          ],
        ),
        AppSpacing.verticalGap2,
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

/// Notification card for alerts list
class NotificationCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String timeAgo;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isUnread;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.timeAgo,
    this.icon = Icons.star,
    this.iconColor = AppColors.secondary,
    this.iconBgColor = AppColors.secondaryLight,
    this.isUnread = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: isUnread ? AppColors.primaryLight : AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allLg,
        child: Padding(
          padding: AppSpacing.all12,
          child: Row(
            children: [
              Container(
                padding: AppSpacing.all10,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              AppSpacing.horizontalGap12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyB3.copyWith(
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (subtitle != null) ...[
                      AppSpacing.verticalGap2,
                      Text(
                        subtitle!,
                        style: AppTypography.captionC1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.horizontalGap8,
              Text(
                timeAgo,
                style: AppTypography.captionC2.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat card for manager dashboard
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final double? percentChange;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color = AppColors.primary,
    this.backgroundColor,
    this.percentChange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: backgroundColor ?? AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allXl,
        child: Padding(
          padding: AppSpacing.all16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: AppSpacing.all8,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: AppRadius.allLg,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  if (percentChange != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: percentChange! >= 0
                            ? AppColors.successLight
                            : AppColors.errorLight,
                        borderRadius: AppRadius.allPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            percentChange! >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 12,
                            color: percentChange! >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          Text(
                            '${percentChange!.abs().toStringAsFixed(0)}%',
                            style: AppTypography.captionC2.copyWith(
                              color: percentChange! >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              AppSpacing.verticalGap12,
              Text(
                value,
                style: AppTypography.displayD3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.verticalGap4,
              Text(
                label,
                style: AppTypography.bodyB4.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings menu item
class SettingsMenuItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool isDestructive;

  const SettingsMenuItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = isDestructive
        ? AppColors.error
        : (iconColor ?? AppColors.primary);
    final effectiveIconBgColor = isDestructive
        ? AppColors.errorLight
        : (iconBgColor ?? AppColors.primaryLight);
    final titleColor = isDestructive ? AppColors.error : AppColors.textPrimary;

    return ListTile(
      leading: Container(
        padding: AppSpacing.all8,
        decoration: BoxDecoration(
          color: effectiveIconBgColor,
          borderRadius: AppRadius.allLg,
        ),
        child: Icon(icon, color: effectiveIconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyB3.copyWith(color: titleColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.captionC1.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing: trailing ??
          (showChevron
              ? Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                )
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

/// User list item for searching/selecting users
class UserListItem extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String avatarUrl;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? trailing;

  const UserListItem({
    super.key,
    required this.name,
    this.subtitle,
    required this.avatarUrl,
    this.isSelected = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundImage:
            avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        backgroundColor: AppColors.neutral200,
        child: avatarUrl.isEmpty
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTypography.bodyB3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: Text(
        name,
        style: AppTypography.bodyB3.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.captionC1.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: trailing ??
          (isSelected
              ? const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                )
              : null),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: AppColors.primaryLight,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.allLg,
      ),
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.all24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: AppSpacing.all20,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
            AppSpacing.verticalGap16,
            Text(
              title,
              style: AppTypography.headingH5,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              AppSpacing.verticalGap8,
              Text(
                subtitle!,
                style: AppTypography.bodyB4.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              AppSpacing.verticalGap20,
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
