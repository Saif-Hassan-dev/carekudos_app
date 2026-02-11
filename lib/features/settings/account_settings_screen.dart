import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/permissions_provider.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    // Load profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        _firstNameController.text = profile.firstName;
        _lastNameController.text = profile.lastName;
        _emailController.text = profile.email;
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

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
          'Account Settings',
          style: AppTypography.headingH5,
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => SingleChildScrollView(
          padding: AppSpacing.all16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        profile?.firstName.isNotEmpty == true
                            ? profile!.firstName[0].toUpperCase()
                            : '?',
                        style: AppTypography.displayD2.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    AppSpacing.verticalGap12,
                    TextButton(
                      onPressed: () {
                        // TODO: Implement photo change
                      },
                      child: Text(
                        'Change Photo',
                        style: AppTypography.actionA2.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalGap24,

              // Career Information
              Text(
                'Career Information',
                style: AppTypography.headingH6.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.verticalGap16,
              _InfoRow(
                label: 'Role',
                value: profile?.jobTitle ?? 'Care Worker',
              ),
              AppSpacing.verticalGap12,
              _InfoRow(
                label: 'Organisation',
                value: profile?.organizationId ?? 'Sunshine Care Home',
              ),
              AppSpacing.verticalGap24,

              // Account Information
              Text(
                'Account Information',
                style: AppTypography.headingH6.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.verticalGap16,
              AppTextField(
                controller: _firstNameController,
                label: 'First Name',
              ),
              AppSpacing.verticalGap16,
              AppTextField(
                controller: _lastNameController,
                label: 'Last Name',
              ),
              AppSpacing.verticalGap16,
              AppTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email typically can't be changed
              ),
              AppSpacing.verticalGap16,
              AppTextField(
                controller: _phoneController,
                label: 'Phone number',
                hintText: 'Enter phone number',
                keyboardType: TextInputType.phone,
                helperText: 'Used for contact and account recovery',
              ),
              AppSpacing.verticalGap32,

              // Save Button
              AppButton.primary(
                text: 'Save',
                onPressed: _saveChanges,
                isLoading: _isLoading,
              ),
              AppSpacing.verticalGap24,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    // TODO: Implement save functionality
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionC1.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        AppSpacing.verticalGap4,
        Text(value, style: AppTypography.bodyB2),
      ],
    );
  }
}
