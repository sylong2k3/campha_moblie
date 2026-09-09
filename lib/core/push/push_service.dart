import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../error/crashlytics_service.dart';
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
    this.registrationSession,
    this.onForegroundMessage,
    this.onMessageTap,
  });

  /// Gọi sau khi có token FCM mới (đăng nhập xong hoặc token rotate).
  final Future<void> Function(String token, String platform)? onRegisterToken;

  /// Gọi trước khi logout (JWT còn hiệu lực) để huỷ token trên server.
  final Future<void> Function(String token)? onUnregisterToken;

  /// Phiên hiện tại (identity ổn định); null khi guest hoặc đang logout.
  final Object? Function()? registrationSession;

  /// Gọi khi có push đến lúc app đang mở foreground (Android đã tự hiện local
  /// notification; iOS hệ điều hành tự hiện banner).
  final void Function(Map<String, dynamic> data)? onForegroundMessage;

  /// Gọi khi người dùng bấm vào thông báo (app đang mở/background/terminated).
  final void Function(Map<String, dynamic> data)? onMessageTap;

  static bool _firebaseReady = false;
  static Future<void>? _firebaseInitialization;

  bool _attached = false;
  bool _disposed = false;
  bool _unregistering = false;
  Object? _registeredSession;
  Future<bool> _registration = Future.value(false);
  String? _registeredToken;

  Object? get _session =>
      _disposed || _unregistering ? null : registrationSession?.call();
  bool _current(Object? session) =>
      session != null && identical(session, _session);
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
      await CrashlyticsService.initialize();
    } catch (_) {
      _firebaseReady = false;
      if (kDebugMode) debugPrint('[PUSH] firebase_unavailable');
    }
  }

  /// Gắn listener FCM + khởi tạo local notifications — gọi 1 lần khi app
  /// dựng ProviderScope (idempotent).
  Future<void> attach() async {
    await initFirebase();
    if (!_firebaseReady || _attached || _disposed) return;
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

      if (_disposed) return;
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        _onForegroundMessage,
        onError: _logListenerError,
      );
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
        message,
      ) {
        if (!_disposed) onMessageTap?.call(message.data);
      }, onError: _logListenerError);

      // App mở từ trạng thái terminated do bấm thông báo.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      final localLaunch = await _local.getNotificationAppLaunchDetails();
      if (_disposed) return;
      if (localLaunch?.didNotificationLaunchApp == true) {
        await _openFromPayload(localLaunch?.notificationResponse?.payload);
      } else if (initial != null) {
        onMessageTap?.call(initial.data);
      }

      // Token rotate — luôn thử lại trong phiên authenticated, kể cả lần đăng ký
      // đầu thất bại. Callback không bao giờ nhận token khi guest.
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
        token,
      ) {
        final session = _session;
        if (session != null) {
          unawaited(_registerToken(token, session));
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
    _disposed = true;
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
  Future<bool> registerDevice() async {
    final session = _session;
    if (session == null) return false;
    await initFirebase();
    if (!_firebaseReady || !_current(session)) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (!_current(session) ||
          settings.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || !_current(session)) return false;
      return await _registerToken(token, session);
    } catch (_) {
      if (kDebugMode) debugPrint('[PUSH] register_device_failed');
      return false;
    }
  }

  /// Trước khi logout (khi header JWT còn hiệu lực) — huỷ token trên server.
  Future<void> unregisterDevice() async {
    _unregistering = true;
    try {
      await _registration;
      await initFirebase();
      if (!_firebaseReady) return;
      final token =
          _registeredToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) await onUnregisterToken?.call(token);
    } catch (_) {
      if (kDebugMode) debugPrint('[PUSH] unregister_device_failed');
    } finally {
      _registeredToken = null;
      _registeredSession = null;
      // Stay blocked until coordinator observes the next session.
    }
  }

  void sessionChanged() {
    _unregistering = false;
    _registeredSession = null;
    _registeredToken = null;
  }

  Future<bool> _registerToken(String token, Object session) {
    _registration = _registration.then((_) async {
      if (!_current(session) || onRegisterToken == null) return false;
      if (identical(session, _registeredSession) && token == _registeredToken) {
        return true;
      }
      final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
      try {
        await onRegisterToken!(token, platform);
        if (!_current(session)) return false;
        _registeredToken = token;
        _registeredSession = session;
        return true;
      } catch (_) {
        if (kDebugMode) debugPrint('[PUSH] token_registration_failed');
        return false;
      }
    });
    return _registration;
  }

  void _onForegroundMessage(RemoteMessage message) {
    if (_disposed || _session == null) return;
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
    if (_disposed || payload == null || payload.isEmpty) return;
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
