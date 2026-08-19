import 'user_model.dart';

/// Kết quả auth có thể yêu cầu xác minh email và không cấp token.
class AuthResult {
  const AuthResult({
    required this.user,
    required this.requiresVerification,
    this.accessToken,
    this.refreshToken,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map) {
      throw const FormatException('Auth response thiếu user.');
    }
    return AuthResult(
      user: UserModel.fromJson(Map<String, dynamic>.from(userJson)),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      requiresVerification: json['requiresVerification'] as bool? ?? false,
    );
  }

  final UserModel user;
  final String? accessToken;
  final String? refreshToken;
  final bool requiresVerification;

  bool get hasTokenPair =>
      accessToken != null &&
      accessToken!.isNotEmpty &&
      refreshToken != null &&
      refreshToken!.isNotEmpty;
}
