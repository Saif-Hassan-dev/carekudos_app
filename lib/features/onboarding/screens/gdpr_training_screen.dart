import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_button.dart';

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
  bool? _lastAnswerCorrect;
  bool _showFeedback = false;

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

  final List<Map<String, dynamic>> quizQuestions = [
    {
      'question': '"Sarah enjoyed her afternoon activity"',
      'isGdprSafe': false,
      'explanation': '"Sarah" is a personal identifier.',
    },
    {
      'question': '"The resident in the blue room had visitors"',
      'isGdprSafe': false,
      'explanation': '"Blue room" could identify a specific person.',
    },
    {
      'question': '"A lady enjoyed the music therapy session"',
      'isGdprSafe': true,
      'explanation': 'No personal identifiers - this is GDPR safe!',
    },
    {
      'question': '"Mr. Johnson\'s medication was administered"',
      'isGdprSafe': false,
      'explanation': '"Mr. Johnson" is a personal identifier.',
    },
    {
      'question': '"Someone had a great day at the facility"',
      'isGdprSafe': true,
      'explanation': 'No identifiers - perfectly safe!',
    },
  ];

  bool get _isOnQuizSection => _currentSlide >= slides.length;
  bool get _allQuizzesCompleted => _currentQuizIndex >= quizQuestions.length;

  void _nextSlide() {
    if (_currentSlide < slides.length - 1) {
      setState(() => _currentSlide++);
    } else if (_currentSlide == slides.length - 1) {
      setState(() => _currentSlide++);
    }
  }

  void _previousSlide() {
    if (_currentSlide > 0) {
      setState(() => _currentSlide--);
    }
  }

  void _answerQuiz(bool userAnsweredSafe) {
    if (_showFeedback) return;

    final currentQuestion = quizQuestions[_currentQuizIndex];
    final correctAnswer = currentQuestion['isGdprSafe'] as bool;
    final isCorrect = userAnsweredSafe == correctAnswer;

    setState(() {
      _showFeedback = true;
      _lastAnswerCorrect = isCorrect;
      if (isCorrect) _correctAnswers++;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showFeedback = false;
        _lastAnswerCorrect = null;
        if (isCorrect) {
          _currentQuizIndex++;
          if (_allQuizzesCompleted) {
            _quizCompleted = true;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.all24,
          child: Column(
            children: [
              AppSpacing.verticalGap20,
              // Progress indicator
              _buildProgressIndicator(),
              AppSpacing.verticalGap24,
              // Title
              Text(
                _isOnQuizSection
                    ? 'GDPR Quiz'
                    : 'GDPR Training',
                style: AppTypography.displayD3,
              ),
              AppSpacing.verticalGap8,
              Text(
                _isOnQuizSection
                    ? 'Question ${_currentQuizIndex + 1} of ${quizQuestions.length}'
                    : 'Step ${_currentSlide + 1} of ${slides.length}',
                style: AppTypography.bodyB3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.verticalGap32,

              // Content
              if (!_isOnQuizSection)
                _buildSlideCard()
              else if (!_allQuizzesCompleted)
                _buildQuizCard()
              else
                _buildCompletionCard(),

              AppSpacing.verticalGap40,

              // Navigation Buttons
              if (!_quizCompleted)
                _buildNavigationButtons()
              else
                AppButton.primary(
                  label: 'Continue',
                  onPressed: widget.onNext,
                  isFullWidth: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalSteps = slides.length + quizQuestions.length;
    final currentStep = _isOnQuizSection
        ? slides.length + _currentQuizIndex
        : _currentSlide;
    final progress = (currentStep + 1) / totalSteps;

    return Column(
      children: [
        ClipRRect(
          borderRadius: AppRadius.allPill,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.neutral200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    if (_isOnQuizSection) return const SizedBox.shrink();

    return Row(
      children: [
        if (_currentSlide > 0)
          Expanded(
            child: AppButton.secondary(
              label: 'Back',
              onPressed: _previousSlide,
            ),
          ),
        if (_currentSlide > 0) AppSpacing.horizontalGap12,
        Expanded(
          child: AppButton.primary(
            label: _currentSlide == slides.length - 1 ? 'Start Quiz' : 'Next',
            onPressed: _nextSlide,
          ),
        ),
      ],
    );
  }

  Widget _buildSlideCard() {
    return Container(
      width: double.infinity,
      padding: AppSpacing.all24,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.allXl,
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: AppSpacing.all16,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.neutral0,
              size: 32,
            ),
          ),
          AppSpacing.verticalGap20,
          Text(
            slides[_currentSlide]['title']!,
            style: AppTypography.headingH4,
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalGap16,
          Text(
            slides[_currentSlide]['content']!,
            style: AppTypography.bodyB3.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
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
        // Question card
        Container(
          width: double.infinity,
          padding: AppSpacing.all24,
          decoration: BoxDecoration(
            color: _showFeedback
                ? (_lastAnswerCorrect == true
                    ? AppColors.successLight
                    : AppColors.errorLight)
                : AppColors.secondaryLight,
            borderRadius: AppRadius.allXl,
            border: Border.all(
              color: _showFeedback
                  ? (_lastAnswerCorrect == true
                      ? AppColors.success
                      : AppColors.error)
                  : AppColors.secondary,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _showFeedback
                    ? (_lastAnswerCorrect == true
                        ? Icons.check_circle
                        : Icons.cancel)
                    : Icons.help_outline,
                color: _showFeedback
                    ? (_lastAnswerCorrect == true
                        ? AppColors.success
                        : AppColors.error)
                    : AppColors.secondary,
                size: 48,
              ),
              AppSpacing.verticalGap16,
              Text(
                _showFeedback
                    ? (_lastAnswerCorrect == true ? 'Correct!' : 'Incorrect')
                    : 'Is this GDPR-safe?',
                style: AppTypography.headingH5.copyWith(
                  color: _showFeedback
                      ? (_lastAnswerCorrect == true
                          ? AppColors.success
                          : AppColors.error)
                      : AppColors.textPrimary,
                ),
              ),
              AppSpacing.verticalGap16,
              Text(
                question['question'] as String,
                style: AppTypography.bodyB2.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (_showFeedback) ...[
                AppSpacing.verticalGap12,
                Text(
                  question['explanation'] as String,
                  style: AppTypography.bodyB4.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        AppSpacing.verticalGap24,

        // Answer buttons
        if (!_showFeedback)
          Row(
            children: [
              Expanded(
                child: QuizActionButton(
                  label: 'Yes',
                  icon: Icons.check,
                  onPressed: () => _answerQuiz(true),
                ),
              ),
              AppSpacing.horizontalGap12,
              Expanded(
                child: QuizActionButton(
                  label: 'No',
                  icon: Icons.close,
                  isSecondary: true,
                  onPressed: () => _answerQuiz(false),
                ),
              ),
            ],
          ),

        AppSpacing.verticalGap16,
        // Score display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: AppRadius.allPill,
          ),
          child: Text(
            'Score: $_correctAnswers / ${quizQuestions.length}',
            style: AppTypography.bodyB4.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionCard() {
    final passedQuiz = _correctAnswers >= quizQuestions.length;

    return Container(
      padding: AppSpacing.all24,
      decoration: BoxDecoration(
        color: passedQuiz ? AppColors.successLight : AppColors.errorLight,
        borderRadius: AppRadius.allXl,
        border: Border.all(
          color: passedQuiz ? AppColors.success : AppColors.error,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: AppSpacing.all16,
            decoration: BoxDecoration(
              color: passedQuiz ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              passedQuiz ? Icons.check : Icons.close,
              color: AppColors.neutral0,
              size: 32,
            ),
          ),
          AppSpacing.verticalGap16,
          Text(
            passedQuiz ? 'Quiz Completed!' : 'Try Again',
            style: AppTypography.headingH3.copyWith(
              color: passedQuiz ? AppColors.success : AppColors.error,
            ),
          ),
          AppSpacing.verticalGap12,
          Text(
            'Final Score: $_correctAnswers / ${quizQuestions.length}',
            style: AppTypography.headingH5,
          ),
          AppSpacing.verticalGap8,
          Text(
            passedQuiz
                ? 'You\'ve successfully completed the GDPR training!'
                : 'Please review the material and try again.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyB3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
