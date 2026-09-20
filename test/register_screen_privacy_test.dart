import 'package:campha_moblie/core/network/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ApiConfig has correct public privacy policy URL', () {
    expect(
      ApiConfig.privacyPolicyUrl,
      'https://apicampha.tourismpj.pro.vn/privacy-policy',
    );
  });

  test('ApiConfig has correct public terms of service URL', () {
    expect(
      ApiConfig.termsOfServiceUrl,
      'https://apicampha.tourismpj.pro.vn/terms',
    );
  });
}
