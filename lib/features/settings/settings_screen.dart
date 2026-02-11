import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/cards.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: AppTypography.headingH5,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.verticalGap16,
            // Account section
            _SectionHeader(title: 'Account'),
            Card(
              margin: AppSpacing.horizontal16,
              child: Column(
                children: [
                  SettingsMenuItem(
                    title: 'Edit Profile',
                    subtitle: 'Change your name, photo, and bio',
                    icon: Icons.person_outline,
                    onTap: () => context.push('/settings/profile'),
                  ),
                  const Divider(height: 1),
                  SettingsMenuItem(
                    title: 'Email & Password',
                    subtitle: 'Update your login credentials',
                    icon: Icons.lock_outline,
                    onTap: () => context.push('/settings/security'),
                  ),
                  const Divider(height: 1),
                  SettingsMenuItem(
                    title: 'Organization',
                    subtitle: userProfileAsync.maybeWhen(
                      data: (profile) => profile?.organizationName ?? 'Not set',
                      orElse: () => 'Loading...',
                    ),
                    icon: Icons.business_outlined,
                    onTap: () => context.push('/settings/organization'),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalGap24,

            // Preferences section
            _SectionHeader(title: 'Preferences'),
            Card(
              margin: AppSpacing.horizontal16,
              child: Column(
                children: [
                  SettingsMenuItem(
                    title: 'Notifications',
                    subtitle: 'Manage push and email notifications',
                    icon: Icons.notifications_outlined,
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  const Divider(height: 1),
                  SettingsMenuItem(
                    title: 'Appearance',
                    subtitle: 'Theme and display settings',
                    icon: Icons.palette_outlined,
                    onTap: () => context.push('/settings/appearance'),
                  ),
                  const Divider(height: 1),
                  SettingsMenuItem(
                    title: 'Privacy',
                    subtitle: 'Control who can see your activity',
                    icon: Icons.shield_outlined,
                    onTap: () => context.push('/settings/privacy'),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalGap24,

            // Support section
            _SectionHeader(title: 'Support'),
            Card(
              margin: AppSpacing.horizontal16,
              child: Column(
                children: [
                  SettingsMenuItem(
                    title: 'Help Center',
                    subtitle: 'FAQs and tutorials',
                    icon: Icons.help_outline,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  SettingsMenuItem(
                    title: 'Contact Support',
                    subtitle: 'Get help from our team',
                    icon: Icons.mail_outline,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  SettingsMenuItem(
                    title: 'GDPR Training',
                    subtitle: 'Retake the privacy training',
                    icon: Icons.school_outlined,
                    iconColor: AppColors.tertiary,
                    iconBgColor: AppColors.tertiaryLight,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            AppSpacing.verticalGap24,

            // Legal section
            _SectionHeader(title: 'Legal'),
            Card(
              margin: AppSpacing.horizontal16,
              child: Column(
                children: [
                  SettingsMenuItem(
                    title: 'Terms of Service',
                    icon: Icons.description_outlined,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  SettingsMenuItem(
                    title: 'Privacy Policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  SettingsMenuItem(
                    title: 'Licenses',
                    icon: Icons.article_outlined,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            AppSpacing.verticalGap24,

            // Danger zone
            Card(
              margin: AppSpacing.horizontal16,
              child: Column(
                children: [
                  SettingsMenuItem(
                    title: 'Sign Out',
                    icon: Icons.logout,
                    isDestructive: false,
                    showChevron: false,
                    onTap: () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        'Sign Out',
                        'Are you sure you want to sign out?',
                      );
                      if (confirmed && context.mounted) {
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) context.go('/welcome');
                      }
                    },
                  ),
                  const Divider(height: 1),
                  SettingsMenuItem(
                    title: 'Delete Account',
                    icon: Icons.delete_forever,
                    isDestructive: true,
                    showChevron: false,
                    onTap: () async {
                      final confirmed = await _showConfirmDialog(
                        context,
                        'Delete Account',
                        'This action cannot be undone. All your data will be permanently deleted.',
                        isDestructive: true,
                      );
                      if (confirmed) {
                        // TODO: Implement account deletion
                      }
                    },
                  ),
                ],
              ),
            ),
            AppSpacing.verticalGap16,

            // App version
            Center(
              child: Text(
                'CareKudos v1.0.0',
                style: AppTypography.captionC2.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            AppSpacing.verticalGap32,
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message, {
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? AppColors.error : null,
            ),
            child: Text(isDestructive ? 'Delete' : 'Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.captionC2.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
