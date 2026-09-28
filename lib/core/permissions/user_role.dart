/// Vai trò backend hiện hành; enum phục vụ nhãn và fallback UI bảo thủ.
/// UserModel tính capability phía ứng dụng; backend quyết định quyền thực thi.
enum UserRole {
  guest,
  citizen,
  ubndTp,
  soTnmt,
  soXd,
  systemAdmin;

  static UserRole fromApiValue(String? value) {
    return switch (value) {
      'citizen' => UserRole.citizen,
      'ubnd_tp' => UserRole.ubndTp,
      'so_tnmt' => UserRole.soTnmt,
      'so_xd' => UserRole.soXd,
      'system_admin' => UserRole.systemAdmin,
      _ => UserRole.guest,
    };
  }
}

extension UserRoleX on UserRole {
  bool get isAuthenticated => this != UserRole.guest;

  bool get canReadUsers =>
      this == UserRole.systemAdmin ||
      this == UserRole.ubndTp ||
      this == UserRole.soTnmt;
  bool get canCreateUser =>
      this == UserRole.systemAdmin || this == UserRole.soTnmt;
  bool get canUpdateUser =>
      this == UserRole.systemAdmin || this == UserRole.soTnmt;
  bool get canDeleteUser => this == UserRole.systemAdmin;
  bool get canResetUserPassword =>
      this == UserRole.systemAdmin || this == UserRole.soTnmt;
  bool get canChangeUserRole => this == UserRole.systemAdmin;
  bool get canChangeUserStatus =>
      this == UserRole.systemAdmin || this == UserRole.soTnmt;

  bool get canManageOwnProfile => isAuthenticated;
  bool get canManageRoles => this == UserRole.systemAdmin;
  bool get canViewSystemLogs => this == UserRole.systemAdmin;
  bool get canManageSystemLogs => this == UserRole.systemAdmin;

  /// Văn bản/bản đồ PDF gắn `visibility: internal` chỉ dành cho cán bộ;
  /// citizen/guest chỉ thấy nội dung `public`.
  bool get canViewInternalDocuments =>
      this == UserRole.systemAdmin ||
      this == UserRole.ubndTp ||
      this == UserRole.soTnmt ||
      this == UserRole.soXd;
}
