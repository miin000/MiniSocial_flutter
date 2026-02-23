import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../models/group_post_model.dart';
import '../home/post_card.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import 'group_settings_screen.dart';
import 'create_post_in_group_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  final String currentUserId;

  const GroupDetailScreen({
    Key? key,
    required this.group,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late GroupModel group;
  bool _isLoading = true;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    group = widget.group;

    // Chạy async SAU khi frame đầu build xong → tránh gọi notifyListeners trong build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadGroupData();
    });
  }

  Future<void> _reloadGroupData() async {
    if (!mounted) return;

    final gp = Provider.of<GroupProvider>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      // Chỉ fetch lại nếu chưa join hoặc để sync với server
      // Nếu vừa join (role != null), ta dùng data local từ provider
      if (gp.currentUserRole == null) {
        await gp.fetchGroupDetail(group.id);
      }
      
      await gp.fetchGroupPosts(group.id, refresh: true);

      final currentGroup = gp.currentGroup ?? group;
      final currentUserId = widget.currentUserId.isNotEmpty
          ? widget.currentUserId
          : (Provider.of<AuthProvider>(context, listen: false).user?.id ?? '');

      // Tính isJoined - BỎ currentGroup.isJoined vì backend trả sai
      final joined = gp.currentUserRole != null ||
          gp.groupMembers.any((m) {
            final uid = (m['userId'] ?? m['user_id'] ?? m['id'] ?? m['user']?['_id'] ?? '').toString();
            return uid == currentUserId;
          });

      if (mounted) {
        setState(() {
          _isJoined = joined;
          _isLoading = false;
        });
      }

      if (gp.groupMembers.isNotEmpty) {
        print('  - First member userId = ${gp.groupMembers.first['userId'] ?? gp.groupMembers.first['user']?['_id']}');
      }
    } catch (e) {
      print('ERROR reload group data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentGroup = gp.currentGroup ?? group;
    final currentUserId = widget.currentUserId.isNotEmpty
        ? widget.currentUserId
        : (authProvider.user?.id ?? '');

    final isOwner = gp.isCurrentUserAdmin ||
        (currentGroup.ownerId != null &&
            currentUserId.isNotEmpty &&
            currentGroup.ownerId.toString() == currentUserId);

    final userRole = isOwner ? MemberRole.owner : currentGroup.getUserRole(currentUserId);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải thông tin nhóm...'),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            group.name,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),
            if (_isJoined)
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.black),
                onPressed: () async {
                  final updatedGroup = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupSettingsScreen(
                        group: group,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                  if (updatedGroup != null && updatedGroup is GroupModel) {
                    setState(() => group = updatedGroup);
                  }
                },
              ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: currentGroup.coverUrl != null
                            ? DecorationImage(image: NetworkImage(currentGroup.coverUrl!), fit: BoxFit.cover)
                            : null,
                        color: Colors.grey[300],
                      ),
                    ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: currentGroup.avatar != null
                                ? NetworkImage(currentGroup.avatar!)
                                : null,
                            child: currentGroup.avatar == null
                                ? const Icon(Icons.group, size: 40)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentGroup.name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${currentGroup.membersCount} thành viên",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${userRole.icon} ${userRole.displayName}",
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (currentGroup.description.isNotEmpty)
                            Text(
                              currentGroup.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          const SizedBox(height: 16),

                          // Nút hành động - dùng _isJoined
                          if (!_isJoined)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.group_add, color: Colors.white),
                                label: const Text('Tham gia nhóm'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1877F2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _showJoinConfirmation(context),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.post_add),
                                    label: const Text("Đăng bài"),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreatePostInGroupScreen(
                                            group: currentGroup,
                                            currentUserId: currentUserId,
                                          ),
                                        ),
                                      ).then((value) {
                                        if (value == true) {
                                          gp.fetchGroupPosts(currentGroup.id, refresh: true);
                                          setState(() {});
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.exit_to_app, color: Colors.red),
                                    label: const Text(
                                      "Rời nhóm",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: _leaveGroup,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    const TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(text: "Bài viết"),
                        Tab(text: "Thành viên"),
                        Tab(text: "Thông tin"),
                      ],
                    ),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _PostsTab(group: currentGroup, currentUserId: currentUserId),
              _MembersTab(group: currentGroup, currentUserId: currentUserId),
              _InfoTab(group: currentGroup),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinConfirmation(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tham gia nhóm?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                  child: user?.avatar == null
                      ? Text(user?.fullName?[0] ?? 'U', style: const TextStyle(color: Colors.white))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? user?.username ?? 'Bạn',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        '@${user?.username ?? 'username'}',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn sẽ tham gia nhóm "${group.name}" với ${group.membersCount} thành viên hiện tại.',
              style: const TextStyle(fontSize: 14),
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                group.description,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final gp = Provider.of<GroupProvider>(context, listen: false);
              final res = await gp.joinGroup(group.id, currentUserId: widget.currentUserId);

              if (res['success']) {
                Fluttertoast.showToast(
                  msg: 'Tham gia thành công! 🎉',
                  backgroundColor: Colors.green,
                );

                // Reload toàn bộ để cập nhật isJoined + danh sách thành viên
                await _reloadGroupData();
              } else {
                Fluttertoast.showToast(
                  msg: res['message'] ?? 'Không thể tham gia nhóm',
                  backgroundColor: Colors.red,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tham gia'),
          ),
        ],
      ),
    );
  }

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rời nhóm"),
        content: const Text("Bạn có chắc chắn muốn rời nhóm này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              final gp = Provider.of<GroupProvider>(context, listen: false);
              final currentUserId = widget.currentUserId.isNotEmpty
                  ? widget.currentUserId
                  : (Provider.of<AuthProvider>(context, listen: false).user?.id ?? '');

              final res = await gp.leaveGroup(group.id, currentUserId: currentUserId);

              if (res['success']) {
                Fluttertoast.showToast(msg: 'Đã rời nhóm', backgroundColor: Colors.green);

                // Refresh lại dữ liệu sau khi rời
                await _reloadGroupData();
                await gp.fetchGroups(authProvider: Provider.of<AuthProvider>(context, listen: false));

                if (mounted) Navigator.pop(context, true);
              } else {
                Fluttertoast.showToast(
                  msg: res['message'] ?? 'Không thể rời nhóm',
                  backgroundColor: Colors.red,
                );
              }
            },
            child: const Text("Rời nhóm"),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////

