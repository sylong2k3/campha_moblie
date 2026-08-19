import '../l10n/l10n.dart';
import 'app_exception.dart';

/// Localize message lỗi khi hiển thị lên UI.
///
/// - Message server trả về (đã theo ngữ cảnh nghiệp vụ) hiển thị nguyên văn.
/// - Message mặc định phía client được dịch theo ngôn ngữ app.
extension AppExceptionL10n on AppException {
  String localizedMessage(AppLocalizations l10n) {
    if (!isFallbackMessage) return message;
    return switch (this) {
      NetworkException() => l10n.errorNetwork,
      ValidationException() => l10n.errorValidation,
      ConflictException() => l10n.errorValidation,
      SemanticValidationException() => l10n.errorValidation,
      UnauthorizedException() => l10n.errorUnauthorized,
      ForbiddenException() => l10n.errorForbidden,
      PasswordChangeRequiredException() => l10n.errorPasswordChangeRequired,
      NotFoundException() => l10n.errorNotFound,
      PayloadTooLargeException() => l10n.errorPayloadTooLarge,
      RateLimitException() => l10n.errorRateLimit,
      ServiceUnavailableException() => l10n.errorServer,
      ServerException() => l10n.errorServer,
      UnknownException() => l10n.errorUnknown,
    };
  }
}

/// Tiện ích cho lỗi bất kỳ (AsyncValue.error trả `Object`).
extension ObjectErrorL10n on Object {
  String localizedErrorMessage(AppLocalizations l10n) {
    final self = this;
    return self is AppException
        ? self.localizedMessage(l10n)
        : l10n.errorUnknown;
  }
}
