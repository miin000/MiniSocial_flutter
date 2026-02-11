// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import 'create_post_screen.dart';
import 'post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
 _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    await postProvider.loadPosts(refresh: true, userId: userId);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (!postProvider.isLoading && postProvider.hasMore) {
        postProvider.loadPosts(userId: userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PostProvider>(
      builder: (context, authProvider, postProvider, child) {
        final user = authProvider.user;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _loadPosts,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header with user info
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3b82f6), Color(0xFF8b5cf6)],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: user?.avatar != null
                                ? ClipOval(
                                    child: Image.network(
                                      user!.avatar!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Text(
                                          user.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color: Color(0xFF3b82f6),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Text(
                                    user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Color(0xFF3b82f6),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Xin chào, ${user?.fullName ?? 'Người dùng'}!',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Bạn đang nghĩ gì?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Create post button
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatePostScreen(),
                            ),
                          ).then((_) => _loadPosts());
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF3b82f6),
                                child: user?.avatar != null
                                    ? ClipOval(
                                        child: Image.network(
                                          user!.avatar!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Text(
                                              user.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                              style: const TextStyle(color: Colors.white),
                                            );
                                          },
                                        ),
                                      )
                                    : Text(
                                        user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Bạn đang nghĩ gì?',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              const Icon(Icons.image, color: Color(0xFF10b981)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Posts list
                if (postProvider.isLoading && postProvider.posts.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (postProvider.posts.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Chưa có bài viết nào.\nHãy tạo bài viết đầu tiên!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < postProvider.posts.length) {
                            return PostCard(post: postProvider.posts[index]);
                          } else if (postProvider.hasMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        childCount: postProvider.posts.length + 
                            (postProvider.hasMore ? 1 : 0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();

                Fluttertoast.showToast(
                  msg: 'Đã đăng xuất!',
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                );

                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}
