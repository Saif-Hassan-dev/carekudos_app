import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class GdprExplanationScreen extends StatefulWidget {
  final VoidCallback onNext;

  const GdprExplanationScreen({super.key, required this.onNext});

  @override
  State<GdprExplanationScreen> createState() => _GdprExplanationScreenState();
}

class _GdprExplanationScreenState extends State<GdprExplanationScreen> {
  bool _anonymized = false;
  bool _canContinue = false;
  Timer? _loopTimer;

  @override
  void initState() {
    super.initState();
    //time befiore the user can continue

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _canContinue = true);
    });

    // loop the transition every 2.4s (1.2s each state)

    _loopTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      if (!mounted) return;
      setState(() => _anonymized = !_anonymized);
    });
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Q&A Icon
              SizedBox(
                width: 200,
                height: 200,
                child: Image.asset(
                  'assets/images/qna icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(Icons.quiz, size: 80, color: Colors.grey),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title with colored word
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: Color(0xFF0A2C6B), // Navy
                  ),
                  children: [
                    const TextSpan(text: 'GDPR '),
                    TextSpan(
                      text: 'Training',
                      style: TextStyle(
                        color: const Color(0xFFD4AF37), // Gold
                      ),
                    ),
                    const TextSpan(text: ' Check'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Complete the GDPR quiz to protect patient privacy and continue recognising colleagues on CareKudos safely platform.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.neutral600,
                ),
              ),
              
              const Spacer(flex: 3),
              
              // Take The Quiz Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2C6B), // Navy
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Take The Quiz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Page Indicator
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
