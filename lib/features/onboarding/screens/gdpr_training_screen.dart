import 'package:flutter/material.dart';

class GdprTrainingScreen extends StatefulWidget {
  final VoidCallback onNext;

  const GdprTrainingScreen({super.key, required this.onNext});

  @override
  State<GdprTrainingScreen> createState() => _GdprTrainingScreenState();
}

class _GdprTrainingScreenState extends State<GdprTrainingScreen> {
  int _currentSlide = 0;
  int _currentQuizIndex = 0;
  int _correctAnswers = 0;
  bool _quizCompleted = false;

  // Regular training slides
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
  ];

  // Quiz questions - add as many as you want!
  final List<Map<String, dynamic>> quizQuestions = [
    {
      'question': '"Sarah enjoyed her afternoon activity"',
      'isGdprSafe': false, // Sarah is a name = personal data
      'explanation': '"Sarah" is a personal identifier.',
    },
    {
      'question': '"The resident in the blue room had visitors"',
      'isGdprSafe': false, // Room description can identify someone
      'explanation': '"Blue room" could identify a specific person.',
    },
    {
      'question': '"A lady enjoyed the music therapy session"',
      'isGdprSafe': true, // Generic, no identifiers
      'explanation': 'No personal identifiers - this is GDPR safe!',
    },
    {
      'question': '"Mr. Johnson\'s medication was administered"',
      'isGdprSafe': false, // Name = personal data
      'explanation': '"Mr. Johnson" is a personal identifier.',
    },
    {
      'question': '"Someone had a great day at the facility"',
      'isGdprSafe': true, // Generic and safe
      'explanation': 'No identifiers - perfectly safe!',
    },
  ];

  bool get _isOnQuizSection => _currentSlide >= slides.length;
  bool get _allQuizzesCompleted => _currentQuizIndex >= quizQuestions.length;

  void _nextSlide() {
    if (_currentSlide < slides.length - 1) {
      setState(() => _currentSlide++);
    } else if (_currentSlide == slides.length - 1) {
      // Move to quiz section
      setState(() => _currentSlide++);
    }
  }

  void _previousSlide() {
    if (_currentSlide > 0) {
      setState(() => _currentSlide--);
    }
  }

  void _answerQuiz(bool userAnsweredSafe) {
    final currentQuestion = quizQuestions[_currentQuizIndex];
    final correctAnswer = currentQuestion['isGdprSafe'] as bool;
    final isCorrect = userAnsweredSafe == correctAnswer;

    if (isCorrect) {
      _correctAnswers++;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Correct! ${currentQuestion['explanation']}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Move to next quiz or complete
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _currentQuizIndex++;
          if (_allQuizzesCompleted) {
            _quizCompleted = true;
          }
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Incorrect! ${currentQuestion['explanation']}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      // Retry same question - don't advance
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Title
              Text(
                _isOnQuizSection
                    ? 'Quiz (${_currentQuizIndex + 1}/${quizQuestions.length})'
                    : 'GDPR Training (${_currentSlide + 1}/${slides.length})',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              // Content Card
              if (!_isOnQuizSection)
                _buildSlideCard()
              else if (!_allQuizzesCompleted)
                _buildQuizCard()
              else
                _buildCompletionCard(),

              const SizedBox(height: 40),

              // Navigation Buttons
              if (!_quizCompleted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _currentSlide > 0 && !_isOnQuizSection
                          ? _previousSlide
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                    if (!_isOnQuizSection)
                      ElevatedButton(
                        onPressed: _nextSlide,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: Text(
                          _currentSlide == slides.length - 1
                              ? 'Start Quiz'
                              : 'Next',
                        ),
                      ),
                  ],
                )
              else
                Center(
                  child: ElevatedButton(
                    onPressed: widget.onNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 20,
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            slides[_currentSlide]['title']!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slides[_currentSlide]['content']!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard() {
    final question = quizQuestions[_currentQuizIndex];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: Column(
            children: [
              const Text(
                'Is this GDPR-safe?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                question['question'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Answer Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Not Safe'),
                onPressed: () => _answerQuiz(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('GDPR Safe'),
                onPressed: () => _answerQuiz(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),

        // Score display
        const SizedBox(height: 16),
        Text(
          'Score: $_correctAnswers/${quizQuestions.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCompletionCard() {
    final passedQuiz = _correctAnswers >= quizQuestions.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: passedQuiz ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: passedQuiz ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            passedQuiz ? Icons.check_circle : Icons.error,
            color: passedQuiz ? Colors.green : Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            passedQuiz ? 'Quiz Completed!' : 'Quiz Failed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: passedQuiz ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Final Score: $_correctAnswers/${quizQuestions.length}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            passedQuiz
                ? 'You\'ve successfully completed the GDPR training!'
                : 'Please review the material and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
