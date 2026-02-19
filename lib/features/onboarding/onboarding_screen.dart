import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/gdpr_explanation_screen.dart';
import 'screens/gdpr_training_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/registration_screen.dart';
import '../../core/services/storage_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

// Onboarding flow: Quiz Intro → Quiz → Role Selection → Create Account
class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as complete
    await StorageService.setOnboardingComplete(true);
    // Navigate to feed after onboarding is complete
    if (mounted) context.go('/feed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          GdprExplanationScreen(onNext: _nextPage), // Quiz Intro
          GdprTrainingScreen(onNext: _nextPage),     // Quiz
          RoleSelectionScreen(onNext: _nextPage),    // Role Selection
          RegistrationScreen(onNext: _completeOnboarding), // Create Account (all info + profile)
        ],
      ),
    );
  }
}
