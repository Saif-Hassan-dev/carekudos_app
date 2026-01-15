import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final String? role;
  final String? email;
  final String? password;
  final String? orgCode;
  final String? firstName;
  final String? lastName;
  final String? jobTitle;

  OnboardingState({
    this.role,
    this.email,
    this.password,
    this.orgCode,
    this.firstName,
    this.lastName,
    this.jobTitle,
  });

  // Add getter for selectedRole
  String? get selectedRole => role;

  OnboardingState copyWith({
    String? role,
    String? email,
    String? password,
    String? orgCode,
    String? firstName,
    String? lastName,
    String? jobTitle,
  }) {
    return OnboardingState(
      role: role ?? this.role,
      email: email ?? this.email,
      password: password ?? this.password,
      orgCode: orgCode ?? this.orgCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      jobTitle: jobTitle ?? this.jobTitle,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  void setRole(String role) {
    state = state.copyWith(role: role);
  }

  void setRegistration({
    required String email,
    required String password,
    required String orgCode,
  }) {
    state = state.copyWith(email: email, password: password, orgCode: orgCode);
  }

  void setProfile({
    required String firstName,
    required String lastName,
    required String jobTitle,
  }) {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      jobTitle: jobTitle,
    );
  }

  // Add reset method
  void reset() {
    state = OnboardingState();
  }

  void clear() {
    state = OnboardingState();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
      (ref) => OnboardingNotifier(),
    );
