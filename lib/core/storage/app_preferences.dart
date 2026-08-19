import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cài đặt cục bộ không nhạy cảm: anonymous id, ngôn ngữ, theme, deep-link
/// đang chờ điều hướng... Feature mới cần thêm cờ cục bộ thì bổ sung key ở
/// đây thay vì tự đọc `SharedPreferences` rải rác.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _anonymousIdKey = 'anonymous_id';
  static const _localeKey = 'locale';
  static const _themeModeKey = 'theme_mode';
  static const _pendingRouteKey = 'pending_route';

  String? get anonymousId => _prefs.getString(_anonymousIdKey);
  Future<void> setAnonymousId(String value) =>
      _prefs.setString(_anonymousIdKey, value);

  String? get locale => _prefs.getString(_localeKey);
  Future<void> setLocale(String value) => _prefs.setString(_localeKey, value);

  String get themeMode => _prefs.getString(_themeModeKey) ?? 'light';
  Future<void> setThemeMode(String value) =>
      _prefs.setString(_themeModeKey, value);

  /// Đích đến đang chờ điều hướng — set khi cần đăng nhập giữa chừng hoặc
  /// khi bấm push notification lúc phiên chưa khôi phục xong.
  String? get pendingRoute => _prefs.getString(_pendingRouteKey);
  Future<void> setPendingRoute(String value) =>
      _prefs.setString(_pendingRouteKey, value);
  Future<void> clearPendingRoute() => _prefs.remove(_pendingRouteKey);
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
  name: 'sharedPreferencesProvider',
);

final appPreferencesProvider = FutureProvider<AppPreferences>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AppPreferences(prefs);
}, name: 'appPreferencesProvider');
