import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../models/group_post_model.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import 'group_settings_screen.dart';
import 'create_post_in_group_screen.dart';

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

  @override
  void initState() {
    super.initState();
    group = widget.group;
    // Fetch latest group detail (members + updated role info) after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gp = Provider.of<GroupProvider>(context, listen: false);
      gp.fetchGroupDetail(group.id).then((_) {
        if (mounted && gp.currentGroup != null) {
          setState(() {
            group = gp.currentGroup!;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GroupProvider>(context);
    final currentGroup = gp.currentGroup ?? group;
    final currentUserId = widget.currentUserId.isNotEmpty
        ? widget.currentUserId
        : (Provider.of<AuthProvider>(context, listen: false).user?.id ?? '');

    // isOwner: check via creator_id match OR backend returned userRole == ADMIN
    final isOwner = gp.isCurrentUserAdmin ||
        (currentGroup.ownerId != null &&
            currentUserId.isNotEmpty &&
            currentGroup.ownerId.toString() == currentUserId);

    final userRole = isOwner
        ? MemberRole.owner
        : currentGroup.getUserRole(currentUserId);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],

        // ================= APP BAR =================
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            group.name,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // 🔔 Thông báo
            IconButton(
              icon: const Icon(Icons.notifications_none,
                  color: Colors.black),
              onPressed: () {},
            ),

            // ⚙ Cài đặt
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
                  setState(() {
                    group = updatedGroup;
                  });
                }
              },
            ),
          ],
        ),

        // ================= BODY =================
        body: Column(
          children: [
            // -------- COVER --------
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                image: group.coverUrl != null
                    ? DecorationImage(
                  image: NetworkImage(group.coverUrl!),
                  fit: BoxFit.cover,
                )
                    : null,
                color: Colors.grey[300],
              ),
            ),

            // -------- GROUP INFO --------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: group.avatar != null
                        ? NetworkImage(group.avatar!)
                        : null,
                    child: group.avatar == null
                        ? const Icon(Icons.group, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${group.membersCount} thành viên",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${userRole.icon} ${userRole.displayName}",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (group.description.isNotEmpty)
                    Text(
                      group.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87),
                    ),

                  const SizedBox(height: 16),

                  // ================= ACTION BUTTONS =================

                  Row(
                    children: [
                      // 📝 ĐĂNG BÀI
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.post_add),
                          label: const Text("Đăng bài"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreatePostInGroupScreen(
                                  group: group,
                                  currentUserId: widget.currentUserId,
                                ),
                              ),
                            ).then((value) {
                              if (value == true) {
                                setState(() {});
                              }
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      // 🚪 RỜI NHÓM
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.exit_to_app,
                              color: Colors.red),
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

            // -------- TABS --------
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

            Expanded(
              child: TabBarView(
                children: [
                  _PostsTab(group: group, currentUserId: widget.currentUserId),
                  _MembersTab(group: group, currentUserId: widget.currentUserId),
                  _InfoTab(group: group),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LEAVE GROUP =================

  void _leaveGroup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rời nhóm"),
        content: const Text(
            "Bạn có chắc chắn muốn rời nhóm này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Bạn đã rời nhóm"),
                ),
              );
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

  const _PostsTab({required this.group, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final gp = Provider.of<GroupProvider>(context);
    final current = gp.currentGroup ?? group;
    final posts = current.posts;

    if (posts.isEmpty) {
      return const Center(child: Text('Chưa có bài viết nào trong nhóm'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final p = posts[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(p.authorId.isNotEmpty ? p.authorId[0].toUpperCase() : 'U'),
          ),
          title: Text(p.content.isNotEmpty ? p.content : '[Hình/Media]'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tác giả: ${p.authorId}'),
              Text('${p.createdAt}'),
              Text('Trạng thái: ${p.status.name}'),
            ],
          ),
        );
      },
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
