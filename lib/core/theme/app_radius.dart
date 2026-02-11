import 'package:flutter/material.dart';

/// App border radius constants from Figma design system
abstract class AppRadius {
  // ============================================
  // RADIUS VALUES
  // ============================================
  static const double sm = 4.0;
  static const double md = 6.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
  static const double xxl = 16.0;
  static const double pill = 9999.0;
  static const double circle = 9999.0;

  // ============================================
  // BORDER RADIUS HELPERS
  // ============================================
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));

  static const BorderRadius topLg = BorderRadius.only(
    topLeft: Radius.circular(lg),
    topRight: Radius.circular(lg),
  );
  static const BorderRadius topXl = BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );
  static const BorderRadius topXxl = BorderRadius.only(
    topLeft: Radius.circular(xxl),
    topRight: Radius.circular(xxl),
  );

  static const BorderRadius bottomLg = BorderRadius.only(
    bottomLeft: Radius.circular(lg),
    bottomRight: Radius.circular(lg),
  );

  // ============================================
  // SHAPE HELPERS
  // ============================================
  static const RoundedRectangleBorder shapeSm = RoundedRectangleBorder(
    borderRadius: allSm,
  );
  static const RoundedRectangleBorder shapeMd = RoundedRectangleBorder(
    borderRadius: allMd,
  );
  static const RoundedRectangleBorder shapeLg = RoundedRectangleBorder(
    borderRadius: allLg,
  );
  static const RoundedRectangleBorder shapeXl = RoundedRectangleBorder(
    borderRadius: allXl,
  );
  static const RoundedRectangleBorder shapeXxl = RoundedRectangleBorder(
    borderRadius: allXxl,
  );
  static const StadiumBorder shapePill = StadiumBorder();
  static const CircleBorder shapeCircle = CircleBorder();
}
