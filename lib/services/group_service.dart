// lib/services/group_service.dart

import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/group_model.dart';

class GroupService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> createGroup(String name, String description, String? avatar, {String? ownerId}) async {
    try {
      print('🔍 GroupService: Creating group - name: $name');
      final data = {
        'name': name,
        'description': description,
        'avatar_url': avatar,
        if (ownerId != null) 'owner_id': ownerId,
      };
      final response = await _apiService.post('/groups', data: data);
      print('✅ GroupService: Group created successfully');
      return {
        'success': true,
        'message': 'Tạo nhóm thành công!',
        'group': response.data
      };
    } on DioException catch (e) {
      print('❌ GroupService: DioException creating group: ${e.message} (Status: ${e.response?.statusCode})');
      print('❌ GroupService: Response data: ${e.response?.data}');
      
      String message = 'Lỗi tạo nhóm';
      if (e.response?.statusCode == 401) {
        message = '🔐 Phiên hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.response?.statusCode == 403) {
        message = '⚠️ Bạn không có quyền tạo nhóm.';
      } else if (e.response?.statusCode == 400) {
        message = '❌ Dữ liệu không hợp lệ. Kiểm tra tên và mô tả.';
      } else if (e.response?.statusCode == 500) {
        message = '⚠️ Lỗi máy chủ. Vui lòng thử lại sau.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      
      return {
        'success': false,
        'message': message,
        'statusCode': e.response?.statusCode,
        'error': e.message,
      };
    } catch (e) {
      print('❌ GroupService: Unexpected error creating group: $e');
      return {
        'success': false,
        'message': 'Lỗi không xác định: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getGroups() async {
    try {
      print('🔍 GroupService: Calling API GET /groups');
      final response = await _apiService.get('/groups');

      print('✅ GroupService: Response status code: ${response.statusCode}');
      print('✅ GroupService: Response data: ${response.data}');

      List<dynamic> myGroupsJson = [];
      List<dynamic> suggestedGroupsJson = [];

      // Xử lý cả hai format: object hoặc array
      if (response.data is List) {
        // API trả về array trực tiếp
        print('📊 GroupService: Response is List, treating as myGroups');
        myGroupsJson = response.data as List<dynamic>;
      } else if (response.data is Map) {
        // API trả về object với keys myGroups và suggestedGroups
        print('📊 GroupService: Response is Map, extracting myGroups and suggestedGroups');
        myGroupsJson = response.data['myGroups'] as List<dynamic>? ?? [];
        suggestedGroupsJson = response.data['suggestedGroups'] as List<dynamic>? ?? [];
      }

      print('📊 GroupService: myGroupsJson length: ${myGroupsJson.length}');
      print('📊 GroupService: suggestedGroupsJson length: ${suggestedGroupsJson.length}');

      // In thử 1 item nếu có để kiểm tra cấu trúc
      if (myGroupsJson.isNotEmpty) {
        print('📌 GroupService: First myGroup item: ${myGroupsJson.first}');
      }
      if (suggestedGroupsJson.isNotEmpty) {
        print('📌 GroupService: First suggestedGroup item: ${suggestedGroupsJson.first}');
      }

      final myGroups = myGroupsJson
          .map((g) => GroupModel.fromJson(g as Map<String, dynamic>))
          .toList();

      final suggestedGroups = suggestedGroupsJson
          .map((g) => GroupModel.fromJson(g as Map<String, dynamic>))
          .toList();

      print('✅ GroupService: Parsed ${myGroups.length} myGroups and ${suggestedGroups.length} suggestedGroups');

      return {
        'success': true,
        'myGroups': myGroups,
        'suggestedGroups': suggestedGroups,
      };
    } on DioException catch (e) {
      print('❌ GroupService: DioException: ${e.message} (Status: ${e.response?.statusCode})');
      print('❌ GroupService: Response data: ${e.response?.data}');
      
      String message = 'Lỗi khi tải danh sách nhóm (${e.response?.statusCode})';
      if (e.response?.statusCode == 403) {
        message = '⚠️ Không có quyền truy cập. Vui lòng đăng nhập lại.';
      } else if (e.response?.statusCode == 401) {
        message = '🔐 Phiên hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      
      return {
        'success': false,
        'message': message,
        'statusCode': e.response?.statusCode,
      };
    } catch (e) {
      print('❌ GroupService: Unexpected error: $e');
      return {
        'success': false,
        'message': 'Lỗi không xác định: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> joinGroup(String groupId) async {
    try {
      await _apiService.post('/groups/$groupId/join');
      return {'success': true, 'message': 'Tham gia nhóm thành công!'};
    } on DioException catch (e) {
      String message = 'Lỗi tham gia nhóm';
      if (e.response?.statusCode == 403) {
        message = '⚠️ Không thể tham gia nhóm này.';
      } else if (e.response?.statusCode == 401) {
        message = '🔐 Phiên hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {'success': false, 'message': message, 'statusCode': e.response?.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi tham gia: $e'};
    }
  }

  Future<Map<String, dynamic>> leaveGroup(String groupId) async {
    try {
      await _apiService.post('/groups/$groupId/leave');
      return {'success': true, 'message': 'Rời nhóm thành công!'};
    } on DioException catch (e) {
      String message = 'Lỗi rời nhóm';
      if (e.response?.statusCode == 403) {
        message = '⚠️ Trưởng nhóm không thể rời nhóm. Hãy chuyển quyền trước.';
      } else if (e.response?.statusCode == 401) {
        message = '🔐 Phiên hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {'success': false, 'message': message, 'statusCode': e.response?.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi rời nhóm: $e'};
    }
  }

  Future<Map<String, dynamic>> addMember(String groupId, String userId) async {
    try {
      await _apiService.post('/groups/$groupId/members', data: {'userId': userId});
      return {'success': true, 'message': 'Thêm thành viên thành công!'};
    } on DioException catch (e) {
      String message = 'Lỗi thêm thành viên';
      if (e.response?.statusCode == 403) {
        message = '⚠️ Bạn không có quyền thêm thành viên.';
      } else if (e.response?.statusCode == 401) {
        message = '🔐 Phiên hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.response?.statusCode == 400) {
        message = '❌ Người dùng này không tồn tại hoặc đã là thành viên.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {'success': false, 'message': message, 'statusCode': e.response?.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi thêm thành viên: $e'};
    }
  }

  Future<Map<String, dynamic>> removeMember(String groupId, String userId) async {
    try {
      await _apiService.delete('/groups/$groupId/members/$userId');
      return {'success': true, 'message': 'Xóa thành viên thành công!'};
    } on DioException catch (e) {
      String message = 'Lỗi xóa thành viên';
      if (e.response?.statusCode == 403) {
        message = '⚠️ Bạn không có quyền xóa thành viên này.';
      } else if (e.response?.statusCode == 401) {
        message = '🔐 Phiên hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.response?.statusCode == 400) {
        message = '❌ Không thể xóa trưởng nhóm.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {'success': false, 'message': message, 'statusCode': e.response?.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi xóa thành viên: $e'};
    }
  }

  Future<Map<String, dynamic>> transferOwnership(String groupId, String newOwnerId) async {
    try {
      await _apiService.put('/groups/$groupId/ownership', data: {'newOwnerId': newOwnerId});
      return {'success': true, 'message': 'Chuyển quyền thành công!'};
    } on DioException catch (e) {
      String message = 'Lỗi chuyển quyền';
      if (e.response?.statusCode == 403) {
        message = '⚠️ Bạn không có quyền chuyển quyền.';
      } else if (e.response?.statusCode == 401) {
        message = '🔐 Phiên hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.response?.statusCode == 400) {
        message = '❌ Người dùng này không phải là thành viên của nhóm.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {'success': false, 'message': message, 'statusCode': e.response?.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi chuyển quyền: $e'};
    }
  }

  Future<Map<String, dynamic>> getGroupDetail(String groupId) async {
    try {
      final response = await _apiService.get('/groups/$groupId');

      // Backend returns { group: {...}, members: [...], userRole: '...', isMember: bool }
      final data = response.data;
      print('🔍 GroupService getGroupDetail: data keys = ${data is Map ? data.keys.toList() : data.runtimeType}');
      print('🔍 GroupService getGroupDetail: members = ${data is Map ? data['members']?.runtimeType : "n/a"}, count = ${data is Map && data['members'] is List ? (data['members'] as List).length : 0}');

      final groupJson = (data is Map && data['group'] != null)
          ? Map<String, dynamic>.from(data['group'] as Map)
          : (data is Map ? Map<String, dynamic>.from(data as Map) : <String, dynamic>{});

      final membersRaw = (data is Map && data['members'] is List)
          ? data['members'] as List<dynamic>
          : <dynamic>[];

      final userRole = data is Map ? (data['userRole']?.toString()) : null;

      final group = GroupModel.fromJson(groupJson);
      // Use Map.from() to safely convert each member from LinkedHashMap to Map<String, dynamic>
      final members = membersRaw
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();

      return {
        'success': true,
        'group': group,
        'members': members,
        'userRole': userRole,
      };
    } on DioException catch (e) {
      String message = 'Lỗi tải chi tiết nhóm';
      if (e.response?.statusCode == 403) {
        message = '⚠️ Không có quyền xem nhóm này.';
      } else if (e.response?.statusCode == 401) {
        message = '🔐 Phiên hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.response?.statusCode == 404) {
        message = '❌ Nhóm không tồn tại.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {'success': false, 'message': message, 'statusCode': e.response?.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi tải chi tiết nhóm: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMemberRole(String groupId, String userId, String role) async {
    try {
      await _apiService.put(
        '/groups/$groupId/members/$userId/role',
        data: {'role': role},
      );
      return {'success': true, 'message': 'Cập nhật vai trò thành công!'};
    } on DioException catch (e) {
      String message = 'Lỗi cập nhật vai trò';
      if (e.response?.statusCode == 403) {
        message = '⚠️ Bạn không có quyền cập nhật vai trò.';
      } else if (e.response?.statusCode == 401) {
        message = '🔐 Phiên hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.response?.statusCode == 400) {
        message = '❌ Vai trò không hợp lệ.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {'success': false, 'message': message, 'statusCode': e.response?.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi cập nhật vai trò: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteGroup(String groupId) async {
    try {
      await _apiService.delete('/groups/$groupId');
      return {'success': true, 'message': 'Xóa nhóm thành công!'};
    } on DioException catch (e) {
      String message = 'Lỗi xóa nhóm';
      if (e.response?.statusCode == 403) {
        message = '⚠️ Chỉ trưởng nhóm mới có thể xóa nhóm.';
      } else if (e.response?.statusCode == 401) {
        message = '🔐 Phiên hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {'success': false, 'message': message, 'statusCode': e.response?.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi xóa nhóm: $e'};
    }
  }

  Future<Map<String, dynamic>> updateGroup(
      String groupId, String name, String description, String? avatar) async {
    try {
      final data = {
        'name': name,
        'description': description,
        if (avatar != null) 'avatar_url': avatar,
      };
      final response = await _apiService.put('/groups/$groupId', data: data);
      return {
        'success': true,
        'message': 'Cập nhật nhóm thành công!',
        'group': response.data
      };
    } on DioException catch (e) {
      String message = 'Lỗi cập nhật nhóm';
      if (e.response?.statusCode == 403) {
        message = '⚠️ Bạn không có quyền cập nhật nhóm này.';
      } else if (e.response?.statusCode == 401) {
        message = '🔐 Phiên hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.response?.statusCode == 400) {
        message = '❌ Dữ liệu không hợp lệ.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      return {'success': false, 'message': message, 'statusCode': e.response?.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi cập nhật nhóm: $e'};
    }
  }


// Thêm hàm cho getGroupDetail, updateGroup, etc. nếu cần
}