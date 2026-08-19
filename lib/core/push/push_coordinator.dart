import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../app/router/route_names.dart';
import '../../features/auth/domain/session_controller.dart';
import '../../features/field_reports/data/field_report_repository.dart';
import 'push_service.dart';

final appPushCoordinatorProvider = Provider<PushService>((ref) {
  void openMessage(Map<String, dynamic> data) {
    final raw = data['reportId']?.toString();
    final id = int.tryParse(raw ?? '');
    if (id == null || id <= 0) return;
    ref.read(appRouterProvider).go(RoutePaths.reportDetail('$id'));
  }

  final service = PushService(
    onRegisterToken: (token, platform) =>
        ref.read(fieldReportRepositoryProvider).registerDevice(token, platform),
    onUnregisterToken: (token) =>
        ref.read(fieldReportRepositoryProvider).unregisterDevice(token),
    onMessageTap: openMessage,
  );
  unawaited(service.attach());

  String? previousOwner;
  final subscription = ref.listen<SessionState>(sessionControllerProvider, (
    _,
    next,
  ) {
    final owner = next.user?.id;
    if (owner != null && owner != previousOwner) {
      unawaited(service.registerDevice());
    }
    previousOwner = owner;
  }, fireImmediately: true);

  ref.onDispose(() {
    subscription.close();
    unawaited(service.dispose());
  });
  return service;
});
