import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Metadata-only HTTP diagnostics in debug builds.
///
/// Query, headers, body and response/error payloads can contain JWT, phone,
/// precise GPS or media metadata, so they must never reach logs.
class AppLoggingInterceptor extends Interceptor {
  static const _startedAtKey = 'logStartedAt';

  static final _safeErrorCode = RegExp(r'^[A-Z][A-Z0-9_]{0,63}$');

  static String safePath(Uri uri) => uri.path.isEmpty ? '/' : uri.path;

  static List<String> safeErrorCodes(Object? data) {
    if (data is! Map || data['errors'] is! List) return const [];
    return (data['errors'] as List)
        .whereType<String>()
        .where(_safeErrorCode.hasMatch)
        .take(5)
        .toList(growable: false);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now().microsecondsSinceEpoch;
    if (kDebugMode) {
      debugPrint('HTTP ${options.method} ${safePath(options.uri)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final request = response.requestOptions;
      debugPrint(
        'HTTP ${response.statusCode} ${request.method} '
        '${safePath(request.uri)} ${_elapsedMs(request)}ms',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final request = err.requestOptions;
      final codes = safeErrorCodes(err.response?.data);
      final codeSuffix = codes.isEmpty ? '' : ' codes=${codes.join(',')}';
      debugPrint(
        'HTTP ${err.response?.statusCode ?? '-'} ${request.method} '
        '${safePath(request.uri)} ${_elapsedMs(request)}ms '
        '${err.type.name}$codeSuffix',
      );
    }
    handler.next(err);
  }

  static int _elapsedMs(RequestOptions request) {
    final startedAt = request.extra[_startedAtKey];
    if (startedAt is! int) return 0;
    return ((DateTime.now().microsecondsSinceEpoch - startedAt) / 1000).round();
  }
}
