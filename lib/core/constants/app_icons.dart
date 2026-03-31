/// App Icons - Central icon asset management
/// 
/// This file provides type-safe access to all icon assets in the app.
/// Icons are organized by category for easy reference.
abstract class AppIcons {
  // ============================================
  // ROLES
  // ============================================
  static const String admin = 'assets/icons/carekudos_5/other-icons/admin.png';
  static const String careWorker = 'assets/icons/carekudos_5/other-icons/care-worker.png';
  static const String manager = 'assets/icons/carekudos_5/other-icons/manager.png';

  // ============================================
  // LOCATION & NAVIGATION
  // ============================================
  static const String directDown = 'assets/icons/carekudos_13/direct-down.png';
  static const String directLeft = 'assets/icons/carekudos_13/direct-left.png';
  static const String directRight = 'assets/icons/carekudos_13/direct-right.png';
  static const String directUp = 'assets/icons/carekudos_13/direct-up.png';
  static const String discover = 'assets/icons/carekudos_13/discover.png';
  static const String globalRefresh = 'assets/icons/carekudos_13/global-refresh.png';
  static const String global = 'assets/icons/carekudos_13/global.png';
  static const String gpsSlash = 'assets/icons/carekudos_13/gps-slash.png';
  static const String gps = 'assets/icons/carekudos_13/gps.png';
  static const String locationAdd = 'assets/icons/carekudos_13/location-add.png';
  static const String locationCross = 'assets/icons/carekudos_13/location-cross.png';
  static const String locationMinus = 'assets/icons/carekudos_13/location-minus.png';
  static const String locationSlash = 'assets/icons/carekudos_13/location-slash.png';
  static const String locationTick = 'assets/icons/carekudos_13/location-tick.png';
  static const String location = 'assets/icons/carekudos_13/location.png';
  static const String map = 'assets/icons/carekudos_13/map.png';
  static const String routing2 = 'assets/icons/carekudos_13/routing-2.png';
  static const String routing = 'assets/icons/carekudos_13/routing.png';

  // ============================================
  // DOCUMENTS
  // ============================================
  static const String documentNormal = 'assets/icons/carekudos_15/document-normal.png';

  // ============================================
  // STYLES/UI ELEMENTS
  // ============================================
  // From carekudos_11
  static const String styles11_1 = 'assets/icons/carekudos_11/Styles-1.png';
  static const String styles11_2 = 'assets/icons/carekudos_11/Styles-2.png';
  static const String styles11_3 = 'assets/icons/carekudos_11/Styles-3.png';
  static const String styles11 = 'assets/icons/carekudos_11/Styles.png';

  // From carekudos_12
  static const String styles12_1 = 'assets/icons/carekudos_12/Styles-1.png';
  static const String styles12_2 = 'assets/icons/carekudos_12/Styles-2.png';
  static const String styles12_3 = 'assets/icons/carekudos_12/Styles-3.png';
  static const String styles12 = 'assets/icons/carekudos_12/Styles.png';

  // From carekudos_13
  static const String styles13_1 = 'assets/icons/carekudos_13/Styles-1.png';
  static const String styles13_2 = 'assets/icons/carekudos_13/Styles-2.png';
  static const String styles13_3 = 'assets/icons/carekudos_13/Styles-3.png';
  static const String styles13_4 = 'assets/icons/carekudos_13/Styles-4.png';
  static const String styles13 = 'assets/icons/carekudos_13/Styles.png';

  // From carekudos_14
  static const String styles14_1 = 'assets/icons/carekudos_14/Styles-1.png';
  static const String styles14_2 = 'assets/icons/carekudos_14/Styles-2.png';
  static const String styles14_3 = 'assets/icons/carekudos_14/Styles-3.png';
  static const String styles14 = 'assets/icons/carekudos_14/Styles.png';

  // From carekudos_15
  static const String styles15_1 = 'assets/icons/carekudos_15/Styles-1.png';
  static const String styles15_2 = 'assets/icons/carekudos_15/Styles-2.png';
  static const String styles15_3 = 'assets/icons/carekudos_15/Styles-3.png';
  static const String styles15 = 'assets/icons/carekudos_15/Styles.png';

  // From carekudos_16
  static const String styles16_1 = 'assets/icons/carekudos_16/Styles-1.png';
  static const String styles16_2 = 'assets/icons/carekudos_16/Styles-2.png';
  static const String styles16_3 = 'assets/icons/carekudos_16/Styles-3.png';
  static const String styles16_4 = 'assets/icons/carekudos_16/Styles-4.png';
  static const String styles16 = 'assets/icons/carekudos_16/Styles.png';

  // From carekudos_17
  static const String styles17_1 = 'assets/icons/carekudos_17/Styles-1.png';
  static const String styles17_2 = 'assets/icons/carekudos_17/Styles-2.png';
  static const String styles17_3 = 'assets/icons/carekudos_17/Styles-3.png';
  static const String styles17_4 = 'assets/icons/carekudos_17/Styles-4.png';
  static const String styles17 = 'assets/icons/carekudos_17/Styles.png';

  // From carekudos_18
  static const String bulk = 'assets/icons/carekudos_18/Bulk.png';
  static const String line = 'assets/icons/carekudos_18/Line.png';

  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Get role icon based on role name
  static String getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return admin;
      case 'manager':
        return manager;
      case 'care_worker':
      case 'care worker':
      case 'senior_carer':
      case 'senior carer':
        return careWorker;
      default:
        return careWorker;
    }
  }

  /// Get navigation direction icon
  static String getDirectionIcon(String direction) {
    switch (direction.toLowerCase()) {
      case 'up':
        return directUp;
      case 'down':
        return directDown;
      case 'left':
        return directLeft;
      case 'right':
        return directRight;
      default:
        return discover;
    }
  }
}
