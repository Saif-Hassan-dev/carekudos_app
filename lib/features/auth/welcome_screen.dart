import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/app_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.horizontal24,
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              const AppLogo(size: LogoSize.display),
              AppSpacing.verticalGap32,
              // Welcome Text
              Text(
                'Welcome to',
                style: AppTypography.headingH3.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalGap8,
              Text(
                'CareKudos',
                style: AppTypography.displayD1.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalGap16,
              Text(
                'Recognizing care excellence,\nprotecting privacy',
                style: AppTypography.bodyB2.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              // Register Button
              AppButton.primary(
                text: 'Create Account',
                onPressed: () => context.go('/onboarding'),
                isFullWidth: true,
              ),
              AppSpacing.verticalGap12,
              // Login Button
              AppButton.secondary(
                text: 'Sign In',
                onPressed: () => context.go('/login'),
                isFullWidth: true,
              ),
              AppSpacing.verticalGap40,
            ],
          ),
        ),
      ),
    );
  }
}
