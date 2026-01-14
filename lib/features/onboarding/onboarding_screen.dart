import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  state<OnboardingScreen> createState() => _OnboardingScreenState();
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

  @override
  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
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
          GdprExplanationScreen(onNext: _nextPage, onBack: _previousPage),
          RoleSelectionScreen(onNext: _nextPage, onBack: _previousPage),
          RegistrationScreen(onNext: _nextPage, onBack: _previousPage),
          GdprTrainingScreen(onNext: _nextPage, onBack: _previousPage),
          ProfileSetupScreen(
            onFinish: () {
              Navigator.pushReplacementNamed(context, '/feed');
            },
            onBack: _previousPage,
          ),
        ],
      ),
    );
  }
}
