import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../home/post_card.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _loadUserPosts(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  void _loadUserPosts({bool refresh = true}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId == null) {
      print('DEBUG: Không có userId, không load posts');
      return;
    }

    print('DEBUG: Load posts cho userId: $userId, refresh: $refresh');
    postProvider.loadPosts(refresh: refresh, userId: userId);
  }

  void _onScroll() {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    if (_scrollController.position.extentAfter < 300 &&
        !postProvider.isLoading &&
        postProvider.hasMore) {
      _loadUserPosts(refresh: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final postsCount = postProvider.posts.length;
    final likesCount = postProvider.posts.fold<int>(0, (sum, post) => sum + post.likesCount);

    final friendsCount = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Cài đặt',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authProvider.checkAuthStatus();
          _loadUserPosts(refresh: true);
        },
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (user.cover != null && user.cover!.isNotEmpty)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(image: NetworkImage(user.cover!), fit: BoxFit.cover),
                      ),
                    )
                  else
                    Container(height: 200, color: Colors.blue),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                          child: user.avatar == null ? Text(user.fullName?[0] ?? 'U') : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.fullName ?? user.username ?? 'Người dùng',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.bio!,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),

                        if (user.job != null && user.job!.isNotEmpty)
                          _buildInfoRow(Icons.work, user.job!),
                        if (user.location != null && user.location!.isNotEmpty)
                          _buildInfoRow(Icons.location_on, user.location!),
                        if (user.createdAt != null)
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Tham gia tháng ${user.createdAt!.month} năm ${user.createdAt!.year}',
                          ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn('$friendsCount', 'Bạn bè'),
                            _buildStatColumn('$postsCount', 'Bài viết'),
                            _buildStatColumn('$likesCount', 'Lượt thích'),
                          ],
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isReloading
                                ? null
                                : () async {
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              );

                              if (result == true && mounted) {
                                setState(() => _isReloading = true);
                                try {
                                  await authProvider.checkAuthStatus();

                                  _loadUserPosts(refresh: true);

                                  Fluttertoast.showToast(
                                    msg: 'Đã cập nhật hồ sơ!',
                                    backgroundColor: Colors.green,
                                  );
                                } catch (e) {
                                  Fluttertoast.showToast(
                                    msg: 'Lỗi reload hồ sơ: $e',
                                    backgroundColor: Colors.red,
                                  );
                                } finally {
                                  if (mounted) setState(() => _isReloading = false);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1877F2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              // Disable button khi đang reload
                              elevation: _isReloading ? 0 : 2,
                            ),
                            child: _isReloading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Text('Chỉnh sửa hồ sơ'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          body: postProvider.isLoading && postProvider.posts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : postProvider.posts.isEmpty
              ? const Center(child: Text('Bạn chưa có bài viết nào'))
              : ListView.builder(
            itemCount: postProvider.posts.length,
            itemBuilder: (context, index) => PostCard(post: postProvider.posts[index]),
          ),
        ),
      ),
    );
  }

  // Giữ nguyên 2 hàm _buildInfoRow và _buildStatColumn như cũ
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String number, String label) {
    return Column(
      children: [
        Text(number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}