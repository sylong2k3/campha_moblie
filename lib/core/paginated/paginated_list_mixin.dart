import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_exception.dart';
import 'page_size.dart';
import 'paginated_state.dart';

/// Kết quả 1 trang từ repository — item mới của trang + còn trang sau hay
/// không (`pagination.hasNextPage` phía server).
typedef PageResult<T> = ({List<T> items, bool hasMore});

/// Logic dùng chung cho controller danh sách phân trang kiểu infinite-scroll
/// có filter + search debounce: trang đầu qua `build()`, tải thêm qua
/// [loadMore], luôn tải lại từ trang 1 khi đổi filter/search để không bỏ sót
/// kết quả nằm ngoài các trang đã tải.
///
/// Subclass chỉ cần cài đặt [fetchPage] gọi đúng repository của mình, ví dụ:
/// ```dart
/// class NewsController extends AutoDisposeAsyncNotifier<PaginatedState<News, NewsStatus>>
///     with PaginatedListMixin<News, NewsStatus> {
///   @override
///   Future<PaginatedState<News, NewsStatus>> build() => buildFirstPage();
///
///   @override
///   Future<PageResult<News>> fetchPage({
///     required int page,
///     required int limit,
///     NewsStatus? filter,
///     required String query,
///   }) async {
///     final result = await ref
///         .read(newsRepositoryProvider)
///         .fetchPage(page: page, limit: limit, status: filter, query: query);
///     return (items: result.items, hasMore: result.hasMore);
///   }
/// }
/// ```
mixin PaginatedListMixin<T, F>
    on AutoDisposeAsyncNotifier<PaginatedState<T, F>> {
  int _requestRevision = 0;

  int _invalidatePendingRequests() => ++_requestRevision;

  bool _isCurrentRequest(int revision) => revision == _requestRevision;

  Future<void> _replaceWithLatest(
    Future<PaginatedState<T, F>> Function() request,
  ) async {
    final revision = _invalidatePendingRequests();
    state = AsyncLoading<PaginatedState<T, F>>().copyWithPrevious(state);
    try {
      final result = await request();
      if (_isCurrentRequest(revision)) {
        state = AsyncData(result);
      }
    } catch (error, stackTrace) {
      if (_isCurrentRequest(revision)) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  int get pageSize => defaultPageSize;

  Future<PageResult<T>> fetchPage({
    required int page,
    required int limit,
    F? filter,
    required String query,
  });

  /// Dùng trong `build()` của subclass. Mỗi lần dependency (như locale)
  /// thay đổi, revision mới vô hiệu mọi request đang chạy với dữ liệu cũ.
  Future<PaginatedState<T, F>> buildFirstPage() {
    _invalidatePendingRequests();
    return fetchFirstPage();
  }

  Future<PaginatedState<T, F>> fetchFirstPage({
    bool clearFilter = false,
    F? filter,
  }) async {
    final current = state.valueOrNull;
    final effectiveFilter = clearFilter ? null : (filter ?? current?.filter);
    final effectiveQuery = current?.searchQuery ?? '';

    final result = await fetchPage(
      page: 1,
      limit: pageSize,
      filter: effectiveFilter,
      query: effectiveQuery,
    );
    return PaginatedState<T, F>(
      items: result.items,
      page: 1,
      hasMore: result.hasMore,
      filter: effectiveFilter,
      searchQuery: effectiveQuery,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final revision = _requestRevision;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final result = await fetchPage(
        page: nextPage,
        limit: pageSize,
        filter: current.filter,
        query: current.searchQuery,
      );
      if (!_isCurrentRequest(revision)) return;
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...result.items],
          page: nextPage,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } on AppException {
      if (_isCurrentRequest(revision)) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> refresh() => _replaceWithLatest(fetchFirstPage);

  /// `null` nghĩa là bỏ lọc, xem tất cả.
  Future<void> updateFilter(F? filter) {
    return _replaceWithLatest(
      () => fetchFirstPage(clearFilter: filter == null, filter: filter),
    );
  }

  Future<void> updateSearchQuery(String value) async {
    final current = state.valueOrNull;
    final query = value.trim();
    if (current?.searchQuery == query) return;
    await _replaceWithLatest(() async {
      final result = await fetchPage(
        page: 1,
        limit: pageSize,
        filter: current?.filter,
        query: query,
      );
      return PaginatedState<T, F>(
        items: result.items,
        page: 1,
        hasMore: result.hasMore,
        filter: current?.filter,
        searchQuery: query,
      );
    });
  }
}
