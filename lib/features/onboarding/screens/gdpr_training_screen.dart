import 'package:flutter/material.dart';

class GdprTrainingScreen extends StatefulWidget {
  final VoidCallback onNext;

  const GdprTrainingScreen({super.key, required this.onNext});

  @override
  State<GdprTrainingScreen> createState() => _GdprTrainingScreenState();
}

class _GdprTrainingScreenState extends State<GdprTrainingScreen> {
  int _currentSlide = 0;
  bool _quizPassed = false;

  final List<Map<String, String>> slides = [
    {
      'title': 'What is personal data?',
      'content':
          'Any information that can identify a person directly or indirectly.',
    },
    {
      'title': 'Real Examples',
      'content':
          '✓ Good: "A gentleman had great company today"\n✗ Bad: "Mr. Smith had great company"',
    },
    {
      'title': 'More Examples',
      'content':
          '✓ Good: "Their room was beautifully arranged"\n✗ Bad: "Room 12 was beautifully arranged"',
    },
    {
      'title': 'Quiz Time',
      'content': 'Is this GDPR-safe?\n"Sarah enjoyed her afternoon activity"',
    },
  ];

  void _nextSlide() {
    if (_currentSlide < slides.length - 1) {
      setState(() => _currentSlide++);
    }
  }

  void _previousSlide() {
    if (_currentSlide > 0) {
      setState(() => _currentSlide--);
    }
  }

  void _passQuiz() {
    setState(() => _quizPassed = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 20),
            Column(
              children: [
                Text(
                  'GDPR Training (${_currentSlide + 1}/${slides.length})',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        slides[_currentSlide]['title']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        slides[_currentSlide]['content']!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (_currentSlide == slides.length - 1 && !_quizPassed)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('No'),
                          onPressed: _previousSlide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Yes'),
                          onPressed: _passQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentSlide > 0 ? _previousSlide : null,
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: (_currentSlide < slides.length - 1) || _quizPassed
                      ? _quizPassed
                            ? widget.onNext
                            : _nextSlide
                      : null,
                  child: Text(_quizPassed ? 'Continue' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
