import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App typography from Figma design system
abstract class AppTypography {
  static const String fontFamily = 'Inter';

  // ============================================
  // DISPLAY STYLES
  // ============================================
  
  /// Display D1 - 36px SemiBold
  static const TextStyle displayD1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Display D2 - 28px SemiBold
  static const TextStyle displayD2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// Display D3 - 24px SemiBold
  static const TextStyle displayD3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ============================================
  // HEADING STYLES
  // ============================================

  /// Heading H1 - 28px SemiBold
  static const TextStyle headingH1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// Heading H2 - 24px SemiBold
  static const TextStyle headingH2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// Heading H3 - 20px SemiBold
  static const TextStyle headingH3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// Heading H4 - 16px SemiBold
  static const TextStyle headingH4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Heading H5 - 14px SemiBold
  static const TextStyle headingH5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Heading H6 - 12px SemiBold
  static const TextStyle headingH6 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ============================================
  // BODY STYLES
  // ============================================

  /// Body B1 - 16px Medium
  static const TextStyle bodyB1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body B2 - 16px Regular
  static const TextStyle bodyB2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body B3 - 14px Medium
  static const TextStyle bodyB3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body B4 - 14px Regular
  static const TextStyle bodyB4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body B5 - 12px Medium
  static const TextStyle bodyB5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body B6 - 12px Regular
  static const TextStyle bodyB6 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ============================================
  // ACTION STYLES
  // ============================================

  /// Action A1 - 16px Medium (buttons)
  static const TextStyle actionA1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Action A2 - 14px Medium
  static const TextStyle actionA2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Action A3 - 12px Medium
  static const TextStyle actionA3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ============================================
  // CAPTION STYLES
  // ============================================

  /// Caption C1 - 10px Medium
  static const TextStyle captionC1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Caption C2 - 10px Regular
  static const TextStyle captionC2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );
}
