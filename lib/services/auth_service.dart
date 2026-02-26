// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/firebase_config.dart' show isFirebaseInitialized;
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
    await signOutFirebase();
    await _apiService.removeToken();
  }

  // Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    await _apiService.loadToken();
    return _apiService.hasToken;
  }

  // Lấy Firebase Custom Token từ backend và sign in Firebase Auth
  // Để Firestore security rules hoạt động (xác thực user_id)
  Future<void> signInFirebase() async {
    if (!isFirebaseInitialized) return;
    try {
      final response = await _apiService.get('/auth/firebase-token');
      final firebaseToken = response.data['firebaseToken'];
      if (firebaseToken != null) {
        await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);
        debugPrint('Firebase Auth signed in successfully');
      }
    } catch (e) {
      // Không block login nếu Firebase Auth fail
      // Firestore listener sẽ fallback sang REST API
      debugPrint('Firebase Auth sign-in failed: $e');
    }
  }

  // Đăng xuất Firebase Auth
  Future<void> signOutFirebase() async {
    if (!isFirebaseInitialized) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Firebase Auth sign-out failed: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile(UserModel user) async {
    try {
      // Use PATCH /users/profile (no user ID in URL) with backend field names
      final data = <String, dynamic>{};
      if (user.fullName != null) data['full_name'] = user.fullName;
      if (user.bio != null) data['bio'] = user.bio;
      if (user.job != null) data['job'] = user.job;
      if (user.location != null) data['location'] = user.location;
      if (user.avatar != null) data['avatar_url'] = user.avatar;
      if (user.cover != null) data['cover_url'] = user.cover;

      final response = await _apiService.patch('/users/profile', data: data);
      return {'success': true, 'user': UserModel.fromJson(response.data)};
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
