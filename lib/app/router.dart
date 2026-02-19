import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/welcome_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/feed/create_post_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/account_settings_screen.dart';
import '../features/settings/privacy_gdpr_screen.dart';
import '../features/settings/settings_notifications_screen.dart';
import '../features/settings/help_support_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../core/auth/auth_provider.dart';
import '../core/auth/permissions_provider.dart';
import '../core/services/storage_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref.watch(authStateProvider.stream);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: GoRouterRefreshStream(authStateStream),
    redirect: (context, state) async {
      final user = ref.read(authStateProvider).value;
      final isLoggedIn = user != null;
      final hasSeenOnboarding = StorageService.hasCompletedOnboarding();

      // If user is logged in
      if (isLoggedIn) {
        // Check if profile exists in Firestore
        final profile = await ref.read(userProfileProvider.future);
        final hasProfile = profile != null && profile.firstName.isNotEmpty;

        if (!hasProfile && state.matchedLocation != '/onboarding') {
          return '/onboarding'; // Force onboarding completion
        }

        if (hasProfile &&
            (state.matchedLocation == '/welcome' ||
                state.matchedLocation == '/login')) {
          return '/feed';
        }
      } else {
        // User is NOT logged in
        // If they haven't completed onboarding, show welcome screen
        if (!hasSeenOnboarding && state.matchedLocation != '/welcome' && state.matchedLocation != '/onboarding') {
          return '/welcome';
        }
        
        // If they've completed onboarding but accessing welcome/onboarding, redirect to login
        if (hasSeenOnboarding && (state.matchedLocation == '/welcome' || state.matchedLocation == '/onboarding')) {
          return '/login';
        }
        
        // If they're trying to access protected routes without login
        if (state.matchedLocation == '/feed' || 
            state.matchedLocation == '/profile' ||
            state.matchedLocation.startsWith('/settings')) {
          return hasSeenOnboarding ? '/login' : '/welcome';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/account',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacyGdprScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const SettingsNotificationsScreen(),
      ),
      GoRoute(
        path: '/settings/help',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});

// Helper class to refresh router when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
