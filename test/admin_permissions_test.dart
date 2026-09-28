import 'package:campha_moblie/app/router/app_router.dart';
import 'package:campha_moblie/app/router/route_names.dart';
import 'package:campha_moblie/core/error/app_exception.dart';
import 'package:campha_moblie/core/network/interceptors/idempotent_retry_interceptor.dart';
import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/auth/domain/user_model.dart';
import 'package:campha_moblie/features/feature_edit/data/feature_edit_repository.dart';
import 'package:campha_moblie/features/feature_edit/presentation/feature_edit_screen.dart';
import 'package:campha_moblie/features/map/domain/feature_detail_model.dart';
import 'package:campha_moblie/features/map/domain/layer_model.dart';
import 'package:campha_moblie/features/map/domain/map_controller.dart';
import 'package:campha_moblie/features/map/presentation/feature_detail_screen.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _updatePermission = <String, dynamic>{
  'map_feature': {'update': true},
};
const _featureKey = (layerId: '1', featureId: 'feature_1');

UserModel _user({
  String role = 'system_admin',
  Map<String, dynamic> permissions = const {},
  bool active = true,
  bool mustChangePassword = false,
}) => UserModel.fromJson({
  'id': '1',
  'role': {'code': role, 'permissions': permissions},
  'is_active': active,
  'must_change_password': mustChangePassword,
});

