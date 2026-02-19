import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/constants/app_icons.dart';

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

  Widget _getRoleIconWidget(String roleId) {
    String? iconPath;
    IconData fallbackIcon;
    
    switch (roleId) {
      case 'care_worker':
      case 'senior_carer':
        iconPath = AppIcons.careWorker;
        fallbackIcon = Icons.volunteer_activism_outlined;
        break;
      case 'manager':
        iconPath = AppIcons.manager;
        fallbackIcon = Icons.admin_panel_settings_outlined;
        break;
      case 'family_member':
        fallbackIcon = Icons.family_restroom_outlined;
        break;
      default:
        fallbackIcon = Icons.person_outline;
    }

    // Try to load custom icon, fallback to Material icon
    if (iconPath != null) {
      return Image.asset(
        iconPath,
        width: 24,
        height: 24,
        color: Colors.white,
        errorBuilder: (context, error, stackTrace) {
          return Icon(fallbackIcon, size: 24);
        },
      );
    }
    
    return Icon(fallbackIcon, size: 24);
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
                    final isSelected = _selectedRole == roleId;
                    
                    return SelectionCard(
                      title: role['label']!,
                      description: _getRoleDescription(roleId),
                      leading: Container(
                        padding: AppSpacing.all12,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.neutral100,
                          borderRadius: AppRadius.allLg,
                        ),
                        child: _getRoleIconWidget(roleId),
                      ),
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedRole = roleId),
                    );
                  },
                ),
              ),
              AppSpacing.verticalGap24,
              AppButton.primary(
                text: 'Continue',
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
