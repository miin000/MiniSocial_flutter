// lib/screens/group/group_posts_screen.dart

import 'package:flutter/material.dart';

class GroupPostsScreen extends StatefulWidget {
  final String groupId;

  const GroupPostsScreen({super.key, required this.groupId});

  @override
  State<GroupPostsScreen> createState() => _GroupPostsScreenState();
}

class _GroupPostsScreenState extends State<GroupPostsScreen> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchGroupPosts();
  }

  Future<void> _fetchGroupPosts() async {
    setState(() => _isLoading = true);
    // TODO: Fetch posts from API using GroupProvider
    // final result = await groupProvider.getGroupPosts(widget.groupId);
    // setState(() {
    //   _posts = result['posts'] ?? [];
    //   _isLoading = false;
    // });
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có bài viết nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy đăng bài viết đầu tiên cho nhóm',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to create post
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng đăng bài sắp có'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Đăng bài'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchGroupPosts,
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _buildPostCard(context, post);
        },
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade200,
                  child: Text(
                    (post['authorName'] ?? 'U')[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['authorName'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        post['createdAt'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post['content'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.thumb_up, 'Thích'),
                _buildActionButton(Icons.comment, 'Bình luận'),
                _buildActionButton(Icons.share, 'Chia sẻ'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
