import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../features/settings/gdpr_guidelines_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/manager/select_core_values_screen.dart';
import '../features/manager/screens/audit_log_screen.dart';
import '../features/training/training_library_screen.dart';
import '../features/admin/admin_login_screen.dart';
import '../core/auth/auth_provider.dart';
import '../core/auth/permissions_provider.dart';
import '../core/services/storage_service.dart';
import '../core/utils/constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref.watch(authStateProvider.stream);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authStateStream),
    redirect: (context, state) async {
      // Don't redirect away from splash
      if (state.matchedLocation == '/splash') return null;

      // Admin routes bypass regular app auth flow
      if (state.matchedLocation.startsWith('/admin')) return null;

      // Use FirebaseAuth directly — avoids StreamProvider race condition
      // where authStateProvider hasn't processed the new event yet
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final hasSeenOnboarding = StorageService.hasCompletedOnboarding();

      // ── PUBLIC ROUTES (no auth required) ──
      const publicRoutes = {'/login', '/welcome', '/onboarding', '/forgot-password'};

      if (isLoggedIn) {
        // Mark device as "has seen onboarding" so logout goes to /login, not /welcome
        if (!hasSeenOnboarding) {
          StorageService.setOnboardingComplete(true);
        }

        // Try cached provider first, fall back to direct Firestore read
        var profile = ref.read(userProfileProvider).valueOrNull;
        if (profile == null) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection(AppConstants.usersCollection)
                .doc(user.uid)
                .get();
            if (doc.exists) {
              profile = UserProfile.fromFirestore(doc);
            }
          } catch (e) {
            debugPrint('[Router] Error reading profile directly: $e');
          }
        }
        final hasProfile = profile != null && profile.firstName.isNotEmpty;

        // Step 1: No profile → force onboarding
        if (!hasProfile && state.matchedLocation != '/onboarding') {
          return '/onboarding';
        }

        // Step 2: Profile exists but GDPR training not done → force quiz
        if (hasProfile && !profile.gdprTrainingCompleted &&
            state.matchedLocation != '/gdpr-training') {
          return '/gdpr-training';
        }

        // Step 3: Manager with GDPR done but core values not set → force setup
        if (hasProfile && profile.gdprTrainingCompleted &&
            profile.isManager && !profile.coreValuesSetupComplete &&
            state.matchedLocation != '/select-core-values') {
          return '/select-core-values';
        }

        // Step 4: Fully onboarded — redirect away from auth/setup screens
        final isFullyOnboarded = hasProfile &&
            profile.gdprTrainingCompleted &&
            (!profile.isManager || profile.coreValuesSetupComplete);
        final isOnAuthScreen =
            publicRoutes.contains(state.matchedLocation) ||
            state.matchedLocation == '/gdpr-training' ||
            state.matchedLocation == '/select-core-values';

        if (isFullyOnboarded && isOnAuthScreen) {
          return profile.isManager ? '/manager-dashboard' : '/feed';
        }
      } else {
        // ── USER IS NOT LOGGED IN ──
        // If on a public route, allow it (but redirect /welcome→/login for returning users)
        if (publicRoutes.contains(state.matchedLocation)) {
          if (state.matchedLocation == '/welcome' && hasSeenOnboarding) {
            return '/login';
          }
          return null;
        }

        // Any other route is protected → redirect to login or welcome
        return hasSeenOnboarding ? '/login' : '/welcome';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          onComplete: () {
            // Use FirebaseAuth directly — provider may still be loading
            final user = FirebaseAuth.instance.currentUser;
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
            var profile = ref.read(userProfileProvider).valueOrNull;
            if (profile == null) {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final doc = await FirebaseFirestore.instance
                    .collection(AppConstants.usersCollection)
                    .doc(user.uid)
                    .get();
                if (doc.exists) {
                  profile = UserProfile.fromFirestore(doc);
                }
              }
            }
            if (profile != null && profile.isManager) {
              return '/manager-dashboard';
            }
          } catch (e) {
            debugPrint('[Router] Error checking manager role: $e');
          }
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
      GoRoute(
        path: '/gdpr-guidelines',
        builder: (context, state) => const GdprGuidelinesScreen(),
      ),
      GoRoute(
        path: '/audit-log',
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        path: '/training',
        builder: (context, state) => const TrainingLibraryScreen(),
      ),
      // ── Admin Web Dashboard Routes ──
      GoRoute(
        path: '/admin',
        redirect: (context, state) {
          if (state.matchedLocation == '/admin') return '/admin/login';
          return null;
        },
        builder: (context, state) => const AdminLoginScreen(),
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => const AdminLoginScreen(),
          ),
          GoRoute(
            path: 'dashboard',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Admin Dashboard — Coming Soon')),
            ),
          ),
        ],
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
