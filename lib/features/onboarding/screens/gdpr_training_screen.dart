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
      'question': 'Should you avoid sharing a patient\'s name in a recognition post?',
      'correctAnswer': true,
      'correctMessage': 'Correct! Under GDPR (Article 5), patient names are personal data. Sharing them without explicit consent breaches data protection law. Always use anonymous language like "a resident" instead.',
      'incorrectMessage': 'That\'s not right. Patient names are classified as personal data under GDPR (Article 5). Sharing them in any post without explicit consent is a data protection breach. Use "a resident" or "a service user" instead.',
    },
    {
      'question': 'Can you mention room numbers when recognising care?',
      'correctAnswer': false,
      'correctMessage': 'Correct! Room numbers are indirect identifiers under GDPR — they can be combined with other information to identify a specific individual. For example, "the resident in Room 12" narrows identity. Avoid any location-specific details in posts.',
      'incorrectMessage': 'That\'s not right. Room numbers can indirectly identify individuals under GDPR (Recital 26). For example, colleagues may know who occupies Room 12. Even indirect identifiers must be protected. Keep posts location-free.',
    },
    {
      'question': 'Is it acceptable to say "A resident enjoyed the activity"?',
      'correctAnswer': true,
      'correctMessage': 'Correct! Using anonymous, non-identifying language like "a resident" is GDPR-compliant. This protects individual privacy while still allowing meaningful recognition of good care.',
      'incorrectMessage': 'Actually, this phrasing is safe! "A resident" is generic and non-identifying, making it fully GDPR-compliant. You don\'t need to avoid mentioning residents entirely — just avoid details that could identify them.',
    },
    {
      'question': 'Is it okay to share a colleague\'s medical condition in a post praising their dedication?',
      'correctAnswer': false,
      'correctMessage': 'Correct! Health data is classified as "special category data" under GDPR (Article 9). It requires explicit consent to process or share. Even well-intentioned posts must never reveal someone\'s medical information.',
      'incorrectMessage': 'That\'s not right. Health information is "special category data" under GDPR (Article 9) and has the highest level of protection. Sharing it without explicit consent — even in a positive context — is a serious data breach.',
    },
    {
      'question': 'Can you post a photo of a care home resident without their written consent?',
      'correctAnswer': false,
      'correctMessage': 'Correct! Photographs of identifiable individuals are personal data under GDPR. You must obtain clear, informed, written consent before sharing any images. This applies even if the photo is used positively.',
      'incorrectMessage': 'That\'s not right. Photos are personal data under GDPR. Sharing identifiable images without written, informed consent is a breach — regardless of intent. Always obtain documented consent before taking or posting photos.',
    },
  ];

  Future<void> _completeTrainingAndContinue() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await FirebaseService.completeGdprTraining(userId);
      } catch (e) {
        debugPrint('Error completing GDPR training: $e');
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
    final canContinue = _showFeedback; // Allow continue after any answer (learning-focused)

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
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

                      // Feedback message
                      if (_showFeedback)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _isCorrect
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isCorrect
                                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                                  : const Color(0xFFE53935).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _isCorrect ? Icons.check_circle : Icons.info_outline,
                                color: _isCorrect
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFE53935),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _isCorrect
                                      ? (currentQuestion['correctMessage'] as String)
                                      : (currentQuestion['incorrectMessage'] as String),
                                  style: AppTypography.bodyB4.copyWith(
                                    color: _isCorrect
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFC62828),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 20),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Continue button – full width, pinned at bottom
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: canContinue ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canContinue
                        ? const Color(0xFF0A2C6B)
                        : const Color(0xFFF2F2F7),
                    foregroundColor: canContinue
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
                          color: canContinue
                              ? Colors.white
                              : const Color(0xFFBDBDBD),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: canContinue
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
