import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../auth/domain/session_controller.dart';
import '../../domain/notification_controller.dart';

bool _bellNavigating = false;

class NotificationBellButton extends ConsumerWidget {
  final Color? color;

  const NotificationBellButton({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticated = ref.watch(
      sessionControllerProvider.select((session) => session.isAuthenticated),
    );
    final result = authenticated
        ? ref.watch(unreadNotificationCountProvider)
        : null;
    final count = result != null && !result.isLoading && !result.hasError
        ? result.valueOrNull ?? 0
        : 0;

    return IconButton(
      tooltip: context.l10n.notificationsTitle,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(Icons.notifications_outlined, color: color),
      ),
      onPressed: () {
        if (_bellNavigating) return;
        _bellNavigating = true;
        context.push(RoutePaths.notifications).whenComplete(() {
          _bellNavigating = false;
        });
      },
    );
  }
}
