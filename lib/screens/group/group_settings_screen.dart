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

  static const Color _blue      = Color(0xFF3b82f6);
  static const Color _blueDark  = Color(0xFF2563eb);
  static const Color _blueLight = Color(0xFFEFF6FF);
  static const Color _white     = Colors.white;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descController = TextEditingController(text: widget.group.description);
  }

  // ✅ Đảm bảo mỗi lần mở nhóm khác thì controller cập nhật đúng nhóm đó
  @override
  void didUpdateWidget(covariant GroupSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      _nameController.text = widget.group.name;
      _descController.text = widget.group.description;
    }
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
        backgroundColor: _white,
        appBar: AppBar(
          title: const Text('Cài đặt nhóm'),
          backgroundColor: _blue,
          foregroundColor: _white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: _blueLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 32, color: _blue),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn không có quyền truy cập',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chỉ trưởng nhóm mới có thể cài đặt nhóm.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748b)),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Quay lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          group.name,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 17, color: _white),
        ),
        backgroundColor: _blue,
        foregroundColor: _white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ── Blue header strip ─────────────────────────────────
          Container(
            color: _blue,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: _white, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cài đặt nhóm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đang chỉnh sửa: "${group.name}"',
                      style: TextStyle(
                        fontSize: 13,
                        color: _white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Card section ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'THÔNG TIN NHÓM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94a3b8),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                // White card
                Container(
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      /// ================= VIEW MODE =================
                      if (!_isEditing) ...[
                        _viewTile(
                          icon: Icons.group_rounded,
                          label: 'Tên nhóm',
                          value: group.name,
                        ),
                        _divider(),
                        _viewTile(
                          icon: Icons.notes_rounded,
                          label: 'Mô tả',
                          value: group.description.isEmpty
                              ? 'Chưa có mô tả'
                              : group.description,
                          dimmed: group.description.isEmpty,
                        ),
                        _divider(),
                        InkWell(
                          onTap: () => setState(() => _isEditing = true),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: const BoxDecoration(
                              color: _blueLight,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, size: 17, color: _blue),
                                SizedBox(width: 6),
                                Text(
                                  'Chỉnh sửa thông tin',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]

                      /// ================= EDIT MODE =================
                      else ...[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _editField(
                                controller: _nameController,
                                label: 'Tên nhóm',
                                icon: Icons.group_rounded,
                              ),
                              const SizedBox(height: 12),
                              _editField(
                                controller: _descController,
                                label: 'Mô tả nhóm',
                                icon: Icons.notes_rounded,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          setState(() => _isEditing = false),
                                      icon: const Icon(
                                          Icons.close_rounded, size: 17),
                                      label: const Text('Hủy'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                        const Color(0xFF64748b),
                                        side: const BorderSide(
                                            color: Color(0xFFcbd5e1)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
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
                                          final updatedGroup =
                                          widget.group.copyWith(
                                            name: name,
                                            description: desc,
                                          );

                                          Navigator.pop(context,
                                              updatedGroup); // ✅ trả dữ liệu về
                                        } else {
                                          Fluttertoast.showToast(
                                            msg: result['message'] ??
                                                'Lỗi cập nhật',
                                            backgroundColor: Colors.red,
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                          Icons.check_rounded, size: 17),
                                      label: const Text('Lưu thay đổi'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _blue,
                                        foregroundColor: _white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Info note ──────────────────────────────────
                if (!_isEditing) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _blueLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _blue.withOpacity(0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: _blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chỉ trưởng nhóm mới có thể thay đổi thông tin này.',
                            style: TextStyle(
                                fontSize: 13,
                                color: _blueDark,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── View tile ──────────────────────────────────────────────────
  Widget _viewTile({
    required IconData icon,
    required String label,
    required String value,
    bool dimmed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _blueLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: _blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94a3b8),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: dimmed
                        ? const Color(0xFFb0bac9)
                        : const Color(0xFF1e293b),
                    fontStyle:
                    dimmed ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit field ─────────────────────────────────────────────────
  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1e293b),
          fontWeight: FontWeight.w500),
      cursorColor: _blue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        const TextStyle(color: Color(0xFF94a3b8), fontSize: 13),
        prefixIcon: Icon(icon, color: _blue, size: 19),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _blue, width: 1.6),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  // ── Divider ────────────────────────────────────────────────────
  Widget _divider() => const Divider(
    height: 1,
    thickness: 1,
    color: Color(0xFFF1F5F9),
    indent: 62,
    endIndent: 0,
  );
}