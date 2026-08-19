import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Push FCM — đăng ký device token sau đăng nhập, nhận push ở foreground
/// (hiện qua local notification) và deep-link khi bấm vào.
///
/// An toàn khi Firebase CHƯA cấu hình (chưa có google-services.json/
/// GoogleService-Info.plist, chưa bật gradle plugin `google-services`) —
/// [initFirebase] nuốt lỗi và mọi method còn lại thành no-op, app chạy bình
/// thường không push.
///
/// Core chưa biết gì về feature `auth`/`notifications` (server-campha hiện
/// cũng chưa có route `/notifications/*`) nên việc đăng ký/huỷ token với
/// server và mở đích đến khi bấm thông báo được để ngỏ qua
/// [onRegisterToken]/[onUnregisterToken]/[onMessageTap] — feature
/// `notifications` khi được xây truyền callback thật vào đây bằng cách
/// override [pushServiceProvider] (`ProviderScope(overrides: [...])`).
class PushService {
  PushService({
    this.onRegisterToken,
    this.onUnregisterToken,
    this.onForegroundMessage,
    this.onMessageTap,
  });

  /// Gọi sau khi có token FCM mới (đăng nhập xong hoặc token rotate).
  final Future<void> Function(String token, String platform)? onRegisterToken;

  /// Gọi trước khi logout (JWT còn hiệu lực) để huỷ token trên server.
  final Future<void> Function(String token)? onUnregisterToken;

  /// Gọi khi có push đến lúc app đang mở foreground (Android đã tự hiện local
  /// notification; iOS hệ điều hành tự hiện banner).
  final void Function(Map<String, dynamic> data)? onForegroundMessage;

  /// Gọi khi người dùng bấm vào thông báo (app đang mở/background/terminated).
  final void Function(Map<String, dynamic> data)? onMessageTap;

  static bool _firebaseReady = false;
  static Future<void>? _firebaseInitialization;

  bool _attached = false;
  String? _registeredToken;
  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;

  static const _channel = AndroidNotificationChannel(
    'campha_default',
    'Thông báo GIS Cẩm Phả',
    description: 'Cảnh báo môi trường và thông báo hệ thống',
    importance: Importance.high,
  );

  /// Khởi tạo một lần, không phụ thuộc caller nào vào trước. `main()` có thể
  /// fire-and-forget để không chặn first frame; push actions vẫn await future này.
  static Future<void> initFirebase() =>
      _firebaseInitialization ??= _initializeFirebase();

  static Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
      FlutterError.onError = (details) {
        FirebaseCrashlytics.instance.recordError(
          StateError('flutter_fatal_error'),
          details.stack,
          fatal: true,
        );
      };
      PlatformDispatcher.instance.onError = (_, stack) {
        FirebaseCrashlytics.instance.recordError(
          StateError('platform_uncaught_error'),
          stack,
          fatal: true,
        );
        return true;
      };
    } catch (_) {
      _firebaseReady = false;
      if (kDebugMode) debugPrint('[PUSH] firebase_unavailable');
    }
  }

  /// Gắn listener FCM + khởi tạo local notifications — gọi 1 lần khi app
  /// dựng ProviderScope (idempotent).
  Future<void> attach() async {
    await initFirebase();
    if (!_firebaseReady || _attached) return;
    _attached = true;

    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) {
          unawaited(_openFromPayload(response.payload));
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      // iOS: cho phép hiện banner ngay cả khi app đang mở.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      _messageSubscription = FirebaseMessaging.onMessage.listen(
        _onForegroundMessage,
        onError: _logListenerError,
      );
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => onMessageTap?.call(message.data),
        onError: _logListenerError,
      );

      // App mở từ trạng thái terminated do bấm thông báo.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) onMessageTap?.call(initial.data);

      // Token rotate — đăng ký lại nếu phiên này đã từng đăng ký.
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
        token,
      ) {
        if (_registeredToken != null && token != _registeredToken) {
          unawaited(_registerToken(token));
        }
      }, onError: _logListenerError);
    } catch (_) {
      _attached = false;
      await dispose();
      if (kDebugMode) debugPrint('[PUSH] attach_failed');
    }
  }

  void _logListenerError(Object _) {
    if (kDebugMode) debugPrint('[PUSH] listener_failed');
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
    _messageSubscription = null;
    _openedSubscription = null;
    _tokenSubscription = null;
    _attached = false;
  }

  /// Sau đăng nhập/khôi phục phiên — xin quyền (Android 13+ / iOS) rồi đăng
  /// ký token với server qua [onRegisterToken]. Guest không nên gọi (API cần
  /// JWT).
  Future<void> registerDevice() async {
    await initFirebase();
    if (!_firebaseReady) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } catch (_) {
      if (kDebugMode) debugPrint('[PUSH] register_device_failed');
    }
  }

  /// Trước khi logout (khi header JWT còn hiệu lực) — huỷ token trên server.
  Future<void> unregisterDevice() async {
    await initFirebase();
    if (!_firebaseReady) return;
    try {
      final token =
          _registeredToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) await onUnregisterToken?.call(token);
    } catch (_) {
      if (kDebugMode) debugPrint('[PUSH] unregister_device_failed');
    } finally {
      _registeredToken = null;
    }
  }

  Future<void> _registerToken(String token) async {
    final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
    try {
      await onRegisterToken?.call(token, platform);
      _registeredToken = token;
    } catch (_) {
      if (kDebugMode) debugPrint('[PUSH] token_registration_failed');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    onForegroundMessage?.call(message.data);

    final notification = message.notification;
    if (notification == null || kIsWeb || Platform.isIOS) {
      return; // iOS đã hiện banner hệ thống.
    }
    unawaited(
      _local
          .show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            payload: jsonEncode(message.data),
          )
          .catchError((Object _) {
            if (kDebugMode) debugPrint('[PUSH] local_notification_failed');
          }),
    );
  }

  Future<void> _openFromPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    try {
      onMessageTap?.call(jsonDecode(payload) as Map<String, dynamic>);
    } catch (_) {
      // Payload hỏng → bỏ qua, không crash luồng thông báo.
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService();
  unawaited(service.attach());
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
}, name: 'pushServiceProvider');
