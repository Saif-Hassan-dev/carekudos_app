import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/permissions_provider.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/extensions.dart';

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
      body: SafeArea(
        child: Column(
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
                    'Account Settings',
                    style: AppTypography.headingH3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: profileAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (profile) => SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Photo Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: AppColors.neutral0,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.neutral200, width: 1),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryLight,
                                border: Border.all(
                                    color: AppColors.neutral300, width: 2),
                                image: profile?.profilePictureUrl != null &&
                                        profile!.profilePictureUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(
                                            profile.profilePictureUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: profile?.profilePictureUrl == null ||
                                      profile!.profilePictureUrl!.isEmpty
                                  ? Center(
                                      child: Text(
                                        profile?.firstName.isNotEmpty == true
                                            ? profile!.firstName[0]
                                                .toUpperCase()
                                            : '?',
                                        style:
                                            AppTypography.headingH1.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                // TODO: Implement photo change
                              },
                              child: Text(
                                'Change Photo',
                                style: AppTypography.bodyB3.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Career Information Card
                      _SectionCard(
                        headerTitle: 'Career Information',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              label: 'Role',
                              value:
                                  profile?.jobTitle ?? 'Care Worker',
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              label: 'Organisation',
                              value: profile?.organizationId ??
                                  'Sunshine Care Home',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Account Information Card
                      _SectionCard(
                        headerTitle: 'Account Information',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              controller: _firstNameController,
                              label: 'First name',
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              enabled: false,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _phoneController,
                              label: 'Phone number',
                              hintText: 'Enter phone number',
                              keyboardType: TextInputType.phone,
                              helperText:
                                  'Used for contact and account recovery',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.neutral0,
                            disabledBackgroundColor: AppColors.neutral300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        context.showErrorSnackBar('User not found');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        context.showSnackBar('Changes saved successfully');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to save changes: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String headerTitle;
  final Widget child;

  const _SectionCard({
    required this.headerTitle,
    required this.child,
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
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.neutral0,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.neutral200, width: 1),
          ),
          child: child,
        ),
      ],
    );
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
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyB2.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
