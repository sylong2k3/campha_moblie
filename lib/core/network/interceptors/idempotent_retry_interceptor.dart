import 'dart:async';

import 'package:dio/dio.dart';

/// Retry đúng một lần cho GET khi lỗi kết nối/timeout/502/503.
/// Request ghi và multipart không bao giờ tự retry.
class IdempotentRetryInterceptor extends Interceptor {
  IdempotentRetryInterceptor(this._dio);

  static const _retryKey = 'idempotent_retry_count';
  final Dio _dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final count = options.extra[_retryKey] as int? ?? 0;
    if (options.method.toUpperCase() != 'GET' ||
        count >= 1 ||
        !_retryable(err)) {
      handler.next(err);
      return;
    }

    options.extra[_retryKey] = count + 1;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    try {
      handler.resolve(await _dio.fetch(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _retryable(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse =>
        error.response?.statusCode == 502 || error.response?.statusCode == 503,
      _ => false,
    };
  }
}
