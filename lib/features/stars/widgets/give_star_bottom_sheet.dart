import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/cards.dart';

/// Bottom sheet for giving a star to a colleague
class GiveStarBottomSheet extends StatefulWidget {
  final String? recipientId;
  final String? recipientName;
  final String? recipientAvatarUrl;
  final Function(int stars, String category, String message)? onSubmit;

  const GiveStarBottomSheet({
    super.key,
    this.recipientId,
    this.recipientName,
    this.recipientAvatarUrl,
    this.onSubmit,
  });

  /// Shows the give star bottom sheet
  static Future<void> show({
    required BuildContext context,
    String? recipientId,
    String? recipientName,
    String? recipientAvatarUrl,
    Function(int stars, String category, String message)? onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GiveStarBottomSheet(
        recipientId: recipientId,
        recipientName: recipientName,
        recipientAvatarUrl: recipientAvatarUrl,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<GiveStarBottomSheet> createState() => _GiveStarBottomSheetState();
}

class _GiveStarBottomSheetState extends State<GiveStarBottomSheet> {
  int _starCount = 1;
  String _selectedCategory = 'Compassion';
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  final _categories = [
    'Compassion',
    'Teamwork',
    'Excellence',
    'Leadership',
    'Reliability',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a message')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      widget.onSubmit?.call(
        _starCount,
        _selectedCategory,
        _messageController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: AppSpacing.all24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral300,
                      borderRadius: AppRadius.allPill,
                    ),
                  ),
                ),
                AppSpacing.verticalGap20,

                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Give a Star',
                        style: AppTypography.headingH4,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                AppSpacing.verticalGap8,
                Text(
                  'Recognize your colleague for their great work',
                  style: AppTypography.bodyB3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.verticalGap24,

                // Recipient (if provided)
                if (widget.recipientName != null) ...[
                  Text(
                    'Recipient',
                    style: AppTypography.bodyB4.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSpacing.verticalGap8,
                  Container(
                    padding: AppSpacing.all12,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.allLg,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: widget.recipientAvatarUrl != null
                              ? NetworkImage(widget.recipientAvatarUrl!)
                              : null,
                          backgroundColor: AppColors.primary,
                          child: widget.recipientAvatarUrl == null
                              ? Text(
                                  widget.recipientName![0].toUpperCase(),
                                  style: AppTypography.bodyB3.copyWith(
                                    color: AppColors.neutral0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        AppSpacing.horizontalGap12,
                        Expanded(
                          child: Text(
                            widget.recipientName!,
                            style: AppTypography.bodyB3.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalGap24,
                ],

                // Star count
                Text(
                  'How many stars?',
                  style: AppTypography.bodyB4.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.verticalGap12,
                StarRatingInput(
                  rating: _starCount,
                  maxRating: 5,
                  onRatingChanged: (rating) => setState(() => _starCount = rating),
                  size: 48,
                ),
                AppSpacing.verticalGap4,
                Center(
                  child: Text(
                    '$_starCount ${_starCount == 1 ? 'star' : 'stars'}',
                    style: AppTypography.bodyB4.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppSpacing.verticalGap24,

                // Category selection
                Text(
                  'Category',
                  style: AppTypography.bodyB4.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.verticalGap12,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return AppChip(
                      label: category,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedCategory = category),
                      selectedColor: AppColors.neutral0,
                      selectedBgColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                AppSpacing.verticalGap24,

                // Message
                Text(
                  'Message',
                  style: AppTypography.bodyB4.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.verticalGap8,
                AppTextField(
                  controller: _messageController,
                  hintText: 'Share what made their work exceptional...',
                  maxLines: 4,
                  maxLength: 280,
                  showCounter: true,
                ),
                AppSpacing.verticalGap32,

                // Submit button
                AppButton.primary(
                  text: 'Give Star${_starCount > 1 ? 's' : ''}',
                  onPressed: _submit,
                  isLoading: _isSubmitting,
                  isFullWidth: true,
                  leadingIcon: Icons.star,
                ),
                AppSpacing.verticalGap16,
              ],
            ),
          );
        },
      ),
    );
  }
}
