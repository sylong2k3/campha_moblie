import 'package:campha_moblie/app/router/app_router.dart';
import 'package:campha_moblie/app/router/route_names.dart';
import 'package:campha_moblie/core/push/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('push registration lifetime', () {
    test('guest session never reaches the register callback', () async {
      var registrations = 0;
      final service = PushService(
        registrationSession: () => null,
        onRegisterToken: (_, _) async => registrations++,
      );
      addTearDown(service.dispose);

      expect(await service.registerDevice(), isFalse);
      expect(registrations, 0);
    });

    test('registration reports failure when Firebase is unavailable', () async {
      var registrations = 0;
      final session = Object();
      final service = PushService(
        registrationSession: () => session,
        onRegisterToken: (_, _) async => registrations++,
      );
      addTearDown(service.dispose);

      // Môi trường test không có google-services: initFirebase thất bại nên
      // registerDevice phải trả false để coordinator còn retry khi resume.
      expect(await service.registerDevice(), isFalse);
      expect(registrations, 0);
    });

    test('disposed service stops registering for any session', () async {
      var registrations = 0;
      final session = Object();
      final service = PushService(
        registrationSession: () => session,
        onRegisterToken: (_, _) async => registrations++,
      );
      await service.dispose();

      expect(await service.registerDevice(), isFalse);
      expect(registrations, 0);
    });

    test('unregister blocks registration until the next session', () async {
      var registrations = 0;
      var unregistrations = 0;
      Object? session = Object();
      final service = PushService(
        registrationSession: () => session,
        onRegisterToken: (_, _) async => registrations++,
        onUnregisterToken: (_) async => unregistrations++,
      );
      addTearDown(service.dispose);

      await service.unregisterDevice();
      expect(await service.registerDevice(), isFalse);
      expect(registrations, 0);
      expect(unregistrations, 0, reason: 'no token was registered');

      session = Object();
      service.sessionChanged();
      expect(await service.registerDevice(), isFalse);
    });
  });

  group('notification destinations', () {
    test('notifications route survives sanitization for returnTo', () {
      expect(
        sanitizeReturnTo(RoutePaths.notifications),
        RoutePaths.notifications,
      );
      expect(sanitizeReturnTo('/notifications/../auth/login'), isNull);
      expect(sanitizeReturnTo('https://evil.example/notifications'), isNull);
    });

    test('guest declining login lands on a public destination', () {
      expect(guestReturnTo(RoutePaths.notifications), RoutePaths.profile);
    });
  });
}
