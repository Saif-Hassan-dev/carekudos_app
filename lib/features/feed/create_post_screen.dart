import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/gdpr_checker.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/custom_button.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  String _selectedCategory = 'Teamwork';
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Add validation at the start
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
      final userDoc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      await FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .add({
            'authorId': user.uid,
            'authorName': '${userDoc['firstName']} ${userDoc['lastName']}',
            'content': _contentController.text,
            'category': _selectedCategory,
            'stars': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'pending', // For manager approval if needed
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
      appBar: AppBar(
        title: const Text('Share Achievement'),
        actions: [
          CustomButton(
            text: 'Post',
            onPressed: _submitPost,
            isLoading: _isSubmitting,
            isFullWidth: false,
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What made a difference today?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 8,
              maxLength: AppConstants.maxPostLength,
              decoration: InputDecoration(
                hintText: 'Share your achievement...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _getBorderColor(), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _getBorderColor(), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildGdprIndicator(),
            if (_gdprStatus == GdprStatus.unsafe) ...[
              const SizedBox(height: 8),
              _buildGdprSuggestions(),
            ],
            const SizedBox(height: 24),
            const Text(
              'Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                return ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (_gdprStatus) {
      case GdprStatus.safe:
        return Colors.green;
      case GdprStatus.warning:
        return Colors.orange;
      case GdprStatus.unsafe:
        return Colors.red;
    }
  }

  Widget _buildGdprIndicator() {
    IconData icon;
    Color color;
    String message;

    switch (_gdprStatus) {
      case GdprStatus.safe:
        icon = Icons.check_circle;
        color = Colors.green;
        message = '🟢 GDPR-safe - ready to post';
        break;
      case GdprStatus.warning:
        icon = Icons.warning;
        color = Colors.orange;
        message = '🟡 ' + _gdprIssues.join(', ');
        break;
      case GdprStatus.unsafe:
        icon = Icons.error;
        color = Colors.red;
        message = '🔴 Contains personal data:\n• ' + _gdprIssues.join('\n• ');
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color.withOpacity(0.8)),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Suggestions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text('• $s'),
            ),
          ),
        ],
      ),
    );
  }
}
