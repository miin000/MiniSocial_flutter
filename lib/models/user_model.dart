class UserModel {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final List<String>? rolesAdmin;
  final List<String>? rolesGroup;
  final String? avatar;
  final String? cover;
  final String? bio;
  final String? job;
  final String? location;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.rolesAdmin,
    this.rolesGroup,
    this.avatar,
    this.cover,
    this.bio,
    this.job,
    this.location,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? json['_id']?.toString() ?? '',
      email: json['email'] ?? '',
      username: json['username'],
      fullName: json['fullName'] ?? json['full_name'],
      rolesAdmin: json['roles_admin'] != null ? List<String>.from(json['roles_admin']) : null,
      rolesGroup: json['roles_group'] != null ? List<String>.from(json['roles_group']) : null,
      avatar: json['avatar'],
      cover: json['cover'] ?? json['cover_url'],  // ← THÊM
      bio: json['bio'],
      job: json['job'],
      location: json['location'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,  // ← THÊM
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'roles_admin': rolesAdmin,
      'roles_group': rolesGroup,
      'avatar': avatar,
      'cover': cover,     // ← THÊM
      'bio': bio,
      'job': job,
      'location': location,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    List<String>? rolesAdmin,
    List<String>? rolesGroup,
    String? avatar,
    String? cover,
    String? bio,
    String? job,
    String? location,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      rolesAdmin: rolesAdmin ?? this.rolesAdmin,
      rolesGroup: rolesGroup ?? this.rolesGroup,
      avatar: avatar ?? this.avatar,
      cover: cover ?? this.cover,
      bio: bio ?? this.bio,
      job: job ?? this.job,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}