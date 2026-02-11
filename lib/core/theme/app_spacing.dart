import 'package:flutter/material.dart';

/// App spacing constants from Figma design system
abstract class AppSpacing {
  // ============================================
  // SPACING VALUES
  // ============================================
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;

  // ============================================
  // SEMANTIC ALIASES
  // ============================================
  static const double xs = space4;
  static const double sm = space8;
  static const double smd = space12;
  static const double md = space16;
  static const double lg = space24;
  static const double xl = space32;
  static const double xxl = space40;

  // ============================================
  // EDGE INSETS HELPERS
  // ============================================
  static const EdgeInsets all4 = EdgeInsets.all(space4);
  static const EdgeInsets all8 = EdgeInsets.all(space8);
  static const EdgeInsets all12 = EdgeInsets.all(space12);
  static const EdgeInsets all16 = EdgeInsets.all(space16);
  static const EdgeInsets all20 = EdgeInsets.all(space20);
  static const EdgeInsets all24 = EdgeInsets.all(space24);
  static const EdgeInsets all32 = EdgeInsets.all(space32);

  static const EdgeInsets horizontal4 = EdgeInsets.symmetric(horizontal: space4);
  static const EdgeInsets horizontal8 = EdgeInsets.symmetric(horizontal: space8);
  static const EdgeInsets horizontal12 = EdgeInsets.symmetric(horizontal: space12);
  static const EdgeInsets horizontal16 = EdgeInsets.symmetric(horizontal: space16);
  static const EdgeInsets horizontal20 = EdgeInsets.symmetric(horizontal: space20);
  static const EdgeInsets horizontal24 = EdgeInsets.symmetric(horizontal: space24);

  static const EdgeInsets vertical4 = EdgeInsets.symmetric(vertical: space4);
  static const EdgeInsets vertical8 = EdgeInsets.symmetric(vertical: space8);
  static const EdgeInsets vertical12 = EdgeInsets.symmetric(vertical: space12);
  static const EdgeInsets vertical16 = EdgeInsets.symmetric(vertical: space16);
  static const EdgeInsets vertical20 = EdgeInsets.symmetric(vertical: space20);
  static const EdgeInsets vertical24 = EdgeInsets.symmetric(vertical: space24);

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: space24,
    vertical: space16,
  );

  // ============================================
  // SIZED BOX HELPERS
  // ============================================
  static const SizedBox verticalGap4 = SizedBox(height: space4);
  static const SizedBox verticalGap8 = SizedBox(height: space8);
  static const SizedBox verticalGap12 = SizedBox(height: space12);
  static const SizedBox verticalGap16 = SizedBox(height: space16);
  static const SizedBox verticalGap20 = SizedBox(height: space20);
  static const SizedBox verticalGap24 = SizedBox(height: space24);
  static const SizedBox verticalGap32 = SizedBox(height: space32);
  static const SizedBox verticalGap40 = SizedBox(height: space40);

  static const SizedBox horizontalGap4 = SizedBox(width: space4);
  static const SizedBox horizontalGap8 = SizedBox(width: space8);
  static const SizedBox horizontalGap12 = SizedBox(width: space12);
  static const SizedBox horizontalGap16 = SizedBox(width: space16);
  static const SizedBox horizontalGap20 = SizedBox(width: space20);
  static const SizedBox horizontalGap24 = SizedBox(width: space24);
}
