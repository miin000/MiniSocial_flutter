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

class _GroupSettingsScreenState extends State<GroupSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isEditing = false;

  // Approval toggles
  late bool _requireMemberApproval;
  late bool _requirePostApproval;
  bool _savingSettings = false;

  late TabController _tabController;

  static const Color _blue      = Color(0xFF3b82f6);
  static const Color _blueDark  = Color(0xFF2563eb);
  static const Color _blueLight = Color(0xFFEFF6FF);
  static const Color _white     = Colors.white;
  static const Color _red       = Color(0xFFef4444);
  static const Color _green     = Color(0xFF22c55e);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descController = TextEditingController(text: widget.group.description);
    _requireMemberApproval = widget.group.requireMemberApproval;
    _requirePostApproval   = widget.group.requirePostApproval;
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gp = Provider.of<GroupProvider>(context, listen: false);
      final current = gp.currentGroup;
      if (current != null && current.id == widget.group.id) {
        setState(() {
          _requireMemberApproval = current.requireMemberApproval;
          _requirePostApproval   = current.requirePostApproval;
        });
      }
      gp.fetchPendingMembers(widget.group.id);
    });
  }

  @override
  void didUpdateWidget(covariant GroupSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      _nameController.text = widget.group.name;
      _descController.text = widget.group.description;
      _requireMemberApproval = widget.group.requireMemberApproval;
      _requirePostApproval   = widget.group.requirePostApproval;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveToggle({bool? memberApproval, bool? postApproval}) async {
    if (_savingSettings) return;
    setState(() => _savingSettings = true);
    final gp = Provider.of<GroupProvider>(context, listen: false);
    final result = await gp.updateGroupSettings(
      widget.group.id,
      requireMemberApproval: memberApproval,
      requirePostApproval: postApproval,
    );
    setState(() => _savingSettings = false);
    Fluttertoast.showToast(
      msg: result['success'] == true
          ? result['message'] ?? 'Đã lưu'
          : result['message'] ?? 'Lỗi cập nhật',
      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
    );
    if (result['success'] != true) {
      setState(() {
        if (memberApproval != null) _requireMemberApproval = !memberApproval;
        if (postApproval   != null) _requirePostApproval   = !postApproval;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final group = widget.group;
    final userId = widget.currentUserId;

    if (!group.isOwner(userId) && !groupProvider.isCurrentUserAdmin) {
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
                width: 72, height: 72,
                decoration: const BoxDecoration(color: _blueLight, shape: BoxShape.circle),
                child: const Icon(Icons.lock_outline_rounded, size: 32, color: _blue),
              ),
              const SizedBox(height: 16),
              const Text('Bạn không có quyền truy cập',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
              const SizedBox(height: 8),
              const Text('Chỉ trưởng nhóm mới có thể cài đặt nhóm.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748b))),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Quay lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pendingCount = groupProvider.pendingMembers.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(group.name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: _white)),
        backgroundColor: _blue,
        foregroundColor: _white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _white,
          unselectedLabelColor: _white.withOpacity(0.65),
          indicatorColor: _white,
          indicatorWeight: 3,
          tabs: [
            const Tab(text: 'Thông tin'),
            const Tab(text: 'Cài đặt'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Yêu cầu'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(10)),
                      child: Text('$pendingCount',
                          style: const TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(groupProvider, group),
          _buildSettingsTab(),
          _buildPendingTab(groupProvider),
        ],
      ),
    );
  }

  // ─── Tab 1: Thông tin nhóm ──────────────────────────────────────
  Widget _buildInfoTab(GroupProvider groupProvider, GroupModel group) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.group_rounded, color: _white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin nhóm',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _white)),
                  Text('Chỉnh sửa: "${group.name}"',
                      style: TextStyle(fontSize: 12, color: _white.withOpacity(0.8))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionLabel('THÔNG TIN NHÓM'),
        _card(children: [
          if (!_isEditing) ...[
            _viewTile(icon: Icons.group_rounded, label: 'Tên nhóm', value: group.name),
            _divider(),
            _viewTile(
              icon: Icons.notes_rounded,
              label: 'Mô tả',
              value: group.description.isEmpty ? 'Chưa có mô tả' : group.description,
              dimmed: group.description.isEmpty,
            ),
            _divider(),
            InkWell(
              onTap: () => setState(() => _isEditing = true),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  color: _blueLight,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded, size: 17, color: _blue),
                    SizedBox(width: 6),
                    Text('Chỉnh sửa thông tin',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _blue)),
                  ],
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _editField(controller: _nameController, label: 'Tên nhóm', icon: Icons.group_rounded),
                  const SizedBox(height: 12),
                  _editField(controller: _descController, label: 'Mô tả nhóm',
                      icon: Icons.notes_rounded, maxLines: 3),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _isEditing = false),
                          icon: const Icon(Icons.close_rounded, size: 17),
                          label: const Text('Hủy'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748b),
                            side: const BorderSide(color: Color(0xFFcbd5e1)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final name = _nameController.text.trim();
                            final desc = _descController.text.trim();
                            if (name.isEmpty) {
                              Fluttertoast.showToast(
                                  msg: 'Tên nhóm không thể trống',
                                  backgroundColor: Colors.red);
                              return;
                            }
                            final result = await groupProvider.updateGroupInfo(
                                group.id, name, desc, group.avatar);
                            if (result['success']) {
                              Fluttertoast.showToast(
                                  msg: 'Cập nhật thành công!',
                                  backgroundColor: Colors.green);
                              setState(() => _isEditing = false);
                              if (mounted) {
                                Navigator.pop(context,
                                    widget.group.copyWith(name: name, description: desc));
                              }
                            } else {
                              Fluttertoast.showToast(
                                  msg: result['message'] ?? 'Lỗi cập nhật',
                                  backgroundColor: Colors.red);
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 17),
                          label: const Text('Lưu thay đổi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue, foregroundColor: _white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ]),
        if (!_isEditing) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _blueLight, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _blue.withOpacity(0.25))),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: _blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Chỉ trưởng nhóm mới có thể thay đổi thông tin này.',
                      style: TextStyle(fontSize: 13, color: _blueDark, height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Tab 2: Cài đặt duyệt ───────────────────────────────────────
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('DUYỆT THÀNH VIÊN'),
        _card(children: [
          _toggleTile(
            icon: Icons.person_add_rounded,
            iconColor: const Color(0xFF8b5cf6),
            iconBg: const Color(0xFFF3E8FF),
            title: 'Duyệt yêu cầu tham gia',
            subtitle: _requireMemberApproval
                ? 'Thành viên mới cần được duyệt trước khi vào nhóm'
                : 'Ai cũng có thể tham gia ngay không cần duyệt',
            value: _requireMemberApproval,
            onChanged: _savingSettings
                ? null
                : (v) async {
                    setState(() => _requireMemberApproval = v);
                    await _saveToggle(memberApproval: v);
                  },
          ),
        ]),
        const SizedBox(height: 16),
        _sectionLabel('DUYỆT BÀI VIẾT'),
        _card(children: [
          _toggleTile(
            icon: Icons.rate_review_rounded,
            iconColor: const Color(0xFFf59e0b),
            iconBg: const Color(0xFFFEF3C7),
            title: 'Duyệt bài trước khi đăng',
            subtitle: _requirePostApproval
                ? 'Bài viết của thành viên cần được admin duyệt'
                : 'Thành viên có thể đăng bài ngay không cần duyệt',
            value: _requirePostApproval,
            onChanged: _savingSettings
                ? null
                : (v) async {
                    setState(() => _requirePostApproval = v);
                    await _saveToggle(postApproval: v);
                  },
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFed7aa))),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tips_and_updates_rounded, size: 18, color: Color(0xFFf59e0b)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bật duyệt thành viên giúp kiểm soát ai được vào nhóm. '
                  'Bật duyệt bài giúp lọc nội dung trước khi hiển thị công khai.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF92400e), height: 1.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Tab 3: Yêu cầu tham gia ────────────────────────────────────
  Widget _buildPendingTab(GroupProvider gp) {
    final pending = gp.pendingMembers;

    return RefreshIndicator(
      onRefresh: () => gp.fetchPendingMembers(widget.group.id),
      child: pending.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                            color: _blueLight, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.group_add_rounded, size: 34, color: _blue),
                      ),
                      const SizedBox(height: 16),
                      const Text('Không có yêu cầu nào',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                              color: Color(0xFF1e293b))),
                      const SizedBox(height: 6),
                      const Text('Tất cả yêu cầu tham gia sẽ hiện ở đây',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final m = pending[index];
                final memberId = m['_id']?.toString() ?? '';
                final userObj = m['user'] is Map
                    ? Map<String, dynamic>.from(m['user'] as Map)
                    : null;
                final name = (userObj?['fullName'] ??
                        userObj?['username'] ??
                        m['userId'] ??
                        '')
                    .toString();
                final avatarUrl =
                    (userObj?['avatarUrl'] ?? userObj?['avatar_url'] ?? '').toString();
                final requestedAt = m['createdAt'] != null
                    ? _formatDate(DateTime.tryParse(m['createdAt'].toString()))
                    : '';

                return Container(
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                          backgroundColor: const Color(0xFFE0E7FF),
                          child: avatarUrl.isEmpty
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: _blue))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Color(0xFF1e293b))),
                              if (requestedAt.isNotEmpty)
                                Text('Yêu cầu $requestedAt',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF94a3b8))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reject button
                        GestureDetector(
                          onTap: memberId.isEmpty
                              ? null
                              : () async {
                                  final res = await gp.rejectPendingMember(
                                      widget.group.id, memberId);
                                  Fluttertoast.showToast(
                                    msg: res['message'] ??
                                        (res['success'] == true ? 'Đã từ chối' : 'Lỗi'),
                                    backgroundColor: res['success'] == true
                                        ? Colors.orange
                                        : Colors.red,
                                  );
                                },
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.close_rounded, color: _red, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Approve button
                        GestureDetector(
                          onTap: memberId.isEmpty
                              ? null
                              : () async {
                                  final res = await gp.approvePendingMember(
                                      widget.group.id, memberId);
                                  Fluttertoast.showToast(
                                    msg: res['message'] ??
                                        (res['success'] == true ? 'Đã duyệt' : 'Lỗi'),
                                    backgroundColor: res['success'] == true
                                        ? Colors.green
                                        : Colors.red,
                                  );
                                },
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.check_rounded, color: _green, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _toggleTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1e293b))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748b), height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: onChanged, activeColor: _blue),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94a3b8),
              letterSpacing: 1.2)),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

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
            width: 34, height: 34,
            decoration: BoxDecoration(
                color: _blueLight, borderRadius: BorderRadius.circular(9)),
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
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: dimmed
                            ? const Color(0xFFb0bac9)
                            : const Color(0xFF1e293b),
                        fontStyle:
                            dimmed ? FontStyle.italic : FontStyle.normal)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        labelStyle: const TextStyle(color: Color(0xFF94a3b8), fontSize: 13),
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

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: Color(0xFFF1F5F9), indent: 62, endIndent: 0);
}
