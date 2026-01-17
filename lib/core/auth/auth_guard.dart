import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import 'permissions_provider.dart';

/// Widget that protects routes requiring authentication
class AuthGuard extends ConsumerWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    if (!isLoggedIn) {
      // Redirect to welcome screen if not logged in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/welcome');
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return child;
  }
}

/// Widget that protects routes requiring manager role
class ManagerGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const ManagerGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isManager = ref.watch(isManagerProvider);

    if (!isManager) {
      return fallback ??
          Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: const Center(
              child: Text(
                'This feature is only available to managers',
                textAlign: TextAlign.center,
              ),
            ),
          );
    }

    return child;
  }
}

/// Widget that shows content only for specific roles
class RoleBasedWidget extends ConsumerWidget {
  final Widget child;
  final List<String> allowedRoles;

  const RoleBasedWidget({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);

    if (role == null || !allowedRoles.contains(role)) {
      return const SizedBox.shrink(); // Hide widget
    }

    return child;
  }
}
