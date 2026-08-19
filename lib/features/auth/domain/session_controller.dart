import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/push/push_coordinator.dart';
import '../../../core/storage/token_storage.dart';
import '../../cms/domain/paged_controller.dart';
import '../../feature_edit/data/offline_edit_queue.dart';
import '../../feature_edit/domain/feature_sync_controller.dart';
import '../../field_reports/domain/field_reports_controller.dart';
import '../../field_reports/domain/report_composer_controller.dart';
import '../../map/domain/map_controller.dart';
import '../../tools/domain/field_tools_controller.dart';
import '../data/auth_repository.dart';
import 'auth_result.dart';
import 'user_model.dart';

enum SessionStatus { bootstrapping, guest, authenticated, verificationRequired }

class SessionState {
  const SessionState({
    required this.status,
    this.user,
    this.verificationEmail,
    this.error,
  });

  const SessionState.bootstrapping()
    : this(status: SessionStatus.bootstrapping);
  const SessionState.guest({Object? error})
    : this(status: SessionStatus.guest, error: error);
  const SessionState.authenticated(UserModel user)
    : this(status: SessionStatus.authenticated, user: user);
  const SessionState.verificationRequired(String email)
    : this(
        status: SessionStatus.verificationRequired,
        verificationEmail: email,
      );

  final SessionStatus status;
  final UserModel? user;
  final String? verificationEmail;
  final Object? error;

  bool get isAuthenticated => status == SessionStatus.authenticated;
  bool get isBootstrapping => status == SessionStatus.bootstrapping;
}

class SessionController extends Notifier<SessionState> {
  late final TokenStorage _tokenStorage;
  bool _cleaningSession = false;
  Future<OfflineEditQueue>? _ownerQueue;

  @override
  SessionState build() {
    _tokenStorage = ref.watch(tokenStorageProvider);
    _tokenStorage.addClearListener(_onTokensCleared);
    ref.onDispose(() => _tokenStorage.removeClearListener(_onTokensCleared));
    Future.microtask(bootstrap);
    return const SessionState.bootstrapping();
  }

  Future<void> bootstrap() async {
    state = const SessionState.bootstrapping();
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        state = const SessionState.guest();
        return;
      }
      final user = await ref.read(authRepositoryProvider).getMe();
      state = SessionState.authenticated(user);
    } on UnauthorizedException catch (error) {
      final ownerId = state.user?.id;
      state = SessionState.guest(error: error);
      await _clearLocalSession(ownerId);
    } on AppException catch (error) {
      // Không giả authenticated khi chưa xác minh được token với server.
      state = SessionState.guest(error: error);
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    state = SessionState.authenticated(result.user);
    return result;
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .register(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
        );
    state = result.requiresVerification
        ? SessionState.verificationRequired(email)
        : SessionState.authenticated(result.user);
    return result;
  }

  Future<String> forgotPassword(String email) =>
      ref.read(authRepositoryProvider).forgotPassword(email);

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final ownerId = state.user?.id;
    await ref
        .read(authRepositoryProvider)
        .changePassword(oldPassword: oldPassword, newPassword: newPassword);
    _ownerQueue = ownerId == null
        ? null
        : ref.read(offlineEditQueueProvider.future);
    state = const SessionState.guest();
    await _clearLocalSession(ownerId);
  }

  Future<void> logout() async {
    final ownerId = state.user?.id;
    _ownerQueue = ownerId == null
        ? null
        : ref.read(offlineEditQueueProvider.future);
    try {
      await ref.read(appPushCoordinatorProvider).unregisterDevice();
    } catch (_) {
      // Logout local vẫn phải hoàn tất khi unregister push lỗi.
    }
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Server logout best effort; token và dữ liệu local vẫn bị xóa bên dưới.
    } finally {
      await _clearLocalSession(ownerId);
    }
  }

  void continueAsGuest() => state = const SessionState.guest();

  void _onTokensCleared() {
    final ownerId = state.user?.id;
    if (state.status == SessionStatus.authenticated) {
      final queue = ownerId == null
          ? null
          : ref.read(offlineEditQueueProvider.future);
      state = const SessionState.guest();
      if (!_cleaningSession) {
        unawaited(_clearOwnerData(ownerId, queue: queue));
      }
    }
  }

  Future<void> _clearLocalSession(String? ownerId) async {
    state = const SessionState.guest();
    _cleaningSession = true;
    try {
      await _tokenStorage.clear();
    } finally {
      try {
        await _clearOwnerData(ownerId, queue: _ownerQueue);
      } finally {
        _ownerQueue = null;
        _cleaningSession = false;
      }
    }
  }

  Future<void> _clearOwnerData(
    String? ownerId, {
    Future<OfflineEditQueue>? queue,
  }) async {
    if (ownerId != null) {
      try {
        await (await (queue ?? ref.read(offlineEditQueueProvider.future)))
            .purgeOwner(ownerId);
      } catch (_) {
        // ponytail: local DB cleanup is best effort; app startup cleanup can retry after a corrupt/unavailable DB is repaired.
      }
    }
    try {
      await ref.read(reportComposerProvider.notifier).clear();
    } catch (_) {
      // Draft metadata/media cleanup must not block logout.
    }
    for (final cleanup in <void Function()>[
      () => ref.invalidate(reportComposerProvider),
      () => ref.invalidate(myReportsProvider),
      () => ref.invalidate(featureSyncProvider),
      () => ref.invalidate(documentListProvider),
      () => ref.invalidate(pdfMapListProvider),
      () => ref.invalidate(mapCatalogProvider),
      () => ref.read(fieldReportsProvider.notifier).clearSensitiveState(),
      () => ref.read(fieldToolsProvider.notifier).clearSensitiveState(),
    ]) {
      try {
        cleanup();
      } catch (_) {
        // Mỗi cache/state riêng tư được dọn độc lập.
      }
    }
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
