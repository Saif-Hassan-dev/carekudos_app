import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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

  // ── Basic Information ──
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _preferredContactMethod;
  Uint8List? _profilePhotoBytes;
  String? _profilePhotoBase64;

  // ── Address & Organisation ──
  final _fullAddressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _orgCodeController = TextEditingController();
  final _profRegNumberController = TextEditingController();

  // ── Emergency Contact ──
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // ── Account Information ──
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ── Agreement checkboxes ──
  bool _eligibleToWork = false;
  bool _agreeToTerms = false;
  bool _agreeToGdpr = false;
  bool _agreeToUpdates = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Password strength
  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  Color _passwordStrengthColor = const Color(0xFFE0E0E0);

  static const _contactMethods = ['Email', 'Phone', 'SMS', 'Post'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _fullAddressController.dispose();
    _postcodeController.dispose();
    _orgCodeController.dispose();
    _profRegNumberController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Password strength ──
  void _updatePasswordStrength(String password) {
    double strength = 0;
    String label = '';
    Color color = const Color(0xFFE0E0E0);

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthLabel = '';
        _passwordStrengthColor = const Color(0xFFE0E0E0);
      });
      return;
    }

    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.15;

    if (strength <= 0.3) {
      label = 'Weak';
      color = const Color(0xFFE53935);
    } else if (strength <= 0.6) {
      label = 'Medium';
      color = const Color(0xFFFFA726);
    } else {
      label = 'Strong';
      color = const Color(0xFF4CAF50);
    }

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
      _passwordStrengthLabel = label;
      _passwordStrengthColor = color;
    });
  }

  // ── Photo picker (uses XFile bytes directly — works on all platforms) ──
  Future<void> _pickProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (picked == null) return; // User cancelled

      final bytes = await picked.readAsBytes();

      // Check file size (5 MB limit)
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          context.showErrorSnackBar('Photo must be under 5 MB');
        }
        return;
      }

      setState(() {
        _profilePhotoBytes = bytes;
        _profilePhotoBase64 = base64Encode(bytes);
      });
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Could not load photo. Please try again.');
      }
      debugPrint('Image picker error: $e');
    }
  }

  // ── Date of Birth ──
  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A2C6B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF212121),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  bool get _canSubmit {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
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
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User creation failed');

      final onboardingData = ref.read(onboardingProvider);

      await FirebaseService.createUserProfile(
        userId: userId,
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: onboardingData.selectedRole ?? 'care_worker',
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        postcode: _postcodeController.text.trim().isNotEmpty
            ? _postcodeController.text.trim()
            : null,
        organizationId: _orgCodeController.text.trim().isNotEmpty
            ? _orgCodeController.text.trim()
            : null,
        gdprConsent: _agreeToGdpr,
        dateOfBirth: _dateOfBirth,
        preferredContactMethod: _preferredContactMethod,
        fullAddress: _fullAddressController.text.trim().isNotEmpty
            ? _fullAddressController.text.trim()
            : null,
        professionalRegNumber: _profRegNumberController.text.trim().isNotEmpty
            ? _profRegNumberController.text.trim()
            : null,
        emergencyContactName: _emergencyNameController.text.trim().isNotEmpty
            ? _emergencyNameController.text.trim()
            : null,
        emergencyContactPhone:
            _emergencyPhoneController.text.trim().isNotEmpty
                ? _emergencyPhoneController.text.trim()
                : null,
        profilePhotoBase64: _profilePhotoBase64,
        agreeToUpdates: _agreeToUpdates,
      );

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

  // ═══════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Title
                const Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please fill in the following form to create your account.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 24),

                // ══════════════════════════════════
                //  1. BASIC INFORMATION
                // ══════════════════════════════════
                _sectionBox('Basic Information', [
                  const SizedBox(height: 18),
                  // Profile Photo
                  _label('Profile Photo (optional)'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Preview circle
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF5F5F5),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                          ),
                          image: _profilePhotoBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(_profilePhotoBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profilePhotoBytes == null
                            ? const Icon(
                                Icons.file_upload_outlined,
                                color: Color(0xFF757575),
                                size: 22,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      // Upload button
                      ElevatedButton.icon(
                        onPressed: _pickProfilePhoto,
                        icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                        label: const Text('Upload Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A2C6B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'JPG, PNG\nup to 5MB',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                        height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  _field(
                      controller: _firstNameController,
                      label: 'First name',
                      hint: 'Enter first name',
                      validator: Validators.validateName),
                  _gap,
                  _field(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hint: 'Enter last name',
                      validator: Validators.validateName),
                  _gap,
                  _buildDateField(),
                  _gap,
                  _field(
                      controller: _phoneController,
                      label: 'Phone number (optional)',
                      hint: 'Enter phone number',
                      keyboard: TextInputType.phone),
                  _gap,
                  _buildDropdownField(),
                ]),
                const SizedBox(height: 20),

                // ══════════════════════════════════
                //  2. ADDRESS & ORGANISATION
                // ══════════════════════════════════
                _sectionBox('Address & Organisation', [
                  const SizedBox(height: 18),
                  _field(
                      controller: _fullAddressController,
                      label: 'Full address',
                      hint: 'Enter full address'),
                  _gap,
                  _field(
                      controller: _postcodeController,
                      label: 'Postcode',
                      hint: 'Enter Post Code'),
                  _gap,
                  _field(
                    controller: _orgCodeController,
                    label: 'Organization Code',
                    hint: 'Enter organization code',
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Organization code is required' : null,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Provided by your care home manager.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                  _gap,
                  _field(
                      controller: _profRegNumberController,
                      label: 'Professional Registration Number (optional)',
                      hint: 'e.g., Social Work England ID'),
                ]),
                const SizedBox(height: 20),

                // ══════════════════════════════════
                //  3. EMERGENCY CONTACT
                // ══════════════════════════════════
                _sectionBox('Emergency Contact', [
                  const SizedBox(height: 18),
                  _field(
                      controller: _emergencyNameController,
                      label: 'Emergency Contact Namer (optional)',
                      hint: 'Emergency Contact name'),
                  _gap,
                  _field(
                      controller: _emergencyPhoneController,
                      label: 'Emergency Contact Phone Number',
                      hint: 'Emergency Contact Number',
                      keyboard: TextInputType.phone),
                ]),
                const SizedBox(height: 20),

                // ══════════════════════════════════
                //  4. ACCOUNT INFORMATION
                // ══════════════════════════════════
                _sectionBox('Account Information', [
                  const SizedBox(height: 18),
                  _field(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'you@example.com',
                      keyboard: TextInputType.emailAddress,
                      validator: Validators.validateEmail),
                  _gap,
                  // Password
                  _field(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter password',
                    obscure: _obscurePassword,
                    onChanged: _updatePasswordStrength,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF757575),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: Validators.validatePassword,
                  ),
                  // Strength bar
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 6,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: const Color(0xFFE0E0E0),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: _passwordStrength,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: _passwordStrengthColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _passwordStrengthLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _passwordStrengthColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                  _gap,
                  // Confirm Password
                  _field(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Re-enter password',
                    obscure: _obscureConfirmPassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF757575),
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  _gap,
                  // 2FA info box
                  _infoBox(
                    icon: Icons.lock_outlined,
                    iconBg: const Color(0xFF0A2C6B),
                    text:
                        'Two-factor authentication will be available after registration for enhanced security.',
                  ),
                ]),
                const SizedBox(height: 20),

                // ══════════════════════════════════
                //  5. ORGANIZATION
                // ══════════════════════════════════
                _sectionBox('Organization', [
                  const SizedBox(height: 18),
                  _field(
                    controller: _orgCodeController,
                    label: 'Organization Code',
                    hint: 'Enter organization code',
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Organization code is required' : null,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Provided by your care home manager.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ]),
                const SizedBox(height: 24),

                // ══════════════════════════════════
                //  6. CHECKBOXES
                // ══════════════════════════════════
                _check(_eligibleToWork, 'I am eligible to work in the UK',
                    (v) => setState(() => _eligibleToWork = v ?? false)),
                const SizedBox(height: 14),
                _check(_agreeToTerms, 'I agree to the ',
                    (v) => setState(() => _agreeToTerms = v ?? false),
                    linkText: 'Terms & Conditions'),
                const SizedBox(height: 14),
                _check(
                    _agreeToGdpr,
                    'I understand and agree to the ',
                    (v) => setState(() => _agreeToGdpr = v ?? false),
                    linkText: 'GDPR guidelines'),
                const SizedBox(height: 14),
                _check(_agreeToUpdates, 'I agree to receive product updates',
                    (v) => setState(() => _agreeToUpdates = v ?? false)),
                const SizedBox(height: 28),

                // ══════════════════════════════════
                //  7. WHY WE COLLECT DATA
                // ══════════════════════════════════
                _whyWeCollect(),
                const SizedBox(height: 16),

                // ══════════════════════════════════
                //  8. GDPR COMPLIANT
                // ══════════════════════════════════
                _gdprBox(),
                const SizedBox(height: 16),

                // ══════════════════════════════════
                //  9. NEED HELP?
                // ══════════════════════════════════
                _needHelpBox(),
                const SizedBox(height: 24),

                // ══════════════════════════════════
                //  10. CREATE ACCOUNT
                // ══════════════════════════════════
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _canSubmit && !_isLoading ? _createAccount : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSubmit
                          ? const Color(0xFF0A2C6B)
                          : const Color(0xFFE0E0E0),
                      foregroundColor:
                          _canSubmit ? Colors.white : const Color(0xFFBDBDBD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDBDBD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  SECTION BOX (wraps header + fields)
  // ═══════════════════════════════════════════════
  static const _gap = SizedBox(height: 14);

  Widget _sectionBox(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EAED), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 0, right: 0, top: 0),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  LABEL
  // ═══════════════════════════════════════════════
  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF424242),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TEXT FIELD
  // ═══════════════════════════════════════════════
  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          validator: validator,
          onChanged: (val) {
            setState(() {});
            onChanged?.call(val);
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFFBDBDBD),
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0A2C6B)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE53935)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE53935)),
            ),
            errorStyle: const TextStyle(
                fontSize: 12, color: Color(0xFFE53935)),
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  DATE FIELD
  // ═══════════════════════════════════════════════
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242)),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDateOfBirth,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dateOfBirth != null
                        ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                        : 'Select Date of Birth',
                    style: TextStyle(
                      fontSize: 14,
                      color: _dateOfBirth != null
                          ? const Color(0xFF212121)
                          : const Color(0xFFBDBDBD),
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: Color(0xFF757575)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  DROPDOWN
  // ═══════════════════════════════════════════════
  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred Contact Method',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242)),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _preferredContactMethod,
              hint: const Text(
                'Select Preferred Contact Method',
                style: TextStyle(fontSize: 14, color: Color(0xFFBDBDBD)),
              ),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF757575)),
              isExpanded: true,
              items: _contactMethods
                  .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF212121)))))
                  .toList(),
              onChanged: (v) => setState(() => _preferredContactMethod = v),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  CHECKBOX
  // ═══════════════════════════════════════════════
  Widget _check(bool value, String label, ValueChanged<bool?> onChanged,
      {String? linkText}) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF0A2C6B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              side: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: linkText != null
                ? RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF212121),
                        fontFamily: 'Inter',
                      ),
                      children: [
                        TextSpan(text: label),
                        TextSpan(
                          text: linkText,
                          style: const TextStyle(
                            color: Color(0xFF0A2C6B),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF0A2C6B),
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF212121),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  INFO BOX (2FA)
  // ═══════════════════════════════════════════════
  Widget _infoBox({
    required IconData icon,
    required Color iconBg,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB8D4E8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconBg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF424242),
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  WHY WE COLLECT
  // ═══════════════════════════════════════════════
  Widget _whyWeCollect() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A2C6B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Why we collect this data',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121))),
                    SizedBox(height: 2),
                    Text('Your safety and compliance matter',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF757575))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _bullet('Identity verification:',
              'Ensures only authorized care professionals access the platform'),
          const SizedBox(height: 12),
          _bullet('Emergency safeguarding:',
              'Contact details enable rapid response in critical situations'),
          const SizedBox(height: 12),
          _bullet('Regulatory compliance:',
              'Required for CQC standards and audit trails'),
          const SizedBox(height: 12),
          _bullet('Professional verification:',
              'Registration numbers validate credentials and qualifications'),
        ],
      ),
    );
  }

  Widget _bullet(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle, size: 18, color: Color(0xFF4CAF50)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: Color(0xFF424242)),
              children: [
                TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  GDPR BOX
  // ═══════════════════════════════════════════════
  Widget _gdprBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0A2C6B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 20, color: Color(0xFF0A2C6B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GDPR Compliant',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A2C6B))),
                const SizedBox(height: 4),
                Text(
                  'Your data is encrypted, secure, and protected under UK GDPR regulations. '
                  'You have full control over your information and can request access, '
                  'modification, or deletion at any time.',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF424242).withAlpha(217),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  NEED HELP BOX
  // ═══════════════════════════════════════════════
  Widget _needHelpBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Need help?',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121))),
          const SizedBox(height: 4),
          Text(
            'Contact your care home manager or email '
            'support@carekudos.com for assistance with registration.',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF424242).withAlpha(217),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
