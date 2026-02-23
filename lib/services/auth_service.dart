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
      final response = await _apiService.put('/users/${user.id}', data: user.toJson());
      return {'success': true, 'user': UserModel.fromJson(response.data)};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? 'Lỗi cập nhật profile'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
