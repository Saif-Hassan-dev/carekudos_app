import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/gdpr_explanation_screen.dart';
import 'screens/gdpr_training_screen.dart';

/// Standalone GDPR training flow shown after registration.
/// Contains the GDPR explanation intro and the training quiz.
class GdprTrainingFlow extends StatefulWidget {
  const GdprTrainingFlow({super.key});

  @override
  State<GdprTrainingFlow> createState() => _GdprTrainingFlowState();
}

class _GdprTrainingFlowState extends State<GdprTrainingFlow> {
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

  void _onTrainingComplete() {
    // GDPR training screen already saves completion to Firestore.
    // Navigate to feed.
    if (mounted) context.go('/feed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          GdprExplanationScreen(onNext: _nextPage),
          GdprTrainingScreen(onNext: _onTrainingComplete),
        ],
      ),
    );
  }
}
