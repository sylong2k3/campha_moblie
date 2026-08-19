import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'current_role_provider.dart';
import 'user_role.dart';

/// Chỉ hiển thị [child] nếu vai trò hiện tại nằm trong [roles];
/// ngược lại hiển thị [fallback] (mặc định `SizedBox.shrink`).
class RoleGate extends ConsumerWidget {
  const RoleGate({
    super.key,
    required this.roles,
    required this.child,
    this.fallback,
  });

  final List<UserRole> roles;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    if (roles.contains(role)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
