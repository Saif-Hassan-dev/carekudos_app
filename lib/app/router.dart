import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/welcome_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/feed/feed_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/welcome',

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    // If logged in and trying to access auth screens, redirect to feed
    if (isLoggedIn &&
        (state.matchedLocation == '/welcome' ||
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/onboarding')) {
      return '/feed';
    }

    return null; // No redirect
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
  ],
);
