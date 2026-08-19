class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roleCode,
    required this.roleName,
    required this.permissions,
    required this.isActive,
    required this.emailVerified,
    required this.mustChangePassword,
    required this.hasPassword,
    this.phone,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final wrapped = json['user'];
    final user = wrapped is Map
        ? Map<String, dynamic>.from(wrapped)
        : Map<String, dynamic>.from(json);
    final role = user['role'];
    final roleData = role is Map
        ? Map<String, dynamic>.from(role)
        : <String, dynamic>{'code': role?.toString() ?? ''};
    final rawPermissions = roleData['permissions'];

    return UserModel(
      id: user['id']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      fullName:
          user['full_name']?.toString() ?? user['fullName']?.toString() ?? '',
      phone: user['phone']?.toString(),
      avatarUrl:
          user['avatar_url']?.toString() ?? user['avatarUrl']?.toString(),
      roleCode: roleData['code']?.toString() ?? '',
      roleName: roleData['name']?.toString() ?? '',
      permissions: rawPermissions is Map
          ? Map<String, dynamic>.from(rawPermissions)
          : const <String, dynamic>{},
      isActive: user['is_active'] as bool? ?? true,
      emailVerified: user['email_verified'] as bool? ?? false,
      mustChangePassword: user['must_change_password'] as bool? ?? false,
      hasPassword: user['has_password'] as bool? ?? true,
    );
  }

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String roleCode;
  final String roleName;
  final Map<String, dynamic> permissions;
  final bool isActive;
  final bool emailVerified;
  final bool mustChangePassword;
  final bool hasPassword;

  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    String firstRune(String value) => String.fromCharCode(value.runes.first);
    return words.length == 1
        ? firstRune(words.first).toUpperCase()
        : '${firstRune(words.first)}${firstRune(words.last)}'.toUpperCase();
  }

  bool hasPermission(String resource, String action) {
    final resourceValue = permissions[resource];
    if (resourceValue is Map) return resourceValue[action] == true;
    if (resourceValue is List) return resourceValue.contains(action);
    return permissions['$resource.$action'] == true;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'phone': phone,
    'avatar_url': avatarUrl,
    'role': {'code': roleCode, 'name': roleName, 'permissions': permissions},
    'is_active': isActive,
    'email_verified': emailVerified,
    'must_change_password': mustChangePassword,
    'has_password': hasPassword,
  };

  bool get isTnmtAdmin => roleCode == 'so_tnmt';
}
