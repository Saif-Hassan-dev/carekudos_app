import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/cards.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const RoleSelectionScreen({super.key, required this.onNext});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = 'care_worker';
  }

  void _continueWithRole() {
    if (_selectedRole != null) {
      ref.read(onboardingProvider.notifier).setRole(_selectedRole!);
      widget.onNext();
    }
  }

  IconData _getRoleIcon(String roleId) {
    switch (roleId) {
      case 'care_worker':
        return Icons.volunteer_activism_outlined;
      case 'senior_carer':
        return Icons.supervisor_account_outlined;
      case 'manager':
        return Icons.admin_panel_settings_outlined;
      case 'family_member':
        return Icons.family_restroom_outlined;
      default:
        return Icons.person_outline;
    }
  }

  String _getRoleDescription(String roleId) {
    switch (roleId) {
      case 'care_worker':
        return 'Provide direct care to residents';
      case 'senior_carer':
        return 'Lead and mentor care workers';
      case 'manager':
        return 'Oversee team and operations';
      case 'family_member':
        return 'Stay connected with your loved one';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = [
      {'id': 'care_worker', 'label': 'Care Worker'},
      {'id': 'senior_carer', 'label': 'Senior Carer'},
      {'id': 'manager', 'label': 'Manager'},
      {'id': 'family_member', 'label': 'Family Member'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.all24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.verticalGap40,
              Text(
                'I am a...',
                style: AppTypography.displayD2.copyWith(
                  color: AppColors.primary,
                ),
              ),
              AppSpacing.verticalGap8,
              Text(
                'Select your role to personalize your experience',
                style: AppTypography.bodyB3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.verticalGap32,
              Expanded(
                child: ListView.separated(
                  itemCount: roles.length,
                  separatorBuilder: (_, __) => AppSpacing.verticalGap12,
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    final roleId = role['id']!;
                    return SelectionCard(
                      title: role['label']!,
                      description: _getRoleDescription(roleId),
                      icon: _getRoleIcon(roleId),
                      isSelected: _selectedRole == roleId,
                      onTap: () => setState(() => _selectedRole = roleId),
                    );
                  },
                ),
              ),
              AppSpacing.verticalGap24,
              AppButton.primary(
                label: 'Continue',
                onPressed: _selectedRole != null ? _continueWithRole : null,
                isFullWidth: true,
              ),
              AppSpacing.verticalGap16,
            ],
          ),
        ),
      ),
    );
  }
}
