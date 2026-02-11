import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const ProfileSetupScreen({super.key, required this.onNext});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _jobTitleController;
  final _formKey = GlobalKey<FormState>();
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _jobTitleController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jobTitleController.dispose();
    super.dispose();
  }

  Future<void> _finishSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final onboardingData = ref.read(onboardingProvider);

      // Save complete user profile to Firestore
      await FirebaseService.createUserProfile(
        userId: userId,
        email: onboardingData.email ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: onboardingData.selectedRole ?? 'care_worker',
        jobTitle: _jobTitleController.text.trim(),
      );

      // Clear onboarding state
      ref.read(onboardingProvider.notifier).reset();

      if (mounted) widget.onNext();
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(ErrorHandler.getGenericErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () {
                    // TODO: Implement photo picker
                  },
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                    child: const Icon(Icons.camera_alt, size: 40),
                  ),
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  validator: Validators.validateName,
                  prefixIcon: Icons.person,
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  validator: Validators.validateName,
                  prefixIcon: Icons.person_outline,
                ),

                const SizedBox(height: 16),
                CustomTextField(
                  controller: _jobTitleController,
                  label: 'Job Title',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Job title is required';
                    }
                    return null;
                  },
                  prefixIcon: Icons.work,
                ),

                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => _notificationsEnabled = value),
                ),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Finish Setup',
                  onPressed: _finishSetup,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
