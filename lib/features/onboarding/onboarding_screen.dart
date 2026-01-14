import 'package:flutter/material.dart';
import 'screens/value_proposition_screen.dart';
import 'screens/gdpr_explanation_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/gdpr_training_screen.dart';
import 'screens/profile_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// diff screens in Onboarding!
class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

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

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _currentPage = page),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ValuePropositionScreen(onNext: _nextPage),
          GdprExplanationScreen(onNext: _nextPage),
          RoleSelectionScreen(onNext: _nextPage),
          RegistrationScreen(onNext: _nextPage),
          GdprTrainingScreen(onNext: _nextPage),
          ProfileSetupScreen(onNext: _nextPage),
        ],
      ),
    );
  }
}
