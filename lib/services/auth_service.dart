// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Set token cho ApiService
  void setToken(String token) {
    _apiService.setToken(token);
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await _apiService.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });

      final data = response.data;
      final accessToken = data['accessToken'];
      final user = UserModel.fromJson(data['user']);

      // Lưu token
      await _apiService.saveToken(accessToken);

      return {
        'success': true,
        'user': user,
        'token': accessToken,
      };
    } on DioException catch (e) {
      String message = 'Đăng nhập thất bại';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Đăng ký
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String fullName,
    required String password,
  }) async {
    try {
      await _apiService.post('/auth/register', data: {
        'email': email,
        'username': username,
        'full_name': fullName,
        'password': password,
      });

      return {
        'success': true,
        'message': 'Đăng ký thành công! Vui lòng đăng nhập.',
      };
    } on DioException catch (e) {
      String message = 'Đăng ký thất bại';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Lấy thông tin user hiện tại
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _apiService.get('/auth/me');
      final user = UserModel.fromJson(response.data);

      return {
        'success': true,
        'user': user,
      };
    } on DioException catch (e) {
      String message = 'Không thể lấy thông tin người dùng';
      if (e.response?.statusCode == 401) {
        message = 'Phiên đăng nhập đã hết hạn';
      }
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _apiService.removeToken();
  }

  // Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    await _apiService.loadToken();
    return _apiService.hasToken;
  }

  Future<Map<String, dynamic>> updateProfile(UserModel user) async {
    try {
      print('DEBUG: === BẮT ĐẦU UPDATE PROFILE ===');
      print('DEBUG: Data gửi: ${user.toJson()}');

      Response? response;
      String? successEndpoint;
      String? successMethod;

      // Danh sách endpoint + method cần thử (thêm nhiều hơn để bao quát)
      final attempts = [
        {'path': '/users/${user.id}', 'method': 'put'},
        {'path': '/users/${user.id}', 'method': 'patch'},
        {'path': '/profile', 'method': 'put'},
        {'path': '/profile', 'method': 'patch'},
        {'path': '/users/me', 'method': 'put'},
        {'path': '/users/me', 'method': 'patch'},
        {'path': '/users/update', 'method': 'put'},
        {'path': '/users/update', 'method': 'patch'},
        {'path': '/auth/profile', 'method': 'put'},
        {'path': '/auth/profile', 'method': 'patch'},
        {'path': '/profile/update', 'method': 'put'},
        {'path': '/profile/update', 'method': 'patch'},
      ];

      for (final attempt in attempts) {
        final path = attempt['path']!;
        final method = attempt['method']!;

        try {
          print('DEBUG: Thử $method $path ...');

          if (method == 'put') {
            response = await _apiService.put(path, data: user.toJson());
          } else if (method == 'patch') {
            response = await _apiService.patch(path, data: user.toJson());
          }

          successEndpoint = path;
          successMethod = method;
          print('DEBUG: THÀNH CÔNG! $method $path - status: ${response?.statusCode}');
          print('DEBUG: Response data: ${response?.data}');
          break; // Dừng khi thành công
        } catch (e) {
          print('DEBUG: Thất bại $method $path: $e');
        }
      }

      if (successEndpoint == null) {
        throw Exception('Không tìm thấy endpoint update profile nào hoạt động');
      }

      final updatedUser = UserModel.fromJson(response!.data);
      print('DEBUG: Update thành công qua $successMethod $successEndpoint');

      return {'success': true, 'user': updatedUser};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = e.response?.data?['message'] ?? 'Lỗi server';
      print('ERROR updateProfile: $status - $message');
      print('ERROR full response: ${e.response?.data}');
      return {'success': false, 'message': message};
    } catch (e) {
      print('ERROR updateProfile general: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // Đổi mật khẩu
  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    try {
      // Ensure token loaded into ApiService so request contains Authorization header
      await _apiService.loadToken();
      final response = await _apiService.post('/users/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });

      // Nếu backend trả ok (200)
      return {'success': true, 'message': 'Đổi mật khẩu thành công'};
    } on DioException catch (e) {
      String message = 'Đổi mật khẩu thất bại';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Đã xảy ra lỗi: $e'};
    }
  }
}
