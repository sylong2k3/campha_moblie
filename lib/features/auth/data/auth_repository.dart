import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_result.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  AuthRepository({required this.dio, required this.tokenStorage});

  final Dio dio;
  final TokenStorage tokenStorage;

  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRegister,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'fullName': fullName.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );
      final result = AuthResult.fromJson(_readData(response.data));
      if (result.hasTokenPair) {
        await tokenStorage.saveTokens(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken!,
        );
      }
      return result;
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.authLogin,
        data: {'email': email.trim().toLowerCase(), 'password': password},
      );
      final result = AuthResult.fromJson(_readData(response.data));
      if (!result.hasTokenPair) {
        throw const FormatException('Login response thiếu token.');
      }
      await tokenStorage.saveTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken!,
      );
      return result;
    } on AppException {
      rethrow;
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(ApiEndpoints.authMe);
      return UserModel.fromJson(_readData(response.data));
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<String> forgotPassword(String email) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.authForgotPassword,
        data: {'email': email.trim().toLowerCase()},
      );
      return response.data?['message']?.toString() ??
          'Nếu email tồn tại, hướng dẫn đặt lại mật khẩu đã được gửi.';
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await dio.post<Map<String, dynamic>>(
        ApiEndpoints.authChangePassword,
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
      // Backend tăng tokenVersion và xóa mọi refresh token; SessionController
      // đóng phiên và dọn toàn bộ dữ liệu local sau response thành công.
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await tokenStorage.readRefreshToken();
      if (await tokenStorage.readAccessToken() != null) {
        await dio.post<Map<String, dynamic>>(
          ApiEndpoints.authLogout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Remote logout và secure reads best effort; local token clear là bắt buộc.
    } finally {
      await tokenStorage.clear();
    }
  }

  Map<String, dynamic> _readData(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is! Map) {
      throw const FormatException('API response thiếu data.');
    }
    return Map<String, dynamic>.from(data);
  }
}
