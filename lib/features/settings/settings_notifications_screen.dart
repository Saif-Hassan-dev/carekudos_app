import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/permissions_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/app_switch.dart';

class SettingsNotificationsScreen extends ConsumerStatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  ConsumerState<SettingsNotificationsScreen> createState() =>
      _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState
    extends ConsumerState<SettingsNotificationsScreen> {
  // In-app notification settings
  bool _starsReceived = true;
  bool _mentions = true;
  bool _systemUpdates = true;

  // Communication settings
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  bool _loaded = false;

  void _loadFromProfile(UserProfile profile) {
    if (_loaded) return;
    _loaded = true;
    _starsReceived = profile.notifyStarsReceived;
    _mentions = profile.notifyMentions;
    _systemUpdates = profile.notifySystemUpdates;
    _emailNotifications = profile.emailNotifications;
    _pushNotifications = profile.pushNotifications;
  }

  Future<void> _savePreferences(String userId) async {
    try {
      await FirebaseService.updateNotificationPreferences(
        userId: userId,
        starsReceived: _starsReceived,
        mentions: _mentions,
        systemUpdates: _systemUpdates,
        emailNotifications: _emailNotifications,
        pushNotifications: _pushNotifications,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save preferences')),
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
          title: const Text('Notifications'),
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
              'Notifications',
              style: AppTypography.headingH5,
            ),
          ),
          body: ListView(
            children: [
              // In-app notifications section
              _SectionHeader(title: 'In-app notifications'),
              _ToggleItem(
                title: 'Stars received',
                value: _starsReceived,
                onChanged: (v) {
                  setState(() => _starsReceived = v);
                  if (userId != null) _savePreferences(userId);
                },
              ),
              _ToggleItem(
                title: 'Mentions',
                value: _mentions,
                onChanged: (v) {
                  setState(() => _mentions = v);
                  if (userId != null) _savePreferences(userId);
                },
              ),
              _ToggleItem(
                title: 'System updates',
                value: _systemUpdates,
                onChanged: (v) {
                  setState(() => _systemUpdates = v);
                  if (userId != null) _savePreferences(userId);
                },
              ),
              Padding(
                padding: AppSpacing.horizontal16,
                child: Text(
                  'These affect in-app notifications only.',
                  style: AppTypography.captionC2.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              AppSpacing.verticalGap24,

              // Communication section
              _SectionHeader(title: 'Communication'),
              _ToggleItem(
                title: 'Email notifications',
                value: _emailNotifications,
                onChanged: (v) {
                  setState(() => _emailNotifications = v);
                  if (userId != null) _savePreferences(userId);
                },
              ),
              _ToggleWithSubtitle(
                title: 'Push notifications',
                subtitle: 'Choose how you want to be notified.',
                value: _pushNotifications,
                onChanged: (v) {
                  setState(() => _pushNotifications = v);
                  if (userId != null) _savePreferences(userId);
                },
              ),
              AppSpacing.verticalGap32,
            ],
          ),
        );
      },
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

class _ToggleItem extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: AppTypography.bodyB2),
      trailing: AppSwitch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationItem({
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

class _ToggleWithSubtitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleWithSubtitle({
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
