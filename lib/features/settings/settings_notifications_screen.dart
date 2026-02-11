import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';

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
            onChanged: (v) => setState(() => _starsReceived = v),
          ),
          _ToggleItem(
            title: 'Mentions',
            value: _mentions,
            onChanged: (v) => setState(() => _mentions = v),
          ),
          _ToggleItem(
            title: 'System updates',
            value: _systemUpdates,
            onChanged: (v) => setState(() => _systemUpdates = v),
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

          // In-app notifications section 2
          _SectionHeader(title: 'In-app notifications'),
          _ToggleItem(
            title: 'Email notifications',
            value: _emailNotifications,
            onChanged: (v) => setState(() => _emailNotifications = v),
          ),
          _ToggleWithSubtitle(
            title: 'Push notifications',
            subtitle: 'Choose how you want to be notified.',
            value: _pushNotifications,
            onChanged: (v) => setState(() => _pushNotifications = v),
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}
