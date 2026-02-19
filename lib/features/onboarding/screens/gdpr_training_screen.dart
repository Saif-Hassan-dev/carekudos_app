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
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Progress text
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${quizQuestions.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Question text
                    Text(
                      questionText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A2C6B),
                        height: 1.3,
                      ),
                    ),
                    const Spacer(flex: 1),
                    // Yes/No buttons
                    Column(
                      children: [
                        _buildAnswerButton(
                          label: 'Yes',
                          value: true,
                        ),
                        const SizedBox(height: 16),
                        _buildAnswerButton(
                          label: 'No',
                          value: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Feedback message
                    if (_showFeedback) ...[
                      Text(
                        _isCorrect
                            ? (currentQuestion['correctMessage'] as String)
                            : (currentQuestion['incorrectMessage'] as String),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      const SizedBox(height: 56), // Spacer when no feedback
                    ],
                    // Continue button - always visible but disabled when not correct
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_showFeedback && _isCorrect) ? _nextQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_showFeedback && _isCorrect)
                              ? const Color(0xFF0A2C6B)
                              : const Color(0xFFE0E0E0),
                          foregroundColor: (_showFeedback && _isCorrect)
                              ? Colors.white
                              : const Color(0xFFBDBDBD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFFE0E0E0),
                          disabledForegroundColor: const Color(0xFFBDBDBD),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: (_showFeedback && _isCorrect)
                                    ? Colors.white
                                    : const Color(0xFFBDBDBD),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: (_showFeedback && _isCorrect)
                                  ? Colors.white
                                  : const Color(0xFFBDBDBD),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
            // Bottom indicator bar
            _buildBottomIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required bool value,
  }) {
    bool isSelected = _showFeedback && _selectedAnswer == value;
    
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    if (isSelected) {
      if (_isCorrect) {
        backgroundColor = const Color(0xFF4CAF50); // Green
        borderColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
      } else {
        backgroundColor = const Color(0xFFE53935); // Red
        borderColor = const Color(0xFFE53935);
        textColor = Colors.white;
      }
    } else {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFFE0E0E0);
      textColor = const Color(0xFF212121);
    }
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _showFeedback ? null : () => _answerQuestion(value),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
          elevation: 0,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: textColor,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomIndicator() {
    return Container(
      height: 8,
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          quizQuestions.length,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentQuestionIndex
                  ? const Color(0xFF0A2C6B)
                  : const Color(0xFFE0E0E0),
            ),
          ),
        ),
      ),
    );
  }
}
