import 'dart:async';

import 'package:campha_moblie/core/push/push_coordinator.dart';
import 'package:campha_moblie/core/push/push_service.dart';
import 'package:campha_moblie/core/storage/token_storage.dart';
import 'package:campha_moblie/features/auth/data/auth_repository.dart';
import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/auth/domain/user_model.dart';
import 'package:campha_moblie/features/feature_edit/data/offline_edit_queue.dart';
import 'package:campha_moblie/features/field_reports/data/field_report_repository.dart';
import 'package:campha_moblie/features/field_reports/domain/field_report_models.dart';
import 'package:campha_moblie/features/field_reports/domain/field_reports_controller.dart';
import 'package:campha_moblie/features/field_reports/domain/report_composer_controller.dart';
import 'package:campha_moblie/features/map/data/map_repository.dart';
import 'package:campha_moblie/features/map/domain/layer_model.dart';
import 'package:campha_moblie/features/map/domain/map_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_secure_storage.dart';

class _Auth extends AuthRepository {
  _Auth(TokenStorage storage, {this.role = ''})
    : super(dio: Dio(), tokenStorage: storage);
  final String role;
  @override
  Future<UserModel> getMe() async => UserModel.fromJson({
    'id': '1',
    'email': 'test@example.com',
    'role': {'code': role},
  });
  @override
  Future<void> logout() => tokenStorage.clear();
  @override
  Future<void> deleteAccount() => tokenStorage.clear();
}

class _Queue extends Fake implements OfflineEditQueue {
  int purges = 0;
  Completer<void>? pending;
  @override
  Future<void> purgeOwner(String ownerId) async {
    expect(ownerId, '1');
    purges++;
    await pending?.future;
  }
}

class _Draft extends ReportComposerController {
  _Draft(this.onClear);
  final void Function() onClear;
  @override
  ReportComposerState build() => const ReportComposerState(restoring: false);
  @override
  Future<void> clear() async => onClear();
}

class _Reports extends FieldReportsController {
  @override
  FieldReportsState build() => const FieldReportsState();
}

class _ReportRepository extends Fake implements FieldReportRepository {
  final publicReady = Completer<void>();
  final publicCalls = <({int page, int limit})>[];
  final publicTokens = <CancelToken>[];
  CancelToken? adminToken;

  FieldReportPage _page(bool admin, int page, int limit) {
    final json = {
      'id': admin ? 'private' : 'public-$page',
      'reference_code': 'CP-001',
      'description': 'Report content',
      'status': admin ? 'pending' : 'approved',
      'longitude': 107.3,
      'latitude': 21.0,
      'created_at': '2026-09-01T00:00:00Z',
      'updated_at': '2026-09-01T00:00:01Z',
      'sender_name': 'Private sender',
      'sender_email': 'private@example.test',
    };
    return FieldReportPage(
      items: [
        admin ? FieldReport.fromJson(json) : FieldReport.fromPublicJson(json),
      ],
      page: page,
      limit: limit,
      total: admin ? 1 : limit + 1,
      totalPages: admin ? 1 : 2,
    );
  }

