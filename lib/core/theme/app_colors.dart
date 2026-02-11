import 'package:flutter/material.dart';


abstract class AppColors {
  // ============================================
  // NEUTRAL
  // ============================================
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF8F9FA);
  static const Color neutral100 = Color(0xFFF1F3F5);
  static const Color neutral200 = Color(0xFFE9ECEF);
  static const Color neutral300 = Color(0xFFDEE2E6);
  static const Color neutral400 = Color(0xFFCED4DA);
  static const Color neutral500 = Color(0xFFADB5BD);
  static const Color neutral600 = Color(0xFF868E96);
  static const Color neutral700 = Color(0xFF495057);
  static const Color neutral800 = Color(0xFF212529);
  static const Color neutral900 = Color(0xFF121417);
  static const Color neutral1000 = Color(0xFF0B0D12);

  // ============================================
  // NAVY (PRIMARY)
  // ============================================
  static const Color navy50 = Color(0xFFEEF3FB);
  static const Color navy100 = Color(0xFFD6E1F2);
  static const Color navy200 = Color(0xFFADC4E5);
  static const Color navy300 = Color(0xFF7FA2D4);
  static const Color navy400 = Color(0xFF4F7EC1);
  static const Color navy500 = Color(0xFF0A2C6B);
  static const Color navy600 = Color(0xFF082555);
  static const Color navy700 = Color(0xFF061D48);
  static const Color navy800 = Color(0xFF041537);
  static const Color navy900 = Color(0xFF020E26);

  static const Color primary = navy500;
  static const Color primaryLight = navy100;
  static const Color primaryDark = navy700;

  // ============================================
  // GOLD (SECONDARY)
  // ============================================
  static const Color gold50 = Color(0xFFFFF9E6);
  static const Color gold100 = Color(0xFFFFF0BF);
  static const Color gold200 = Color(0xFFFFE28A);
  static const Color gold300 = Color(0xFFFFD24F);
  static const Color gold400 = Color(0xFFD4AF37);
  static const Color gold500 = Color(0xFFB8962E);
  static const Color gold600 = Color(0xFF947723);
  static const Color gold700 = Color(0xFF6F5910);
  static const Color gold800 = Color(0xFF4A3B10);

  static const Color secondary = gold400;
  static const Color secondaryLight = gold100;
  static const Color secondaryDark = gold600;

  // ============================================
  // SKY (TERTIARY)
  // ============================================
  static const Color sky50 = Color(0xFFEAF8FC);
  static const Color sky100 = Color(0xFFD4F0F9);
  static const Color sky200 = Color(0xFFA8E1F2);
  static const Color sky300 = Color(0xFF76CFEA);
  static const Color sky400 = Color(0xFF4ABFE1);
  static const Color sky500 = Color(0xFF26B6D9);
  static const Color sky600 = Color(0xFF1FA0BE);
  static const Color sky700 = Color(0xFF19809A);
  static const Color sky800 = Color(0xFF136176);
  static const Color sky900 = Color(0xFF004252);

  static const Color tertiary = sky500;
  static const Color tertiaryLight = sky100;
  static const Color tertiaryDark = sky700;

  // ============================================
  // BLUE
  // ============================================
  static const Color blue50 = Color(0xFFEEF0FF);
  static const Color blue100 = Color(0xFFD0E2FF);
  static const Color blue200 = Color(0xFFC2CBFF);
  static const Color blue300 = Color(0xFFA5B0FF);
  static const Color blue400 = Color(0xFF7F8DFF);
  static const Color blue500 = Color(0xFF5B6CFF);
  static const Color blue600 = Color(0xFF4C5BDF);
  static const Color blue700 = Color(0xFF3E4BC0);
  static const Color blue800 = Color(0xFF303A9A);
  static const Color blue900 = Color(0xFF232C73);

  // ============================================
  // CORAL
  // ============================================
  static const Color coral50 = Color(0xFFFFF1ED);
  static const Color coral100 = Color(0xFFFFE3D8);
  static const Color coral200 = Color(0xFFFFC7B5);
  static const Color coral300 = Color(0xFFFFA98D);
  static const Color coral400 = Color(0xFFFF8A63);
  static const Color coral500 = Color(0xFFFF6B3D);
  static const Color coral600 = Color(0xFFEB562F);
  static const Color coral700 = Color(0xFFC74426);
  static const Color coral800 = Color(0xFFA3351D);
  static const Color coral900 = Color(0xFF7F2718);

  // ============================================
  // TEAL
  // ============================================
  static const Color teal50 = Color(0xFFEAF8F6);
  static const Color teal100 = Color(0xFFD6F1ED);
  static const Color teal200 = Color(0xFFAEE4DA);
  static const Color teal300 = Color(0xFF7FD3C4);
  static const Color teal400 = Color(0xFF4FC0AE);
  static const Color teal500 = Color(0xFF2FB9A3);
  static const Color teal600 = Color(0xFF229E8B);
  static const Color teal700 = Color(0xFF1C7F71);
  static const Color teal800 = Color(0xFF16645A);
  static const Color teal900 = Color(0xFF0F483F);

  // ============================================
  // GREEN (SUCCESS)
  // ============================================
  static const Color green50 = Color(0xFFEDFDF3);
  static const Color green100 = Color(0xFFD1FAE5);
  static const Color green200 = Color(0xFFA7F3D0);
  static const Color green300 = Color(0xFF6EE7B7);
  static const Color green400 = Color(0xFF34D399);
  static const Color green500 = Color(0xFF18A34A);
  static const Color green600 = Color(0xFF059669);
  static const Color green700 = Color(0xFF047857);
  static const Color green800 = Color(0xFF065F46);
  static const Color green900 = Color(0xFF064E3B);

  static const Color success = green500;
  static const Color successLight = green50;
  static const Color successDark = green700;

  // ============================================
  // RED (ERROR)
  // ============================================
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red400 = Color(0xFFF87171);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red800 = Color(0xFF991B1B);
  static const Color red900 = Color(0xFF7F1D1D);

  static const Color error = red500;
  static const Color errorLight = red50;
  static const Color errorDark = red700;

  // ============================================
  // YELLOW (WARNING)
  // ============================================
  static const Color yellow50 = Color(0xFFFFFBEB);
  static const Color yellow100 = Color(0xFFFEF3C7);
  static const Color yellow200 = Color(0xFFFDE68A);
  static const Color yellow300 = Color(0xFFFCD34D);
  static const Color yellow400 = Color(0xFFFBBF24);
  static const Color yellow500 = Color(0xFFF59E0B);
  static const Color yellow600 = Color(0xFFD97706);
  static const Color yellow700 = Color(0xFFB45309);
  static const Color yellow800 = Color(0xFF92400E);
  static const Color yellow900 = Color(0xFF78350F);

  static const Color warning = yellow500;
  static const Color warningLight = yellow50;
  static const Color warningDark = yellow700;

  // ============================================
  // SEMANTIC COLORS
  // ============================================
  static const Color background = neutral0;
  static const Color surface = neutral0;
  static const Color surfaceVariant = neutral50;
  static const Color onBackground = neutral900;
  static const Color onSurface = neutral900;
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color textTertiary = neutral500;
  static const Color textDisabled = neutral400;
  static const Color divider = neutral200;
  static const Color border = neutral300;
  static const Color borderLight = neutral200;

  // ============================================
  // CATEGORY TAG COLORS
  // ============================================
  static const Color compassionTag = coral500;
  static const Color compassionTagBg = coral50;
  static const Color teamworkTag = blue500;
  static const Color teamworkTagBg = blue50;
  static const Color excellenceTag = teal500;
  static const Color excellenceTagBg = teal50;
  static const Color leadershipTag = gold500;
  static const Color leadershipTagBg = gold50;
  static const Color reliabilityTag = navy500;
  static const Color reliabilityTagBg = navy50;
}