class _PostsTab extends StatelessWidget {
  final GroupModel group;
  final String currentUserId;

  const _PostsTab({
    required this.group,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, gp, child) {
        final groupPosts = gp.getGroupPosts(group.id);

        if (gp.isLoadingPosts) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải bài viết nhóm...'),
              ],
            ),
          );
        }

        if (groupPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có bài viết nào trong nhóm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy là người đăng bài đầu tiên!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Builder(builder: (context) {
                  final provider = Provider.of<GroupProvider>(context);

                  // check membership
                  Map<String, dynamic>? memberObj;
                  try {
                    memberObj = provider.groupMembers.firstWhere((m) {
                      final id = (m['userId'] ?? m['user_id'])?.toString() ?? '';
                      return id == currentUserId;
                    }) as Map<String, dynamic>?;
                  } catch (_) {
                    memberObj = null;
                  }

                  final isActiveMember = memberObj != null ||
                      provider.currentUserRole != null ||
                      provider.groupMembers.any((m) {
                        final uid = (m['userId'] ?? m['user_id'])?.toString();
                        return uid == currentUserId;
                      });

                  if (!isActiveMember) {
                    return OutlinedButton.icon(
                      onPressed: () {
                        Fluttertoast.showToast(msg: 'Bạn cần tham gia nhóm để đăng bài');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Đăng bài ngay'),
                    );
                  }

                  return OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreatePostInGroupScreen(
                            group: group,
                            currentUserId: currentUserId,
                          ),
                        ),
                      ).then((value) {
                        if (value == true) {
                          gp.fetchGroupPosts(group.id, refresh: true);
                        }
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Đăng bài ngay'),
                  );
                }),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await gp.fetchGroupPosts(group.id, refresh: true);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: groupPosts.length,
            itemBuilder: (context, index) {
              final post = groupPosts[index];
              return PostCard(post: post);
            },
          ),
        );
      },
    );
  }

  // Helper: format ngày giờ đơn giản
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Helper: nút hành động (like, comment, share)
  Widget _buildActionButton(IconData icon, String label) {
    return TextButton.icon(
      onPressed: () {
        // TODO: Xử lý like/comment/share
        Fluttertoast.showToast(msg: 'Tính năng đang phát triển');
      },
      icon: Icon(icon, size: 18, color: Colors.grey[700]),
      label: Text(
        label,
        style: TextStyle(color: Colors.grey[700], fontSize: 13),
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final GroupModel group;
  final String currentUserId;

  const _MembersTab({required this.group, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GroupProvider>(context);
    final current = gp.currentGroup ?? group;
    final members = gp.groupMembers.isNotEmpty ? gp.groupMembers : current.members;

    // Debug để kiểm tra danh sách thành viên có cập nhật không
    print('DEBUG _MembersTab: members count = ${members.length}');

    if (gp.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (members.isEmpty) {
      return const Center(child: Text('Chưa có thành viên'));
    }

    // Sắp xếp: ADMIN trước, MODERATOR, rồi MEMBER
    final sorted = [...members];
    const roleOrder = {'ADMIN': 0, 'MODERATOR': 1, 'MEMBER': 2};
    sorted.sort((a, b) {
      final aR = (a['role']?.toString().toUpperCase() ?? 'MEMBER');
      final bR = (b['role']?.toString().toUpperCase() ?? 'MEMBER');
      return (roleOrder[aR] ?? 2).compareTo(roleOrder[bR] ?? 2);
    });

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final m = sorted[index];
        final Map<String, dynamic>? userObj =
        m['user'] != null ? Map<String, dynamic>.from(m['user'] as Map) : null;

        final String memberId =
            m['userId']?.toString() ??
                m['user_id']?.toString() ??
                userObj?['_id']?.toString() ?? '';

        final String name = (userObj?['fullName'] ??
            userObj?['username'] ??
            m['fullName'] ?? m['username'] ?? memberId).toString();

        final String avatarUrl = (userObj?['avatarUrl'] ??
            userObj?['avatar_url'] ??
            userObj?['avatar'] ??
            m['avatar_url'] ?? m['avatar'] ?? '').toString();

        final String roleRaw =
        (m['role']?.toString().toUpperCase() ?? 'MEMBER');

        // Check creator via ownerId fallback
        final bool isCreator = memberId.isNotEmpty &&
            memberId == current.ownerId;
        final effectiveRole = isCreator ? 'ADMIN' : roleRaw;

        final (String roleLabel, Color roleColor, IconData roleIcon) =
        switch (effectiveRole) {
          'ADMIN' => ('Trưởng nhóm', Colors.amber[700]!, Icons.verified),
          'MODERATOR' => ('Quản trị viên', Colors.blue[600]!, Icons.shield),
          _ => ('Thành viên', Colors.grey[600]!, Icons.person),
        };

        return ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundImage:
            avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
                : null,
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Icon(roleIcon, size: 14, color: roleColor),
              const SizedBox(width: 4),
              Text(
                roleLabel,
                style: TextStyle(
                  color: roleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: effectiveRole == 'ADMIN'
              ? const Icon(Icons.verified, color: Colors.amber)
              : effectiveRole == 'MODERATOR'
              ? const Icon(Icons.shield, color: Colors.blue, size: 18)
              : null,
        );
      },
    );
  }
}

class _InfoTab extends StatelessWidget {
  final GroupModel group;

  const _InfoTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GroupProvider>(context);
    final current = gp.currentGroup ?? group;

    // Find owner from gp.groupMembers (fetched from API) first, then fallback to current.members
    final allMembers = gp.groupMembers.isNotEmpty ? gp.groupMembers : current.members;

    Map<String, dynamic>? ownerMember;
    try {
      final found = allMembers.firstWhere((m) {
        final String uid = m['userId']?.toString() ?? m['user_id']?.toString() ?? '';
        final String role = (m['role']?.toString().toUpperCase() ?? '');
        // Match by ownerId OR by ADMIN role
        return uid == current.ownerId || role == 'ADMIN';
      });
      if (found is Map<String, dynamic>) ownerMember = found;
    } catch (_) {
      ownerMember = null;
    }

    String ownerName = 'Không có';
    String ownerAvatar = '';
    if (ownerMember != null) {
      final Map<String, dynamic>? userObj = ownerMember['user'] != null
          ? Map<String, dynamic>.from(ownerMember['user'] as Map)
          : null;
      ownerName = (userObj?['fullName'] ??
          userObj?['username'] ??
          ownerMember['fullName'] ??
          ownerMember['username'] ??
          current.ownerId ??
          'Không có').toString();
      ownerAvatar = (userObj?['avatarUrl'] ??
          userObj?['avatar_url'] ??
          userObj?['avatar'] ??
          ownerMember['avatar_url'] ??
          ownerMember['avatar'] ?? '').toString();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: ownerAvatar.isNotEmpty ? NetworkImage(ownerAvatar) : null,
                child: ownerAvatar.isEmpty ? Text(ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'U') : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ownerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Trưởng nhóm', style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 6),
          Text(current.description.isNotEmpty ? current.description : 'Chưa có mô tả'),
          const SizedBox(height: 16),
          Text('Số thành viên: ${current.membersCount}'),
          const SizedBox(height: 8),
          if (current.createdAt != null) Text('Tạo ngày: ${current.createdAt}'),
        ],
      ),
    );
  }
}