import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../auth/domain/session_controller.dart';
import '../../tools/domain/field_tools_models.dart';
import '../data/field_report_repository.dart';
import 'field_report_models.dart';

typedef FieldReportAccess = ({
  String? ownerId,
  String? roleCode,
  bool canRead,
  bool canReview,
  bool canStats,
});

final fieldReportAccessProvider = Provider<FieldReportAccess>((ref) {
  final session = ref.watch(sessionControllerProvider);
  final user =
      session.isAuthenticated &&
          session.user?.isActive == true &&
          session.user?.mustChangePassword == false
      ? session.user
      : null;
  return (
    ownerId: user?.id,
    roleCode: user?.roleCode,
    canRead: user?.canReadFieldReports ?? false,
    canReview: user?.canReviewFieldReports ?? false,
    canStats: user?.canViewFieldReportStats ?? false,
  );
});

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
    this.admin = false,
    this.mapMode = false,
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
  final bool admin;
  final bool mapMode;
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
    bool? mapMode,
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
    admin: admin,
    mapMode: mapMode ?? this.mapMode,
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
  int _generation = 0;
  bool _mapMode = false;

  void _safeCancel(String reason) {
    final t = _cancelToken;
    if (t != null && !t.isCancelled) t.cancel(reason);
  }

  @override
  FieldReportsState build() {
    final access = ref.watch(
      fieldReportAccessProvider.select((value) => value),
    );
    _safeCancel('access changed');
    final generation = ++_generation;
    ref.onDispose(() {
      _generation++;
      _safeCancel('provider disposed');
    });
    Future.microtask(() {
      if (generation == _generation) loadFirstPage();
    });
    return FieldReportsState(admin: access.canRead, mapMode: _mapMode);
  }

  Future<void> setAdminView(bool admin) {
    if (admin && !ref.read(fieldReportAccessProvider).canRead) {
      throw const ForbiddenException();
    }
    if (state.admin == admin) return Future.value();
    _safeCancel('report scope changed');
    state = FieldReportsState(admin: admin, mapMode: _mapMode);
    return loadFirstPage();
  }

  Future<void> setMapMode(bool mapMode) {
    if (_mapMode == mapMode) return Future.value();
    _mapMode = mapMode;
    state = state.copyWith(mapMode: mapMode);
    if (state.filter.nearbyLocation != null) return Future.value();
    if (state.loading ||
        state.appending ||
        (mapMode && (state.hasMore || state.page == 0))) {
      return loadFirstPage();
    }
    return Future.value();
  }

  Future<FieldReportPage> _getPage(
    int page,
    CancelToken token, {
    int limit = 20,
  }) {
    final repository = ref.read(fieldReportRepositoryProvider);
    return state.admin
        ? repository.getAdmin(
            status: state.filter.status,
            page: page,
            limit: limit,
            cancelToken: token,
          )
        : repository.getPublic(
            status: state.filter.status,
            page: page,
            limit: limit,
            cancelToken: token,
          );
  }

  Future<void> setStatus(String? status) {
    if (status != null &&
        (!fieldReportStatuses.contains(status) ||
            (!state.admin && status != 'approved' && status != 'resolved'))) {
      throw ArgumentError('Invalid report status filter');
    }
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
    if (state.admin) throw const ForbiddenException();
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
      if (!token.isCancelled) _setError(error);
    } catch (error) {
      if (!token.isCancelled) _setError(error);
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
    if (_mapMode) await loadFirstPage();
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

  void applyReviewedReport(FieldReport report) {
    if (!state.admin) return;
    final status = state.filter.status;
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id != report.id)
            item
          else if (status == null || status == report.status)
            report,
      ],
    );
  }

  void clearSensitiveState() {
    _safeCancel('session ended');
    state = FieldReportsState(mapMode: _mapMode);
  }

  Future<void> loadFirstPage() async {
    final token = _replaceToken();
    state = state.copyWith(
      loading: true,
      appending: false,
      stale: false,
      clearError: true,
    );
    try {
      final limit = _mapMode ? 100 : 20;
      var page = 1;
      final items = <String, FieldReport>{};
      late FieldReportPage result;
      // ponytail: API caps pages at 100; batch markers once, use server tiles
      // if the full report dataset outgrows device memory.
      do {
        result = await _getPage(page, token, limit: limit);
        if (token.isCancelled) return;
        if (result.page != page || (result.hasMore && result.items.isEmpty)) {
          throw const FormatException('Invalid field report pagination');
        }
        for (final report in result.items) {
          items[report.id] = report;
        }
        page++;
      } while (_mapMode && result.hasMore);
      state = FieldReportsState(
        admin: state.admin,
        mapMode: _mapMode,
        items: items.values.toList(growable: false),
        filter: state.filter,
        page: result.page,
        totalPages: result.totalPages,
      );
    } on DioException catch (error) {
      if (!token.isCancelled) _setError(error);
    } catch (error) {
      if (!token.isCancelled) _setError(error);
    }
  }

  Future<void> loadMore() async {
    if (_mapMode ||
        state.filter.nearbyLocation != null ||
        state.loading ||
        state.appending ||
        !state.hasMore) {
      return;
    }
    final token = _replaceToken();
    state = state.copyWith(appending: true, clearError: true);
    try {
      final result = await _getPage(state.page + 1, token);
      if (token.isCancelled) return;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        totalPages: result.totalPages,
        appending: false,
      );
    } on DioException catch (error) {
      if (!token.isCancelled) _setError(error);
    } catch (error) {
      if (!token.isCancelled) _setError(error);
    }
  }

  CancelToken _replaceToken() {
    _safeCancel('superseded');
    return _cancelToken = CancelToken();
  }

  void _setError(Object error) {
    final status = error is DioException
        ? error.response?.statusCode
        : error is AppException
        ? error.statusCode
        : null;
    if (state.admin && (status == 401 || status == 403)) {
      state = FieldReportsState(
        admin: true,
        mapMode: _mapMode,
        filter: state.filter,
        error: error,
      );
      return;
    }
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
