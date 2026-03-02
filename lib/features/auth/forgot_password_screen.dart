import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/theme/theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkEmailAndSendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();

    try {
      // Send password reset email directly.
      // Firebase's email enumeration protection means we can't reliably
      // check if an email exists beforehand. sendPasswordResetEmail will
      // silently succeed for non-existent emails (security best practice)
      // but will deliver the reset link for valid accounts.
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset email sent again. Check your inbox.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend. Please try again.'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Color(0xFF212121)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reset Password',
          style: AppTypography.headingH4.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _emailSent ? _buildSuccessView() : _buildEmailForm(),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),

          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF0A2C6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 40,
                color: Color(0xFF0A2C6B),
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Forgot your password?',
            style: AppTypography.headingH2.copyWith(
              color: const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            'Enter your registered email address and we\'ll send you a link to reset your password.',
            style: AppTypography.bodyB2.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            prefixIcon: Icons.email_outlined,
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFE53935).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 20, color: Color(0xFFE53935)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodyB4.copyWith(
                        color: const Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _checkEmailAndSendReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2C6B),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF0A2C6B).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'Send Reset Link',
                      style: AppTypography.actionA1.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Back to Login',
              style: AppTypography.bodyB3.copyWith(
                color: const Color(0xFF0A2C6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),

        // Success icon
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 50,
              color: Color(0xFF4CAF50),
            ),
          ),
        ),

        const SizedBox(height: 32),

        Text(
          'Check your email',
          style: AppTypography.headingH2.copyWith(
            color: const Color(0xFF1A1A2E),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        Text(
          'We\'ve sent a password reset link to:',
          style: AppTypography.bodyB2.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          _emailController.text.trim(),
          style: AppTypography.bodyB1.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A2C6B),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'What to do next:',
                style: AppTypography.bodyB2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 12),
              _buildStep('1', 'Open the email from CareKudos'),
              const SizedBox(height: 8),
              _buildStep('2', 'Tap the password reset link'),
              const SizedBox(height: 8),
              _buildStep('3', 'Create a new password'),
              const SizedBox(height: 8),
              _buildStep('4', 'Return here and log in'),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Back to login button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A2C6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Back to Login',
              style: AppTypography.actionA1.copyWith(color: Colors.white),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Resend option
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _resendEmail,
            child: Text(
              'Didn\'t receive it? Resend email',
              style: AppTypography.bodyB3.copyWith(
                color: const Color(0xFF0A2C6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Check your spam folder if you don\'t see the email.',
          style: AppTypography.captionC1.copyWith(
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF0A2C6B),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyB3.copyWith(
              color: const Color(0xFF424242),
            ),
          ),
        ),
      ],
    );
  }
}
