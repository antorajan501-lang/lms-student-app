import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final int roleId;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String? about;
  final String? jobTitle;

  const UserModel({
    required this.id,
    required this.roleId,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.about,
    this.jobTitle,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // ── Resolve role ────────────────────────────────────────────────────────
    int resolvedRoleId = 3; // default to Student
    final rawRole = json['role'];
    if (rawRole is Map) {
      resolvedRoleId = (rawRole['id'] as num?)?.toInt() ?? 3;
    } else if (json['role_id'] is num) {
      resolvedRoleId = (json['role_id'] as num).toInt();
    }

    // ── Resolve nested vs flat structure ────────────────────────────────────
    // /user-detail returns: { id, basic_info: { name, email, phone, image }, about: { biography, job_title }, ... }
    // /login returns flat:  { id, name, email, ... }
    final basicInfo = json['basic_info'] is Map<String, dynamic>
        ? json['basic_info'] as Map<String, dynamic>
        : null;
    final aboutInfo = json['about'] is Map<String, dynamic>
        ? json['about'] as Map<String, dynamic>
        : null;

    // Prefer nested fields; fall back to root-level for login responses
    String name = '';
    if (basicInfo != null) {
      name = (basicInfo['name'] as String?)?.trim() ?? '';
    }
    if (name.isEmpty) {
      name = (json['name'] as String?)?.trim() ?? '';
    }

    String email = '';
    if (basicInfo != null) {
      email = (basicInfo['email'] as String?)?.trim() ?? '';
    }
    if (email.isEmpty) {
      email = (json['email'] as String?)?.trim() ?? '';
    }

    String? phone;
    if (basicInfo != null) {
      final rawPhone = basicInfo['phone'];
      phone = rawPhone is String && rawPhone.isNotEmpty ? rawPhone : null;
    }
    phone ??= json['phone'] is String ? (json['phone'] as String?) : null;

    // Avatar — nested basic_info.image or root avatar/photo/image
    String? avatar;
    if (basicInfo != null) {
      final img = basicInfo['image'];
      avatar = img is String && img.isNotEmpty ? img : null;
    }
    avatar ??= json['avatar'] is String
        ? json['avatar'] as String?
        : json['photo'] is String
            ? json['photo'] as String?
            : json['image'] is String
                ? json['image'] as String?
                : null;
    if (avatar != null && avatar.isEmpty) avatar = null;

    // About / biography
    String? about;
    if (aboutInfo != null) {
      final bio = aboutInfo['biography'];
      about = bio is String && bio.isNotEmpty ? bio : null;
    }
    about ??= json['about'] is String ? json['about'] as String? : null;
    about ??= json['about_me'] is String ? json['about_me'] as String? : null;

    // Job title
    String? jobTitle;
    if (aboutInfo != null) {
      final jt = aboutInfo['job_title'];
      jobTitle = jt is String && jt.isNotEmpty ? jt : null;
    }
    jobTitle ??= json['job_title'] is String ? json['job_title'] as String? : null;

    return UserModel(
      id: (json['id'] as num).toInt(),
      roleId: resolvedRoleId,
      name: name,
      email: email,
      phone: phone,
      avatar: avatar,
      about: about,
      jobTitle: jobTitle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_id': roleId,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'about': about,
      'job_title': jobTitle,
    };
  }

  String? get profilePhoto => avatar;

  @override
  List<Object?> get props => [id, roleId, name, email, phone, avatar, about, jobTitle];
}
