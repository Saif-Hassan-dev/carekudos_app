import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/theme.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const RoleSelectionScreen({super.key, required this.onNext});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;

  static const _roles = [
    {
      'id': 'care_worker',
      'label': 'Care Worker',
      'description': 'Provide and recognise great care',
      'icon': AppIcons.careWorker,
    },
    {
      'id': 'manager',
      'label': 'Manager',
      'description': 'Oversee teams and recognise staff',
      'icon': AppIcons.manager,
    },
    {
      'id': 'admin',
      'label': 'Admin',
      'description': 'Organisation and compliance',
      'icon': AppIcons.admin,
    },
  ];

  void _continueWithRole() {
    if (_selectedRole != null) {
      ref.read(onboardingProvider.notifier).setRole(_selectedRole!);
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedRole != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),

              // Title
              Text(
                'Select your role',
                style: AppTypography.headingH1.copyWith(
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'This helps us set up the right experience for you.',
                style: AppTypography.bodyB4.copyWith(
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 32),

              // Role cards — no scroll, just a column
              ...List.generate(_roles.length, (index) {
                final role = _roles[index];
                final roleId = role['id'] as String;
                final isSelected = _selectedRole == roleId;

                return Padding(
                  padding: EdgeInsets.only(bottom: index < _roles.length - 1 ? 12 : 0),
                  child: _RoleCard(
                    label: role['label'] as String,
                    description: role['description'] as String,
                    iconPath: role['icon'] as String,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedRole = roleId),
                  ),
                );
              }),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: hasSelection ? _continueWithRole : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasSelection
                        ? const Color(0xFF0A2C6B)
                        : const Color(0xFFF2F2F7),
                    foregroundColor: hasSelection
                        ? Colors.white
                        : const Color(0xFFBDBDBD),
                    disabledBackgroundColor: const Color(0xFFF2F2F7),
                    disabledForegroundColor: const Color(0xFFBDBDBD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: AppTypography.actionA1.copyWith(
                          color: hasSelection
                              ? Colors.white
                              : const Color(0xFFBDBDBD),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: hasSelection
                            ? Colors.white
                            : const Color(0xFFBDBDBD),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Role card widget
// ──────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String label;
  final String description;
  final String iconPath;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.description,
    required this.iconPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A2C6B) : const Color(0xFFE8E8E8),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F5F5),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0A2C6B)
                      : const Color(0xFFE0E0E0),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  iconPath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const Icon(
                    Icons.person,
                    size: 24,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.headingH4.copyWith(
                      color: const Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.bodyB6.copyWith(
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark — only visible when selected
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A2C6B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
