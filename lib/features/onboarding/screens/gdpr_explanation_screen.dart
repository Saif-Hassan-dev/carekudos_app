import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/widgets/custom_button.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 40),

            Column(
              children: [
                const Text(
                  'Why we protect privacy',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 0, 36, 243),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                const Text(
                  'We guide you to post safely.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 5000),
                  curve: Curves.easeInOut,
                  width: 500,
                  constraints: const BoxConstraints(
                    minHeight: 100,
                    minWidth: 200,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _anonymized ? Colors.blue[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1200),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: _anonymized
                        ? const Column(
                            key: ValueKey('safe'),
                            children: [
                              Text(
                                'A gentleman enjoyed his walk',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Their room needed extra support',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            key: ValueKey('unsafe'),
                            children: [
                              Text(
                                'Mr. Smith enjoyed his walk',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Room 12 needed extra support',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),

            CustomButton(
              text: 'I Understand',
              onPressed: _canContinue ? widget.onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}
