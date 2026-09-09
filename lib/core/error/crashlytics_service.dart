import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ quản lý ghi nhận lỗi và crash report qua Firebase Crashlytics & Analytics.
///
/// Hỗ trợ:
/// - Tự động ghi nhận lỗi giao diện (Flutter framework fatal errors).
/// - Tự động ghi nhận lỗi bất đồng bộ chưa bắt được (Platform dispatcher errors).
/// - Tự động tích hợp Google Analytics breadcrumbs theo tài liệu Firebase.
/// - Ghi nhận lỗi có chủ đích (non-fatal errors, API errors, logging breadcrumbs).
/// - Gắn thông tin người dùng đang đăng nhập vào phiên lỗi và Analytics session.
class CrashlyticsService {
  const CrashlyticsService._();

  static bool _initialized = false;
  static Future<void> _identityUpdate = Future.value();

  /// Khởi tạo và liên kết bộ lắng nghe lỗi của Flutter với Firebase Crashlytics.
  static Future<void> initialize() async {
    if (_initialized) return;
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[Crashlytics] Firebase chưa được khởi tạo, bỏ qua Crashlytics.',
        );
      }
      return;
    }

    try {
      // Bật thu thập crash report tự động
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // 1. Bắt tất cả lỗi fatal phát sinh từ Flutter framework (UI layout, widget tree)
      final originalFlutterOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        if (kDebugMode) {
          FlutterError.presentError(details);
        } else if (originalFlutterOnError != null) {
          originalFlutterOnError(details);
        }
      };

      // 2. Bắt tất cả lỗi bất đồng bộ ngoài Flutter framework
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        if (kDebugMode) {
          debugPrint(
            '[Crashlytics] PlatformDispatcher caught error: $error\n$stack',
          );
        }
        return true;
      };

      _initialized = true;
      if (kDebugMode) {
        debugPrint(
          '[Crashlytics] Đã khởi tạo Firebase Crashlytics & Analytics thành công.',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[Crashlytics] Lỗi khi khởi tạo Crashlytics: $e\n$stack');
      }
    }
  }

  /// Ghi nhận lỗi thủ công (Non-fatal hoặc Fatal) kèm thông tin bổ sung.
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        information: information,
        fatal: fatal,
      );
    } catch (_) {
      // Tránh để việc log crash làm crash ứng dụng
    }
  }

  /// Gắn định danh người dùng vào Crashlytics và Analytics sau khi đăng nhập.
  static Future<void> setUser({required String id, String? role}) {
    _identityUpdate = _identityUpdate.then((_) async {
      if (Firebase.apps.isEmpty) return;
      final userRole = role == null || role.isEmpty ? null : role;
      for (final update in <Future<void> Function()>[
        () => FirebaseCrashlytics.instance.setUserIdentifier(id),
        () => FirebaseCrashlytics.instance.setCustomKey('user_email', ''),
        () => FirebaseCrashlytics.instance.setCustomKey(
          'user_role',
          userRole ?? '',
        ),
        () => FirebaseAnalytics.instance.setUserId(id: id.isEmpty ? null : id),
        () => FirebaseAnalytics.instance.setUserProperty(
          name: 'user_role',
          value: userRole,
        ),
      ]) {
        try {
          await update();
        } catch (_) {
          // One SDK failure must not prevent identity cleanup in the other SDK.
        }
      }
    });
    return _identityUpdate;
  }

  /// Xoá định danh người dùng khi đăng xuất.
  static Future<void> clearUser() => setUser(id: '');

  /// Ghi lại breadcrumb log để xem luồng hành động trước khi ứng dụng gặp sự cố.
  static Future<void> log(String message) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  /// Ghi lại sự kiện nghiệp vụ vào Firebase Analytics (tự động tạo breadcrumbs trong Crashlytics).
  static Future<void> logEvent(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
      await FirebaseCrashlytics.instance.log('[Event] $name: $parameters');
    } catch (_) {}
  }

  /// Hàm kiểm thử tạo Crash tức thì (dùng cho Developer / Tester kiểm tra trên Firebase Console).
  static void testCrash() {
    if (kDebugMode) {
      debugPrint('[Crashlytics] Triggering test crash...');
    }
    FirebaseCrashlytics.instance.crash();
  }
}
