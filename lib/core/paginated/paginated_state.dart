/// State dùng chung cho mọi danh sách phân trang có filter + search — xem
/// [PaginatedListMixin].
///
/// [T] là kiểu item, [F] là kiểu filter (enum trạng thái/loại/chủ đề tuỳ
/// feature). `filter == null` nghĩa là không lọc, xem tất cả.
class PaginatedState<T, F> {
  const PaginatedState({
    required this.items,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.filter,
    this.searchQuery = '',
  });

  final List<T> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final F? filter;
  final String searchQuery;

  /// Chỉ dùng để cập nhật `items`/`page`/`hasMore`/`isLoadingMore` khi tải
  /// thêm trang — đổi `filter`/`searchQuery` luôn tạo state mới trực tiếp
  /// (xem [PaginatedListMixin.fetchFirstPage]) nên không cần ở đây.
  PaginatedState<T, F> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginatedState<T, F>(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filter: filter,
      searchQuery: searchQuery,
    );
  }
}
