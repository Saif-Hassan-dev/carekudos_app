import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/permissions_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/app_switch.dart';

class PrivacyGdprScreen extends ConsumerStatefulWidget {
  const PrivacyGdprScreen({super.key});

  @override
  ConsumerState<PrivacyGdprScreen> createState() => _PrivacyGdprScreenState();
}

class _PrivacyGdprScreenState extends ConsumerState<PrivacyGdprScreen> {
  bool _marketingOptIn = false;
  bool _loaded = false;

  void _loadFromProfile(UserProfile profile) {
    if (_loaded) return;
    _loaded = true;
    _marketingOptIn = profile.agreeToUpdates;
  }

  Future<void> _saveMarketingOptIn(String userId) async {
    try {
      await FirebaseService.updateMarketingOptIn(
        userId: userId,
        optIn: _marketingOptIn,
      );
    } catch (e) {
      debugPrint('[Privacy] Failed to save marketing opt-in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save preference')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Privacy & GDPR'),
        ),
        body: const Center(child: Text('Failed to load preferences')),
      ),
      data: (profile) {
        if (profile != null) _loadFromProfile(profile);
        final userId = profile?.uid;

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
                onChanged: (value) {
                  setState(() => _marketingOptIn = value);
                  if (userId != null) _saveMarketingOptIn(userId);
                },
              ),
              AppSpacing.verticalGap24,

              // Your Data Rights
              _SectionHeader(title: 'Your data rights'),
              _ActionItem(
                title: 'Request a copy of my data',
                subtitle: 'We\'ll email your data within 30 days',
                onTap: () => _submitDeletionRequest('data_export'),
              ),
              _ActionItem(
                title: 'Request account deletion',
                subtitle: 'Your account will be deleted within 30 days',
                onTap: () => _confirmAccountDeletion(),
              ),
              AppSpacing.verticalGap24,

              // Legal Documents
              _SectionHeader(title: 'Legal documents'),
              _NavigationItem(
                title: 'Privacy Policy',
                onTap: () => launchUrl(Uri.parse('https://carekudos-1.web.app/privacy')),
              ),
              _NavigationItem(
                title: 'Terms & Conditions',
                onTap: () => launchUrl(Uri.parse('https://carekudos-1.web.app/terms')),
              ),
              AppSpacing.verticalGap32,
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitDeletionRequest(String type) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('deletion_requests').add({
        'userId': user.uid,
        'email': user.email,
        'type': type,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(type == 'data_export'
                ? 'Data export request submitted. We\'ll email you within 30 days.'
                : 'Account deletion request submitted. Your account will be removed within 30 days.'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Privacy] Failed to submit $type request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmAccountDeletion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to request account deletion? '
          'This action cannot be undone. Your account and all associated data '
          'will be permanently deleted within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitDeletionRequest('account_deletion');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete My Account'),
          ),
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
