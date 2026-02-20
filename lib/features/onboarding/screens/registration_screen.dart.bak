import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/extensions.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const RegistrationScreen({super.key, required this.onNext});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Information
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _postcodeController = TextEditingController();
  
  // Account Information
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Organization
  final _orgCodeController = TextEditingController();
  
  // Agreement checkboxes
  bool _eligibleToWork = false;
  bool _agreeToTerms = false;
  bool _agreeToGdpr = false;
  bool _agreeToUpdates = false;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _postcodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgCodeController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _postcodeController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _orgCodeController.text.isNotEmpty &&
        _eligibleToWork &&
        _agreeToTerms &&
        _agreeToGdpr;
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit) return;

    setState(() => _isLoading = true);

    try {
      // Create Firebase auth account
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User creation failed');
      }

      final onboardingData = ref.read(onboardingProvider);

      // Save complete user profile to Firestore
      await FirebaseService.createUserProfile(
        userId: userId,
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: onboardingData.selectedRole ?? 'care_worker',
        jobTitle: '', // Can be set later
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        postcode: _postcodeController.text.trim().isNotEmpty ? _postcodeController.text.trim() : null,
        organizationId: _orgCodeController.text.trim().isNotEmpty ? _orgCodeController.text.trim() : null,
        gdprConsent: _agreeToGdpr,
      );

      // Clear onboarding state
      ref.read(onboardingProvider.notifier).reset();

      if (mounted) widget.onNext();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        context.showErrorSnackBar(ErrorHandler.getAuthErrorMessage(e));
      }
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Title
                const Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please fill in the following form to create your account.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Basic Information Section
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First name',
                  hintText: 'Enter first name',
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hintText: 'Enter last name',
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone number (optional)',
                  hintText: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                  validator: null, // Optional field
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _postcodeController,
                  label: 'Postcode',
                  hintText: 'Enter postcode',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Postcode is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Account Information Section
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Enter password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF757575),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hintText: 'Re-enter password',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF757575),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Organization Section
                const Text(
                  'organization',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildTextField(
                  controller: _orgCodeController,
                  label: 'Organization Code',
                  hintText: 'Enter organization code',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Organization code is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Provided by your care home manager.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Checkboxes
                _buildCheckbox(
                  value: _eligibleToWork,
                  label: 'I am eligible to work in the UK',
                  onChanged: (value) => setState(() => _eligibleToWork = value ?? false),
                ),
                const SizedBox(height: 12),
                
                _buildCheckbox(
                  value: _agreeToTerms,
                  label: 'I agree to the Terms & Conditions',
                  onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                  hasLink: true,
                ),
                const SizedBox(height: 12),
                
                _buildCheckbox(
                  value: _agreeToGdpr,
                  label: 'I understand and agree to the GDPR guidelines',
                  onChanged: (value) => setState(() => _agreeToGdpr = value ?? false),
                  hasLink: true,
                ),
                const SizedBox(height: 12),
                
                _buildCheckbox(
                  value: _agreeToUpdates,
                  label: 'I agree to receive product updates',
                  onChanged: (value) => setState(() => _agreeToUpdates = value ?? false),
                ),
                const SizedBox(height: 32),
                
                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _canSubmit && !_isLoading ? _createAccount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSubmit ? const Color(0xFF0A2C6B) : const Color(0xFFE0E0E0),
                      foregroundColor: _canSubmit ? Colors.white : const Color(0xFFBDBDBD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      disabledForegroundColor: const Color(0xFFBDBDBD),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Account',
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: (_) => setState(() {}), // Rebuild to update button state
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFFBDBDBD),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0A2C6B), width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFFE53935),
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF212121),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
    bool hasLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0A2C6B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: const BorderSide(
              color: Color(0xFFBDBDBD),
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF212121),
                decoration: hasLink ? TextDecoration.underline : null,
                decorationColor: hasLink ? const Color(0xFF0A2C6B) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
