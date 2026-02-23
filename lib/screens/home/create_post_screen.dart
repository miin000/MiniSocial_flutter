import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/cloudinary_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = [];
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
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty && images.length <= 5) {
        setState(() {
          _selectedImages.addAll(images.map((e) => File(e.path)));
        });
      } else if (images.length > 5) {
        Fluttertoast.showToast(
          msg: 'Chỉ được chọn tối đa 5 ảnh',
          backgroundColor: Colors.red,
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
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
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
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId == null) {
      Fluttertoast.showToast(
        msg: 'Vui lòng đăng nhập',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<String>? mediaUrls;
      
      // Upload images to Cloudinary
      if (_selectedImages.isNotEmpty) {
        mediaUrls = await _cloudinaryService.uploadMultipleImages(_selectedImages);
        if (mediaUrls.isEmpty) {
          throw Exception('Không thể upload ảnh');
        }
      }

      // Create post
      final createdPost = await postProvider.createPost(
        userId: userId,
        content: content.isNotEmpty ? content : null,
        mediaUrls: mediaUrls,
      );

      if (createdPost != null) {
        Fluttertoast.showToast(
          msg: 'Đăng bài thành công!',
          backgroundColor: Colors.green,
        );
        if (mounted) {
          Navigator.pop(context);
        }
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
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bài viết'),
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
            // User info
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
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Người dùng',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.public, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Công khai',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Content input
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Bạn đang nghĩ gì?',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Selected images
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
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
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
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
