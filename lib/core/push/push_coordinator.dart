import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../app/router/route_names.dart';
import '../../features/auth/domain/session_controller.dart';
import '../../features/field_reports/data/field_report_repository.dart';
import '../../features/field_reports/domain/field_reports_controller.dart';
import '../../features/notifications/data/notification_model.dart';
import '../../features/notifications/domain/notification_controller.dart';
import 'push_service.dart';

final appPushCoordinatorProvider = Provider<PushService>((ref) {
  var disposed = false;
  void refreshNotifications() {
    if (disposed || !ref.read(sessionControllerProvider).isAuthenticated) {
      return;
    }
    ref.invalidate(unreadNotificationCountProvider);
    if (ref.exists(notificationListControllerProvider)) {
      unawaited(
        ref.read(notificationListControllerProvider.notifier).refresh(),
      );
    }
  }

  void refreshReports() {
    if (disposed || !ref.read(fieldReportAccessProvider).canRead) return;
    if (ref.exists(fieldReportsProvider)) {
      unawaited(ref.read(fieldReportsProvider.notifier).refresh());
    }
  }

  void openMessage(Map<String, dynamic> data) {
    if (disposed) return;
    final id = notificationReportId(data);
    ref
        .read(appRouterProvider)
        .go(
          id == null ? RoutePaths.notifications : RoutePaths.reportDetail(id),
        );
  }

  final service = PushService(
    onRegisterToken: (token, platform) =>
        ref.read(fieldReportRepositoryProvider).registerDevice(token, platform),
    onUnregisterToken: (token) =>
        ref.read(fieldReportRepositoryProvider).unregisterDevice(token),
    registrationSession: () {
      if (disposed) return null;
      final session = ref.read(sessionControllerProvider);
      return session.isAuthenticated ? session : null;
    },
    onMessageTap: openMessage,
    onForegroundMessage: (data) {
      refreshNotifications();
      if (notificationReportId(data) != null) refreshReports();
    },
  );
  unawaited(service.attach());

  Future<void> register() async {
    final registered = await service.registerDevice();
    if (!registered && !disposed) {
      // ponytail: retry on resume/token rotation, not a background retry timer.
    }
  }

  final subscription = ref.listen<SessionState>(sessionControllerProvider, (
    previous,
    next,
  ) {
    if (!identical(previous, next)) service.sessionChanged();
    if (next.isAuthenticated) unawaited(register());
  }, fireImmediately: true);

  final lifecycle = AppLifecycleListener(
    onResume: () {
      if (ref.read(sessionControllerProvider).isAuthenticated) {
        unawaited(register());
        refreshNotifications();
        refreshReports();
      }
    },
  );

  ref.onDispose(() {
    disposed = true;
    lifecycle.dispose();
    subscription.close();
    unawaited(service.dispose());
  });
  return service;
});
