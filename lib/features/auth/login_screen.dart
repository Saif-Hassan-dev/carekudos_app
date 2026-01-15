import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Trim and validate inputs
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    print('═══════════════════════════════════');
    print('LOGIN ATTEMPT');
    print('Email entered: "$email"');
    print('Email length: ${email.length}');
    print('Password entered: "$password"');
    print('Password length: ${password.length}');
    print('═══════════════════════════════════');

    if (email.isEmpty || password.isEmpty) {
      print('Empty fields detected');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Calling Firebase signInWithEmailAndPassword...');

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Login successful!');
      print('User ID: ${credential.user?.uid}');
      print('User Email: ${credential.user?.email}');

      if (mounted) {
        context.go('/feed');
      }
    } on FirebaseAuthException catch (e) {
      print('═══════════════════════════════════');
      print('FIREBASE AUTH ERROR');
      print('Error Code: ${e.code}');
      print('Error Message: ${e.message}');
      print('═══════════════════════════════════');

      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password';
      } else {
        message = 'Error: ${e.code}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('═══════════════════════════════════');
      print('UNEXPECTED ERROR');
      print('Error: $e');
      print('═══════════════════════════════════');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              const Text(
                'Welcome Back!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: true,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text('Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
