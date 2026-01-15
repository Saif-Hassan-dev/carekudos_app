import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Hero Image
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.favorite, size: 80, color: Colors.blue),
              ),

              const SizedBox(height: 40),

              // Welcome Text
              const Text(
                'Welcome to CareKudos',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              const Text(
                'Recognizing care excellence,\nprotecting privacy',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // Register Button
              ElevatedButton(
                onPressed: () => context.go('/onboarding'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 16),

              // Login Button
              OutlinedButton(
                onPressed: () => context.go('/login'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Colors.blue, width: 2),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
