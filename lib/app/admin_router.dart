import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/admin/admin_login_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/web_manager_dashboard_screen.dart';
import '../core/auth/auth_provider.dart';
import '../core/auth/permissions_provider.dart';
import 'router.dart' show GoRouterRefreshStream;

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref.watch(authStateProvider.stream);

  return GoRouter(
    initialLocation: '/admin/login',
    refreshListenable: GoRouterRefreshStream(authStateStream),
    redirect: (context, state) async {
      final user = ref.read(authStateProvider).value;
      final isLoggedIn = user != null;
      final isOnLogin = state.matchedLocation == '/admin/login';

      // Not logged in → always go to login
      if (!isLoggedIn && !isOnLogin) return '/admin/login';

      // Logged in and on login → redirect to correct dashboard
      if (isLoggedIn && isOnLogin) {
        final profile = await ref.read(userProfileProvider.future);
        if (profile == null) return null;
        if (profile.role == 'admin') return '/admin/dashboard';
        if (profile.role == 'manager') return '/admin/manager';
        // Any other role — sign them out, stay on login
        return null;
      }

      // Protect /admin/dashboard — admin only
      if (state.matchedLocation.startsWith('/admin/dashboard')) {
        final profile = await ref.read(userProfileProvider.future);
        if (profile == null || profile.role != 'admin') return '/admin/login';
      }

      // Protect /admin/manager — manager (or admin) only
      if (state.matchedLocation.startsWith('/admin/manager')) {
        final profile = await ref.read(userProfileProvider.future);
        if (profile == null ||
            (profile.role != 'manager' && profile.role != 'admin')) {
          return '/admin/login';
        }
      }

      return null;
    },
    routes: [
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
