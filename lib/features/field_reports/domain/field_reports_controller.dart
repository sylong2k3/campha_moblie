import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/session_controller.dart';
import '../../tools/domain/field_tools_models.dart';
import '../data/field_report_repository.dart';
import 'field_report_models.dart';

class ReportFilter {
  const ReportFilter({
    this.status,
    this.from,
    this.to,
    this.nearbyLocation,
    this.radiusMeters = 100,
  });
  final String? status;
  final DateTime? from;
  final DateTime? to;
  final GeoCoordinate? nearbyLocation;
  final int radiusMeters;

  ReportFilter copyWith({
    String? status,
    bool clearStatus = false,
    DateTime? from,
    DateTime? to,
    GeoCoordinate? nearbyLocation,
    bool clearNearby = false,
    int? radiusMeters,
  }) => ReportFilter(
    status: clearStatus ? null : status ?? this.status,
    from: from ?? this.from,
    to: to ?? this.to,
    nearbyLocation: clearNearby ? null : nearbyLocation ?? this.nearbyLocation,
    radiusMeters: radiusMeters ?? this.radiusMeters,
  );
}

class FieldReportsState {
  const FieldReportsState({
    this.items = const [],
    this.nearbyItems = const [],
    this.filter = const ReportFilter(),
    this.page = 0,
    this.totalPages = 0,
    this.loading = false,
    this.appending = false,
    this.stale = false,
    this.error,
  });
  final List<FieldReport> items;
  final List<FieldReport> nearbyItems;
  final ReportFilter filter;
  final int page;
  final int totalPages;
  final bool loading;
  final bool appending;
  final bool stale;
  final Object? error;
  bool get hasMore => page < totalPages;

  FieldReportsState copyWith({
    List<FieldReport>? items,
    List<FieldReport>? nearbyItems,
    ReportFilter? filter,
    int? page,
    int? totalPages,
    bool? loading,
    bool? appending,
    bool? stale,
    Object? error,
    bool clearError = false,
  }) => FieldReportsState(
    items: items ?? this.items,
    nearbyItems: nearbyItems ?? this.nearbyItems,
    filter: filter ?? this.filter,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    loading: loading ?? this.loading,
    appending: appending ?? this.appending,
    stale: stale ?? this.stale,
    error: clearError ? null : error ?? this.error,
  );
}

class FieldReportsController extends Notifier<FieldReportsState> {
  CancelToken? _cancelToken;

  void _safeCancel(String reason) {
    final t = _cancelToken;
    if (t != null && !t.isCancelled) t.cancel(reason);
  }

  @override
  FieldReportsState build() {
    final ownerId = ref.watch(
      sessionControllerProvider.select((session) => session.user?.id),
    );
    ref.onDispose(() => _safeCancel('provider disposed'));
    Future.microtask(() {
      if (ownerId == ref.read(sessionControllerProvider).user?.id) {
        loadFirstPage();
      }
    });
    return const FieldReportsState();
  }

  Future<void> setStatus(String? status) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        status: status,
        clearStatus: status == null,
      ),
    );
    if (state.filter.nearbyLocation != null) return Future.value();
    return loadFirstPage();
  }

  Future<void> setNearby({
    required GeoCoordinate location,
    required DateTime from,
    required DateTime to,
    int radiusMeters = 100,
  }) async {
    state = state.copyWith(
      filter: state.filter.copyWith(
        nearbyLocation: location,
        from: from,
        to: to,
        radiusMeters: radiusMeters,
      ),
      loading: true,
      clearError: true,
    );
    final token = _replaceToken();
    try {
      final items = await ref
          .read(fieldReportRepositoryProvider)
          .getNearby(
            location: location,
            from: from,
            to: to,
            radiusMeters: radiusMeters,
            cancelToken: token,
          );
      if (!token.isCancelled) {
        state = state.copyWith(nearbyItems: items, loading: false);
      }
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) _setError(error);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> clearNearby() async {
    _safeCancel('nearby filter cleared');
    state = state.copyWith(
      nearbyItems: const [],
      filter: state.filter.copyWith(clearNearby: true),
      loading: false,
      appending: false,
      stale: false,
      clearError: true,
    );
  }

  Future<void> refresh() {
    final filter = state.filter;
    final location = filter.nearbyLocation;
    if (location == null || filter.from == null || filter.to == null) {
      return loadFirstPage();
    }
    return setNearby(
      location: location,
      from: filter.from!,
      to: filter.to!,
      radiusMeters: filter.radiusMeters,
    );
  }

  void clearSensitiveState() {
    _safeCancel('session ended');
    state = const FieldReportsState();
  }

  Future<void> loadFirstPage() async {
    final token = _replaceToken();
    state = state.copyWith(loading: true, stale: false, clearError: true);
    try {
      final result = await ref
          .read(fieldReportRepositoryProvider)
          .getPublic(status: state.filter.status, page: 1, cancelToken: token);
      if (token.isCancelled) return;
      state = FieldReportsState(
        items: result.items,
        filter: state.filter,
        page: result.page,
        totalPages: result.totalPages,
      );
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) _setError(error);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> loadMore() async {
    if (state.filter.nearbyLocation != null ||
        state.loading ||
        state.appending ||
        !state.hasMore) {
      return;
    }
    final token = _replaceToken();
    state = state.copyWith(appending: true, clearError: true);
    try {
      final result = await ref
          .read(fieldReportRepositoryProvider)
          .getPublic(
            status: state.filter.status,
            page: state.page + 1,
            cancelToken: token,
          );
      if (token.isCancelled) return;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        totalPages: result.totalPages,
        appending: false,
      );
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) {
        state = state.copyWith(appending: false, error: error);
      }
    } catch (error) {
      state = state.copyWith(appending: false, error: error);
    }
  }

  CancelToken _replaceToken() {
    _safeCancel('superseded');
    return _cancelToken = CancelToken();
  }

  void _setError(Object error) {
    state = state.copyWith(
      loading: false,
      appending: false,
      stale: state.items.isNotEmpty,
      error: error,
    );
  }
}

