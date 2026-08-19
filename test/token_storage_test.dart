import 'package:campha_moblie/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_secure_storage.dart';

void main() {
  test('notifies token listeners after save and clear', () async {
    final secureStorage = MemorySecureStorage();
    final storage = TokenStorage(secureStorage);
    var notifications = 0;
    var clears = 0;
    storage.addTokenChangeListener(() => notifications++);
    storage.addClearListener(() => clears++);

    await storage.saveTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );
    expect(await storage.readAccessToken(), 'access-1');
    expect(secureStorage.values['access_token'], 'access-1');
    expect(notifications, 1);
    expect(clears, 0);

    await storage.saveTokens(
      accessToken: 'access-2',
      refreshToken: 'refresh-2',
    );
    expect(await storage.readAccessToken(), 'access-2');
    expect(notifications, 2);
    expect(clears, 0);

    await storage.clear();
    expect(await storage.readAccessToken(), isNull);
    expect(secureStorage.values['refresh_token'], isNull);
    expect(notifications, 3);
    expect(clears, 1);

    await storage.clear();
    expect(notifications, 3);
    expect(clears, 1);
  });

  test('clear deletes secure values before any token read', () async {
    final secureStorage = MemorySecureStorage();
    secureStorage.values.addAll({
      'access_token': 'unread-access',
      'refresh_token': 'unread-refresh',
    });
    final storage = TokenStorage(secureStorage);

    await storage.clear();

    expect(secureStorage.values, isEmpty);
  });
}