  @override
  Future<FieldReportPage> getAdmin({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    adminToken = cancelToken;
    return _page(true, page, limit);
  }

  @override
  Future<FieldReportPage> getPublic({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    publicCalls.add((page: page, limit: limit));
    publicTokens.add(cancelToken!);
    await publicReady.future;
    return _page(false, page, limit);
  }
}

class _Push extends Fake implements PushService {
  @override
  Future<void> unregisterDevice() async {}
}

class _MapRepository extends MapRepository {
  _MapRepository() : super(dio: Dio());
  int loads = 0;
  @override
  Future<List<LayerModel>> getLayers({String? category}) async {
    loads++;
    return [
      LayerModel(
        id: '1',
        code: 'public',
        nameVi: 'Public',
        category: 'test',
        geometryType: 'POINT',
        storageKind: 'postgis',
        srid: 4326,
        isPublic: true,
        legend: const {},
        isEnableDefault: true,
      ),
    ];
  }

  @override
  Future<List<BasemapModel>> getBasemaps() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final action in ['logout', 'deleteAccount', 'tokenExpired']) {
    test(
      '$action cleans owner once and preserves public map selection',
      () async {
        final tokens = TokenStorage(MemorySecureStorage());
        await tokens.saveTokens(accessToken: 'access', refreshToken: 'refresh');
        final auth = _Auth(tokens);
        final repository = _MapRepository();
        final queue = _Queue();
        var draftClears = 0;
        final container = ProviderContainer(
          overrides: [
            tokenStorageProvider.overrideWithValue(tokens),
            authRepositoryProvider.overrideWithValue(auth),
            mapRepositoryProvider.overrideWithValue(repository),
            offlineEditQueueProvider.overrideWith((ref) async => queue),
            reportComposerProvider.overrideWith(
              () => _Draft(() => draftClears++),
            ),
            fieldReportsProvider.overrideWith(_Reports.new),
            appPushCoordinatorProvider.overrideWithValue(_Push()),
          ],
        );
        addTearDown(() {
          container.dispose();
          auth.dio.close(force: true);
          repository.dio.close(force: true);
        });
        container.read(sessionControllerProvider);
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(sessionControllerProvider).isAuthenticated,
          isTrue,
        );
        final subscription = container.listen(mapCatalogProvider, (_, _) {});
        addTearDown(subscription.close);
        await Future<void>.delayed(Duration.zero);
        final catalog = container.read(mapCatalogProvider.notifier);
        final basemap = container.read(mapCatalogProvider).basemaps.last.code;
        catalog.selectBasemap(basemap);
        catalog.setLayerOpacity('1', 0.4);
        catalog.disableAll();
        final loads = repository.loads;
        final session = container.read(sessionControllerProvider.notifier);
        switch (action) {
          case 'logout':
            await session.logout();
          case 'deleteAccount':
            await session.deleteAccount();
          case 'tokenExpired':
            await tokens.clear();
        }
        await Future<void>.delayed(Duration.zero);
        expect(queue.purges, 1);
        expect(draftClears, 1);
        expect(repository.loads, loads + 1);
        expect(await tokens.readAccessToken(), isNull);
        expect(
          container.read(sessionControllerProvider).isAuthenticated,
          isFalse,
        );
        expect(container.read(mapCatalogProvider.notifier), same(catalog));
        final after = container.read(mapCatalogProvider);
        expect(after.selectedBasemapCode, basemap);
        expect(after.opacityOf('1'), 0.4);
        expect(after.activeLayerIds, isEmpty);
      },
    );

    for (final mapMode in [false, true]) {
      for (final responseBeforeCleanup in [false, true]) {
        test(
          '$action keeps public reload through delayed cleanup '
          '(map: $mapMode, response before cleanup: $responseBeforeCleanup)',
          () async {
            final tokens = TokenStorage(MemorySecureStorage());
            await tokens.saveTokens(
              accessToken: 'access',
              refreshToken: 'refresh',
            );
            final auth = _Auth(tokens, role: 'system_admin');
            final repository = _ReportRepository();
            final queue = _Queue()..pending = Completer<void>();
            var draftClears = 0;
            final container = ProviderContainer(
              overrides: [
                tokenStorageProvider.overrideWithValue(tokens),
                authRepositoryProvider.overrideWithValue(auth),
                fieldReportRepositoryProvider.overrideWithValue(repository),
                offlineEditQueueProvider.overrideWith((ref) async => queue),
                reportComposerProvider.overrideWith(
                  () => _Draft(() => draftClears++),
                ),
                appPushCoordinatorProvider.overrideWithValue(_Push()),
              ],
            );
            addTearDown(() {
              container.dispose();
              auth.dio.close(force: true);
            });
            container.read(sessionControllerProvider);
            await pumpEventQueue();
            expect(
              container.read(sessionControllerProvider).isAuthenticated,
              isTrue,
            );
            final subscription = container.listen(
              fieldReportsProvider,
              (_, _) {},
            );
            addTearDown(subscription.close);
            await pumpEventQueue();
            final controller = container.read(fieldReportsProvider.notifier);
            await controller.setMapMode(mapMode);
            expect(
              container.read(fieldReportsProvider).items.single.senderName,
              'Private sender',
            );

            final session = container.read(sessionControllerProvider.notifier);
            final ending = switch (action) {
              'logout' => session.logout(),
              'deleteAccount' => session.deleteAccount(),
              _ => tokens.clear(),
            };
            await pumpEventQueue();
            expect(
              container.read(sessionControllerProvider).isAuthenticated,
              isFalse,
            );
            expect(queue.purges, 1);
            expect(draftClears, 0);
            final reset = container.read(fieldReportsProvider);
            expect(reset.admin, isFalse);
            expect(reset.mapMode, mapMode);
            expect(reset.items, isEmpty);
            expect(reset.loading, isTrue);
            expect(repository.adminToken!.isCancelled, isTrue);
            expect(repository.publicCalls.map((call) => call.page), [1]);

            if (responseBeforeCleanup) {
              repository.publicReady.complete();
              await pumpEventQueue();
              expect(container.read(fieldReportsProvider).items, isNotEmpty);
            }
            queue.pending!.complete();
            await ending;
            await pumpEventQueue();
            if (!responseBeforeCleanup) {
              repository.publicReady.complete();
              await pumpEventQueue();
            }

            final after = container.read(fieldReportsProvider);
            expect(after.admin, isFalse);
            expect(after.mapMode, mapMode);
            expect(after.loading, isFalse);
            expect(after.error, isNull);
            expect(after.items.map((item) => item.id), [
              'public-1',
              if (mapMode) 'public-2',
            ]);
            expect(
              after.items.every(
                (item) =>
                    item.isPublic &&
                    item.senderName == null &&
                    item.senderEmail == null,
              ),
              isTrue,
            );
            expect(after.hasMore, !mapMode);
            expect(repository.publicCalls, [
              (page: 1, limit: mapMode ? 100 : 20),
              if (mapMode) (page: 2, limit: 100),
            ]);
            expect(
              repository.publicTokens.every((token) => !token.isCancelled),
              isTrue,
            );
            expect(queue.purges, 1);
            expect(draftClears, 1);
          },
        );
      }
    }
  }
}
