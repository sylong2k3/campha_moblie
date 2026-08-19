import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/locale/locale_controller.dart';
import '../storage/token_storage.dart';
import 'anonymous_id_provider.dart';
import 'api_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/idempotent_retry_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// dio singleton dùng cho toàn app — mọi repository lấy qua provider này
/// thay vì tự tạo Dio riêng.
///
/// `onUnauthorized` chỉ xoá token cục bộ (core không biết gì về feature
/// `auth` chưa tồn tại) — khi feature `auth` được xây, nó tự watch
/// [tokenStorageProvider]/điều hướng theo state của nó, không cần sửa lại
/// provider này.
final dioProvider = Provider<Dio>((ref) {
  final languageCode = ref.watch(localeControllerProvider).languageCode;
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Accept-Language': languageCode,
        'Content-Type': 'application/json',
      },
    ),
  );

  final tokenStorage = ref.watch(tokenStorageProvider);

  dio.interceptors.addAll([
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Accept-Language'] = languageCode;
        handler.next(options);
      },
    ),
    AuthInterceptor(
      tokenStorage: tokenStorage,
      readAnonymousId: () => ref.read(anonymousIdProvider.future),
      onUnauthorized: () => tokenStorage.clear(),
    ),
    IdempotentRetryInterceptor(dio),
    AppLoggingInterceptor(),
  ]);

  return dio;
}, name: 'dioProvider');
