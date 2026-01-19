class AppConstants {
  static const String appName = 'CareKudos';
  static const String appVersion = '1.0.0';

  static const int minPostLength = 50;
  static const int maxPostLength = 500;
  static const int maxPostsPerDay = 10;

  static const int maxStarsPerDay = 20;
  static const int managerStarMultiplier = 3;
  static const int familyStarMultiplier = 5;
  static const int maxFamilyStarsPerMonth = 2;

  static const Map<String, int> starTiers = {
    'Rising Star': 10,
    'Quality Champion': 25,
    'Exceptional Practitioner': 50,
    'Care Expert': 100,
    'Sector Influencer': 200,
  };

  // Categories
  static const List<String> postCategories = [
    'Teamwork',
    'Above & Beyond',
    'Communication',
    'Compassion',
    'Clinical Excellence',
    'Problem Solving',
  ];

  // Notification Times
  static const Duration morningReminderTime = Duration(hours: 7, minutes: 30);
  static const Duration afternoonReminderTime = Duration(hours: 16, minutes: 0);

  //tutorial
  static const String feedTutorialSeenKey = 'feed_tutorial_seen';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String orgsCollection = 'organizations';
  static const String notificationsCollection = 'notifications';

  // Local Storage Keys
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String lastPostDateKey = 'last_post_date';
  static const String streakCountKey = 'streak_count';
}
