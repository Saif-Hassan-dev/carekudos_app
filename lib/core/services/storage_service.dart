import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'dart:convert';

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

  // Draft Posts
  static Future<bool> saveDraft({
    required String content,
    required String category,
    required String visibility,
  }) async {
    final draftData = {
      'content': content,
      'category': category,
      'visibility': visibility,
      'savedAt': DateTime.now().toIso8601String(),
    };
    return await prefs.setString('post_draft', jsonEncode(draftData));
  }

  static Map<String, String>? getDraft() {
    final draftString = prefs.getString('post_draft');
    if (draftString == null) return null;

    try {
      final Map<String, dynamic> decoded = jsonDecode(draftString);
      return {
        'content': decoded['content'] as String? ?? '',
        'category': decoded['category'] as String? ?? 'Teamwork',
        'visibility': decoded['visibility'] as String? ?? 'team',
        'savedAt': decoded['savedAt'] as String? ?? '',
      };
    } catch (e) {
      return null;
    }
  }

  static Future<bool> clearDraft() async {
    return await prefs.remove('post_draft');
  }

  static bool hasDraft() {
    return prefs.containsKey('post_draft');
  }

  // Clear all data
  static Future<bool> clearAll() async {
    return await prefs.clear();
  }
}
