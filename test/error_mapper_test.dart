import 'package:campha_moblie/core/error/app_exception.dart';
import 'package:campha_moblie/core/error/error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException responseError(
  int statusCode, {
  Object? data,
  Map<String, List<String>> headers = const {},
}) {
  final request = RequestOptions(path: '/resource');
  return DioException(
    requestOptions: request,
    response: Response(
      requestOptions: request,
      statusCode: statusCode,
      data: data,
      headers: Headers.fromMap(headers),
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  test('preserves named 409 conflict errors', () {
    final request = RequestOptions(path: '/mobile/drafts/1');
    final mapped = mapErrorToAppException(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 409,
          data: {
            'message': 'Dữ liệu đã thay đổi',
            'errors': ['OPTIMISTIC_LOCK_CONFLICT'],
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );
    expect(mapped, isA<ConflictException>());
    expect(
      (mapped as ConflictException).errors,
      contains('OPTIMISTIC_LOCK_CONFLICT'),
    );
  });

  test('preserves optimistic draft conflict code', () {
    final mapped =
        mapErrorToAppException(
              responseError(
                409,
                data: {
                  'message': 'Draft changed',
                  'errors': ['OPTIMISTIC_LOCK_CONFLICT'],
                },
              ),
            )
            as ConflictException;
    expect(mapped.errors, contains('OPTIMISTIC_LOCK_CONFLICT'));
  });

  test('maps release HTTP status matrix to explicit exception types', () {
    final cases = <int, Type>{
      400: ValidationException,
      401: UnauthorizedException,
      403: ForbiddenException,
      404: NotFoundException,
      409: ConflictException,
      413: PayloadTooLargeException,
      422: SemanticValidationException,
      429: RateLimitException,
      500: ServerException,
      502: ServerException,
      503: ServiceUnavailableException,
    };

    for (final entry in cases.entries) {
      final mapped = mapErrorToAppException(
        responseError(entry.key, data: const {'message': 'Safe message'}),
      );
      expect(mapped.runtimeType, entry.value, reason: 'HTTP ${entry.key}');
      expect(mapped.statusCode, entry.key);
    }
  });

  test('preserves password-change code and validation messages', () {
    final passwordRequired = mapErrorToAppException(
      responseError(
        403,
        data: {
          'message': 'Change password',
          'errors': ['PASSWORD_CHANGE_REQUIRED'],
        },
      ),
    );
    final validation =
        mapErrorToAppException(
              responseError(
                422,
                data: {
                  'message': 'Geometry invalid',
                  'errors': ['GEOMETRY_OUTSIDE_BOUNDS'],
                },
              ),
            )
            as SemanticValidationException;

    expect(passwordRequired, isA<PasswordChangeRequiredException>());
    expect(validation.errors, ['GEOMETRY_OUTSIDE_BOUNDS']);
  });

  test('reads rate-limit delay and ignores non-string server message', () {
    final rateLimit =
        mapErrorToAppException(
              responseError(
                429,
                data: const {'message': 'Wait'},
                headers: const {
                  'retry-after': ['17'],
                },
              ),
            )
            as RateLimitException;
    final rateLimitReset =
        mapErrorToAppException(
              responseError(
                429,
                headers: const {
                  'ratelimit-reset': ['30'],
                },
              ),
            )
            as RateLimitException;
    final privacyFallback = mapErrorToAppException(
      responseError(
        500,
        data: const {
          'message': {'token': 'must-not-render'},
        },
      ),
    );

    expect(rateLimit.retryAfterSeconds, 17);
    expect(rateLimitReset.retryAfterSeconds, 30);
    expect(privacyFallback.message, 'Lỗi hệ thống, vui lòng thử lại sau');
    expect(privacyFallback.isFallbackMessage, isTrue);
  });

  test('maps transport failures without leaking transport details', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
      DioExceptionType.badCertificate,
      DioExceptionType.unknown,
    ]) {
      final mapped = mapErrorToAppException(
        DioException(
          requestOptions: RequestOptions(path: '/private?token=secret'),
          type: type,
          message: 'token=secret',
        ),
      );
      expect(mapped, isA<NetworkException>(), reason: '$type');
      expect(mapped.message, isNot(contains('secret')));
    }
    expect(
      mapErrorToAppException(
        DioException(
          requestOptions: RequestOptions(path: '/cancelled'),
          type: DioExceptionType.cancel,
        ),
      ),
      isA<UnknownException>(),
    );
  });
}
