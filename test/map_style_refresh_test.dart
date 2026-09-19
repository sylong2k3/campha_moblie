import 'dart:async';
import 'dart:convert';

import 'package:campha_moblie/core/storage/token_storage.dart';
import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/map/data/map_repository.dart';
import 'package:campha_moblie/features/map/domain/flood_scenario_controller.dart';
import 'package:campha_moblie/features/map/domain/layer_model.dart';
import 'package:campha_moblie/features/map/domain/map_controller.dart';
import 'package:campha_moblie/features/map/presentation/legend_card_widget.dart';
import 'package:campha_moblie/features/map/presentation/map_home_screen.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import 'support/memory_secure_storage.dart';

LayerModel _layer(String geometry, Map<String, dynamic> style) => LayerModel(
  id: '1',
  code: 'test_layer',
  nameVi: 'Test layer',
  category: 'test',
  geometryType: geometry,
  storageKind: 'postgis',
  srid: 4326,
  isPublic: true,
  legend: const {},
  defaultStyle: style,
);

class _Catalog extends MapCatalogController {
  _Catalog(this.layer);
  final LayerModel layer;
  @override
  MapCatalogState build() =>
      MapCatalogState(layers: [layer], activeLayerIds: {'1'});
  void refresh(LayerModel next) => state = state.copyWith(layers: [next]);
}

class _Guest extends SessionController {
  @override
  SessionState build() => const SessionState.guest();
}

class _Scenarios extends FloodScenarioController {
  @override
  FloodScenarioState build() => const FloodScenarioState();
}

class _Style extends Fake implements StyleManager {
  final layers = <String, Map<String, dynamic>>{};
  int sourceAdds = 0;
  int layerAdds = 0;
  int updates = 0;
  int layerChecks = 0;
  int invalidUpdates = 0;
  Future<bool> Function(String)? onLayerExists;
  Future<void> Function()? onAddSource;
  @override
  Future<void> localizeLabels(String locale, List<String>? ids) async {}
  @override
  Future<bool> styleLayerExists(String id) async {
    layerChecks++;
    return onLayerExists == null
        ? layers.containsKey(id)
        : await onLayerExists!(id);
  }

  @override
  Future<void> addStyleSource(String id, String properties) async {
    sourceAdds++;
    await onAddSource?.call();
  }

  @override
  Future<void> setStyleSourceProperties(String id, String properties) async {}

  @override
  Future<void> addStyleLayer(String properties, LayerPosition? position) async {
    final json = jsonDecode(properties) as Map<String, dynamic>;
    layers[json['id'] as String] = json;
    layerAdds++;
  }

  @override
  Future<void> setStyleLayerProperties(String id, String properties) async {
    if (!layers.containsKey(id)) invalidUpdates++;
    expectSync(layers, contains(id));
    layers[id] = jsonDecode(properties) as Map<String, dynamic>;
    updates++;
  }

  @override
  Future<void> removeStyleLayer(String id) async {
    layers.remove(id);
  }

  @override
  Future<void> removeStyleSource(String id) async {}
}

class _Http extends Fake implements MapboxHttpService {
  bool fail = false;
  @override
  Future<void> setCustomHeadersForHost(
    String host,
    Map<String, String> headers,
  ) async {
    if (fail) throw PlatformException(code: 'channel-error');
  }
}

class _Compass extends Fake implements CompassSettingsInterface {
  @override
  Future<void> updateSettings(CompassSettings settings) async {}
}

class _ScaleBar extends Fake implements ScaleBarSettingsInterface {
  @override
  Future<void> updateSettings(ScaleBarSettings settings) async {}
}

class _Map extends Fake implements MapboxMap {
  @override
  final _Style style = _Style();
  @override
  final _Http httpService = _Http();
  @override
  final compass = _Compass();
  @override
  final scaleBar = _ScaleBar();
  @override
  Future<void> setCamera(CameraOptions options) async {}
  @override
  Future<void> setBounds(CameraBoundsOptions options) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #addInteraction ||
        invocation.memberName == #removeInteraction) {
      return null;
    }
    return super.noSuchMethod(invocation);
  }
}

Future<MapWidget> _pumpMap(
  WidgetTester tester,
  _Catalog catalog,
  MapRepository repository,
) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  final container = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(MemorySecureStorage()),
      sessionControllerProvider.overrideWith(_Guest.new),
      mapCatalogProvider.overrideWith(() => catalog),
      mapRepositoryProvider.overrideWithValue(repository),
      floodScenarioProvider.overrideWith(_Scenarios.new),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
    repository.dio.close(force: true);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MapHomeScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return tester.widget<MapWidget>(find.byType(MapWidget));
}

