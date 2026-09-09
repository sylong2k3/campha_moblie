import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/session_controller.dart';
import '../data/notification_model.dart';
import '../data/notification_repository.dart';

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final session = ref.watch(sessionControllerProvider);
  if (!session.isAuthenticated) return 0;
  final token = CancelToken();
  ref.onDispose(() => token.cancel('notification count disposed'));
  final count = await ref
      .watch(notificationRepositoryProvider)
      .unreadCount(cancelToken: token);
  if (token.isCancelled) return 0;
  return identical(session, ref.read(sessionControllerProvider)) ? count : 0;
});

class NotificationListState {
  final List<NotificationItem> items;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isActing;
  final String? errorMessage;
  final String? actionError;
  final bool hasMore;
  final int page;
  final bool unreadOnly;

  const NotificationListState({
    this.items = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isActing = false,
    this.errorMessage,
    this.actionError,
    this.hasMore = false,
    this.page = 1,
    this.unreadOnly = false,
  });

  NotificationListState copyWith({
    List<NotificationItem>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isActing,
    String? errorMessage,
    String? actionError,
    bool clearError = false,
    bool clearActionError = false,
    bool? hasMore,
    int? page,
    bool? unreadOnly,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isActing: isActing ?? this.isActing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      actionError: clearActionError ? null : actionError ?? this.actionError,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

final notificationListControllerProvider =
    NotifierProvider.autoDispose<
      NotificationListController,
      NotificationListState
    >(NotificationListController.new);

class NotificationListController
    extends AutoDisposeNotifier<NotificationListState> {
  late SessionState _session;
  late CancelToken _lifetime;
  CancelToken? _listToken;
  late Set<CancelToken> _requests;

  @override
  NotificationListState build() {
    _session = ref.watch(sessionControllerProvider);
    final lifetime = _lifetime = CancelToken();
    final requests = _requests = {lifetime};
    ref.onDispose(() {
      for (final token in requests) {
        token.cancel('notification session disposed');
      }
    });
    if (_session.isAuthenticated) {
      Future.microtask(() {
        if (_active(lifetime)) return loadInitial();
      });
    }
    return const NotificationListState();
  }

  bool _active(CancelToken lifetime) =>
      !lifetime.isCancelled &&
      identical(lifetime, _lifetime) &&
      identical(_session, ref.read(sessionControllerProvider)) &&
      _session.isAuthenticated;

  Future<void> loadInitial({bool? unreadOnly}) => _load(unreadOnly: unreadOnly);

  Future<void> refresh() => _load(keepItems: true);

  Future<void> loadMore() => _load(more: true);

  Future<void> _load({
    bool? unreadOnly,
    bool keepItems = false,
    bool more = false,
  }) async {
    final lifetime = _lifetime;
    if (!_active(lifetime) || state.isActing) return;
    if (more &&
        (state.isLoading ||
            state.isRefreshing ||
            state.isLoadingMore ||
            !state.hasMore ||
            state.actionError != null)) {
      return;
    }
    final activeToken = _listToken;
    _listToken = null;
    activeToken?.cancel('notification load superseded');
    final token = _listToken = CancelToken();
    final requests = _requests;
    requests.add(token);
    final filter = unreadOnly ?? state.unreadOnly;
    final page = more ? state.page + 1 : 1;
    state = more
        ? state.copyWith(isLoadingMore: true, clearActionError: true)
        : keepItems
        ? state.copyWith(
            isLoading: false,
            isRefreshing: true,
            isLoadingMore: false,
            clearError: true,
            clearActionError: true,
          )
        : NotificationListState(isLoading: true, unreadOnly: filter);
    try {
      final result = await ref
          .read(notificationRepositoryProvider)
          .list(page: page, limit: 20, unreadOnly: filter, cancelToken: token);
      if (token.isCancelled || !_active(lifetime)) return;
      final byId = <int, NotificationItem>{
        if (more)
          for (final item in state.items) item.id: item,
        for (final item in result.items) item.id: item,
      };
      state = NotificationListState(
        items: byId.values.toList(growable: false),
        hasMore: result.hasMore,
        page: result.page,
        unreadOnly: filter,
      );
      if (!more) ref.invalidate(unreadNotificationCountProvider);
    } catch (error) {
      if (token.isCancelled || !_active(lifetime)) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        errorMessage: more ? null : error.toString(),
        actionError: more ? error.toString() : null,
      );
    } finally {
      requests.remove(token);
    }
  }

  Future<bool> markRead(int id) {
    if (id <= 0) return Future.value(false);
    return _mutate('read', id: id);
  }

  Future<bool> markAllRead() => _mutate('read_all');

  Future<bool> deleteNotification(int id) {
    if (id <= 0) return Future.value(false);
    return _mutate('delete', id: id);
  }

  Future<bool> _mutate(String action, {int? id}) async {
    final lifetime = _lifetime;
    if (!_active(lifetime) || state.isActing) return false;
    final activeListToken = _listToken;
    _listToken = null;
    activeListToken?.cancel('notification mutation started');
    state = state.copyWith(
      isActing: true,
      isLoading: false,
      isRefreshing: false,
      isLoadingMore: false,
      clearActionError: true,
    );
    try {
      final repository = ref.read(notificationRepositoryProvider);
      switch (action) {
        case 'read':
          await repository.markRead(id!, cancelToken: lifetime);
        case 'read_all':
          await repository.markAllRead(cancelToken: lifetime);
        case 'delete':
          await repository.delete(id!, cancelToken: lifetime);
      }
      if (!_active(lifetime)) return false;
      final now = DateTime.now();
      final updated = state.items
          .map((item) {
            return action != 'delete' && (id == null || item.id == id)
                ? item.copyWith(readAt: now)
                : item;
          })
          .where(
            (item) =>
                !(action == 'delete' && item.id == id) &&
                !(state.unreadOnly && item.isRead),
          )
          .toList(growable: false);
      // ponytail: offset pagination resets after writes; use server cursors if preserving deep scroll becomes necessary.
      state = state.copyWith(
        items: updated,
        isActing: false,
        hasMore: false,
        page: 1,
        clearError: true,
        clearActionError: true,
      );
      ref.invalidate(unreadNotificationCountProvider);
      await refresh();
      return true;
    } catch (error) {
      if (_active(lifetime)) {
        state = state.copyWith(isActing: false, actionError: error.toString());
      }
      return false;
    }
  }

  void clearActionError() {
    if (_active(_lifetime)) state = state.copyWith(clearActionError: true);
  }
}