final fieldReportsProvider =
    NotifierProvider<FieldReportsController, FieldReportsState>(
      FieldReportsController.new,
    );

class MyReportsController extends Notifier<FieldReportsState> {
  CancelToken? _cancelToken;

  void _safeCancel(String reason) {
    final t = _cancelToken;
    if (t != null && !t.isCancelled) t.cancel(reason);
  }

  @override
  FieldReportsState build() {
    final ownerId = ref.watch(
      sessionControllerProvider.select((session) => session.user?.id),
    );
    ref.onDispose(() => _safeCancel('provider disposed'));
    if (ownerId != null) Future.microtask(loadFirstPage);
    return const FieldReportsState();
  }

  String? get _owner => ref.read(sessionControllerProvider).user?.id;

  Future<void> setStatus(String? status) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        status: status,
        clearStatus: status == null,
      ),
    );
    return loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    final owner = _owner;
    if (owner == null) return;
    _safeCancel('superseded');
    final token = _cancelToken = CancelToken();
    state = state.copyWith(loading: true, clearError: true);
    try {
      final result = await ref
          .read(fieldReportRepositoryProvider)
          .getMine(status: state.filter.status, page: 1, cancelToken: token);
      if (!token.isCancelled && owner == _owner) {
        state = FieldReportsState(
          items: result.items,
          page: result.page,
          totalPages: result.totalPages,
          filter: state.filter,
        );
      }
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error) && owner == _owner) {
        state = state.copyWith(loading: false, error: error);
      }
    } catch (error) {
      if (owner == _owner) state = state.copyWith(loading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    final owner = _owner;
    if (owner == null || state.loading || state.appending || !state.hasMore) {
      return;
    }
    final token = _cancelToken = CancelToken();
    state = state.copyWith(appending: true, clearError: true);
    try {
      final result = await ref
          .read(fieldReportRepositoryProvider)
          .getMine(
            status: state.filter.status,
            page: state.page + 1,
            cancelToken: token,
          );
      if (!token.isCancelled && owner == _owner) {
        state = state.copyWith(
          items: [...state.items, ...result.items],
          page: result.page,
          totalPages: result.totalPages,
          appending: false,
        );
      }
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error) && owner == _owner) {
        state = state.copyWith(appending: false, error: error);
      }
    } catch (error) {
      if (owner == _owner) {
        state = state.copyWith(appending: false, error: error);
      }
    }
  }

  Future<void> delete(FieldReport report) async {
    final owner = _owner;
    if (owner == null) return;
    try {
      await ref
          .read(fieldReportRepositoryProvider)
          .delete(report.id, report.updatedAt);
      if (owner == _owner) {
        state = state.copyWith(
          items: state.items
              .where((item) => item.id != report.id)
              .toList(growable: false),
        );
        await loadFirstPage();
      }
    } catch (error) {
      if (owner == _owner) state = state.copyWith(error: error);
      rethrow;
    }
  }
}

final myReportsProvider =
    NotifierProvider<MyReportsController, FieldReportsState>(
      MyReportsController.new,
    );
