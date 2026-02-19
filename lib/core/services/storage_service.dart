import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }

  // Onboarding
  static Future<bool> setOnboardingComplete(bool value) async {
    return await prefs.setBool(AppConstants.onboardingCompleteKey, value);
  }

  static bool hasCompletedOnboarding() {
    return prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
  }

  // Feed Tutorial
  static Future<bool> setFeedTutorialSeen(bool value) async {
    return await prefs.setBool(AppConstants.feedTutorialSeenKey, value);
  }

  static bool hasFeedTutorialSeen() {
    return prefs.getBool(AppConstants.feedTutorialSeenKey) ?? false;
  }

  // Clear all data
  static Future<bool> clearAll() async {
    return await prefs.clear();
  }
}
