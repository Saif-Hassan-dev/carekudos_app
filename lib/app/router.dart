import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/welcome_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/gdpr_training_flow.dart';
import '../features/splash/splash_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/feed/create_post_screen.dart';
import '../features/manager/manager_dashboard_screen.dart';
import '../features/post/post_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/user_public_profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/account_settings_screen.dart';
import '../features/settings/privacy_gdpr_screen.dart';
import '../features/settings/settings_notifications_screen.dart';
import '../features/settings/help_support_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/manager/select_core_values_screen.dart';
import '../core/auth/auth_provider.dart';
import '../core/auth/permissions_provider.dart';
import '../core/services/storage_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref.watch(authStateProvider.stream);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authStateStream),
    redirect: (context, state) async {
      // Don't redirect away from splash
      if (state.matchedLocation == '/splash') return null;

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

        // Profile exists but GDPR training not completed — force quiz
        if (hasProfile && !(profile!.gdprTrainingCompleted) &&
            state.matchedLocation != '/gdpr-training') {
          return '/gdpr-training';
        }

        // Manager with GDPR done but core values not set up — force values setup
        if (hasProfile && profile!.gdprTrainingCompleted &&
            profile.isManager && !profile.coreValuesSetupComplete &&
            state.matchedLocation != '/select-core-values') {
          return '/select-core-values';
        }

        // Fully onboarded — redirect away from auth/onboarding screens
        if (hasProfile && profile!.gdprTrainingCompleted &&
            (!profile.isManager || profile.coreValuesSetupComplete) &&
            (state.matchedLocation == '/welcome' ||
                state.matchedLocation == '/login' ||
                state.matchedLocation == '/onboarding' ||
                state.matchedLocation == '/gdpr-training' ||
                state.matchedLocation == '/select-core-values')) {
          return profile.isManager ? '/manager-dashboard' : '/feed';
        }
      } else {
        // User is NOT logged in
        // If they haven't completed onboarding, show welcome screen
        if (!hasSeenOnboarding && state.matchedLocation != '/welcome' && state.matchedLocation != '/onboarding' && state.matchedLocation != '/forgot-password') {
          return '/welcome';
        }
        
        // If they've completed onboarding but accessing welcome, redirect to login
        // Allow /onboarding access so users can register a new account
        if (hasSeenOnboarding && state.matchedLocation == '/welcome') {
          return '/login';
        }
        
        // If they're trying to access protected routes without login
        // (excluding public routes: login, welcome, onboarding, forgot-password)
        if (state.matchedLocation != '/login' &&
            state.matchedLocation != '/welcome' &&
            state.matchedLocation != '/onboarding' &&
            state.matchedLocation != '/forgot-password' &&
            (state.matchedLocation == '/feed' ||
            state.matchedLocation == '/manager-dashboard' ||
            state.matchedLocation == '/profile' ||
            state.matchedLocation == '/create-post' ||
            state.matchedLocation == '/notifications' ||
            state.matchedLocation.startsWith('/post/') ||
            state.matchedLocation.startsWith('/user-profile/') ||
            state.matchedLocation.startsWith('/settings') ||
            state.matchedLocation == '/gdpr-training' ||
            state.matchedLocation == '/select-core-values')) {
          return hasSeenOnboarding ? '/login' : '/welcome';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          onComplete: () {
            final user = ref.read(authStateProvider).value;
            final hasSeenOnboarding = StorageService.hasCompletedOnboarding();
            if (user != null) {
              context.go('/feed');
            } else if (hasSeenOnboarding) {
              context.go('/login');
            } else {
              context.go('/welcome');
            }
          },
        ),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/gdpr-training',
        builder: (context, state) => const GdprTrainingFlow(),
      ),
      GoRoute(
        path: '/select-core-values',
        builder: (context, state) => const SelectCoreValuesScreen(),
      ),
      GoRoute(
        path: '/feed',
        redirect: (context, state) async {
          // If the user is a manager, redirect to manager dashboard
          try {
            final profile = await ref.read(userProfileProvider.future);
            if (profile != null && profile.isManager) {
              return '/manager-dashboard';
            }
          } catch (_) {}
          return null;
        },
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/manager-dashboard',
        builder: (context, state) => const ManagerDashboardScreen(),
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/post/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/user-profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserPublicProfileScreen(userId: userId);
        },
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
