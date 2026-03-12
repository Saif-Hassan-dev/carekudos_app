import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/theme.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/auth/permissions_provider.dart';
import '../../core/widgets/app_logo.dart';

enum _WebRole { manager, admin }

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _errorMessage;
  _WebRole _selectedRole = _WebRole.manager;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final success = await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      final profile = await ref.read(userProfileProvider.future);

      if (_selectedRole == _WebRole.admin) {
        if (profile != null && profile.role == 'admin') {
          context.go('/admin/dashboard');
        } else {
          await ref.read(authNotifierProvider.notifier).logout();
          setState(() {
            _errorMessage =
                'Access denied. This login is for administrators only.';
          });
        }
      } else {
        // Manager
        if (profile != null && profile.role == 'manager') {
          context.go('/admin/manager');
        } else {
          await ref.read(authNotifierProvider.notifier).logout();
          setState(() {
            _errorMessage =
                'Access denied. This login is for managers only.';
          });
        }
      }
    } else {
      final authState = ref.read(authNotifierProvider);
      setState(() {
        _errorMessage = authState.error ?? 'Invalid email or password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive card width: 480px on desktop, full-width minus padding on mobile
    final cardWidth = screenWidth > 560 ? 480.0 : screenWidth - 48;

    return Title(
      title: 'Admin Login',
      color: AppColors.primary,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        body: Column(
          children: [
            // ═══════════════════════════════════════════
            // TOP HEADER BAR — full width, white, logo centered
            // ═══════════════════════════════════════════
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: const Center(
                child: AppLogo(size: LogoSize.lg, showText: true),
              ),
            ),
            // Divider line below header
            Container(height: 1, color: const Color(0xFFE5E7EB)),

            // ═══════════════════════════════════════════
            // MAIN CONTENT — login card centered
            // ═══════════════════════════════════════════
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 40),
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: _buildForm(authState),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AuthState authState) {
    final isManager = _selectedRole == _WebRole.manager;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Role Toggle ──
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _RoleTab(
                  label: 'Manager',
                  isActive: isManager,
                  onTap: () => setState(() {
                    _selectedRole = _WebRole.manager;
                    _errorMessage = null;
                  }),
                ),
                _RoleTab(
                  label: 'Administrator',
                  isActive: !isManager,
                  onTap: () => setState(() {
                    _selectedRole = _WebRole.admin;
                    _errorMessage = null;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Title ──
          Center(
            child: Text(
              isManager ? 'Manager Login' : 'Admin Login',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              isManager
                  ? 'Sign in to manage your team and review posts'
                  : 'Sign in to manage organisations and system settings',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Error message ──
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Email Address ──
          Text(
            'Email Address',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF111827)),
            decoration: _inputDecoration(hint: 'you@example.com'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$')
                  .hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // ── Password ──
          Text(
            'Password',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF111827)),
            decoration: _inputDecoration(
              hint: 'Enter password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: const Color(0xFF9CA3AF),
                ),
                splashRadius: 18,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),

          const SizedBox(height: 4),

          // ── Forgot Password ──
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A2C6B),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Continue Button ──
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : _handleLogin,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return const Color(0xFF1E3A8A).withValues(alpha: 0.7);
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return const Color(0xFF162E6E);
                  }
                  return const Color(0xFF1E3A8A);
                }),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                elevation: WidgetStateProperty.all(0),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '→',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        color: const Color(0xFFADB5BD),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0A2C6B), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}

// ─── Role Toggle Tab ───

class _RoleTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF111827)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
