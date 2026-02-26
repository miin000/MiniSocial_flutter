// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // Constructor - kiểm tra trạng thái đăng nhập
  AuthProvider() {
    checkAuthStatus();
  }

  // Kiểm tra trạng thái đăng nhập khi khởi động app
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('user_data');

      // Ưu tiên load user từ local trước (fake update sẽ được giữ)
      if (userJson != null) {
        _user = UserModel.fromJson(jsonDecode(userJson));
        print('DEBUG AuthProvider: Load user từ local SharedPreferences - bio: ${_user?.bio}, job: ${_user?.job}, location: ${_user?.location}');
      }

      if (token != null && userJson != null) {
        _token = token;

        // Verify token với API (nếu fail thì giữ local user)
        final result = await _authService.getMe();
        if (result['success']) {
          _user = result['user'];
          await _saveUserData(_user!); // Cập nhật lại nếu API trả user mới
          print('DEBUG AuthProvider: Verify API thành công - cập nhật user từ server');
        } else {
          print('DEBUG AuthProvider: Verify API fail, giữ user local');
          // Không clear user, giữ fake local
        }
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      print('ERROR in checkAuthStatus: $e');
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // Đăng nhập
  Future<bool> login(String identifier, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(identifier, password);

    if (result['success']) {
      _user = result['user'];
      _token = result['token'];
      _status = AuthStatus.authenticated;

      // Lưu user data
      await _saveUserData(_user!);

      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Đăng ký
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String fullName,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      email: email,
      username: username,
      fullName: fullName,
      password: password,
    );

    _status = AuthStatus.unauthenticated;
    if (!result['success']) {
      _errorMessage = result['message'];
    }
    notifyListeners();

    return result;
  }

  Future<Map<String, dynamic>> updateProfile(UserModel updatedUser) async {
    final result = await _authService.updateProfile(updatedUser);
    if (result['success']) {
      _user = result['user'];
      await _saveUserData(_user!);
      notifyListeners();
    }
    return result;
  }

  // Đổi mật khẩu
  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    _status = AuthStatus.loading;
    notifyListeners();

    final result = await _authService.changePassword(oldPassword, newPassword);

    if (result['success']) {
      // Lưu mật khẩu mới vào secure storage
      final secure = SecureStorageService();
      await secure.savePassword(newPassword);
    }

    _status = isAuthenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
    return result;
  }

  // Đăng xuất
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _authService.logout();
    await _clearUserData();

    // ✅ CLEAR TOKEN KHỎI API SERVICE
    final apiService = ApiService();
    apiService.clearToken();

    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Lưu user data vào SharedPreferences
  Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  // Xóa user data
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('auth_token');
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Thêm method này để cập nhật user cục bộ (fake khi backend chưa hỗ trợ)
  void updateLocalUser(UserModel updatedUser) {
    _user = updatedUser;
    // Lưu lại vào SharedPreferences để giữ khi reload app
    _saveUserData(updatedUser);
    notifyListeners();
    print('DEBUG AuthProvider: Đã cập nhật local user thành công - bio: ${updatedUser.bio}, job: ${updatedUser.job}, location: ${updatedUser.location}');
  }
}
