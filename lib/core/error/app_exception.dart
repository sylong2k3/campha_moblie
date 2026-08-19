/// Lỗi chuẩn hoá dùng xuyên suốt app — mọi tầng data/domain chỉ nên ném
/// [AppException], không rò rỉ [DioException] hay lỗi platform ra ngoài.
///
/// [message] là fallback tiếng Việt (dùng cho log/debug); UI nên hiển thị qua
/// `localizedMessage(l10n)` trong `core/error/error_l10n.dart` để theo ngôn
/// ngữ app. Khi [isFallbackMessage] là false, message đến từ server và được
/// hiển thị nguyên văn.
sealed class AppException implements Exception {
  const AppException(
    this.message, {
    this.statusCode,
    this.isFallbackMessage = false,
  });

  final String message;
  final int? statusCode;

  /// true nếu [message] là chuỗi mặc định phía client (nên localize khi
  /// hiển thị); false nếu là message server trả về.
  final bool isFallbackMessage;

  @override
  String toString() => message;
}

/// Không có kết nối mạng hoặc timeout.
class NetworkException extends AppException {
  const NetworkException([String? message])
    : super(
        message ?? 'Không có kết nối mạng',
        isFallbackMessage: message == null,
      );
}

/// Lỗi validate dữ liệu từ server (400) — `errors` là danh sách message Joi
/// trả về (server không gắn theo field cụ thể, xem `validate.middleware.js`).
class ValidationException extends AppException {
  const ValidationException(String? message, {this.errors})
    : super(
        message ?? 'Dữ liệu không hợp lệ',
        statusCode: 400,
        isFallbackMessage: message == null,
      );

  final List<String>? errors;
}

/// 409 — tài nguyên thay đổi hoặc dữ liệu đã tồn tại.
class ConflictException extends AppException {
  const ConflictException([String? message, this.errors])
    : super(
        message ?? 'Dữ liệu đã thay đổi, vui lòng tải lại',
        statusCode: 409,
        isFallbackMessage: message == null,
      );

  final List<String>? errors;
}

/// 422 — dữ liệu đúng cú pháp nhưng không hợp lệ về nghiệp vụ/không gian.
class SemanticValidationException extends AppException {
  const SemanticValidationException(String? message, {this.errors})
    : super(
        message ?? 'Không thể xử lý dữ liệu này',
        statusCode: 422,
        isFallbackMessage: message == null,
      );

  final List<String>? errors;
}

/// 401 — token hết hạn/không hợp lệ, refresh thất bại.
class UnauthorizedException extends AppException {
  const UnauthorizedException([String? message])
    : super(
        message ?? 'Phiên đăng nhập đã hết hạn',
        statusCode: 401,
        isFallbackMessage: message == null,
      );
}

/// 403 — không đủ quyền thực hiện thao tác.
class ForbiddenException extends AppException {
  const ForbiddenException([String? message])
    : super(
        message ?? 'Bạn không có quyền thực hiện thao tác này',
        statusCode: 403,
        isFallbackMessage: message == null,
      );
}

/// Server yêu cầu bắt buộc đổi mật khẩu trước khi tiếp tục
/// (`must_change_password = true` — tài khoản do admin cấp mật khẩu tạm).
class PasswordChangeRequiredException extends AppException {
  const PasswordChangeRequiredException([String? message])
    : super(
        message ?? 'Vui lòng đổi mật khẩu để tiếp tục',
        isFallbackMessage: message == null,
      );
}

/// 404 — không tìm thấy tài nguyên.
class NotFoundException extends AppException {
  const NotFoundException([String? message])
    : super(
        message ?? 'Không tìm thấy dữ liệu',
        statusCode: 404,
        isFallbackMessage: message == null,
      );
}

/// 413 — file tải lên vượt giới hạn.
class PayloadTooLargeException extends AppException {
  const PayloadTooLargeException([String? message])
    : super(
        message ?? 'Tệp vượt quá dung lượng cho phép',
        statusCode: 413,
        isFallbackMessage: message == null,
      );
}

/// 429 — vượt rate limit, có thể kèm thời gian chờ (giây).
class RateLimitException extends AppException {
  const RateLimitException(String? message, {this.retryAfterSeconds})
    : super(
        message ?? 'Bạn thao tác quá nhanh, vui lòng thử lại sau',
        statusCode: 429,
        isFallbackMessage: message == null,
      );

  final int? retryAfterSeconds;
}

/// 5xx hoặc lỗi server không xác định.
class ServerException extends AppException {
  const ServerException([String? message, int? statusCode])
    : super(
        message ?? 'Lỗi hệ thống, vui lòng thử lại sau',
        statusCode: statusCode,
        isFallbackMessage: message == null,
      );
}

/// 503 — dịch vụ phụ thuộc tạm thời không sẵn sàng.
class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException([String? message])
    : super(
        message ?? 'Dịch vụ tạm thời không sẵn sàng',
        statusCode: 503,
        isFallbackMessage: message == null,
      );
}

/// Lỗi không xác định / không phân loại được.
class UnknownException extends AppException {
  const UnknownException([String? message])
    : super(message ?? 'Đã có lỗi xảy ra', isFallbackMessage: message == null);
}
