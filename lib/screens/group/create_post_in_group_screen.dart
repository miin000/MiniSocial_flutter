// lib/screens/group/create_post_in_group_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:fluttertoast/fluttertoast.dart';

import '../../models/group_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/cloudinary_service.dart';

class CreatePostInGroupScreen extends StatefulWidget {
  final GroupModel group;
  final String currentUserId;

  const CreatePostInGroupScreen({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  @override
  State<CreatePostInGroupScreen> createState() => _CreatePostInGroupScreenState();
}

class _CreatePostInGroupScreenState extends State<CreatePostInGroupScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;
      final remaining = 5 - _selectedImages.length;
      if (remaining <= 0) {
        Fluttertoast.showToast(
          msg: 'Đã đạt giới hạn 5 ảnh',
          backgroundColor: Colors.orange,
        );
        return;
      }
      final toAdd = images.take(remaining).toList();
      setState(() {
        _selectedImages.addAll(toAdd);
      });
      if (images.length > remaining) {
        Fluttertoast.showToast(
          msg: 'Chỉ thêm được $remaining ảnh (giới hạn 5)',
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Lỗi khi chọn ảnh',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _pickCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Lỗi khi chụp ảnh',
        backgroundColor: Colors.red,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createPost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _selectedImages.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Vui lòng nhập nội dung hoặc chọn ảnh',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    final currentUser = authProvider.user;
    final userId = currentUser?.id;

    if (userId == null) {
      Fluttertoast.showToast(msg: 'Vui lòng đăng nhập', backgroundColor: Colors.red);
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String>? mediaUrls;

      if (_selectedImages.isNotEmpty) {
        mediaUrls = await _cloudinaryService.uploadMultipleXFiles(_selectedImages);
        if (mediaUrls.isEmpty) {
          throw Exception('Không thể upload ảnh');
        }
      }

      final createdPost = await groupProvider.createGroupPost(
        widget.group.id,
        content: content,
        mediaUrls: mediaUrls,
      );

      if (createdPost != null) {
        // Tạo tên hiển thị: ưu tiên fullName → username → fallback
        final displayName = currentUser?.fullName?.isNotEmpty == true
            ? currentUser!.fullName!
            : (currentUser?.username?.isNotEmpty == true
            ? currentUser!.username!
            : 'Bạn');

        // SỬA LỖI: chỉ dùng userName (tham số có sẵn trong model), không dùng username
        final filledPost = createdPost.copyWith(
          userName: displayName,                    // ← đúng tên tham số
          userAvatar: currentUser?.avatar,
          userId: userId,
        );

        // Cập nhật vào cache để hiển thị ngay
        groupProvider.addPostToGroup(widget.group.id, filledPost);

        // Debug để kiểm tra (xem console khi chạy)
        print('DEBUG: Tên sau fill = ${filledPost.userName}');
        print('DEBUG: Avatar = ${filledPost.userAvatar}');

        Fluttertoast.showToast(
          msg: 'Đăng bài trong nhóm thành công!',
          backgroundColor: Colors.green,
        );

        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception('Không thể đăng bài');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Lỗi: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng trong: ${widget.group.name}'),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _createPost,
            child: _isUploading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text(
              'Đăng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3b82f6),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info + Group info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF3b82f6),
                  child: user?.avatar != null
                      ? ClipOval(
                    child: Image.network(
                      user!.avatar!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          user.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 20, color: Colors.white),
                        );
                      },
                    ),
                  )
                      : Text(
                    user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Người dùng',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Đăng trong nhóm: ${widget.group.name}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content input
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Bạn đang nghĩ gì trong nhóm này?',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Selected images preview
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        FutureBuilder<Uint8List>(
                          future: _selectedImages[index].readAsBytes(),
                          builder: (context, snapshot) {
                            return Container(
                              width: 120,
                              height: 120,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                              ),
                              child: snapshot.hasData
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      ),
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                            );
                          },
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Add media buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: _isUploading ? null : _pickImages,
                    icon: const Icon(Icons.photo_library, color: Color(0xFF10b981)),
                    label: const Text('Ảnh/Video', style: TextStyle(color: Colors.black87)),
                  ),
                  TextButton.icon(
                    onPressed: _isUploading ? null : _pickCamera,
                    icon: const Icon(Icons.camera_alt, color: Color(0xFF3b82f6)),
                    label: const Text('Camera', style: TextStyle(color: Colors.black87)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}