import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/onboarding_provider.dart';

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
      // Save role to onboarding state
      ref.read(onboardingProvider.notifier).setRole(_selectedRole!);
      widget.onNext();
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 40),
            Column(
              children: [
                const Text(
                  'I AM A :',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 32),
                ...roles.map(
                  (role) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RadioListTile(
                      title: Text(role['label']!),
                      value: role['id']!,
                      groupValue: _selectedRole,
                      onChanged: (value) =>
                          setState(() => _selectedRole = value),
                    ),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _continueWithRole,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
