import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/error_handler.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Shouldn't happen due to router redirect, but safety check
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/welcome');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          // User email display
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                user.email?.split('@')[0] ?? 'User',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.showSnackBar('Profile coming soon!');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/welcome');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.postsCollection)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading feed...'),
                ],
              ),
            );
          }

          // Show error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Error Loading Feed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      ErrorHandler.getGenericErrorMessage(snapshot.error),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          // Show posts
          return Column(
            children: [
              // Post count indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.blue[50],
                child: Text(
                  '${snapshot.data!.docs.length} posts in feed',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return PostCard(
                      postId: doc.id,
                      authorName: data['authorName'] ?? 'Anonymous',
                      content: data['content'] ?? '',
                      category: data['category'] ?? 'General',
                      stars: data['stars'] ?? 0,
                      createdAt: data['createdAt'] != null
                          ? (data['createdAt'] as Timestamp).toDate()
                          : DateTime.now(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-post'),
        icon: const Icon(Icons.add),
        label: const Text('Share Achievement'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 120, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              'Your feed is empty',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Share your first achievement!\nBe specific and GDPR-safe.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/create-post'),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Post'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _createSamplePost(context),
              child: const Text('Create Sample Post (Test)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSamplePost(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      //creating sample post

      await FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .add({
            'authorId': user.uid,
            'authorName': 'Test User',
            'content':
                'A team member showed exceptional compassion today by spending extra time with a resident who was feeling anxious.',
            'category': 'Compassion',
            'stars': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'approved',
          });

      if (context.mounted) {
        context.showSnackBar('✅ Sample post created!');
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(ErrorHandler.getGenericErrorMessage(e));
      }
    }
  }
}

// PostCard widget (same as before)
class PostCard extends StatelessWidget {
  final String postId;
  final String authorName;
  final String content;
  final String category;
  final int stars;
  final DateTime createdAt;

  const PostCard({
    super.key,
    required this.postId,
    required this.authorName,
    required this.content,
    required this.category,
    required this.stars,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(Formatters.getInitials(authorName))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        Formatters.timeAgo(createdAt), // ← Direct call to util
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(category), backgroundColor: Colors.blue[100]),
              ],
            ),
            const SizedBox(height: 12),
            Text(content),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.star_border),
                  onPressed: () => _giveStar(context),
                ),
                Text('${Formatters.formatStarCount(stars)} stars'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.comment_outlined),
                  label: const Text('Comment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _giveStar(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final starDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('starredBy')
          .doc(user.uid)
          .get();

      if (starDoc.exists) {
        if (context.mounted) {
          context.showSnackBar('You already starred this post');
        }
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(postId);
        final starRef = postRef.collection('starredBy').doc(user.uid);

        transaction.update(postRef, {'stars': FieldValue.increment(1)});
        transaction.set(starRef, {'timestamp': FieldValue.serverTimestamp()});
      });

      if (context.mounted) {
        context.showSnackBar(' Star given!');
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar(ErrorHandler.getGenericErrorMessage(e));
      }
    }
  }
}
