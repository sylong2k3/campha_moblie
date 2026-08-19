import 'dart:async';

import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';
import '../api_config.dart';
import '../api_endpoints.dart';

/// Gắn `Authorization` (nếu đã đăng nhập) hoặc `x-anonymous-id` (khách),
/// và tự refresh token khi gặp 401.
///
/// Refresh chỉ chạy 1 lần cho nhiều request 401 song song (mutex bằng
/// [Completer] dùng chung); refresh thất bại → xoá token và bắn
/// [onUnauthorized] để lớp trên điều hướng về màn đăng nhập.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenStorage,
    required this.readAnonymousId,
    required this.onUnauthorized,
    Dio? refreshDio,
  }) : _refreshDio =
           refreshDio ??
           Dio(
             BaseOptions(
               baseUrl: ApiConfig.baseUrl,
               connectTimeout: ApiConfig.connectTimeout,
             ),
           );

  final TokenStorage tokenStorage;
  final Future<String> Function() readAnonymousId;
  final FutureOr<void> Function() onUnauthorized;
  final Dio _refreshDio;

  Completer<String?>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    } else {
      options.headers['x-anonymous-id'] = await readAnonymousId();
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final requestPath = err.requestOptions.path;

    if (!isUnauthorized ||
        _doesNotRefresh(requestPath) ||
        err.requestOptions.extra['authRetried'] == true) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshToken();
    if (newAccessToken == null) {
      await onUnauthorized();
      handler.next(err);
      return;
    }

    try {
      final retryOptions = err.requestOptions;
      retryOptions.extra['authRetried'] = true;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final data = retryOptions.data;
      if (data is FormData) retryOptions.data = data.clone();
      final response = await _refreshDio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _doesNotRefresh(String path) {
    return path.contains(ApiEndpoints.authRefresh) ||
        path.contains(ApiEndpoints.authLogin) ||
        path.contains(ApiEndpoints.authRegister) ||
        path.contains(ApiEndpoints.authForgotPassword) ||
        path.contains(ApiEndpoints.authResetPassword) ||
        path.contains(ApiEndpoints.authVerifyEmail) ||
        path.contains(ApiEndpoints.authResendVerification) ||
        path.contains(ApiEndpoints.authGoogleMobile) ||
        path.contains(ApiEndpoints.authOauthExchange);
  }

  /// Đảm bảo nhiều request 401 song song chỉ trigger 1 lần gọi refresh.
  Future<String?> _refreshToken() {
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    () async {
      try {
        final refreshToken = await tokenStorage.readRefreshToken();
        if (refreshToken == null) {
          completer.complete(null);
          return;
        }
        final response = await _refreshDio.post<Map<String, dynamic>>(
          ApiEndpoints.authRefresh,
          data: {'refreshToken': refreshToken},
        );
        final envelope = response.data;
        final data = envelope?['data'];
        if (data is! Map<String, dynamic>) {
          throw const FormatException('Refresh response thiếu data.');
        }
        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];
        if (newAccessToken is! String ||
            newAccessToken.isEmpty ||
            newRefreshToken is! String ||
            newRefreshToken.isEmpty) {
          throw const FormatException('Refresh response thiếu token.');
        }
        await tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        completer.complete(newAccessToken);
      } catch (_) {
        await tokenStorage.clear();
        if (!completer.isCompleted) completer.complete(null);
      } finally {
        _refreshCompleter = null;
      }
    }();

    return completer.future;
  }
}
