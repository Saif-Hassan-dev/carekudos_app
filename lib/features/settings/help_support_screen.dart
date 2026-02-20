import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/extensions.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  Future<void> _openEmailClient(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@carekudos.com',
      query: 'subject=CareKudos Support Request',
    );

    if (!await launchUrl(emailUri)) {
      if (context.mounted) {
        context.showErrorSnackBar('Could not open email client');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Help & Support',
          style: AppTypography.headingH5,
        ),
      ),
      body: ListView(
        children: [
          // Help section
          _SectionHeader(title: 'Help'),
          _NavigationItem(
            title: 'FAQ',
            subtitle: 'Contact support to proceed',
            onTap: () {
              // TODO: Open FAQ
            },
          ),
          AppSpacing.verticalGap16,

          // Contact section
          _SectionHeader(title: 'Contact'),
          _NavigationItem(
            title: 'Contact support',
            subtitle: 'support@carekudos.com',
            onTap: () => _openEmailClient(context),
          ),
          AppSpacing.verticalGap16,

          // Contact section (Version)
          _SectionHeader(title: 'Contact'),
          _InfoItem(
            icon: Icons.info_outline,
            title: 'Version 1.0.0',
            trailing: 'Not provided',
          ),
          AppSpacing.verticalGap16,

          // Legal documents
          _SectionHeader(title: 'Legal documents'),
          _NavigationItem(
            title: 'Privacy Policy',
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
          _NavigationItem(
            title: 'Terms & Conditions',
            onTap: () {
              // TODO: Open terms & conditions
            },
          ),
          AppSpacing.verticalGap32,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTypography.headingH6.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: AppTypography.bodyB2),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.captionC1.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTypography.bodyB2),
      trailing: Text(
        trailing,
        style: AppTypography.captionC1.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
