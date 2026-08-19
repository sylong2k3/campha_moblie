import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/cms_models.dart';

final cmsRepositoryProvider = Provider<CmsRepository>(
  (ref) => CmsRepository(dio: ref.watch(dioProvider)),
);

class CmsRepository {
  const CmsRepository({required this.dio});

  final Dio dio;

  Future<PagedResult<NewsModel>> getNews({
    String? query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) => _paged(
    () => dio.get(
      ApiEndpoints.cmsNews,
      queryParameters: _paging(query, page, limit),
      cancelToken: cancelToken,
    ),
    NewsModel.fromJson,
  );

  Future<NewsModel> getNewsDetail(String id) =>
      _item(() => dio.get(ApiEndpoints.cmsNewsDetail(id)), NewsModel.fromJson);

  Future<PagedResult<NewsComment>> getComments(
    String newsId, {
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) => _paged(
    () => dio.get(
      ApiEndpoints.cmsNewsComments(newsId),
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
    ),
    NewsComment.fromJson,
  );

  Future<NewsComment> createComment(String newsId, String content) => _item(
    () => dio.post(
      ApiEndpoints.cmsNewsComments(newsId),
      data: {'content': content.trim()},
    ),
    NewsComment.fromJson,
  );

  Future<PagedResult<CmsDocumentModel>> getDocuments({
    String? query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) => _paged(
    () => dio.get(
      ApiEndpoints.cmsDocuments,
      queryParameters: _paging(query, page, limit),
      cancelToken: cancelToken,
    ),
    CmsDocumentModel.fromJson,
  );

  Future<CmsDocumentModel> getDocumentDetail(String id) => _item(
    () => dio.get(ApiEndpoints.cmsDocumentDetail(id)),
    CmsDocumentModel.fromJson,
  );

  Future<DownloadGrant> getDocumentDownloadGrant(
    String id, {
    int expireSeconds = 300,
  }) => _item(
    () => dio.get(
      ApiEndpoints.cmsDocumentDownload(id),
      queryParameters: {'expireSeconds': expireSeconds},
    ),
    DownloadGrant.fromJson,
  );

  Future<PagedResult<PdfMapModel>> getPdfMaps({
    String? query,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) => _paged(
    () => dio.get(
      ApiEndpoints.cmsPdfMaps,
      queryParameters: _paging(query, page, limit),
      cancelToken: cancelToken,
    ),
    PdfMapModel.fromJson,
  );

  Future<PdfMapModel> getPdfMapDetail(String id) => _item(
    () => dio.get(ApiEndpoints.cmsPdfMapDetail(id)),
    PdfMapModel.fromJson,
  );

  Future<DownloadGrant> getPdfMapDownloadGrant(
    String id, {
    int expireSeconds = 300,
  }) => _item(
    () => dio.get(
      ApiEndpoints.cmsPdfMapDownload(id),
      queryParameters: {'expireSeconds': expireSeconds},
    ),
    DownloadGrant.fromJson,
  );

  Map<String, dynamic> _paging(String? query, int page, int limit) => {
    if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    'page': page,
    'limit': limit,
  };

  Future<PagedResult<T>> _paged<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request();
      final envelope = _responseMap(response.data);
      return PagedResult.fromEnvelope(envelope, fromJson);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw mapErrorToAppException(error);
    } on FormatException {
      throw const UnknownException('Phản hồi máy chủ không đúng định dạng');
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<T> _item<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request();
      return fromJson(envelopeDataMap(response.data));
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw mapErrorToAppException(error);
    } on FormatException {
      throw const UnknownException('Phản hồi máy chủ không đúng định dạng');
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Map<String, dynamic> _responseMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry('$key', value));
    }
    throw const FormatException('Response is not an object');
  }
}
