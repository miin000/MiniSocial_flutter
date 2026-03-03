// lib/screens/friends/friends_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/friend_service.dart';
import '../../providers/chat_provider.dart';
import '../../providers/friend_provider.dart';
import '../chat/chat_detail_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final FriendService _friendService = FriendService();

  List<dynamic> _friends = [];
  List<dynamic> _requests = [];
  List<dynamic> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final f = await _friendService.getFriends();
    final r = await _friendService.getRequests();
    final s = await _friendService.getSuggestions();
    setState(() {
      _friends = f['success'] ? (f['data'] as List<dynamic>? ?? []) : [];
      _requests = r['success'] ? (r['data'] as List<dynamic>? ?? []) : [];
      _suggestions = s['success'] ? (s['data'] as List<dynamic>? ?? []) : [];
      _loading = false;
    });
    // Update pending count badge
    if (mounted) {
      try {
        context.read<FriendProvider>().setPendingCount(_requests.length);
      } catch (_) {}
    }
  }

  Widget _buildAvatar(String? url, String name) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(url),
      );
    }
    return CircleAvatar(
      radius: 28,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bạn bè'),
        backgroundColor: const Color(0xFF3b82f6),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Danh sách bạn'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Lời mời'),
                  if (_requests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _requests.length > 99 ? '99+' : '${_requests.length}',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Gợi ý'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // Friends list
          RefreshIndicator(
            onRefresh: _loadAll,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final item = _friends[index];
                final name = item['fullName'] ?? item['name'] ?? 'Người dùng';
                final avatar = item['avatar'];
                final mutual = item['mutualCount'] ?? item['mutual'] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _buildAvatar(avatar, name),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text('$mutual bạn chung', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Flexible(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final friendId = (item['id'] ?? item['_id'] ?? item['userId'])?.toString() ?? '';
                                        if (friendId.isEmpty) return;
                                        final chatProvider = context.read<ChatProvider>();
                                        final conv = await chatProvider.createPrivateChat(friendId);
                                        if (conv != null && mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatDetailScreen(conversation: conv),
                                            ),
                                          );
                                        } else {
                                          Fluttertoast.showToast(msg: chatProvider.error ?? 'Không thể mở chat');
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3b82f6),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Text('Nhắn tin'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final res = await _friendService.removeFriend(item['id'] ?? item['_id'] ?? item['userId']);
                                        if (res['success']) {
                                          Fluttertoast.showToast(msg: 'Đã hủy kết bạn');
                                          _loadAll();
                                        } else {
                                          Fluttertoast.showToast(msg: res['message'] ?? 'Lỗi');
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: const Text('Hủy kết bạn'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Requests
          RefreshIndicator(
            onRefresh: _loadAll,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final item = _requests[index];
                final name = item['fromName'] ?? item['fullName'] ?? 'Người gửi';
                final avatar = item['avatar'] ?? item['fromAvatar'];
                final mutual = item['mutualCount'] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: _buildAvatar(avatar, name),
                    title: Text(name),
                    subtitle: Text('$mutual bạn chung'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final res = await _friendService.acceptRequest(item['id'] ?? item['_id'] ?? item['requestId']);
                            if (res['success']) {
                              Fluttertoast.showToast(msg: 'Đã chấp nhận');
                              _loadAll();
                            } else {
                              Fluttertoast.showToast(msg: res['message'] ?? 'Lỗi');
                            }
                          },
                          child: const Text('Chấp nhận'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3b82f6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final res = await _friendService.rejectRequest(item['id'] ?? item['_id'] ?? item['requestId']);
                            if (res['success']) {
                              Fluttertoast.showToast(msg: 'Đã từ chối');
                              _loadAll();
                            } else {
                              Fluttertoast.showToast(msg: res['message'] ?? 'Lỗi');
                            }
                          },
                          child: const Text('Từ chối'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Suggestions
          RefreshIndicator(
            onRefresh: _loadAll,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                final name = item['fullName'] ?? item['name'] ?? 'Người dùng';
                final avatar = item['avatar'];
                final mutual = item['mutualCount'] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: _buildAvatar(avatar, name),
                    title: Text(name),
                    subtitle: Text('$mutual bạn chung'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final res = await _friendService.sendRequest(item['id'] ?? item['_id'] ?? item['userId']);
                        if (res['success']) {
                          Fluttertoast.showToast(msg: 'Đã gửi lời mời');
                          _loadAll();
                        } else {
                          Fluttertoast.showToast(msg: res['message'] ?? 'Lỗi');
                        }
                      },
                      child: const Text('Thêm bạn bè'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563eb),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}