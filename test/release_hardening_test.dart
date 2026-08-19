import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campha_moblie/core/network/api_config.dart';
import 'package:campha_moblie/core/network/interceptors/idempotent_retry_interceptor.dart';
import 'package:campha_moblie/core/network/interceptors/logging_interceptor.dart';

void main() {
  group('release config validation', () {
    test('accepts HTTPS API and optional WSS/public client values', () {
      expect(
        ApiConfig.validateForRelease(
          apiBaseUrl: 'https://api.campha.gov.vn/api/v1',
          geoserverBaseUrl: 'https://maps.campha.gov.vn/geoserver',
          notificationsWebSocketUrl: 'wss://api.campha.gov.vn/notifications',
          mapboxAccessToken: 'pk.public-client-token-1234567890',
          googleOAuthClientId: 'mobile.apps.googleusercontent.com',
          timeoutSeconds: 30,
          accuracyThresholdM: 10,
        ),
        isNull,
      );
    });

    test('rejects local, cleartext and invalid websocket config', () {
      expect(
        ApiConfig.validateForRelease(
          apiBaseUrl: 'http://localhost:3006/api/v1',
          mapboxAccessToken: '',
          timeoutSeconds: 30,
          accuracyThresholdM: 10,
        ),
        contains('HTTPS'),
      );
      expect(
        ApiConfig.validateForRelease(
          apiBaseUrl: 'https://127.0.0.1/api/v1',
          mapboxAccessToken: '',
          timeoutSeconds: 30,
          accuracyThresholdM: 10,
        ),
        contains('local/placeholder'),
      );
      expect(
        ApiConfig.validateForRelease(
          apiBaseUrl: 'https://api.campha.gov.vn/api/v1',
          geoserverBaseUrl: 'https://maps.campha.gov.vn/geoserver',
          notificationsWebSocketUrl: 'ws://api.campha.gov.vn/ws',
          mapboxAccessToken: '',
          timeoutSeconds: 30,
          accuracyThresholdM: 10,
        ),
        contains('WSS'),
      );
    });

    test('rejects missing or invalid GEOSERVER_URL', () {
      expect(
        ApiConfig.validateForRelease(
          apiBaseUrl: 'https://api.campha.gov.vn/api/v1',
          geoserverBaseUrl: '',
          mapboxAccessToken: '',
          timeoutSeconds: 30,
          accuracyThresholdM: 10,
        ),
        contains('GEOSERVER_URL'),
      );
      expect(
        ApiConfig.validateForRelease(
          apiBaseUrl: 'https://api.campha.gov.vn/api/v1',
          geoserverBaseUrl: 'http://maps.campha.gov.vn/geoserver',
          mapboxAccessToken: '',
          timeoutSeconds: 30,
          accuracyThresholdM: 10,
        ),
        contains('HTTPS'),
      );
    });
  });

  test('HTTP diagnostic excludes query values and unsafe response details', () {
    final uri = Uri.parse(
      'https://api.campha.gov.vn/reports?phone=0900000000&token=secret#gps',
    );
    expect(AppLoggingInterceptor.safePath(uri), '/reports');
    expect(
      AppLoggingInterceptor.safeErrorCodes({
        'message': 'Token secret at 21.01,107.33',
        'errors': [
          'ROUTING_UPSTREAM_UNAVAILABLE',
          'email citizen@campha.gov.vn',
          'BAD-CODE',
          'VALID_CODE_2',
        ],
      }),
      ['ROUTING_UPSTREAM_UNAVAILABLE', 'VALID_CODE_2'],
    );
  });

  group('idempotent retry', () {
    test('retries eligible GET once and returns retry response', () async {
      final adapter = _SequenceAdapter([503, 200]);
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(IdempotentRetryInterceptor(dio));

      final response = await dio.get<Object>('/catalog');

      expect(response.statusCode, 200);
      expect(adapter.requests, 2);
    });

    test('stops after one retry when GET keeps failing', () async {
      final adapter = _SequenceAdapter([503, 503]);
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(IdempotentRetryInterceptor(dio));

      await expectLater(
        dio.get<Object>('/catalog'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, 2);
    });

    test('never retries writes, multipart, or non-transient GET', () async {
      final requests =
          <({Future<Response<Object>> Function(Dio) run, int status})>[
            (
              run: (dio) =>
                  dio.post<Object>('/reports', data: {'description': 'write'}),
              status: 503,
            ),
            (
              run: (dio) =>
                  dio.patch<Object>('/features/1', data: {'version': 2}),
              status: 503,
            ),
            (
              run: (dio) => dio.post<Object>('/upload', data: FormData()),
              status: 503,
            ),
            (run: (dio) => dio.get<Object>('/rate-limited'), status: 429),
          ];
      for (final request in requests) {
        final adapter = _SequenceAdapter([request.status]);
        final dio = Dio()..httpClientAdapter = adapter;
        dio.interceptors.add(IdempotentRetryInterceptor(dio));

        await expectLater(request.run(dio), throwsA(isA<DioException>()));
        expect(adapter.requests, 1);
      }
    });
  });
}

class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter(this._statusCodes);

  final List<int> _statusCodes;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final statusCode = _statusCodes[requests++];
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
