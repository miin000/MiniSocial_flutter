// lib/screens/profile/public_profile_screen.dart
// Xem hồ sơ công khai của người dùng khác (UC1.7)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final UserService _userService = UserService();

  bool _isLoading = true;
  String? _errorMsg;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    final result = await _userService.getPublicProfile(widget.userId);
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'];
      // backend wraps in { data: {...} } or returns object directly
      setState(() {
        _profile = (data is Map && data['data'] is Map)
            ? Map<String, dynamic>.from(data['data'])
            : Map<String, dynamic>.from(data as Map);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMsg = result['message'] ?? 'Không thể tải hồ sơ';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id ?? '';

    // Redirect self to own profile tab
    if (widget.userId == currentUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile != null
            ? (_profile!['full_name'] ?? _profile!['username'] ?? 'Hồ sơ')
            : 'Hồ sơ'),
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_errorMsg!,
                          style: const TextStyle(color: Colors.grey, fontSize: 15),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildContent(),
                  ),
                ),
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    final fullName = p['full_name'] as String?;
    final username = p['username'] as String?;
    final avatarUrl = p['avatar_url'] as String?;
    final coverUrl = p['cover_url'] as String?;
    final bio = p['bio'] as String?;
    final job = p['job'] as String?;
    final location = p['location'] as String?;
    final gender = p['gender'] as String?;
    final birthdate = p['birthdate'] != null
        ? DateTime.tryParse(p['birthdate'].toString())
        : null;
    final createdAt = p['created_at'] != null
        ? DateTime.tryParse(p['created_at'].toString())
        : null;
    final displayName = fullName?.isNotEmpty == true ? fullName! : username ?? 'Người dùng';
    final initial = displayName[0].toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ảnh bìa
        if (coverUrl != null && coverUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: coverUrl,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        else
          Container(height: 180, color: const Color(0xFF1877F2)),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              // Avatar overlapping cover
              Transform.translate(
                offset: const Offset(0, -45),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.blue.shade200,
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl,
                              width: 104,
                              height: 104,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Text(initial, style: const TextStyle(fontSize: 40, color: Colors.white)),
                            ),
                          )
                        : Text(initial, style: const TextStyle(fontSize: 40, color: Colors.white)),
                  ),
                ),
              ),

              // Reduce spacing from avatar
              const SizedBox(height: 0),

              // Name
              Text(
                displayName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (username != null && username.isNotEmpty && username != fullName)
                Text('@$username',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),

              const SizedBox(height: 8),

              // Bio
              if (bio != null && bio.isNotEmpty)
                Text(bio,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.center)
              else
                const Text('Chưa có tiểu sử',
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Info rows
              if (job != null && job.isNotEmpty) _buildInfoRow(Icons.work_outline, job),
              if (location != null && location.isNotEmpty)
                _buildInfoRow(Icons.location_on_outlined, location),
              if (gender != null && gender.isNotEmpty)
                _buildInfoRow(
                  Icons.wc_outlined,
                  gender == 'male' ? 'Nam' : gender == 'female' ? 'Nữ' : 'Khác',
                ),
              if (birthdate != null)
                _buildInfoRow(
                  Icons.cake_outlined,
                  '${birthdate.day.toString().padLeft(2, '0')}/${birthdate.month.toString().padLeft(2, '0')}/${birthdate.year}',
                ),
              if (createdAt != null)
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Tham gia ${createdAt.month}/${createdAt.year}',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
