// lib/screens/group/group_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../../components/role_badge.dart';
import 'group_posts_screen.dart';
import 'group_members_screen.dart';
import 'group_info_screen.dart';
import 'group_settings_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasFetched) {
        _hasFetched = true;
        final groupProvider = Provider.of<GroupProvider>(context, listen: false);
        groupProvider.fetchGroupDetail(widget.groupId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    final userId = authProvider.user?.id ?? '';
    final group = groupProvider.currentGroup;

    if (group == null && !groupProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết nhóm')),
        body: const Center(child: Text('Không thể tải thông tin nhóm')),
      );
    }

    final isOwner = group?.isOwner(userId) ?? false;
    final isAdmin = group?.isAdmin(userId) ?? false;

    return WillPopScope(
      onWillPop: () async {
        if (isOwner && group != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Bạn là trưởng nhóm. Hãy chuyển quyền trước khi rời nhóm.',
              ),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(group?.name ?? 'Chi tiết nhóm'),
          backgroundColor: const Color(0xFF3b82f6),
          foregroundColor: Colors.white,
          actions: [
            if (isOwner)
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupSettingsScreen(groupId: widget.groupId),
                  ),
                ),
                tooltip: 'Cài đặt',
              ),
            if (!isOwner && group != null)
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'leave') {
                    final result =
                        await groupProvider.leaveGroup(widget.groupId);
                    if (result['success']) {
                      Fluttertoast.showToast(
                        msg: 'Rời nhóm thành công!',
                        backgroundColor: Colors.green,
                      );
                      Navigator.pop(context);
                    } else {
                      // Xử lý lỗi 403 - trưởng nhóm không thể rời
                      final statusCode = result['statusCode'] as int?;
                      String errorMsg = result['message'] ?? 'Lỗi rời nhóm';
                      
                      if (statusCode == 403) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMsg),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      } else {
                        Fluttertoast.showToast(
                          msg: errorMsg,
                          backgroundColor: Colors.red,
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Rời nhóm', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Bài viết', icon: Icon(Icons.article)),
              Tab(text: 'Thành viên', icon: Icon(Icons.people)),
              Tab(text: 'Thông tin', icon: Icon(Icons.info)),
            ],
          ),
        ),
        body: groupProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header Info
                  if (group != null)
                    Container(
                      color: Colors.grey[50],
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue.shade200,
                            backgroundImage: group.avatar != null
                                ? NetworkImage(group.avatar!)
                                : null,
                            child: group.avatar == null
                                ? Text(
                                    group.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${group.memberCount} thành viên',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (isOwner) ...[
                                  const SizedBox(height: 8),
                                  RoleBadge(role: MemberRole.owner),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        GroupPostsScreen(groupId: widget.groupId),
                        GroupMembersScreen(
                          groupId: widget.groupId,
                          isCurrentUserOwner: isOwner,
                        ),
                        if (group != null)
                          GroupInfoScreen(group: group)
                        else
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                onPressed: () {
                  // Navigate to create post in group
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đăng bài sắp có'),
                    ),
                  );
                },
                tooltip: 'Đăng bài',
                child: const Icon(Icons.edit),
              )
            : null,
      ),
    );
  }
}
