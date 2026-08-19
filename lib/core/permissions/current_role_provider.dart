import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_role.dart';

/// Vai trò hiện tại của phiên làm việc. Mặc định [UserRole.guest] cho tới khi
/// feature `auth` cập nhật sau khi `GET /auth/me` trả về.
/// `keepAlive: true` (Provider thường không tự dispose theo widget) — phải
/// sống xuyên suốt app, không phụ thuộc widget nào đang watch.
class CurrentRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.guest;

  void set(UserRole role) => state = role;

  void reset() => state = UserRole.guest;
}

final currentRoleProvider = NotifierProvider<CurrentRoleNotifier, UserRole>(
  CurrentRoleNotifier.new,
);
