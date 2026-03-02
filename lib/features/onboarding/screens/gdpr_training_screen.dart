import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/theme.dart';
import '../../../core/services/firebase_service.dart';

class GdprTrainingScreen extends StatefulWidget {
  final VoidCallback onNext;

  const GdprTrainingScreen({super.key, required this.onNext});

  @override
  State<GdprTrainingScreen> createState() => _GdprTrainingScreenState();
}

class _GdprTrainingScreenState extends State<GdprTrainingScreen> {
  int _currentQuestionIndex = 0;
  bool? _selectedAnswer;
  bool _showFeedback = false;
  bool _isCorrect = false;

  final List<Map<String, dynamic>> quizQuestions = [
    {
      'question': 'Is it recommended not to share the patient\'s name in an recognition post?',
      'correctAnswer': true, // Yes, it IS recommended NOT to share
      'correctMessage': 'Correct. Patient names must never be shared.',
      'incorrectMessage': 'Incorrect. Please try again.',
    },
    {
      'question': 'Can you mention room numbers when recognising care?',
      'correctAnswer': false, // No, you cannot
      'correctMessage': 'Correct. Room numbers are personal identifiers.',
      'incorrectMessage': 'Incorrect. Please try again.',
    },
    {
      'question': 'Is it acceptable to say "A resident enjoyed the activity"?',
      'correctAnswer': true, // Yes, this is acceptable
      'correctMessage': 'Correct. Generic terms protect privacy.',
      'incorrectMessage': 'Incorrect. Please try again.',
    },
  ];

  Future<void> _completeTrainingAndContinue() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await FirebaseService.recordGdprConsent(userId);
      } catch (e) {
        debugPrint('Error recording GDPR consent: $e');
      }
    }
    widget.onNext();
  }

  void _answerQuestion(bool answer) {
    if (_showFeedback) return;

    final currentQuestion = quizQuestions[_currentQuestionIndex];
    final correctAnswer = currentQuestion['correctAnswer'] as bool;
    final isCorrect = answer == correctAnswer;

    setState(() {
      _selectedAnswer = answer;
      _showFeedback = true;
      _isCorrect = isCorrect;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showFeedback = false;
        _isCorrect = false;
      });
    } else {
      // Quiz completed
      _completeTrainingAndContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = quizQuestions[_currentQuestionIndex];
    final questionText = currentQuestion['question'] as String;
    final isAnsweredCorrectly = _showFeedback && _isCorrect;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Question counter + timer icon row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${quizQuestions.length}',
                    style: AppTypography.bodyB3.copyWith(
                      color: const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/icons/CareKudos (16)/vuesax/twotone/timer.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.timer_outlined,
                      size: 28,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Question text
              Text(
                questionText,
                textAlign: TextAlign.center,
                style: AppTypography.headingH2.copyWith(
                  color: const Color(0xFF1A1A2E),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 48),

              // Yes / No answer buttons – tall, equal width
              Row(
                children: [
                  Expanded(
                    child: _buildAnswerButton(label: 'Yes', value: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAnswerButton(label: 'No', value: false),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Feedback message (or empty placeholder to keep layout stable)
              SizedBox(
                height: 40,
                child: _showFeedback
                    ? Text(
                        _isCorrect
                            ? (currentQuestion['correctMessage'] as String)
                            : (currentQuestion['incorrectMessage'] as String),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyB4.copyWith(
                          color: _isCorrect
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE53935),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Push continue button to the bottom
              const Spacer(),

              // Continue button – full width
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isAnsweredCorrectly ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAnsweredCorrectly
                        ? const Color(0xFF0A2C6B)
                        : const Color(0xFFF2F2F7),
                    foregroundColor: isAnsweredCorrectly
                        ? Colors.white
                        : const Color(0xFFBDBDBD),
                    disabledBackgroundColor: const Color(0xFFF2F2F7),
                    disabledForegroundColor: const Color(0xFFBDBDBD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: AppTypography.actionA1.copyWith(
                          color: isAnsweredCorrectly
                              ? Colors.white
                              : const Color(0xFFBDBDBD),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: isAnsweredCorrectly
                            ? Colors.white
                            : const Color(0xFFBDBDBD),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required bool value,
  }) {
    final bool isSelected = _showFeedback && _selectedAnswer == value;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isSelected) {
      if (_isCorrect) {
        // Correct – green
        backgroundColor = const Color(0xFF4CAF50);
        borderColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
      } else {
        // Incorrect – red
        backgroundColor = const Color(0xFFE53935);
        borderColor = const Color(0xFFE53935);
        textColor = Colors.white;
      }
    } else {
      // Default / unselected
      backgroundColor = Colors.white;
      borderColor = const Color(0xFFE0E0E0);
      textColor = const Color(0xFF212121);
    }

    return GestureDetector(
      onTap: _showFeedback ? null : () => _answerQuestion(value),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.headingH4.copyWith(color: textColor),
        ),
      ),
    );
  }
}