void main() {
  test('active admin has client capabilities without changing payload', () {
    for (final permissions in <Map<String, dynamic>>[
      {},
      {
        'map_feature': {'update': false},
        'field_report': <String>[],
        'users.delete': false,
      },
    ]) {
      final user = _user(permissions: permissions);
      expect(user.isSystemAdmin, isTrue);
      expect(user.isTnmtAdmin, isFalse);
      expect(user.canEditMapFeatures, isTrue);
      for (final (resource, action) in [
        ('map_feature', 'update'),
        ('field_report', 'create'),
        ('field_report', 'approve'),
        ('documents', 'read_internal'),
        ('users', 'delete'),
        ('roles', 'update'),
      ]) {
        expect(user.hasPermission(resource, action), isTrue);
      }
      expect(user.permissions, permissions);
      expect(user.toJson()['role'], {
        'code': 'system_admin',
        'name': '',
        'permissions': permissions,
      });
    }
  });

  test('only active admin bypasses permission payload', () {
    for (final role in [
      'guest',
      'citizen',
      'ubnd_tp',
      'so_tnmt',
      'so_xd',
      'admin',
      'SYSTEM_ADMIN',
      'unknown',
      '',
    ]) {
      final user = _user(role: role);
      expect(user.isSystemAdmin, isFalse, reason: role);
      expect(
        user.hasPermission('map_feature', 'update'),
        isFalse,
        reason: role,
      );
      expect(user.canEditMapFeatures, isFalse, reason: role);
    }
    for (final role in ['system_admin', 'so_tnmt']) {
      final user = _user(
        role: role,
        permissions: _updatePermission,
        active: false,
      );
      expect(user.hasPermission('map_feature', 'update'), isFalse);
      expect(user.canEditMapFeatures, isFalse);
    }
  });

  test('TNMT still needs explicit permission in supported payload formats', () {
    for (final permissions in <Map<String, dynamic>>[
      _updatePermission,
      {
        'map_feature': ['update'],
      },
      {'map_feature.update': true},
    ]) {
      expect(
        _user(role: 'so_tnmt', permissions: permissions).canEditMapFeatures,
        isTrue,
      );
      for (final role in ['citizen', 'ubnd_tp', 'so_xd', 'unknown']) {
        expect(
          _user(role: role, permissions: permissions).canEditMapFeatures,
          isFalse,
        );
      }
    }
    expect(
      _user(
        role: 'so_tnmt',
        permissions: {
          'map_feature': {'update': false},
        },
      ).canEditMapFeatures,
      isFalse,
    );
  });

  testWidgets('GIS routes admit admin but preserve auth and role guards', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    final paths = [
      RoutePaths.mapFeatureEdit('1', 'feature_1'),
      RoutePaths.mapFeatureHistory('1', 'feature_1'),
      RoutePaths.mapFeatureSync,
    ];
    for (final (session, deniedPath) in <(SessionState, String?)>[
      (SessionState.authenticated(_user()), null),
      (
        SessionState.authenticated(
          _user(role: 'so_tnmt', permissions: _updatePermission),
        ),
        null,
      ),
      (SessionState.authenticated(_user(role: 'so_tnmt')), RoutePaths.map),
      (
        SessionState.authenticated(
          _user(role: 'citizen', permissions: _updatePermission),
        ),
        RoutePaths.map,
      ),
      (
        SessionState.authenticated(
          _user(role: 'unknown', permissions: _updatePermission),
        ),
        RoutePaths.map,
      ),
      (SessionState.authenticated(_user(active: false)), RoutePaths.map),
      (
        SessionState.authenticated(_user(mustChangePassword: true)),
        RoutePaths.changePassword,
      ),
      (const SessionState.guest(), RoutePaths.login),
      (const SessionState.bootstrapping(), RoutePaths.splash),
    ]) {
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWith(() => _Session(session)),
        ],
      );
      addTearDown(container.dispose);
      final configuration = container.read(appRouterProvider).configuration;
      for (final path in paths) {
        final match = configuration.findMatch(Uri.parse(path));
        expect(match.isError, isFalse);
        final redirect = await configuration.topRedirect(
          context,
          configuration.buildTopLevelGoRouterState(match),
        );
        expect(
          redirect == null ? null : Uri.parse(redirect).path,
          deniedPath,
          reason: '${session.user?.roleCode ?? session.status}: $path',
        );
        if (deniedPath == RoutePaths.login || deniedPath == RoutePaths.splash) {
          expect(Uri.parse(redirect!).queryParameters['returnTo'], path);
        }
      }
    }
  });

  for (final (label, user, layerCanEdit, version, showActions) in [
    ('admin', _user(), true, 3, true),
    (
      'TNMT',
      _user(role: 'so_tnmt', permissions: _updatePermission),
      true,
      3,
      true,
    ),
    ('read-only layer', _user(), false, 3, false),
    ('missing version', _user(), true, null, true),
    ('inactive admin', _user(active: false), true, 3, false),
    (
      'citizen',
      _user(role: 'citizen', permissions: _updatePermission),
      true,
      3,
      false,
    ),
  ]) {
    testWidgets('$label: detail and form use same capability', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWith(
            () => _Session(SessionState.authenticated(user)),
          ),
          mapCatalogProvider.overrideWith(() => _Catalog(layerCanEdit)),
          mapFeatureProvider(_featureKey).overrideWith(
            (ref) async => FeatureDetailModel(
              id: _featureKey.featureId,
              layerId: _featureKey.layerId,
              version: version,
              attributes: const {
                'name': 'Cam Pha',
                'private_field': 'Read only',
              },
              geometry: const {
                'type': 'Point',
                'coordinates': [107.319395, 21.025420],
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        _app(
          container,
          const FeatureDetailScreen(layerId: '1', featureId: 'feature_1'),
        ),
      );
      await tester.pumpAndSettle();
      final edit = find.byKey(const ValueKey('feature-edit-action'));
      expect(edit, showActions ? findsOneWidget : findsNothing);
      expect(
        find.byKey(const ValueKey('feature-history-action')),
        showActions ? findsOneWidget : findsNothing,
      );
      if (showActions) {
        expect(
          tester.widget<IconButton>(edit).onPressed,
          version == null ? isNull : isNotNull,
        );
      }
      await tester.pumpWidget(
        _app(
          container,
          const FeatureEditScreen(layerId: '1', featureId: 'feature_1'),
        ),
      );
      await tester.pumpAndSettle();
      final canEdit = showActions && version != null;
      expect(find.byType(Form), canEdit ? findsOneWidget : findsNothing);
      if (canEdit) {
        expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
        expect(
          find.widgetWithText(TextFormField, 'Private Field'),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final operation in ['update', 'restore']) {
    test('$operation preserves server 403 without retrying write', () async {
      final dio = Dio();
      addTearDown(() => dio.close(force: true));
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<Object>(
                  requestOptions: options,
                  statusCode: 403,
                  data: {'message': 'Forbidden'},
                ),
              ),
            );
          },
        ),
      );
      dio.interceptors.add(IdempotentRetryInterceptor(dio));
      final repository = FeatureEditRepository(dio);
      await expectLater(
        operation == 'update'
            ? repository.update(
                layerId: '1',
                featureId: 'feature_1',
                baseVersion: 3,
                attributes: {'name': 'Updated'},
              )
            : repository.restore(
                layerId: '1',
                featureId: 'feature_1',
                baseVersion: 3,
                version: 1,
              ),
        throwsA(isA<ForbiddenException>()),
      );
      expect(requests, hasLength(1));
      expect(requests.single.data, {
        'baseVersion': 3,
        if (operation == 'update') 'attributes': {'name': 'Updated'},
      });
    });
  }
}

Widget _app(ProviderContainer container, Widget home) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

class _Session extends SessionController {
  _Session(this.initial);
  final SessionState initial;
  @override
  SessionState build() => initial;
}

class _Catalog extends MapCatalogController {
  _Catalog(this.canEdit);
  final bool canEdit;
  @override
  MapCatalogState build() => MapCatalogState(
    layers: [
      LayerModel(
        id: '1',
        code: 'test',
        nameVi: 'Test layer',
        category: 'test',
        geometryType: 'POINT',
        storageKind: 'postgis',
        srid: 4326,
        isPublic: true,
        legend: const {},
        canEdit: canEdit,
        editableFields: const ['name'],
      ),
    ],
  );
}
