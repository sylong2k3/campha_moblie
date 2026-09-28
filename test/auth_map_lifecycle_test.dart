import 'package:campha_moblie/app/router/app_router.dart';
import 'package:campha_moblie/app/router/route_names.dart';
import 'package:campha_moblie/core/storage/token_storage.dart';
import 'package:campha_moblie/features/auth/domain/auth_result.dart';
import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/auth/domain/user_model.dart';
import 'package:campha_moblie/features/map/domain/flood_scenario_controller.dart';
import 'package:campha_moblie/features/map/domain/map_controller.dart';
import 'package:campha_moblie/features/map/presentation/map_home_screen.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/memory_secure_storage.dart';

class _Session extends SessionController {
  @override
  SessionState build() => const SessionState.guest();

  void authenticate() => state = SessionState.authenticated(
    UserModel.fromJson({
      'id': '1',
      'email': 'user@example.com',
      'role': {'code': 'citizen'},
    }),
  );

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    authenticate();
    return AuthResult(user: state.user!, requiresVerification: false);
  }

  @override
  Future<void> logout() async => state = const SessionState.guest();
}

class _Catalog extends MapCatalogController {
  @override
  MapCatalogState build() => const MapCatalogState();

  @override
  void resetForIdentityChange() {}
}

class _Scenarios extends FloodScenarioController {
  @override
  FloodScenarioState build() => const FloodScenarioState();

  @override
  void resetForIdentityChange() {}
}

void main() {
  for (final pushed in [true, false]) {
    testWidgets('auth preserves map and page gestures (pushed: $pushed)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(MemorySecureStorage()),
          sessionControllerProvider.overrideWith(_Session.new),
          mapCatalogProvider.overrideWith(_Catalog.new),
          floodScenarioProvider.overrideWith(_Scenarios.new),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        container.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final router = container.read(appRouterProvider);
      router.go(RoutePaths.map);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final mapState = tester.state(find.byType(MapHomeScreen));
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      if (pushed) {
        router.push(RoutePaths.login);
      } else {
        router.go(RoutePaths.login);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(
        find.byKey(const ValueKey('login-email')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password')),
        'test-password',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('login-submit')));
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, RoutePaths.map);
      expect(
        find.byType(StatefulNavigationShell, skipOffstage: false),
        findsOneWidget,
      );
      final loggedInMap = tester.state(find.byType(MapHomeScreen));
      if (pushed) expect(loggedInMap, same(mapState));

      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const ValueKey('profile-notifications')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(router.state.uri.path, RoutePaths.notifications);
      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(find.byKey(const ValueKey('logout-tile')));
      await tester.tap(find.byKey(const ValueKey('logout-tile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, RoutePaths.map);
      expect(tester.state(find.byType(MapHomeScreen)), same(loggedInMap));
    }, variant: TargetPlatformVariant({TargetPlatform.windows}));
  }
}
