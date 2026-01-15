import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  String _selectedCategory = 'Teamwork';
  GdprStatus _gdprStatus = GdprStatus.empty;
  List<String> _gdprIssues = [];
  bool _isSubmitting = false;

  final categories = [
    'Teamwork',
    'Above & Beyond',
    'Communication',
    'Compassion',
    'Clinical Excellence',
    'Problem Solving',
  ];

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
    final text = _contentController.text;
    final issues = <String>[];

    if (text.isEmpty) {
      setState(() {
        _gdprStatus = GdprStatus.empty;
        _gdprIssues = [];
      });
      return;
    }

    // Basic GDPR checks
    final namePattern = RegExp(
      r'\b(Mr|Mrs|Miss|Ms|Dr)\.?\s+[A-Z][a-z]+',
      caseSensitive: false,
    );
    if (namePattern.hasMatch(text)) {
      issues.add('Contains names (Mr/Mrs/Miss + name)');
    }

    final roomPattern = RegExp(r'\b(room|bed)\s+\d+', caseSensitive: false);
    if (roomPattern.hasMatch(text)) {
      issues.add('Contains room/bed numbers');
    }

    final fullNamePattern = RegExp(r'\b[A-Z][a-z]+\s+[A-Z][a-z]+\b');
    if (fullNamePattern.hasMatch(text)) {
      issues.add('May contain full names');
    }

    // Determine status
    if (issues.isEmpty && text.length >= 50) {
      setState(() {
        _gdprStatus = GdprStatus.safe;
        _gdprIssues = [];
      });
    } else if (issues.isNotEmpty) {
      setState(() {
        _gdprStatus = GdprStatus.unsafe;
        _gdprIssues = issues;
      });
    } else {
      setState(() {
        _gdprStatus = GdprStatus.warning;
        _gdprIssues = ['Minimum 50 characters required'];
      });
    }
  }

  Future<void> _submitPost() async {
    if (_gdprStatus != GdprStatus.safe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix GDPR issues first')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': user.uid,
        'authorName': '${userDoc['firstName']} ${userDoc['lastName']}',
        'content': _contentController.text,
        'category': _selectedCategory,
        'stars': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // For manager approval if needed
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Post created successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
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
              maxLength: 500,
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
      case GdprStatus.empty:
        return Colors.grey;
    }
  }

  Widget _buildGdprIndicator() {
    IconData icon;
    Color color;
    String message;
    Color textColor;

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
      case GdprStatus.empty:
        icon = Icons.info;
        color = Colors.grey;
        message = 'Start typing to check GDPR compliance';
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
}

enum GdprStatus { empty, safe, warning, unsafe }
