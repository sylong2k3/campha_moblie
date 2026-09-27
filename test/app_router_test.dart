import 'package:campha_moblie/app/router/app_router.dart';
import 'package:campha_moblie/app/router/route_names.dart';
import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/auth/domain/user_model.dart';
import 'package:campha_moblie/features/auth/presentation/login_screen.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('allows only known local return routes', () {
    expect(sanitizeReturnTo('/map'), '/map');
    expect(sanitizeReturnTo('/map/search'), '/map/search');
    expect(
      sanitizeReturnTo('/map/feature/1/CAMTRUNG_99'),
      '/map/feature/1/CAMTRUNG_99',
    );
    expect(sanitizeReturnTo('/news?q=campha'), '/news?q=campha');
    expect(sanitizeReturnTo('/news/8?compose=1'), '/news/8?compose=1');
    expect(sanitizeReturnTo('/documents/2'), '/documents/2');
    expect(sanitizeReturnTo('/documents/pdf/5'), '/documents/pdf/5');
    expect(
      sanitizeReturnTo('/map/feature/1/abc_2/edit'),
      '/map/feature/1/abc_2/edit',
    );
    expect(
      sanitizeReturnTo('/map/feature/1/abc_2/history'),
      '/map/feature/1/abc_2/history',
    );
    expect(sanitizeReturnTo('/map/offline-changes'), '/map/offline-changes');
    expect(sanitizeReturnTo('/reports/new'), '/reports/new');
    expect(sanitizeReturnTo('/reports/mine'), '/reports/mine');
    expect(
      sanitizeReturnTo('/reports/9007199254740997'),
      '/reports/9007199254740997',
    );
    expect(
      sanitizeReturnTo('/profile/change-password'),
      '/profile/change-password',
    );
  });

  test('maps guest continuation to a public destination', () {
    expect(guestReturnTo(null), '/map');
    expect(guestReturnTo('/news/8?compose=1'), '/news/8?compose=1');
    expect(guestReturnTo('/reports/new'), '/reports');
    expect(guestReturnTo('/reports/mine'), '/reports');
    expect(guestReturnTo('/reports/42'), '/reports');
    expect(guestReturnTo('/map/feature/1/abc_2/edit'), '/map/feature/1/abc_2');
    expect(guestReturnTo('/map/offline-changes'), '/map');
    expect(guestReturnTo('/profile/change-password'), '/profile');
    expect(guestReturnTo('https://evil.example/map'), '/map');
  });

  test('rejects external, traversal, auth loop and unknown return routes', () {
    expect(sanitizeReturnTo('https://evil.example/map'), isNull);
    expect(sanitizeReturnTo('//evil.example/map'), isNull);
    expect(sanitizeReturnTo('/map/../auth/login'), isNull);
    expect(sanitizeReturnTo('/auth/login'), isNull);
    expect(sanitizeReturnTo('/map/feature/no/1'), isNull);
    expect(sanitizeReturnTo('/map/feature/1/bad%2Fid'), isNull);
    expect(sanitizeReturnTo('/news/not-a-number'), isNull);
    expect(sanitizeReturnTo('/documents/pdf/5/extra'), isNull);
    expect(sanitizeReturnTo('/reports/not-a-number'), isNull);
    expect(sanitizeReturnTo('/map/drafts'), isNull);
    expect(sanitizeReturnTo('/map/feature/1/abc_2/edit/extra'), isNull);
    expect(sanitizeReturnTo('/reports/7/extra'), isNull);
    expect(sanitizeReturnTo('/unknown'), isNull);
    expect(sanitizeReturnTo(null), isNull);
  });

  testWidgets('login back pops to the page that pushed login', (tester) async {
    final router = _loginBackRouter(initialLocation: '/source');
    addTearDown(router.dispose);

    await tester.pumpWidget(_routerApp(router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('source-open-login')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.login);

    await tester.tap(find.byKey(const ValueKey('login-back')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/source');
  });

  testWidgets('login back uses safe return target without history', (
    tester,
  ) async {
    final router = _loginBackRouter(
      initialLocation:
          '${RoutePaths.login}?returnTo=${Uri.encodeQueryComponent(RoutePaths.reportCreate)}',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_routerApp(router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('login-back')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, RoutePaths.reports);
  });

  testWidgets('system back uses safe return target without history', (
    tester,
  ) async {
    final router = _loginBackRouter(
      initialLocation:
          '${RoutePaths.login}?returnTo=${Uri.encodeQueryComponent(RoutePaths.reportCreate)}',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_routerApp(router));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.state.uri.path, RoutePaths.reports);
  });

  testWidgets('push to report detail from notifications', (tester) async {
    final container = ProviderContainer(
      overrides: [sessionControllerProvider.overrideWith(_Session.new)],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go(RoutePaths.map);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.state.uri.path, RoutePaths.map);
    router.push(RoutePaths.notifications);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.state.uri.path, RoutePaths.notifications);
    // Màn Thông báo push route con /notifications/report/:id (ngoài shell) —
    // push /reports/:id ở đây sẽ dựng lại page shell và trùng key Navigator.
    router.push(RoutePaths.notificationReportDetail('28'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(router.state.uri.path, '/notifications/report/28');
  });
}

GoRouter _loginBackRouter({required String initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/source',
      builder: (context, state) => Scaffold(
        body: TextButton(
          key: const ValueKey('source-open-login'),
          onPressed: () => context.push(
            '${RoutePaths.login}?returnTo=${Uri.encodeQueryComponent(RoutePaths.reportCreate)}',
          ),
          child: const Text('Open login'),
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.login,
      builder: (context, state) => LoginScreen(
        returnTo: sanitizeReturnTo(state.uri.queryParameters['returnTo']),
      ),
    ),
    GoRoute(
      path: RoutePaths.reports,
      builder: (context, state) => const Scaffold(body: Text('Reports')),
    ),
  ],
);

Widget _routerApp(GoRouter router) => ProviderScope(
  child: MaterialApp.router(
    routerConfig: router,
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ),
);

class _Session extends SessionController {
  @override
  SessionState build() => SessionState.authenticated(
    UserModel.fromJson({
      'id': '1',
      'email': 'admin@campha.gov.vn',
      'role': {'code': 'system_admin'},
    }),
  );
}
