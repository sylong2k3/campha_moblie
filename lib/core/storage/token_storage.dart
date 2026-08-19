import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu access/refresh token trong Keychain/Keystore.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final Set<void Function()> _clearListeners = {};
  final Set<void Function()> _tokenChangeListeners = {};

  String? _accessTokenCache;
  bool _cleared = true;

  /// Access token giữ thêm trong memory để tránh đọc secure storage mỗi request.
  String? get cachedAccessToken => _accessTokenCache;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessTokenCache = accessToken;
    _cleared = false;
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    _notifyTokenChanged();
  }

  Future<String?> readAccessToken() async {
    _accessTokenCache ??= await _storage.read(key: _accessTokenKey);
    if (_accessTokenCache != null) _cleared = false;
    return _accessTokenCache;
  }

  Future<String?> readRefreshToken() async {
    final token = await _storage.read(key: _refreshTokenKey);
    if (token != null) _cleared = false;
    return token;
  }

  void addTokenChangeListener(void Function() listener) =>
      _tokenChangeListeners.add(listener);
  void removeTokenChangeListener(void Function() listener) =>
      _tokenChangeListeners.remove(listener);

  void addClearListener(void Function() listener) =>
      _clearListeners.add(listener);
  void removeClearListener(void Function() listener) =>
      _clearListeners.remove(listener);

  Future<void> clear() async {
    final notify = !_cleared || _accessTokenCache != null;
    _accessTokenCache = null;
    _cleared = true;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    if (!notify) return;
    _notifyTokenChanged();
    for (final listener in _clearListeners.toList(growable: false)) {
      listener();
    }
  }

  void _notifyTokenChanged() {
    for (final listener in _tokenChangeListeners.toList(growable: false)) {
      listener();
    }
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
  name: 'secureStorageProvider',
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
  name: 'tokenStorageProvider',
);
