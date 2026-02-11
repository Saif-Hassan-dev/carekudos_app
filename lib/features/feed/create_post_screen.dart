import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/gdpr_checker.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/permissions_provider.dart';
import '../post/screens/post_preview_screen.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  String _selectedCategory = 'Teamwork';
  String _selectedVisibility = 'team';
  GdprStatus _gdprStatus = GdprStatus.warning;
  List<String> _gdprIssues = [];
  bool _isSubmitting = false;

  final categories = AppConstants.postCategories;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_checkGdpr);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _checkGdpr() {
    final result = GdprChecker.check(_contentController.text);

    setState(() {
      _gdprStatus = result.status;
      _gdprIssues = result.issues;
    });
  }

  Future<void> _submitPost() async {
    final user = ref.read(currentUserProvider);
    final userProfile = ref.read(userProfileProvider).value;

    if (user == null || userProfile == null) {
      context.showErrorSnackBar('User profile not loaded');
      return;
    }

    final validationError = Validators.validatePostContent(
      _contentController.text,
    );
    if (validationError != null) {
      context.showErrorSnackBar(validationError);
      return;
    }

    if (_gdprStatus != GdprStatus.safe) {
      context.showErrorSnackBar('Please fix GDPR issues first');
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final needsApproval = userProfile.postCount < 5;

      await FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .add({
            'authorId': user.uid,
            'authorName': userProfile.fullName,
            'content': _contentController.text,
            'category': _selectedCategory,
            'stars': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'pending',
            'visibility': _selectedVisibility,
            'teamId': userProfile.teamId,
            'organizationId': userProfile.organizationId,
            'isAnonymized': false,
            'approvalStatus': needsApproval ? 'pending' : 'approved',
            'approvedBy': null,
            'approvedAt': null,
            'needsApproval': needsApproval,
          });

      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
            'postCount': FieldValue.increment(1),
            'lastPostDate': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        context.showSnackBar('✅ Post created successfully!');
        context.pop();
      }
    } catch (e) {
      context.showErrorSnackBar(ErrorHandler.getGenericErrorMessage(e));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Share Achievement',
          style: AppTypography.headingH5,
        ),
        actions: [
          Padding(
            padding: AppSpacing.horizontal16,
            child: AppButton.text(
              label: 'Preview',
              onPressed: _gdprStatus == GdprStatus.safe ? _showPreview : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.all16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What made a difference today?',
              style: AppTypography.headingH5,
            ),
            AppSpacing.verticalGap8,
            Text(
              'Share your achievement without using personal identifiers',
              style: AppTypography.bodyB4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.verticalGap20,
            // Content text field
            Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.allLg,
                border: Border.all(
                  color: _getBorderColor(),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                maxLength: AppConstants.maxPostLength,
                style: AppTypography.bodyB2,
                decoration: InputDecoration(
                  hintText: 'Example: A colleague showed exceptional compassion by...',
                  hintStyle: AppTypography.bodyB3.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: AppSpacing.all16,
                  counterStyle: AppTypography.captionC2.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            AppSpacing.verticalGap16,
            _buildGdprIndicator(),
            if (_gdprStatus == GdprStatus.unsafe) ...[
              AppSpacing.verticalGap12,
              _buildGdprSuggestions(),
            ],
            AppSpacing.verticalGap24,
            Text(
              'Category',
              style: AppTypography.bodyB3.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.verticalGap12,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
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
            Text(
              'Visibility',
              style: AppTypography.bodyB3.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.verticalGap12,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _VisibilityChip(
                  label: 'Team',
                  icon: Icons.group_outlined,
                  isSelected: _selectedVisibility == 'team',
                  onTap: () => setState(() => _selectedVisibility = 'team'),
                ),
                _VisibilityChip(
                  label: 'Organization',
                  icon: Icons.business_outlined,
                  isSelected: _selectedVisibility == 'organization',
                  onTap: () => setState(() => _selectedVisibility = 'organization'),
                ),
                _VisibilityChip(
                  label: 'Private',
                  icon: Icons.lock_outline,
                  isSelected: _selectedVisibility == 'private',
                  onTap: () => setState(() => _selectedVisibility = 'private'),
                ),
              ],
            ),
            AppSpacing.verticalGap32,
            AppButton.primary(
              label: 'Post Achievement',
              onPressed: _gdprStatus == GdprStatus.safe ? _submitPost : null,
              isLoading: _isSubmitting,
              isFullWidth: true,
            ),
            AppSpacing.verticalGap16,
          ],
        ),
      ),
    );
  }

  void _showPreview() {
    final validationError = Validators.validatePostContent(
      _contentController.text,
    );
    if (validationError != null) {
      context.showErrorSnackBar(validationError);
      return;
    }

    if (_gdprStatus != GdprStatus.safe) {
      context.showErrorSnackBar('Please fix GDPR issues first');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostPreviewScreen(
          content: _contentController.text,
          category: _selectedCategory,
          visibility: _selectedVisibility,
          isAnonymized: false,
          onConfirm: _submitPost,
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (_gdprStatus) {
      case GdprStatus.safe:
        return AppColors.success;
      case GdprStatus.warning:
        return AppColors.warning;
      case GdprStatus.unsafe:
        return AppColors.error;
    }
  }

  Widget _buildGdprIndicator() {
    IconData icon;
    Color color;
    Color bgColor;
    String message;

    switch (_gdprStatus) {
      case GdprStatus.safe:
        icon = Icons.check_circle;
        color = AppColors.success;
        bgColor = AppColors.successLight;
        message = 'GDPR-safe - ready to post';
        break;
      case GdprStatus.warning:
        icon = Icons.warning_amber_outlined;
        color = AppColors.warning;
        bgColor = AppColors.warningLight;
        message = _gdprIssues.isNotEmpty ? _gdprIssues.join(', ') : 'Start typing...';
        break;
      case GdprStatus.unsafe:
        icon = Icons.error_outline;
        color = AppColors.error;
        bgColor = AppColors.errorLight;
        message = 'Contains personal data:\n• ${_gdprIssues.join('\n• ')}';
        break;
    }

    return Container(
      padding: AppSpacing.all12,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          AppSpacing.horizontalGap12,
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyB4.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGdprSuggestions() {
    final suggestions = GdprChecker.getSuggestions(_contentController.text);

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: AppSpacing.all12,
      decoration: BoxDecoration(
        color: AppColors.tertiaryLight,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: AppColors.tertiary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.tertiary, size: 20),
              AppSpacing.horizontalGap8,
              Text(
                'Suggestions:',
                style: AppTypography.bodyB4.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
          AppSpacing.verticalGap8,
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                '• $s',
                style: AppTypography.bodyB4.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.neutral0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.allLg,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.neutral0 : AppColors.textSecondary,
              ),
              AppSpacing.horizontalGap8,
              Text(
                label,
                style: AppTypography.bodyB4.copyWith(
                  color: isSelected ? AppColors.neutral0 : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
