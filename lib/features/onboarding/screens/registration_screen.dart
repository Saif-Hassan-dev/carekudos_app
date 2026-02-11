import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const RegistrationScreen({super.key, required this.onNext});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _orgCodeController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Error states for each field
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _orgCodeError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _orgCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgCodeController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    final error = Validators.validateEmail(value);
    setState(() => _emailError = error);
  }

  void _validatePassword(String value) {
    final error = Validators.validatePassword(value);
    setState(() => _passwordError = error);
    _validateConfirmPassword(_confirmPasswordController.text);
  }

  void _validateConfirmPassword(String value) {
    if (value.isEmpty) {
      setState(() => _confirmPasswordError = null);
    } else if (value != _passwordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
    } else {
      setState(() => _confirmPasswordError = null);
    }
  }

  void _validateOrgCode(String value) {
    final error = Validators.validateOrgCode(value);
    setState(() => _orgCodeError = error);
  }

  bool get _hasErrors =>
      _emailError != null ||
      _passwordError != null ||
      _confirmPasswordError != null ||
      _orgCodeError != null;

  bool get _allFieldsFilled =>
      _emailController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty &&
      _orgCodeController.text.isNotEmpty;

  Future<void> _register() async {
    // Validate all fields
    _validateEmail(_emailController.text);
    _validatePassword(_passwordController.text);
    _validateConfirmPassword(_confirmPasswordController.text);
    _validateOrgCode(_orgCodeController.text);

    if (_hasErrors || !_allFieldsFilled) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      ref.read(onboardingProvider.notifier).setRegistration(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            orgCode: _orgCodeController.text,
          );

      if (mounted) widget.onNext();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        context.showErrorSnackBar(ErrorHandler.getAuthErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.all24,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.verticalGap40,
                Text(
                  'Create Account',
                  style: AppTypography.displayD2,
                ),
                AppSpacing.verticalGap8,
                Text(
                  'Enter your details to get started',
                  style: AppTypography.bodyB3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.verticalGap32,

                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'Enter your email address',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  onChanged: _validateEmail,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                ),
                AppSpacing.verticalGap20,

                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Create a strong password',
                  obscureText: true,
                  errorText: _passwordError,
                  onChanged: _validatePassword,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.next,
                ),
                AppSpacing.verticalGap20,

                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  obscureText: true,
                  errorText: _confirmPasswordError,
                  onChanged: _validateConfirmPassword,
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.next,
                ),
                AppSpacing.verticalGap20,

                AppTextField(
                  controller: _orgCodeController,
                  label: 'Organization Code',
                  hintText: 'Enter your organization code',
                  helperText: 'Ask your manager for this code',
                  errorText: _orgCodeError,
                  onChanged: _validateOrgCode,
                  prefixIcon: Icons.business_outlined,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _register(),
                ),
                AppSpacing.verticalGap40,

                AppButton.primary(
                  text: 'Continue',
                  onPressed: _allFieldsFilled && !_hasErrors ? _register : null,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
                AppSpacing.verticalGap16,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
