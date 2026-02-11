// lib/providers/group_provider.dart

import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';
import 'auth_provider.dart';

class GroupProvider with ChangeNotifier {
  final GroupService _groupService = GroupService();
  List<GroupModel> _myGroups = [];
  List<GroupModel> _suggestedGroups = [];
  GroupModel? _currentGroup;
  List<Map<String, dynamic>> _groupMembers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<GroupModel> get myGroups => _myGroups;
  List<GroupModel> get suggestedGroups => _suggestedGroups;
  GroupModel? get currentGroup => _currentGroup;
  List<Map<String, dynamic>> get groupMembers => _groupMembers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchGroups({AuthProvider? authProvider, bool isRetry = false}) async {
    if (_isLoading && !isRetry) {
      print('📌 GroupProvider: Đang loading, bỏ qua request...');
      return;
    }

    // ✅ Kiểm tra xem user đã xác thực chưa
    if (authProvider != null && !authProvider.isAuthenticated) {
      print('🔴 GroupProvider: User chưa xác thực');
      _errorMessage = '🔐 Vui lòng đăng nhập để xem danh sách nhóm';
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (!isRetry) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      print('🟢 GroupProvider: Bắt đầu fetchGroups()...');
    }

    final result = await _groupService.getGroups();

    if (result['success'] == true) {
      _myGroups = result['myGroups'] as List<GroupModel>? ?? [];
      _suggestedGroups = result['suggestedGroups'] as List<GroupModel>? ?? [];
      _errorMessage = null;
      print('✅ GroupProvider: Đã tải ${_myGroups.length} groups của tôi + ${_suggestedGroups.length} suggested groups');
    } else {
      _errorMessage = result['message'] ?? 'Không thể tải danh sách nhóm';
      print('🔴 GroupProvider: ${_errorMessage}');
    }

    _isLoading = false;
    notifyListeners();
    print('✅ GroupProvider: Hoàn thành fetchGroups()');
  }

  Future<Map<String, dynamic>> createGroup(String name, String description, String? avatar) async {
    _isLoading = true;
    notifyListeners();

    final result = await _groupService.createGroup(name, description, avatar);

    // Không cần fetch ở đây nữa vì screen sẽ tự fetch sau khi tạo thành công
    
    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Các hàm khác: joinGroup, leaveGroup, addMember, removeMember, transferOwnership, etc.
  Future<Map<String, dynamic>> joinGroup(String groupId) async {
    final result = await _groupService.joinGroup(groupId);
    if (result['success']) await fetchGroups();
    return result;
  }

  Future<Map<String, dynamic>> leaveGroup(String groupId) async {
    final result = await _groupService.leaveGroup(groupId);
    if (result['success']) await fetchGroups();
    return result;
  }

  Future<Map<String, dynamic>> addMember(String groupId, String userId) async {
    final result = await _groupService.addMember(groupId, userId);
    return result;
  }

  Future<Map<String, dynamic>> removeMember(String groupId, String userId) async {
    final result = await _groupService.removeMember(groupId, userId);
    return result;
  }

  Future<Map<String, dynamic>> transferOwnership(String groupId, String newOwnerId) async {
    final result = await _groupService.transferOwnership(groupId, newOwnerId);
    if (result['success']) await fetchGroups();
    return result;
  }

  Future<Map<String, dynamic>> fetchGroupDetail(String groupId) async {
    _isLoading = true;
    notifyListeners();

    final result = await _groupService.getGroupDetail(groupId);

    if (result['success']) {
      _currentGroup = result['group'] as GroupModel;
      _groupMembers = result['members'] as List<Map<String, dynamic>>? ?? [];
      _errorMessage = null;
    } else {
      _errorMessage = result['message'] ?? 'Không thể tải chi tiết group';
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> updateGroupMemberRole(String groupId, String userId, String role) async {
    final result = await _groupService.updateMemberRole(groupId, userId, role);
    if (result['success']) {
      // Update local state if needed
      await fetchGroupDetail(groupId);
    }
    return result;
  }

  Future<Map<String, dynamic>> deleteGroup(String groupId) async {
    final result = await _groupService.deleteGroup(groupId);
    if (result['success']) await fetchGroups();
    return result;
  }

  Future<Map<String, dynamic>> updateGroupInfo(
      String groupId, String name, String description, String? avatar) async {
    final result = await _groupService.updateGroup(groupId, name, description, avatar);
    if (result['success']) await fetchGroupDetail(groupId);
    return result;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}