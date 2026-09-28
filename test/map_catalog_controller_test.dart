import 'dart:async';

import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/auth/domain/user_model.dart';
import 'package:campha_moblie/features/map/data/map_repository.dart';
import 'package:campha_moblie/features/map/domain/layer_model.dart';
import 'package:campha_moblie/features/map/domain/map_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

LayerModel _layer(String id, {bool enabled = false, bool isPublic = true}) =>
    LayerModel(
      id: id,
      code: 'ranh_gioi_$id',
      nameVi: 'Ranh giới $id',
      category: 'ranh_gioi',
      geometryType: 'LINESTRING',
      storageKind: 'postgis',
      srid: 4326,
      isPublic: isPublic,
      legend: const {},
      isEnableDefault: enabled,
    );

class _Repository extends MapRepository {
  _Repository(this.layers) : super(dio: Dio());
  List<LayerModel> layers;
  Future<List<LayerModel>> Function()? request;
  int requests = 0;

  @override
  Future<List<LayerModel>> getLayers({String? category}) async {
    requests++;
    return request == null ? layers : request!();
  }

  @override
  Future<List<BasemapModel>> getBasemaps() async => [];
}

class _Session extends SessionController {
  @override
  SessionState build() => const SessionState.guest();

  void authenticate(String id) => state = SessionState.authenticated(
    UserModel.fromJson({'id': id, 'email': 'user@example.com'}),
  );
}

Future<ProviderContainer> _catalog(_Repository repository) async {
  final container = ProviderContainer(
    overrides: [
      mapRepositoryProvider.overrideWithValue(repository),
      sessionControllerProvider.overrideWith(_Session.new),
    ],
  );
  addTearDown(() {
    container.dispose();
    repository.dio.close(force: true);
  });
  container.read(mapCatalogProvider);
  await Future<void>.delayed(Duration.zero);
  return container;
}

void main() {
  test(
    'identity refresh keeps public map state and drops private layers immediately',
    () async {
      final repository = _Repository([
        _layer('1', enabled: true),
        _layer('2', enabled: true, isPublic: false),
      ]);
      final container = await _catalog(repository);
      final controller = container.read(mapCatalogProvider.notifier);
      final selectedBasemap = container
          .read(mapCatalogProvider)
          .basemaps
          .last
          .code;
      controller.selectBasemap(selectedBasemap);
      controller.setLayerOpacity('1', 0.4);
      controller.setLayerOpacity('2', 0.6);
      final pending = Completer<List<LayerModel>>();
      repository.request = () => pending.future;
      final session =
          container.read(sessionControllerProvider.notifier) as _Session;
      final before = repository.requests;
      session.authenticate('1');
      final changing = container.read(mapCatalogProvider);
      expect(changing.layers.map((layer) => layer.id), ['1']);
      expect(changing.activeLayerIds, {'1'});
      expect(changing.opacityByLayer, {'1': 0.4});
      expect(changing.selectedBasemapCode, selectedBasemap);
      await Future<void>.delayed(Duration.zero);
      expect(repository.requests, before + 1);
      pending.complete([_layer('1', enabled: true)]);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(mapCatalogProvider.notifier), same(controller));
      expect(
        container.read(mapCatalogProvider).selectedBasemapCode,
        selectedBasemap,
      );
      session.authenticate('1'); // Same identity refresh must not reload tiles.
      await Future<void>.delayed(Duration.zero);
      expect(repository.requests, before + 1);
      session.continueAsGuest();
      await Future<void>.delayed(Duration.zero);
      expect(repository.requests, before + 2);
      expect(container.read(mapCatalogProvider).opacityOf('1'), 0.4);
    },
  );

  test('only API-enabled layers activate on first load', () async {
    final container = await _catalog(
      _Repository([_layer('1', enabled: true), _layer('2')]),
    );
    expect(container.read(mapCatalogProvider).activeLayerIds, {'1'});
    expect(container.read(mapCatalogProvider).error, isNull);
  });

  test('all defaults false never activate heuristic or first layer', () async {
    final container = await _catalog(_Repository([_layer('1'), _layer('2')]));
    expect(container.read(mapCatalogProvider).activeLayerIds, isEmpty);
  });

  for (final disableAll in [true, false]) {
    test('reload preserves empty selection (disableAll=$disableAll)', () async {
      final container = await _catalog(
        _Repository([_layer('1', enabled: true)]),
      );
      final controller = container.read(mapCatalogProvider.notifier);
      if (disableAll) {
        controller.disableAll();
      } else {
        controller.setLayerVisible('1', false);
      }
      await controller.load();
      expect(container.read(mapCatalogProvider).activeLayerIds, isEmpty);
      controller.resetForIdentityChange();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(mapCatalogProvider).activeLayerIds, isEmpty);
    });
  }

  test('removed selection never activates a different default layer', () async {
    final repository = _Repository([_layer('1', enabled: true)]);
    final container = await _catalog(repository);
    repository.layers = [_layer('2', enabled: true)];
    await container.read(mapCatalogProvider.notifier).load();
    expect(container.read(mapCatalogProvider).activeLayerIds, isEmpty);
  });

  test('failed first load can retry API defaults', () async {
    final repository = _Repository([_layer('1', enabled: true)])
      ..request = () => Future.error(StateError('offline'));
    final container = await _catalog(repository);
    expect(container.read(mapCatalogProvider).error, isNotNull);
    repository.request = null;
    await container.read(mapCatalogProvider.notifier).load();
    expect(container.read(mapCatalogProvider).activeLayerIds, {'1'});
  });

  test(
    'disable during first request wins and invalidation can reload',
    () async {
      final initial = Completer<List<LayerModel>>();
      final repository = _Repository([_layer('1', enabled: true)])
        ..request = () => initial.future;
      final container = await _catalog(repository);
      container.read(mapCatalogProvider.notifier).disableAll();
      initial.complete(repository.layers);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(mapCatalogProvider).activeLayerIds, isEmpty);
      repository.request = null;
      container.invalidate(mapCatalogProvider);
      container.read(mapCatalogProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(mapCatalogProvider).loading, isFalse);
      expect(container.read(mapCatalogProvider).activeLayerIds, {'1'});
    },
  );

  test('empty first catalog does not reapply defaults on refresh', () async {
    final repository = _Repository([]);
    final container = await _catalog(repository);
    repository.layers = [_layer('1', enabled: true)];
    await container.read(mapCatalogProvider.notifier).load();
    expect(container.read(mapCatalogProvider).activeLayerIds, isEmpty);
  });

  test(
    'latest reload wins and pending response after dispose is ignored',
    () async {
      final repository = _Repository([_layer('1', enabled: true)]);
      final container = await _catalog(repository);
      final controller = container.read(mapCatalogProvider.notifier);
      final old = Completer<List<LayerModel>>();
      repository.request = () => old.future;
      final pending = controller.load();
      repository.request = null;
      repository.layers = [_layer('2')];
      await controller.load();
      old.complete([_layer('1', enabled: true)]);
      await pending;
      expect(container.read(mapCatalogProvider).layers.single.id, '2');
      final disposed = Completer<List<LayerModel>>();
      repository.request = () => disposed.future;
      final finalRequest = controller.load();
      container.dispose();
      disposed.complete([]);
      await finalRequest;
    },
  );
}
