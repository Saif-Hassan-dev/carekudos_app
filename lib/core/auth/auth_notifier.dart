import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../utils/error_handler.dart';

/// Authentication state
class AuthState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AuthState({this.isLoading = false, this.error, this.successMessage});

  AuthState copyWith({bool? isLoading, String? error, String? successMessage}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  // Helper to reset state
  AuthState reset() => const AuthState();
}

/// Authentication notifier - handles all auth actions
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Login successful',
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getAuthErrorMessage(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  /// Register new user with full profile
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? jobTitle,
    String? orgCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Create Firebase Auth account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Create Firestore profile
      await FirebaseService.createUserProfile(
        userId: credential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        jobTitle: jobTitle,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Registration successful',
      );
      return true;
    } on FirebaseAuthException catch (e) {
      // If Firestore fails but auth succeeds, delete the auth account
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (deleteError) {
        debugPrint('Warning: Could not delete auth account after Firestore failure: $deleteError');
      }

      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getAuthErrorMessage(e),
      );
      return false;
    } catch (e) {
      // Cleanup on error
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (deleteError) {
        debugPrint('Warning: Could not delete auth account during error cleanup: $deleteError');
      }

      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getGenericErrorMessage(e),
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await FirebaseAuth.instance.signOut();
      state = const AuthState(); // Reset to initial state
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Logout failed');
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset email sent',
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getAuthErrorMessage(e),
      );
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }

  /// Reset entire state
  void resetState() {
    state = const AuthState();
  }
}

/// Provider for auth notifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