Future<void> _loadStyle(WidgetTester tester, MapWidget widget) async {
  widget.onStyleLoadedListener!(
    StyleLoadedEventData.fromJson({
      'timeInterval': {'begin': 0, 'end': 1},
    }),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('channel error stays handled and retry refreshes style', (
    tester,
  ) async {
    final catalog = _Catalog(_layer('POINT', {'circleColor': '#112233'}));
    final widget = await _pumpMap(tester, catalog, MapRepository(dio: Dio()));
    final map = _Map();
    widget.onMapCreated!(map);
    await tester.pump();
    await _loadStyle(tester, widget);
    final checks = map.style.layerChecks;
    map.style.onLayerExists = (_) async => throw PlatformException(
      code: 'channel-error',
      message:
          'Unable to establish connection on channel: '
          '"dev.flutter.pigeon.mapbox_maps_flutter.StyleManager.styleLayerExists.0".',
    );
    catalog.refresh(_layer('POINT', {'circleColor': '#445566'}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Một lớp bản đồ chưa tải được'), findsOneWidget);
    expect(map.style.layerChecks, checks + 1);

    map.style.onLayerExists = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final paint = map.style.layers['mvt-style-1']!['paint'] as Map;
    expect((paint['circle-color'] as String).toRGBAInt(), 0xFF445566);
    expect(find.text('Một lớp bản đồ chưa tải được'), findsNothing);
    expect(map.style.sourceAdds, 1);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.windows}));

  for (final failPending in [false, true]) {
    testWidgets(
      'pending native query stops after dispose (error: $failPending)',
      (tester) async {
        final catalog = _Catalog(_layer('POINT', {}));
        final widget = await _pumpMap(
          tester,
          catalog,
          MapRepository(dio: Dio()),
        );
        final map = _Map();
        widget.onMapCreated!(map);
        await tester.pump();
        await _loadStyle(tester, widget);
        final pending = Completer<bool>();
        map.style.onLayerExists = (_) => pending.future;
        catalog.setLayerOpacity('1', 0.6);
        await tester.pump();
        catalog.setLayerOpacity('1', 0.4);
        await tester.pump();
        final checks = map.style.layerChecks;
        final updates = map.style.updates;
        map.httpService.fail = failPending;
        await tester.pumpWidget(const SizedBox.shrink());
        widget.onMapLoadedListener!(
          MapLoadedEventData.fromJson({
            'timeInterval': {'begin': 0, 'end': 1},
          }),
        );
        widget.onMapCreated!(map);
        await _loadStyle(tester, widget);
        if (failPending) {
          pending.completeError(PlatformException(code: 'channel-error'));
        } else {
          pending.complete(false);
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(map.style.layerChecks, checks);
        expect(map.style.sourceAdds, 1);
        expect(map.style.updates, updates);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant({TargetPlatform.windows}),
    );
  }

  testWidgets('pending source does not add layer after dispose', (
    tester,
  ) async {
    final catalog = _Catalog(_layer('POINT', {}));
    final widget = await _pumpMap(tester, catalog, MapRepository(dio: Dio()));
    final pending = Completer<void>();
    final map = _Map();
    map.style.onAddSource = () => pending.future;
    widget.onMapCreated!(map);
    await tester.pump();
    await _loadStyle(tester, widget);
    expect(map.style.sourceAdds, 1);
    expect(map.style.layerAdds, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(map.style.layerAdds, 0);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.windows}));

  testWidgets('new native map waits for style and ignores old query', (
    tester,
  ) async {
    final catalog = _Catalog(_layer('POINT', {}));
    final widget = await _pumpMap(tester, catalog, MapRepository(dio: Dio()));
    final oldMap = _Map();
    widget.onMapCreated!(oldMap);
    await tester.pump();
    await _loadStyle(tester, widget);
    final pending = Completer<bool>();
    oldMap.style.onLayerExists = (_) => pending.future;
    catalog.setLayerOpacity('1', 0.6);
    await tester.pump();
    final oldUpdates = oldMap.style.updates;
    final newMap = _Map();
    widget.onMapCreated!(newMap);
    await tester.pump();
    catalog.refresh(_layer('POINT', {'circleColor': '#445566'}));
    await tester.pump();
    pending.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(oldMap.style.updates, oldUpdates);
    expect(newMap.style.layerChecks, 0);
    await _loadStyle(tester, widget);
    final paint = newMap.style.layers['mvt-style-1']!['paint'] as Map;
    expect((paint['circle-color'] as String).toRGBAInt(), 0xFF445566);
    expect(newMap.style.sourceAdds, 1);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.windows}));

  testWidgets('style reload discards pending result from previous style', (
    tester,
  ) async {
    final catalog = _Catalog(_layer('POINT', {}));
    final widget = await _pumpMap(tester, catalog, MapRepository(dio: Dio()));
    final map = _Map();
    widget.onMapCreated!(map);
    await tester.pump();
    await _loadStyle(tester, widget);
    final pending = Completer<bool>();
    map.style.onLayerExists = (_) => pending.future;
    catalog.refresh(_layer('POINT', {'circleColor': '#445566'}));
    await tester.pump();
    map.style.layers.clear();
    map.style.onLayerExists = null;
    await _loadStyle(tester, widget);
    pending.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final paint = map.style.layers['mvt-style-1']!['paint'] as Map;
    expect((paint['circle-color'] as String).toRGBAInt(), 0xFF445566);
    expect(map.style.sourceAdds, 2);
    expect(map.style.invalidUpdates, 0);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.windows}));

  for (final (geometry, prefix, colorKey, sizeKey, sizeProperty) in [
    ('POINT', 'circle', 'circleColor', 'circleRadius', 'circle-radius'),
    ('LINESTRING', 'line', 'strokeColor', 'strokeWidth', 'line-width'),
    ('POLYGON', 'fill', 'fillColor', 'fillOpacity', 'fill-opacity'),
  ]) {
    testWidgets('refresh updates $geometry style without reloading source', (
      tester,
    ) async {
      final catalog = _Catalog(_layer(geometry, {colorKey: '#112233'}));
      final repository = MapRepository(dio: Dio());
      var legendRequests = 0;
      repository.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/legend')) legendRequests++;
            handler.reject(DioException(requestOptions: options));
          },
        ),
      );
      final widget = await _pumpMap(tester, catalog, repository);
      final map = _Map();
      widget.onMapCreated!(map);
      await tester.pump();
      await _loadStyle(tester, widget);
      expect(map.style.layers, contains('mvt-style-1'));
      final oldPaint = map.style.layers['mvt-style-1']!['paint'] as Map;
      final expectedSize = geometry == 'POLYGON' ? 0.6 : 8.0;
      catalog.refresh(
        _layer(geometry, {
          colorKey: '#445566',
          sizeKey: expectedSize,
          if (geometry == 'POINT') 'circleStrokeColor': '#AA0000',
          if (geometry == 'POINT') 'circleStrokeWidth': 3,
          if (geometry == 'POLYGON') 'strokeColor': '#AA0000',
        }),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final paint = map.style.layers['mvt-style-1']!['paint'] as Map;
      expect(paint['$prefix-color'], isNot(oldPaint['$prefix-color']));
      expect((paint['$prefix-color'] as String).toRGBAInt(), 0xFF445566);
      expect(
        paint[sizeProperty],
        closeTo(geometry == 'POLYGON' ? 0.54 : 8, 0.0001),
      );
      if (geometry == 'POINT') {
        expect(
          (paint['circle-stroke-color'] as String).toRGBAInt(),
          0xFFAA0000,
        );
        expect(paint['circle-stroke-width'], 3);
      }
      if (geometry == 'POLYGON') {
        expect((paint['fill-outline-color'] as String).toRGBAInt(), 0xFFAA0000);
      }
      expect(map.style.sourceAdds, 1);
      expect(map.style.layerAdds, 1);
      expect(map.style.updates, greaterThan(0));
      expect(legendRequests, 0);
      final card = tester.widget<LayerLegendCard>(find.byType(LayerLegendCard));
      expect(card.items.single.color, const Color(0xFF445566));
      await tester.tap(find.byKey(const ValueKey('map-legend-close')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LayerLegendCard), findsNothing);
      catalog.setLayerOpacity('1', 0.5);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(LayerLegendCard), findsNothing);
      expect(catalog.state.activeLayerIds, {'1'});
      await tester.tap(find.byKey(const ValueKey('map-legend-toggle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LayerLegendCard), findsOneWidget);
      expect(legendRequests, 0);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant({TargetPlatform.windows}));
  }
}
