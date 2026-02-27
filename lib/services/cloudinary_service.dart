import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'dcfuybexm';
  static const String uploadPreset = 'MiniSocial';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  static const int _maxBytes = 9 * 1024 * 1024; // 9 MB – Cloudinary unsigned limit is 10 MB

  /// Upload a single [XFile]. Throws a descriptive [Exception] on failure.
  /// Uses readAsBytes() so it works on both mobile and web.
  Future<String?> uploadXFile(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final fileName = imageFile.name.isNotEmpty ? imageFile.name : 'image.jpg';

    if (bytes.length > _maxBytes) {
      final mb = (bytes.length / 1024 / 1024).toStringAsFixed(1);
      throw Exception('Ảnh quá lớn (${mb}MB). Vui lòng chọn ảnh dưới 9MB.');
    }

    final dio = Dio(BaseOptions(
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 60),
    ));

    try {
      final formData = FormData.fromMap({
        'upload_preset': uploadPreset,
        'folder': 'minisocial/posts',
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final response = await dio.post(_uploadUrl, data: formData);
      final url = response.data['secure_url'] as String?;
      if (url == null) throw Exception('Cloudinary không trả về URL');
      return url;
    } on DioException catch (e) {
      // Extract Cloudinary's error message when available
      final cloudinaryMsg = e.response?.data?['error']?['message'] as String?;
      if (cloudinaryMsg != null) {
        throw Exception('Cloudinary: $cloudinaryMsg');
      }
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Upload timeout – ảnh quá lớn hoặc mạng chậm.');
      }
      throw Exception('Upload thất bại: ${e.message}');
    }
  }

  /// Upload multiple [XFile]s sequentially. Throws on first failure.
  Future<List<String>> uploadMultipleXFiles(List<XFile> imageFiles) async {
    final List<String> urls = [];
    for (int i = 0; i < imageFiles.length; i++) {
      // Let exceptions propagate so callers can show meaningful errors
      final url = await uploadXFile(imageFiles[i]);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  // Legacy helpers kept for backward compatibility
  Future<String?> uploadImage(String filePath) =>
      uploadXFile(XFile(filePath));
}
