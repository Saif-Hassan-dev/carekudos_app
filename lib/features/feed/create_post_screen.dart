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
import '../../core/services/storage_service.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  String _selectedCategory = 'Teamwork';
  String? _selectedCareValue;
  String _selectedVisibility = 'team';
  GdprStatus _gdprStatus = GdprStatus.warning;
  List<String> _gdprIssues = [];
  bool _isSubmitting = false;
  bool _hasDraft = false;

  final _categories = const [
    'Teamwork',
    'Above & Beyond',
    'Reliability',
    'Compassion',
    'Leadership',
  ];

  final _careValues = const [
    'Compassion',
    'Teamwork',
    'Excellence',
  ];

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onTextChanged);
    _checkForDraft();
  }

  void _checkForDraft() {
    setState(() {
      _hasDraft = StorageService.hasDraft();
    });
  }

  Future<void> _loadDraft() async {
    final draft = StorageService.getDraft();
    if (draft != null) {
      setState(() {
        _contentController.text = draft['content'] ?? '';
        _selectedCategory = draft['category'] ?? 'Teamwork';
        _selectedVisibility = draft['visibility'] ?? 'team';
        _hasDraft = false;
      });
      if (mounted) {
        context.showSnackBar('📝 Draft restored');
      }
    }
  }

  Future<void> _discardDraft() async {
    await StorageService.clearDraft();
    setState(() => _hasDraft = false);
    if (mounted) {
      context.showSnackBar('🗑️ Draft discarded');
    }
  }

  Future<void> _saveDraft() async {
    if (_contentController.text.trim().isEmpty) {
      context.showErrorSnackBar('Nothing to save');
      return;
    }
    await StorageService.saveDraft(
      content: _contentController.text,
      category: _selectedCategory,
      visibility: _selectedVisibility,
    );
    setState(() => _hasDraft = true);
    if (mounted) {
      context.showSnackBar('💾 Draft saved');
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final result = GdprChecker.check(_contentController.text);
    setState(() {
      _gdprStatus = result.status;
      _gdprIssues = result.issues;
    });
  }

  bool get _canPost =>
      _contentController.text.trim().length >= AppConstants.minPostLength &&
      _gdprStatus != GdprStatus.unsafe;

  Future<void> _submitPost() async {
    final user = ref.read(currentUserProvider);
    final userProfile = ref.read(userProfileProvider).value;

    if (user == null || userProfile == null) {
      context.showErrorSnackBar('User profile not loaded');
      return;
    }

    final validationError =
        Validators.validatePostContent(_contentController.text);
    if (validationError != null) {
      context.showErrorSnackBar(validationError);
      return;
    }

    if (_gdprStatus == GdprStatus.unsafe) {
      context.showErrorSnackBar('Please fix GDPR issues before posting');
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
        'authorRole': userProfile.role,
        'content': _contentController.text,
        'category': _selectedCategory,
        'careValue': _selectedCareValue,
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

      await StorageService.clearDraft();

      if (mounted) {
        setState(() => _hasDraft = false);
        context.pop(true);
      }
    } catch (e) {
      context.showErrorSnackBar(ErrorHandler.getGenericErrorMessage(e));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _contentController.text.length;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBackButton();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          size: 20, color: Color(0xFF1A1A2E)),
                      onPressed: _handleBackButton,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Create a Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Saved draft banner ──
                      if (_hasDraft)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    const Color(0xFF0A2C6B).withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.drafts,
                                  color: Color(0xFF0A2C6B), size: 20),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'You have a saved draft',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0A2C6B),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _loadDraft,
                                child: const Text(
                                  'Restore',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0A2C6B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _discardDraft,
                                child: const Text(
                                  'Discard',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Text area ──
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E5EA),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _contentController,
                          maxLines: 5,
                          maxLength: AppConstants.maxPostLength,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A1A2E),
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText:
                                'Describe the care you want to recognise...',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFC7C7CC),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Character counter ──
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$charCount / ${AppConstants.minPostLength} minimum',
                          style: TextStyle(
                            fontSize: 12,
                            color: charCount >= AppConstants.minPostLength
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFFB0B0B0),
                          ),
                        ),
                      ),

                      // ── GDPR Indicator ──
                      if (_gdprStatus == GdprStatus.safe &&
                          _contentController.text.trim().length >= AppConstants.minPostLength) ...[
                        const SizedBox(height: 12),
                        _buildContentSafeBadge(),
                      ],
                      if (_gdprStatus == GdprStatus.warning &&
                          _contentController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildGdprWarning(),
                      ],
                      if (_gdprStatus == GdprStatus.unsafe) ...[
                        const SizedBox(height: 12),
                        _buildGdprIndicator(),
                      ],

                      const SizedBox(height: 28),

                      // ── Category ──
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0A2C6B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0A2C6B)
                                      : const Color(0xFFE5E5EA),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF3C3C43),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),

                      // ── Care Value (optional) ──
                      RichText(
                        text: const TextSpan(
                          text: 'Care Value',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                          children: [
                            TextSpan(
                              text: '  (optional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF8E8E93),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _careValues.map((value) {
                          final isSelected = _selectedCareValue == value;
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (_selectedCareValue == value) {
                                _selectedCareValue = null;
                              } else {
                                _selectedCareValue = value;
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0A2C6B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0A2C6B)
                                      : const Color(0xFFE5E5EA),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _careValueIcon(value),
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF8E8E93),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF3C3C43),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 28),

                      // ── Visibility ──
                      const Text(
                        'Visibility',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildVisibilityChip('Team', 'team'),
                          _buildVisibilityChip('Organisation', 'organization'),
                          _buildVisibilityChip('Private', 'private'),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ── Post Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _canPost && !_isSubmitting
                              ? _submitPost
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A2C6B),
                            disabledBackgroundColor: const Color(0xFFE5E5EA),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xFFC7C7CC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Post',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityChip(String label, String value) {
    final isSelected = _selectedVisibility == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedVisibility = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A2C6B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF0A2C6B) : const Color(0xFFE5E5EA),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF3C3C43),
          ),
        ),
      ),
    );
  }

  IconData _careValueIcon(String value) {
    switch (value) {
      case 'Compassion':
        return Icons.favorite_outline;
      case 'Teamwork':
        return Icons.groups_outlined;
      case 'Excellence':
        return Icons.settings_outlined;
      default:
        return Icons.label_outline;
    }
  }

  Widget _buildGdprWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF9A825), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Content may contain sensitive info',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF57F17),
                  ),
                ),
                if (_gdprIssues.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _gdprIssues.join(', '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSafeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF81C784)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          const Text(
            'Content looks safe',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGdprIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Contains personal data:\n• ${_gdprIssues.join('\n• ')}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackButton() async {
    if (_contentController.text.trim().isNotEmpty && !_hasDraft) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save Draft?'),
          content:
              const Text('Would you like to save your progress as a draft?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (shouldSave == true) {
        await _saveDraft();
      }
    }
    if (mounted) {
      context.pop();
    }
  }
}
