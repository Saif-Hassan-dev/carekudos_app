import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App typography from Figma design system
abstract class AppTypography {
  static String get fontFamily => GoogleFonts.inter().fontFamily!;

  // ============================================
  // DISPLAY STYLES
  // ============================================
  
  /// Display D1 - 36px SemiBold
  static TextStyle get displayD1 => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Display D2 - 28px SemiBold
  static TextStyle get displayD2 => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// Display D3 - 24px SemiBold
  static TextStyle get displayD3 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ============================================
  // HEADING STYLES
  // ============================================

  /// Heading H1 - 28px SemiBold
  static TextStyle get headingH1 => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// Heading H2 - 24px SemiBold
  static TextStyle get headingH2 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// Heading H3 - 20px SemiBold
  static TextStyle get headingH3 => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// Heading H4 - 16px SemiBold
  static TextStyle get headingH4 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Heading H5 - 14px SemiBold
  static TextStyle get headingH5 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Heading H6 - 12px SemiBold
  static TextStyle get headingH6 => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ============================================
  // BODY STYLES
  // ============================================

  /// Body B1 - 16px Medium
  static TextStyle get bodyB1 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body B2 - 16px Regular
  static TextStyle get bodyB2 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body B3 - 14px Medium
  static TextStyle get bodyB3 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body B4 - 14px Regular
  static TextStyle get bodyB4 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body B5 - 12px Medium
  static TextStyle get bodyB5 => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Body B6 - 12px Regular
  static TextStyle get bodyB6 => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ============================================
  // ACTION STYLES
  // ============================================

  /// Action A1 - 16px Medium (buttons)
  static TextStyle get actionA1 => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Action A2 - 14px Medium
  static TextStyle get actionA2 => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// Action A3 - 12px Medium
  static TextStyle get actionA3 => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ============================================
  // CAPTION STYLES
  // ============================================

  /// Caption C1 - 10px Medium
  static TextStyle get captionC1 => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Caption C2 - 10px Regular
  static TextStyle get captionC2 => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );
}
