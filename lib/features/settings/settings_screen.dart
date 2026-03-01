import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/theme/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    'CareKudos',
                    style: AppTypography.headingH3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Settings items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  _SettingsCard(
                    iconPath:
                        'assets/icons/CareKudos (12)/vuesax/twotone/profile-circle.png',
                    title: 'Account',
                    subtitle: 'Personal and account details',
                    onTap: () => context.push('/settings/account'),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    iconPath:
                        'assets/icons/CareKudos (13)/vuesax/twotone/shield-security.png',
                    title: 'Privacy & GDPR',
                    subtitle: 'Data, consent, and privacy',
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    iconPath:
                        'assets/icons/CareKudos (16)/vuesax/twotone/notification.png',
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    iconPath:
                        'assets/icons/CareKudos (15)/vuesax/twotone/24-support.png',
                    title: 'Help & Support',
                    subtitle: 'Get help and support',
                    onTap: () => context.push('/settings/help'),
                  ),
                ],
              ),
            ),
            // Logout button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await _showConfirmDialog(
                      context,
                      'Sign Out',
                      'Are you sure you want to sign out?',
                    );
                    if (confirmed && context.mounted) {
                      await ref.read(authNotifierProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  icon: Image.asset(
                    'assets/icons/CareKudos (12)/vuesax/twotone/logout.png',
                    width: 20,
                    height: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.neutral0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
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
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _SettingsCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.neutral200, width: 1),
        ),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 28,
              height: 28,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyB1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.captionC1.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.neutral400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
