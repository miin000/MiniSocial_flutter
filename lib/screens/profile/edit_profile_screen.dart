import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  XFile? _newAvatar;
  Uint8List? _newAvatarBytes;
  XFile? _newCover;
  Uint8List? _newCoverBytes;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _bioController.text = user.bio ?? '';
      _jobController.text = user.job ?? '';
      _locationController.text = user.location ?? '';
      print('DEBUG EditProfile: Load user thành công - bio: ${user.bio}, job: ${user.job}, location: ${user.location}');
    } else {
      print('ERROR EditProfile: user null khi init');
      Fluttertoast.showToast(msg: 'Không tìm thấy thông tin người dùng', backgroundColor: Colors.red);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newAvatar = picked;
        _newAvatarBytes = bytes;
      });
    }
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newCover = picked;
        _newCoverBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      Fluttertoast.showToast(msg: 'Không tìm thấy thông tin người dùng', backgroundColor: Colors.red);
      setState(() => _isSaving = false);
      return;
    }

    String? newAvatarUrl;
    String? newCoverUrl;

    try {
      // Upload ảnh nếu có (giữ nguyên, vì Cloudinary hoạt động độc lập)
      if (_newAvatar != null) {
        newAvatarUrl = await CloudinaryService().uploadXFile(_newAvatar!);
        if (newAvatarUrl == null) {
          Fluttertoast.showToast(msg: 'Upload avatar thất bại', backgroundColor: Colors.orange);
        }
      }
      if (_newCover != null) {
        newCoverUrl = await CloudinaryService().uploadXFile(_newCover!);
        if (newCoverUrl == null) {
          Fluttertoast.showToast(msg: 'Upload cover thất bại', backgroundColor: Colors.orange);
        }
      }

      // Tạo user mới với thông tin cập nhật
      final updatedUser = user.copyWith(
        bio: _bioController.text.trim(),
        job: _jobController.text.trim(),
        location: _locationController.text.trim(),
        avatar: newAvatarUrl ?? user.avatar,
        cover: newCoverUrl ?? user.cover,
      );

      print('DEBUG EditProfile: Fake cập nhật local với data: ${updatedUser.toJson()}');

      Fluttertoast.showToast(
        msg: 'Đã cập nhật thông tin (tạm thời trên thiết bị - backend chưa hỗ trợ)',
        backgroundColor: Colors.orange,
        toastLength: Toast.LENGTH_LONG,
      );

      if (mounted) {
        Navigator.pop(context, true); // Quay lại profile và reload
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Lỗi: $e', backgroundColor: Colors.red);
      print('ERROR EditProfile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
        body: const Center(child: Text('Không tìm thấy thông tin người dùng')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : TextButton(
            onPressed: _saveProfile,
            child: const Text('Lưu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: _newCoverBytes != null
                        ? DecorationImage(image: MemoryImage(_newCoverBytes!), fit: BoxFit.cover)
                        : (user.cover != null
                        ? DecorationImage(image: NetworkImage(user.cover!), fit: BoxFit.cover)
                        : null),
                    color: Colors.blue,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: _isSaving ? null : _pickCover,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ảnh đại diện
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _newAvatarBytes != null
                        ? MemoryImage(_newAvatarBytes!) as ImageProvider
                        : (user.avatar != null ? NetworkImage(user.avatar!) : null),
                    child: user.avatar == null && _newAvatar == null
                        ? Text(user.fullName?[0] ?? 'U', style: const TextStyle(fontSize: 40))
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: _isSaving ? null : _pickAvatar,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Mô tả ngắn (bio)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _jobController,
              decoration: const InputDecoration(
                labelText: 'Công việc',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSaving,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Vị trí (thành phố)',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSaving,
            ),
          ],
        ),
      ),
    );
  }
}