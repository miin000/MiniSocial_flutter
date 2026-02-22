// lib/screens/group/group_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../components/group_item.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import '../../models/group_model.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasFetched) {
        _hasFetched = true;
        final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
        final groupProvider =
        Provider.of<GroupProvider>(context, listen: false);

        groupProvider.fetchGroups(authProvider: authProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          )
        ],
      ),
      body: groupProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupProvider.errorMessage != null
          ? _buildError(groupProvider, authProvider)
          : RefreshIndicator(
        onRefresh: () =>
            groupProvider.fetchGroups(authProvider: authProvider),
        child: ListView(
          children: [

            // ================= MY GROUPS =================
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Group của bạn',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),

            if (groupProvider.myGroups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Bạn chưa tham gia group nào'),
              ),

            ...groupProvider.myGroups.map(
                  (group) => GroupItem(
                group: group,
                isOwner: group.getUserRole(userId) ==
                    MemberRole.owner,

                // ✅ FIX Ở ĐÂY
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailScreen(
                      group: group,
                      currentUserId: userId,
                    ),
                  ),
                ),
              ),
            ),

            // ================= SUGGESTED =================
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Gợi ý group',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),

            ...groupProvider.suggestedGroups.map(
                  (group) => GroupItem(
                group: group,

                // ✅ FIX Ở ĐÂY
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailScreen(
                      group: group,
                      currentUserId: userId,
                    ),
                  ),
                ),

                onJoin: () async {
                  final result =
                  await groupProvider.joinGroup(group.id);

                  if (result['success']) {
                    Fluttertoast.showToast(
                      msg: 'Tham gia thành công! 🎉',
                      backgroundColor: Colors.green,
                    );

                    await groupProvider.fetchGroups(
                        authProvider: authProvider);
                  } else {
                    final statusCode =
                    result['statusCode'] as int?;
                    String errorMsg =
                        result['message'] ?? 'Lỗi tham gia';

                    if (statusCode == 403) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text(
                              '⚠️ Không thể tham gia'),
                          content: Text(errorMsg),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      Fluttertoast.showToast(
                        msg: errorMsg,
                        backgroundColor: Colors.red,
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreateGroupScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildError(
      GroupProvider groupProvider, AuthProvider authProvider) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                groupProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Provider.of<GroupProvider>(context,
                      listen: false)
                      .fetchGroups(authProvider: authProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}