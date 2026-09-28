import 'package:campha_moblie/core/push/push_coordinator.dart';
import 'package:campha_moblie/core/push/push_service.dart';
import 'package:campha_moblie/core/storage/token_storage.dart';
import 'package:campha_moblie/features/auth/data/auth_repository.dart';
import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/auth/domain/user_model.dart';
import 'package:campha_moblie/features/feature_edit/data/offline_edit_queue.dart';
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
  _Auth(TokenStorage storage) : super(dio: Dio(), tokenStorage: storage);
  @override
  Future<UserModel> getMe() async =>
      UserModel.fromJson({'id': '1', 'email': 'test@example.com'});
  @override
  Future<void> logout() => tokenStorage.clear();
  @override
  Future<void> deleteAccount() => tokenStorage.clear();
}

class _Queue extends Fake implements OfflineEditQueue {
  int purges = 0;
  @override
  Future<void> purgeOwner(String ownerId) async {
    expect(ownerId, '1');
    purges++;
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
  }
}
