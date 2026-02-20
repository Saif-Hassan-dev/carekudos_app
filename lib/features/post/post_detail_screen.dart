import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/formatters.dart';

class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Post Details',
          style: AppTypography.headingH5,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.postsCollection)
            .doc(postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  AppSpacing.verticalGap16,
                  Text(
                    'Error loading post',
                    style: AppTypography.bodyB2.copyWith(color: AppColors.error),
                  ),
                  AppSpacing.verticalGap16,
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.post_add_outlined, size: 48, color: AppColors.textTertiary),
                  AppSpacing.verticalGap16,
                  Text(
                    'Post not found',
                    style: AppTypography.bodyB2.copyWith(color: AppColors.textTertiary),
                  ),
                  AppSpacing.verticalGap16,
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final authorName = data['authorName'] ?? 'Unknown';
          final authorRole = data['authorRole'] ?? 'Care Worker';
          final content = data['content'] ?? '';
          final category = data['category'] ?? 'Teamwork';
          final stars = data['stars'] ?? 0;
          final createdAt = data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now();

          return SingleChildScrollView(
            padding: AppSpacing.all16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Card
                Container(
                  width: double.infinity,
                  padding: AppSpacing.all16,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: AppRadius.allLg,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              Formatters.getInitials(authorName),
                              style: AppTypography.bodyB4.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          AppSpacing.horizontalGap12,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  style: AppTypography.bodyB3.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _formatRole(authorRole),
                                  style: AppTypography.captionC2.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalGap16,

                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: AppRadius.allSm,
                        ),
                        child: Text(
                          category,
                          style: AppTypography.captionC2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AppSpacing.verticalGap12,

                      // Content
                      Text(
                        content,
                        style: AppTypography.bodyB2,
                      ),
                      AppSpacing.verticalGap16,

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFB300),
                                size: 20,
                              ),
                              AppSpacing.horizontalGap4,
                              Text(
                                '$stars',
                                style: AppTypography.bodyB3.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            Formatters.timeAgo(createdAt),
                            style: AppTypography.captionC2.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalGap24,

                // Placeholder for future features
                Container(
                  width: double.infinity,
                  padding: AppSpacing.all16,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: AppRadius.allLg,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 48,
                        color: AppColors.textTertiary.withOpacity(0.5),
                      ),
                      AppSpacing.verticalGap8,
                      Text(
                        'Comments coming soon',
                        style: AppTypography.bodyB3.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatRole(String role) {
    return role.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
