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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Help & Support',
                    style: AppTypography.headingH3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Help section
                  _SectionCard(
                    headerTitle: 'Help',
                    children: [
                      _CardRow(
                        iconPath:
                            'assets/icons/CareKudos (15)/vuesax/twotone/message-question.png',
                        title: 'FAQ',
                        subtitle: 'Contact support to proceed',
                        trailing: Icon(Icons.chevron_right,
                            color: AppColors.neutral400, size: 22),
                        onTap: () {
                          // TODO: Open FAQ
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Contact section
                  _SectionCard(
                    headerTitle: 'Contact',
                    children: [
                      _CardRow(
                        iconPath:
                            'assets/icons/CareKudos (13)/vuesax/twotone/sms.png',
                        title: 'Contact support',
                        subtitle: 'support@carekudos.com',
                        trailing: Icon(Icons.chevron_right,
                            color: AppColors.neutral400, size: 22),
                        onTap: () => _openEmailClient(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Version section
                  _SectionCard(
                    headerTitle: 'Contact',
                    children: [
                      _CardRow(
                        iconPath:
                            'assets/icons/CareKudos (15)/vuesax/twotone/info-circle.png',
                        title: 'Version 1.0.0',
                        trailing: Text(
                          'Not provided',
                          style: AppTypography.captionC1.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Legal documents section
                  _SectionCard(
                    headerTitle: 'Legal documents',
                    children: [
                      _CardRow(
                        title: 'Privacy Policy',
                        trailing: Icon(Icons.chevron_right,
                            color: AppColors.neutral400, size: 22),
                        onTap: () {
                          // TODO: Open privacy policy
                        },
                      ),
                      Divider(
                          height: 1,
                          color: AppColors.neutral200,
                          indent: 16,
                          endIndent: 16),
                      _CardRow(
                        title: 'Terms & Conditions',
                        trailing: Icon(Icons.chevron_right,
                            color: AppColors.neutral400, size: 22),
                        onTap: () {
                          // TODO: Open terms & conditions
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String headerTitle;
  final List<Widget> children;

  const _SectionCard({
    required this.headerTitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            headerTitle,
            style: AppTypography.headingH5.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.neutral0,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.neutral200, width: 1),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  final String? iconPath;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _CardRow({
    this.iconPath,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            if (iconPath != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Image.asset(
                    iconPath!,
                    width: 22,
                    height: 22,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyB3.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.captionC1.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
