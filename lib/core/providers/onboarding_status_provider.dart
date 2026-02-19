import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

// Provider to check if onboarding has been completed
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  return StorageService.hasCompletedOnboarding();
});

// Provider to mark onboarding as complete
final onboardingCompletionProvider = Provider<OnboardingCompletion>((ref) {
  return OnboardingCompletion();
});

class OnboardingCompletion {
  Future<void> markComplete() async {
    await StorageService.setOnboardingComplete(true);
  }

  Future<void> reset() async {
    await StorageService.setOnboardingComplete(false);
  }
}
