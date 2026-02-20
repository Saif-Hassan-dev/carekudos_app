import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/onboarding_provider.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Title
              const Text(
                'Select your role',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2C6B),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'This helps us set up the right experience for you.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF757575),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // Role cards
              Expanded(
                child: ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final roleId = role['id'] as String;
                    final isSelected = _selectedRole == roleId;

                    return _RoleCard(
                      label: role['label'] as String,
                      description: role['description'] as String,
                      iconPath: role['icon'] as String,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedRole = roleId),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedRole != null ? _continueWithRole : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRole != null
                        ? const Color(0xFF0A2C6B)
                        : const Color(0xFFE0E0E0),
                    foregroundColor: _selectedRole != null
                        ? Colors.white
                        : const Color(0xFFBDBDBD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                    disabledForegroundColor: const Color(0xFFBDBDBD),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedRole != null
                              ? Colors.white
                              : const Color(0xFFBDBDBD),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: _selectedRole != null
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A2C6B) : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
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
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const Icon(
                    Icons.person,
                    size: 28,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A2C6B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
