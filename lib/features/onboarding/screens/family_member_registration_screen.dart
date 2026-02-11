import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

// This screen appears ONLY if user selects 'family_member' role
// Shows after role_selection_screen

class FamilyMemberRegistrationScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const FamilyMemberRegistrationScreen({super.key, required this.onNext});

  @override
  ConsumerState<FamilyMemberRegistrationScreen> createState() =>
      _FamilyMemberRegistrationScreenState();
}

class _FamilyMemberRegistrationScreenState
    extends ConsumerState<FamilyMemberRegistrationScreen> {
  final _residentNameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Member Details')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Connect with your loved one\'s care team',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),

            // Resident Name
            CustomTextField(
              controller: _residentNameController,
              label: 'Resident\'s Name',
              helperText: 'Who are you visiting?',
            ),

            // Relationship
            CustomTextField(
              controller: _relationshipController,
              label: 'Your Relationship',
              helperText: 'e.g., Daughter, Son, Spouse',
            ),

            // Manager Invite Code
            CustomTextField(
              controller: _inviteCodeController,
              label: 'Manager Invite Code',
              helperText: 'Ask your care manager for this code',
            ),

            const Spacer(),

            CustomButton(text: 'Connect Account', onPressed: _connectAccount),
          ],
        ),
      ),
    );
  }

  Future<void> _connectAccount() async {
    // Verify invite code with manager
    // Link family member to specific managers
    // Store resident relationship info

    // Save to onboarding provider
    ref
        .read(onboardingProvider.notifier)
        .setFamilyMemberInfo(
          residentName: _residentNameController.text,
          relationship: _relationshipController.text,
          inviteCode: _inviteCodeController.text,
        );

    widget.onNext();
  }
}
