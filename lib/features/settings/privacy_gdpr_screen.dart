import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/app_switch.dart';

class PrivacyGdprScreen extends ConsumerStatefulWidget {
  const PrivacyGdprScreen({super.key});

  @override
  ConsumerState<PrivacyGdprScreen> createState() => _PrivacyGdprScreenState();
}

class _PrivacyGdprScreenState extends ConsumerState<PrivacyGdprScreen> {
  bool _marketingOptIn = false;

  @override
  Widget build(BuildContext context) {
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
          'Privacy & GDPR',
          style: AppTypography.headingH5,
        ),
      ),
      body: ListView(
        children: [
          // GDPR Consent Section
          _SectionHeader(title: 'GDPR consent'),
          _ConsentStatus(),
          AppSpacing.verticalGap24,

          // Marketing Preferences
          _SectionHeader(title: 'Marketing preferences'),
          _ToggleItem(
            title: 'Product updates & announcements',
            subtitle: 'Optional',
            value: _marketingOptIn,
            onChanged: (value) => setState(() => _marketingOptIn = value),
          ),
          AppSpacing.verticalGap24,

          // Your Data Rights
          _SectionHeader(title: 'Your data rights'),
          _ActionItem(
            title: 'Request a copy of my data',
            subtitle: 'Contact support to proceed',
            onTap: () => _contactSupport('data request'),
          ),
          _ActionItem(
            title: 'Request account deletion',
            subtitle: 'Contact support to proceed',
            onTap: () => _contactSupport('account deletion'),
          ),
          AppSpacing.verticalGap24,

          // Legal Documents
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

  void _contactSupport(String requestType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact support@carekudos.com for $requestType'),
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

class _ConsentStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.successLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: AppColors.success,
          size: 20,
        ),
      ),
      title: Text(
        'Accepted',
        style: AppTypography.bodyB2.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Completed during registration',
        style: AppTypography.captionC1.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: AppTypography.bodyB2),
      subtitle: Text(
        subtitle,
        style: AppTypography.captionC1.copyWith(color: AppColors.textTertiary),
      ),
      trailing: AppSwitch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: AppTypography.bodyB2),
      subtitle: Text(
        subtitle,
        style: AppTypography.captionC1.copyWith(color: AppColors.textTertiary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: AppTypography.bodyB2),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}
