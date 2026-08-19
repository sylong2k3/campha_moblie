import 'package:campha_moblie/features/auth/domain/auth_result.dart';
import 'package:campha_moblie/features/auth/domain/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const userJson = <String, dynamic>{
    'id': '9223372036854775807',
    'email': 'citizen@example.com',
    'full_name': 'Nguyễn Văn An',
    'phone': null,
    'avatar_url': null,
    'role': {
      'code': 'citizen',
      'name': 'Người dân',
      'permissions': {
        'field_reports': {'create': true},
      },
    },
    'is_active': true,
    'email_verified': true,
    'must_change_password': false,
    'has_password': true,
  };

  test('parses BIGINT-safe user and nested permissions', () {
    final user = UserModel.fromJson(userJson);
    expect(user.id, '9223372036854775807');
    expect(user.fullName, 'Nguyễn Văn An');
    expect(user.roleCode, 'citizen');
    expect(user.hasPermission('field_reports', 'create'), isTrue);
    expect(user.initials, 'NA');
  });

  test('registration verification branch does not require tokens', () {
    final result = AuthResult.fromJson({
      'user': userJson,
      'requiresVerification': true,
    });
    expect(result.requiresVerification, isTrue);
    expect(result.hasTokenPair, isFalse);
  });

  test('login branch requires complete token pair', () {
    final result = AuthResult.fromJson({
      'user': userJson,
      'accessToken': 'access',
      'refreshToken': 'refresh',
    });
    expect(result.hasTokenPair, isTrue);
  });
}
