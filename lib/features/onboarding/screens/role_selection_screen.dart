import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatefulWidget {
  final VoidCallback onNext;

  const RoleSelectionScreen({super.key, required this.onNext});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = 'care_worker';
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
                  'I am a:',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              onPressed: widget.onNext,
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
