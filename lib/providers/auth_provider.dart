// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

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

      if (token != null && userJson != null) {
        _token = token;
        _user = UserModel.fromJson(jsonDecode(userJson));

        // Verify token với API
        final result = await _authService.getMe();
        if (result['success']) {
          _user = result['user'];
          _status = AuthStatus.authenticated;
          // Cập nhật user data
          await _saveUserData(_user!);
        } else {
          // Token không hợp lệ
          await _clearUserData();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      print('Error in checkAuthStatus: $e');
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
}
