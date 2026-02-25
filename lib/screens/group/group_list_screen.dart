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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color _blue      = Color(0xFF1877F2);
  static const Color _blueLight = Color(0xFFE7F3FF);
  static const Color _bg        = Color(0xFFF0F2F5);
  static const Color _white     = Colors.white;
  static const Color _textPrim  = Color(0xFF050505);
  static const Color _textSub   = Color(0xFF65676B);
  static const Color _divider   = Color(0xFFE4E6EB);
  static const Color _searchBg  = Color(0xFFF0F2F5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasFetched) {
        _hasFetched = true;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final groupProvider = Provider.of<GroupProvider>(context, listen: false);
        groupProvider.fetchGroups(authProvider: authProvider);
      }
    });

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter groups theo từ khóa tìm kiếm
  List<GroupModel> _filterGroups(List<GroupModel> groups) {
    if (_searchQuery.trim().isEmpty) return groups;
    final q = _searchQuery.toLowerCase().trim();
    return groups.where((g) => g.name.toLowerCase().contains(q)).toList();
  }

  // Widget avatar nhóm (gradient fallback nếu không có ảnh)
  Widget _groupAvatar(GroupModel group, {double size = 60}) {
    final hasAvatar = group.avatar != null && group.avatar!.isNotEmpty;
    if (hasAvatar) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          group.avatar!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(group.name, size),
        ),
      );
    }
    return _avatarFallback(group.name, size);
  }

  Widget _avatarFallback(String name, double size) {
    final colorPairs = [
      [const Color(0xFF1877F2), const Color(0xFF42A5F5)],
      [const Color(0xFF43A047), const Color(0xFF81C784)],
      [const Color(0xFFE53935), const Color(0xFFEF9A9A)],
      [const Color(0xFF8E24AA), const Color(0xFFCE93D8)],
      [const Color(0xFFF57C00), const Color(0xFFFFCC80)],
    ];
    final pair = colorPairs[name.length % colorPairs.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: pair, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Badge vai trò (trưởng nhóm / quản trị)
  Widget? _roleBadge(GroupModel group, String userId) {
    final role = group.getUserRole(userId);
    if (role == null || role == MemberRole.none) return null;
    if (role == MemberRole.owner) {
      return _badge(
        icon: Icons.star_rounded,
        label: 'Trưởng nhóm',
        iconColor: const Color(0xFFF59E0B),
        textColor: const Color(0xFF92400E),
        bgColor: const Color(0xFFFEF3C7),
      );
    }
    if (role == MemberRole.admin) {
      return _badge(
        icon: Icons.shield_rounded,
        label: 'Quản trị viên',
        iconColor: const Color(0xFF1877F2),
        textColor: const Color(0xFF1D4ED8),
        bgColor: _blueLight,
      );
    }
    return null;
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // Row hiển thị một nhóm (giống Facebook)
  Widget _groupRow(
      GroupModel group,
      String userId, {
        VoidCallback? onTap,
        VoidCallback? onJoin,
      }) {
    final badge = _roleBadge(group, userId);

    return InkWell(
      onTap: () {
        // Luôn mở chi tiết nhóm
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(
              group: group,
              currentUserId: userId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _groupAvatar(group, size: 60),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrim,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (badge != null) ...[
                    badge,
                    const SizedBox(height: 3),
                  ],
                  Text(
                    '${group.memberCount} thành viên',
                    style: const TextStyle(fontSize: 13, color: _textSub),
                  ),
                ],
              ),
            ),

            if (!group.isJoined)
              ElevatedButton(
                onPressed: onJoin ?? () {
                  _showJoinDialog(
                    context,
                    group,
                    Provider.of<GroupProvider>(context, listen: false),
                    Provider.of<AuthProvider>(context, listen: false),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blueLight,
                  foregroundColor: _blue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                child: const Text('Tham gia'),
              ),
          ],
        ),
      ),
    );
  }

  // Tiêu đề section
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: _textPrim,
        ),
      ),
    );
  }

  // Divider mỏng giữa các row
  Widget _rowDivider() => const Divider(
    height: 1,
    thickness: 1,
    color: _divider,
    indent: 88,
    endIndent: 0,
  );

  // Empty state
  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Text(
        message,
        style: const TextStyle(fontSize: 14, color: _textSub),
      ),
    );
  }

  // Dialog xác nhận tham gia nhóm (đẹp hơn, có cover + info)
  Future<void> _showJoinDialog(
      BuildContext context,
      GroupModel group,
      GroupProvider groupProvider,
      AuthProvider authProvider,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover ảnh nhóm
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: double.infinity,
                height: 100,
                child: (group.avatar != null && group.avatar!.isNotEmpty)
                    ? Image.network(
                  group.avatar!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarFallback(group.name, 100),
                )
                    : _avatarFallback(group.name, 100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textPrim,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.memberCount} thành viên',
                    style: const TextStyle(fontSize: 13, color: _textSub),
                  ),
                  if ((group.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      group.description!,
                      style: const TextStyle(fontSize: 13, color: _textSub, height: 1.4),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSub,
                    side: const BorderSide(color: _divider),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: _white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Tham gia', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Gọi join
    final result = await groupProvider.joinGroup(group.id);

    if (result['success'] == true) {
      Fluttertoast.showToast(
        msg: 'Tham gia thành công! 🎉',
        backgroundColor: Colors.green,
      );

      // Refresh danh sách nhóm
      await groupProvider.fetchGroups(authProvider: authProvider);

      // Tìm nhóm vừa join trong myGroups
      final joinedGroup = groupProvider.myGroups.firstWhere(
            (g) => g.id == group.id,
        orElse: () => group.copyWith(isJoined: true), // fallback
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(
              group: joinedGroup,
              currentUserId: authProvider.user?.id ?? '',
            ),
          ),
        );
      }
    } else {
      final statusCode = result['statusCode'] as int?;
      String message = result['message'] ?? 'Không thể tham gia nhóm';

      if (statusCode == 401) {
        message = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
      } else if (statusCode == 403) {
        message = 'Bạn không có quyền tham gia nhóm này (có thể nhóm riêng tư hoặc đã bị chặn).';
      } else if (statusCode == 400) {
        message = 'Yêu cầu không hợp lệ. Có thể bạn đã tham gia hoặc gửi yêu cầu trước đó.';
      } else if (statusCode == 404) {
        message = 'Nhóm không tồn tại hoặc đã bị xóa.';
      }

      if (context.mounted) {
        if (statusCode == 403 || statusCode == 401) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('⚠️ Không thể tham gia'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: _blue, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        } else {
          Fluttertoast.showToast(msg: message, backgroundColor: Colors.red);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.id ?? '';

    final filteredMy = _filterGroups(groupProvider.myGroups);
    final filteredSuggested = _filterGroups(groupProvider.suggestedGroups);
    final isSearchActive = _searchQuery.trim().isNotEmpty;
    final totalResults = filteredMy.length + filteredSuggested.length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'Group',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _textPrim,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: _bg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: _textPrim, size: 22),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _divider),
        ),
      ),
      body: groupProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : groupProvider.errorMessage != null
          ? _buildError(groupProvider, authProvider)
          : RefreshIndicator(
        color: _blue,
        onRefresh: () => groupProvider.fetchGroups(authProvider: authProvider),
        child: ListView(
          children: [
            // Search bar
            Container(
              color: _white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 15, color: _textPrim),
                cursorColor: _blue,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm group...',
                  hintStyle: const TextStyle(color: _textSub, fontSize: 15),
                  prefixIcon: const Icon(Icons.search_rounded, color: _textSub, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: _textSub, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: _searchBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _blue, width: 1.4),
                  ),
                ),
              ),
            ),

            // Không tìm thấy khi search
            if (isSearchActive && totalResults == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 56, color: Color(0xFFBCC0C4)),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy nhóm nào\ncho "$_searchQuery"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrim),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Hãy thử từ khoá khác',
                      style: TextStyle(fontSize: 14, color: _textSub),
                    ),
                  ],
                ),
              ),

            // MY GROUPS
            if (!isSearchActive || filteredMy.isNotEmpty) ...[
              Container(
                color: _white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      isSearchActive
                          ? 'Nhóm của bạn'
                          : 'Group của bạn • ${groupProvider.myGroups.length}',
                    ),
                    if (filteredMy.isEmpty)
                      _emptyState('Bạn chưa tham gia group nào')
                    else
                      ...List.generate(
                        filteredMy.length,
                            (i) {
                          final group = filteredMy[i];
                          return Column(
                            children: [
                              _groupRow(
                                group,
                                userId,
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
                              if (i < filteredMy.length - 1) _rowDivider(),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // SUGGESTED GROUPS
            if (!isSearchActive || filteredSuggested.isNotEmpty) ...[
              Container(
                color: _white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Gợi ý group'),
                    if (filteredSuggested.isEmpty)
                      _emptyState('Không có nhóm gợi ý nào lúc này')
                    else
                      ...List.generate(
                        filteredSuggested.length,
                            (i) {
                          final group = filteredSuggested[i];
                          return Column(
                            children: [
                              _groupRow(
                                group,
                                userId,
                                onTap: () => _showJoinDialog(
                                  context,
                                  group,
                                  groupProvider,
                                  authProvider,
                                ),
                                onJoin: () => _showJoinDialog(
                                  context,
                                  group,
                                  groupProvider,
                                  authProvider,
                                ),
                              ),
                              if (i < filteredSuggested.length - 1) _rowDivider(),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Error screen
  Widget _buildError(GroupProvider groupProvider, AuthProvider authProvider) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, size: 32, color: _textSub),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không thể tải danh sách nhóm',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textPrim),
              ),
              const SizedBox(height: 6),
              Text(
                groupProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _textSub),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Provider.of<GroupProvider>(context, listen: false)
                      .fetchGroups(authProvider: authProvider);
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}