// lib/models/group_model.dart

enum MemberRole { owner, admin, member }

extension MemberRoleExtension on MemberRole {
  String get displayName {
    switch (this) {
      case MemberRole.owner:
        return 'Trưởng nhóm 👑';
      case MemberRole.admin:
        return 'Quản trị viên 🛡️';
      case MemberRole.member:
        return 'Thành viên 👤';
    }
  }

  String get shortName {
    switch (this) {
      case MemberRole.owner:
        return 'Trưởng nhóm';
      case MemberRole.admin:
        return 'Quản trị';
      case MemberRole.member:
        return 'Thành viên';
    }
  }

  String get icon {
    switch (this) {
      case MemberRole.owner:
        return '👑';
      case MemberRole.admin:
        return '🛡️';
      case MemberRole.member:
        return '👤';
    }
  }
}

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String? avatar;
  final String? ownerId;
  final List<Map<String, dynamic>> members;
  final int memberCount;
  final bool isJoined;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description = '',
    this.avatar,
    this.ownerId,
    this.members = const [],
    required this.memberCount,
    this.isJoined = false,
    this.createdAt,
    this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final membersList = (json['members'] as List<dynamic>?) ?? [];
    final ownerId = json['owner_id'] as String? ?? json['creator_id'] as String?;
    final membersWithRoles = json['membersWithRoles'] as List<dynamic>?;
    
    List<Map<String, dynamic>> members = [];

    if (membersWithRoles != null && membersWithRoles.isNotEmpty) {
      // Backend trả full member info
      members = membersWithRoles
          .map((m) => {
            'userId': m['user_id']?.toString() ?? m['userId']?.toString() ?? '',
            'role': m['role'] ?? 'member',
            'fullName': m['fullName'] ?? m['full_name'] ?? '',
            'avatar': m['avatar'] ?? m['avatar_url'],
            'email': m['email'] ?? '',
          })
          .toList();
    } else if (membersList.isNotEmpty) {
      // Backend trả array of string (user IDs)
      members = membersList
          .map((id) => {
            'userId': id.toString(),
            'role': ownerId == id.toString() ? 'owner' : 'member',
          })
          .toList();
    }

    return GroupModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      avatar: json['avatar_url'] ?? json['avatar'],
      ownerId: ownerId,
      members: members,
      memberCount: json['members_count'] ?? json['memberCount'] ?? membersList.length,
      isJoined: true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'avatar': avatar,
    };
  }

  MemberRole getUserRole(String userId) {
    if (userId == ownerId) return MemberRole.owner;
    
    final member = members.firstWhere(
      (m) => m['userId'] == userId,
      orElse: () => {},
    );
    
    if (member.isEmpty) return MemberRole.member;
    
    final role = member['role'] as String?;
    return MemberRole.values.firstWhere(
      (r) => r.name == role,
      orElse: () => MemberRole.member,
    );
  }

  bool isOwner(String userId) => userId == ownerId;

  bool isAdmin(String userId) {
    final role = getUserRole(userId);
    return role == MemberRole.admin || role == MemberRole.owner;
  }

  bool canManageMembers(String userId) => isAdmin(userId);

  bool canDeleteGroup(String userId) => isOwner(userId);

  bool canEditGroupInfo(String userId) => isAdmin(userId);

  bool canRemoveGrq(String userId) => userId != ownerId;

  List<Map<String, dynamic>> getAdmins() {
    return members
        .where((m) {
          final role = m['role'] as String?;
          return role == 'admin' || m['userId'] == ownerId;
        })
        .toList();
  }

  List<Map<String, dynamic>> getRegularMembers() {
    return members
        .where((m) {
          final role = m['role'] as String?;
          return role == 'member' && m['userId'] != ownerId;
        })
        .toList();
  }
}
