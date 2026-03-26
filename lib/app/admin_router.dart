import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/admin/admin_login_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/web_manager_dashboard_screen.dart';
import '../features/landing/landing_page.dart';
import '../core/auth/auth_provider.dart';
import '../core/auth/permissions_provider.dart';
import '../core/utils/constants.dart';
import 'router.dart' show GoRouterRefreshStream;

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref.watch(authStateProvider.stream);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authStateStream),
    redirect: (context, state) async {
      // Use FirebaseAuth directly to avoid StreamProvider race condition
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;

      // Public routes — no auth needed
      if (loc == '/') return null;

      final isOnLogin = loc == '/admin/login';

      // Not logged in → allow login page, redirect others to login
      if (!isLoggedIn && !isOnLogin) return '/admin/login';

      // Helper: get profile from cache or direct Firestore read
      Future<UserProfile?> getProfile() async {
        var profile = ref.read(userProfileProvider).valueOrNull;
        if (profile == null && user != null) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection(AppConstants.usersCollection)
                .doc(user.uid)
                .get();
            if (doc.exists) profile = UserProfile.fromFirestore(doc);
          } catch (e) {
            debugPrint('[AdminRouter] Error reading profile: $e');
          }
        }
        return profile;
      }

      // Logged in and on login → redirect to correct dashboard
      if (isLoggedIn && isOnLogin) {
        final profile = await getProfile();
        if (profile == null) return null;
        if (profile.role == 'admin') return '/admin/dashboard';
        if (profile.role == 'manager') return '/admin/manager';
        return null;
      }

      // Protect /admin/dashboard — admin only
      if (loc.startsWith('/admin/dashboard')) {
        final profile = await getProfile();
        if (profile == null || profile.role != 'admin') return '/admin/login';
      }

      // Protect /admin/manager — manager (or admin) only
      if (loc.startsWith('/admin/manager')) {
        final profile = await getProfile();
        if (profile == null ||
            (profile.role != 'manager' && profile.role != 'admin')) {
          return '/admin/login';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/manager',
        builder: (context, state) => const WebManagerDashboardScreen(),
      ),
    ],
  );
});
