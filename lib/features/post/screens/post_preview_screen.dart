import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PostPreviewScreen extends StatelessWidget {
  final String content;
  final String category;
  final String visibility;
  final bool isAnonymized;
  final Function() onConfirm;

  const PostPreviewScreen({
    super.key,
    required this.content,
    required this.category,
    required this.visibility,
    required this.isAnonymized,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Header
            const Text(
              'This is what others will see:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Preview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Chip(label: Text(category)),
                    const SizedBox(height: 12),

                    // Content
                    Text(content),

                    // Anonymization notice
                    if (isAnonymized)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          '🔒 Some details were anonymized for GDPR',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Visibility info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_getVisibilityIcon(visibility)),
                  const SizedBox(width: 8),
                  Text('Post to: ${_getVisibilityText(visibility)}'),
                ],
              ),
            ),

            const Spacer(),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      context.pop();
                    },
                    child: const Text('Post Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getVisibilityIcon(String visibility) {
    switch (visibility) {
      case 'team':
        return Icons.group;
      case 'organization':
        return Icons.business;
      case 'private':
        return Icons.lock;
      default:
        return Icons.public;
    }
  }

  String _getVisibilityText(String visibility) {
    switch (visibility) {
      case 'team':
        return 'Team Only';
      case 'organization':
        return 'Whole Organization';
      case 'private':
        return 'Private Draft';
      default:
        return 'Public';
    }
  }
}
