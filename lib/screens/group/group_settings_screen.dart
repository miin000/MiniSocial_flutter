// lib/screens/group/group_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String groupId;

  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final group = Provider.of<GroupProvider>(context, listen: false).currentGroup;
    _nameController = TextEditingController(text: group?.name ?? '');
    _descController = TextEditingController(text: group?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    final userId = authProvider.user?.id ?? '';
    final group = groupProvider.currentGroup;

    // Kiểm soát truy cập: Chỉ trưởng nhóm
    if (group == null || !group.isOwner(userId)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cài đặt nhóm'),
          backgroundColor: const Color(0xFF3b82f6),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn không có quyền truy cập',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chỉ trưởng nhóm mới có thể cài đặt nhóm.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt nhóm'),
        backgroundColor: const Color(0xFF3b82f6),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Thông tin nhóm
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin nhóm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (!_isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tên nhóm',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Mô tả',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group.description.isEmpty
                              ? '(Chưa có mô tả)'
                              : group.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: group.description.isEmpty
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên nhóm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
                const SizedBox(height: 16),
                if (!_isEditing)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit),
                    label: const Text('Chỉnh sửa'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => setState(() => _isEditing = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _updateGroupInfo(context, groupProvider),
                          child: const Text('Lưu'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(),

          // Các tùy chọn quản lý
          ListTile(
            leading: const Icon(Icons.people, color: Colors.blue),
            title: const Text('Quản lý thành viên'),
            subtitle: const Text('Thêm, xóa hoặc cấp quyền'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),

          // Xóa group
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Xóa nhóm',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Hành động không thể hoàn tác'),
            onTap: () => _showDeleteConfirmation(context, groupProvider),
          ),
        ],
      ),
    );
  }

  void _updateGroupInfo(
    BuildContext context,
    GroupProvider groupProvider,
  ) async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Tên nhóm không thể trống',
        backgroundColor: Colors.red,
      );
      return;
    }

    final result = await groupProvider.updateGroupInfo(
      widget.groupId,
      name,
      desc,
      groupProvider.currentGroup?.avatar,
    );

    if (result['success']) {
      Fluttertoast.showToast(
        msg: 'Cập nhật thành công!',
        backgroundColor: Colors.green,
      );
      setState(() => _isEditing = false);
    } else {
      final statusCode = result['statusCode'] as int?;
      String errorMsg = result['message'] ?? 'Lỗi cập nhật';
      
      if (statusCode == 403) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('⚠️ Không có quyền'),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
  }

  void _showDeleteConfirmation(
    BuildContext context,
    GroupProvider groupProvider,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa nhóm?'),
        content: const Text(
          'Bạn sắp xóa nhóm này.\n\nTất cả dữ liệu sẽ bị mất và hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await groupProvider.deleteGroup(widget.groupId);
              if (result['success']) {
                Fluttertoast.showToast(
                  msg: 'Xóa nhóm thành công',
                  backgroundColor: Colors.red,
                );
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                );
              } else {
                final statusCode = result['statusCode'] as int?;
                String errorMsg = result['message'] ?? 'Lỗi xóa nhóm';
                
                if (statusCode == 403) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('⚠️ Không có quyền'),
                      content: Text(errorMsg),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
