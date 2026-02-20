import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              const Spacer(flex: 1),
              
              // Hero Image
              Container(
                width: double.infinity,
                height: 380,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/heroplace.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: AppColors.neutral100,
                      child: const Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
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
                    const TextSpan(text: 'Shining a Light on\n'),
                    const TextSpan(
                      text: 'Exceptional',
                      style: TextStyle(
                        color: Color(0xFFD4AF37), // Gold
                      ),
                    ),
                    const TextSpan(text: ' Care'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Recognise great care, boost team morale, and demonstrate your professional standards with confidence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.neutral600,
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/onboarding'),
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
                        'Get Started',
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
