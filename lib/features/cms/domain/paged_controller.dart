import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cms_repository.dart';
import 'cms_models.dart';

class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.page = 0,
    this.totalPages = 0,
    this.query = '',
    this.loading = false,
    this.appending = false,
    this.stale = false,
    this.error,
    this.appendError,
  });

  final List<T> items;
  final int page;
  final int totalPages;
  final String query;
  final bool loading;
  final bool appending;
  final bool stale;
  final Object? error;
  final Object? appendError;

  bool get hasMore => page < totalPages;

  PagedState<T> copyWith({
    List<T>? items,
    int? page,
    int? totalPages,
    String? query,
    bool? loading,
    bool? appending,
    bool? stale,
    Object? error,
    Object? appendError,
    bool clearError = false,
    bool clearAppendError = false,
  }) => PagedState(
    items: items ?? this.items,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    query: query ?? this.query,
    loading: loading ?? this.loading,
    appending: appending ?? this.appending,
    stale: stale ?? this.stale,
    error: clearError ? null : error ?? this.error,
    appendError: clearAppendError ? null : appendError ?? this.appendError,
  );
}

typedef PageLoader<T> =
    Future<PagedResult<T>> Function(
      Ref ref, {
      String? query,
      int page,
      int limit,
      CancelToken? cancelToken,
    });

class PagedController<T> extends Notifier<PagedState<T>> {
  PagedController(this.loader);

  final PageLoader<T> loader;
  CancelToken? _cancelToken;

  void _safeCancel(String reason) {
    final t = _cancelToken;
    if (t != null && !t.isCancelled) t.cancel(reason);
  }

  @override
  PagedState<T> build() {
    ref.onDispose(() => _safeCancel('provider disposed'));
    Future.microtask(loadFirstPage);
    return PagedState<T>();
  }

  Future<void> search(String query) => loadFirstPage(query: query.trim());

  Future<void> reloadAndClear() {
    state = PagedState<T>(query: state.query);
    return loadFirstPage();
  }

  Future<void> loadFirstPage({String? query}) async {
    final nextQuery = query ?? state.query;
    _safeCancel('superseded');
    final token = CancelToken();
    _cancelToken = token;
    state = state.copyWith(
      query: nextQuery,
      loading: true,
      stale: false,
      clearError: true,
      clearAppendError: true,
    );
    try {
      final result = await loader(
        ref,
        query: nextQuery,
        page: 1,
        limit: 20,
        cancelToken: token,
      );
      if (token.isCancelled) return;
      state = PagedState(
        items: result.items,
        page: result.page,
        totalPages: result.totalPages,
        query: nextQuery,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      _setRefreshError(error);
    } catch (error) {
      _setRefreshError(error);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.appending || !state.hasMore) return;
    final token = CancelToken();
    _cancelToken = token;
    state = state.copyWith(appending: true, clearAppendError: true);
    try {
      final result = await loader(
        ref,
        query: state.query,
        page: state.page + 1,
        limit: 20,
        cancelToken: token,
      );
      if (token.isCancelled) return;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        totalPages: result.totalPages,
        appending: false,
        stale: false,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      state = state.copyWith(appending: false, appendError: error);
    } catch (error) {
      state = state.copyWith(appending: false, appendError: error);
    }
  }

  void _setRefreshError(Object error) {
    state = state.copyWith(
      loading: false,
      stale: state.items.isNotEmpty,
      error: error,
    );
  }
}

final newsListProvider =
    NotifierProvider<PagedController<NewsModel>, PagedState<NewsModel>>(
      () => PagedController<NewsModel>(
        (ref, {query, page = 1, limit = 20, cancelToken}) => ref
            .read(cmsRepositoryProvider)
            .getNews(
              query: query,
              page: page,
              limit: limit,
              cancelToken: cancelToken,
            ),
      ),
    );

final documentListProvider =
    NotifierProvider<
      PagedController<CmsDocumentModel>,
      PagedState<CmsDocumentModel>
    >(
      () => PagedController<CmsDocumentModel>(
        (ref, {query, page = 1, limit = 20, cancelToken}) => ref
            .read(cmsRepositoryProvider)
            .getDocuments(
              query: query,
              page: page,
              limit: limit,
              cancelToken: cancelToken,
            ),
      ),
    );

final pdfMapListProvider =
    NotifierProvider<PagedController<PdfMapModel>, PagedState<PdfMapModel>>(
      () => PagedController<PdfMapModel>(
        (ref, {query, page = 1, limit = 20, cancelToken}) => ref
            .read(cmsRepositoryProvider)
            .getPdfMaps(
              query: query,
              page: page,
              limit: limit,
              cancelToken: cancelToken,
            ),
      ),
    );
