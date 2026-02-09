// lib/screens/friends/friends_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/friend_service.dart';

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
      _friends = f['success'] ? f['data'] as List<dynamic> : [];
      _requests = r['success'] ? r['data'] as List<dynamic> : [];
      _suggestions = s['success'] ? s['data'] as List<dynamic> : [];
      _loading = false;
    });
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
          tabs: const [
            Tab(text: 'Danh sách bạn'),
            Tab(text: 'Lời mời'),
            Tab(text: 'Gợi ý'),
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
                  child: ListTile(
                    leading: _buildAvatar(avatar, name),
                    title: Text(name),
                    subtitle: Text('$mutual bạn chung'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to messages tab (placeholder)
                            Fluttertoast.showToast(msg: 'Chuyển đến tab Chat');
                          },
                          child: const Text('Nhắn tin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            final res = await _friendService.removeFriend(item['id'] ?? item['_id'] ?? item['userId']);
                            if (res['success']) {
                              Fluttertoast.showToast(msg: 'Đã hủy kết bạn');
                              _loadAll();
                            } else {
                              Fluttertoast.showToast(msg: res['message'] ?? 'Lỗi');
                            }
                          },
                          child: const Text('Hủy kết bạn'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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