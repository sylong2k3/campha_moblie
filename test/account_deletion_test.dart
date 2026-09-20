import 'package:campha_moblie/core/network/api_config.dart';
import 'package:campha_moblie/core/network/api_endpoints.dart';
import 'package:campha_moblie/core/storage/token_storage.dart';
import 'package:campha_moblie/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_secure_storage.dart';

class _FakeDioAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{"success": true, "data": {}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('Apple App Store Guideline Compliance', () {
    test('ApiConfig provides valid HTTPS Privacy Policy and Terms of Service URLs', () {
      expect(ApiConfig.privacyPolicyUrl, startsWith('https://'));
      expect(ApiConfig.termsOfServiceUrl, startsWith('https://'));
      expect(Uri.tryParse(ApiConfig.privacyPolicyUrl)?.hasAuthority, isTrue);
      expect(Uri.tryParse(ApiConfig.termsOfServiceUrl)?.hasAuthority, isTrue);
    });

    test('AuthRepository.deleteAccount calls DELETE /auth/me and clears tokens', () async {
      final secureStorage = MemorySecureStorage();
      final tokenStorage = TokenStorage(secureStorage);
      await tokenStorage.saveTokens(
        accessToken: 'valid-access-token',
        refreshToken: 'valid-refresh-token',
      );

      final dio = Dio();
      final adapter = _FakeDioAdapter();
      dio.httpClientAdapter = adapter;

      final repo = AuthRepository(
        dio: dio,
        tokenStorage: tokenStorage,
      );

      await repo.deleteAccount();

      expect(adapter.lastRequest, isNotNull);
      expect(adapter.lastRequest!.method, 'DELETE');
      expect(adapter.lastRequest!.path, ApiEndpoints.authMe);
      expect(await tokenStorage.readAccessToken(), isNull);
      expect(await tokenStorage.readRefreshToken(), isNull);
    });
  });
}
