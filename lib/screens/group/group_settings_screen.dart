// lib/screens/group/group_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';

class GroupSettingsScreen extends StatefulWidget {
  final GroupModel group;
  final String currentUserId;

  const GroupSettingsScreen({
    super.key,
    required this.group,
    required this.currentUserId,
  });

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
    _nameController =
        TextEditingController(text: widget.group.name);
    _descController =
        TextEditingController(text: widget.group.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final group = widget.group;
    final userId = widget.currentUserId;

    // ✅ Kiểm tra quyền
    if (!group.isOwner(userId)) {
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
              const Icon(Icons.lock, size: 64, color: Colors.grey),
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

                /// ================= VIEW MODE =================
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
                ]

                /// ================= EDIT MODE =================
                else ...[
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
                          onPressed: () =>
                              setState(() => _isEditing = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final name =
                            _nameController.text.trim();
                            final desc =
                            _descController.text.trim();

                            if (name.isEmpty) {
                              Fluttertoast.showToast(
                                msg: 'Tên nhóm không thể trống',
                                backgroundColor: Colors.red,
                              );
                              return;
                            }

                            final result =
                            await groupProvider.updateGroupInfo(
                              group.id,
                              name,
                              desc,
                              group.avatar,
                            );

                            if (result['success']) {
                              Fluttertoast.showToast(
                              msg: 'Cập nhật thành công!',
                              backgroundColor: Colors.green,
                              );

                              // ✅ Tạo group mới với dữ liệu đã sửa
                              final updatedGroup = widget.group.copyWith(
                              name: name,
                              description: desc,
                              );

                              Navigator.pop(context, updatedGroup); // ✅ trả dữ liệu về
                            } else {
                              Fluttertoast.showToast(
                                msg: result['message'] ??
                                    'Lỗi cập nhật',
                                backgroundColor: Colors.red,
                              );
                            }
                          },
                          child: const Text('Lưu'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}