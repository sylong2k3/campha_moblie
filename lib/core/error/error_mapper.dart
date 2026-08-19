import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Ánh xạ [DioException]/lỗi bất kỳ sang [AppException] theo envelope lỗi
/// chuẩn của server (`error-handler.js`: `{success:false, message, errors:[]}`).
AppException mapErrorToAppException(Object error) {
  if (error is AppException) return error;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badCertificate:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const UnknownException();
      case DioExceptionType.badResponse:
        return _mapStatusCode(error);
      case DioExceptionType.unknown:
      default:
        return const NetworkException();
    }
  }

  return const UnknownException();
}

AppException _mapStatusCode(DioException error) {
  final statusCode = error.response?.statusCode;
  final data = error.response?.data;
  final message = _extractMessage(data);
  final errors = _extractErrors(data);

  switch (statusCode) {
    case 400:
      return ValidationException(message, errors: errors);
    case 401:
      return UnauthorizedException(message);
    case 403:
      if (errors != null && errors.contains('PASSWORD_CHANGE_REQUIRED')) {
        return PasswordChangeRequiredException(message);
      }
      return ForbiddenException(message);
    case 404:
      return NotFoundException(message);
    case 409:
      return ConflictException(message, errors);
    case 413:
      return PayloadTooLargeException(message);
    case 422:
      return SemanticValidationException(message, errors: errors);
    case 429:
      return RateLimitException(
        message,
        retryAfterSeconds: _extractRetryAfter(error),
      );
    case 503:
      return ServiceUnavailableException(message);
    default:
      if (statusCode != null && statusCode >= 500) {
        return ServerException(message, statusCode);
      }
      return UnknownException(message);
  }
}

String? _extractMessage(dynamic data) {
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }
  return null;
}

/// Server trả `errors` dạng danh sách message string (không theo field),
/// xem `error-handler.js` / `validate.middleware.js`.
List<String>? _extractErrors(dynamic data) {
  if (data is Map && data['errors'] is List) {
    return (data['errors'] as List).map((e) => e.toString()).toList();
  }
  return null;
}

/// `express-rate-limit` gắn số giây còn lại trong header `RateLimit-Reset`
/// (không có field này trong body).
int? _extractRetryAfter(DioException error) {
  final header =
      error.response?.headers.value('ratelimit-reset') ??
      error.response?.headers.value('retry-after');
  return header == null ? null : int.tryParse(header);
}
