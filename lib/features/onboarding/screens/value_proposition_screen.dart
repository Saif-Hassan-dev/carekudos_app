import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_button.dart';

class ValuePropositionScreen extends StatelessWidget {
  final VoidCallback onNext;

  const ValuePropositionScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.all24,
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Hero Image
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.allXl,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.allXl,
                  child: Image.asset(
                    'assets/images/heroplace.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: AppColors.primaryLight,
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.verticalGap40,
              // Main Text
              Text(
                'Make your exceptional care visible',
                style: AppTypography.displayD2.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalGap16,
              // Subtitle with chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FeatureChip(label: 'Recognition'),
                  AppSpacing.horizontalGap8,
                  const Icon(Icons.circle, size: 4, color: AppColors.textTertiary),
                  AppSpacing.horizontalGap8,
                  _FeatureChip(label: 'Portfolio'),
                  AppSpacing.horizontalGap8,
                  const Icon(Icons.circle, size: 4, color: AppColors.textTertiary),
                  AppSpacing.horizontalGap8,
                  _FeatureChip(label: 'CQC Evidence'),
                ],
              ),
              const Spacer(flex: 2),
              // Get Started Button
              AppButton.primary(
                text: 'Get Started',
                onPressed: onNext,
                isFullWidth: true,
              ),
              AppSpacing.verticalGap24,
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.bodyB4.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
