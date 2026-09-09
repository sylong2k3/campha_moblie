import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:campha_moblie/features/map/data/map_repository.dart';
import 'package:campha_moblie/features/map/domain/flood_scenario_controller.dart';
import 'package:campha_moblie/features/map/domain/flood_scenario_model.dart';
import 'package:campha_moblie/features/map/domain/flood_hydrology_controller.dart';
import 'package:campha_moblie/features/map/domain/flood_hydrology_model.dart';
import 'package:campha_moblie/features/map/domain/forest_classification_controller.dart';
import 'package:campha_moblie/features/map/domain/forest_classification_model.dart';
import 'package:campha_moblie/features/map/domain/layer_model.dart';
import 'package:campha_moblie/features/map/domain/map_controller.dart';
import 'package:campha_moblie/features/map/presentation/flood_scenario_sheet.dart';
import 'package:campha_moblie/features/map/presentation/flood_hydrology_sheet.dart';
import 'package:campha_moblie/features/map/presentation/forest_classification_sheet.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> scenarioJson(
  int id, {
  double rain = 10,
  bool withLayer = true,
}) => {
  'id': id,
  'code': 's$id',
  'name_vi': 'Kịch bản $id',
  'min_rainfall': '$rain',
  'is_active': true,
  'current_rainfall': '310.50',
  'rainfall_source': 'MANUAL',
  'min_tide': null,
  'max_tide': '2.15',
  'current_tide': 2.1,
  'tide_source': 'AUTO',
  'layer': withLayer
      ? {
          'id': 95 + id,
          'code': 'layer$id',
          'nameVi': 'Lớp $id',
          'geometryType': 'RASTER',
          'storageKind': 'geotiff_minio',
          'srid': 32648,
          'isPublic': true,
        }
      : null,
};

ForestSnapshot snapshot(int id) => ForestSnapshot.fromJson({
  'id': '$id',
  'year': 2026,
  'month': id,
  'geoserverLayer': 'campha:forest_$id',
  'provinceSummary': {
    'totalHa': '100',
    'forestPercent': 25,
    'legend': [
      for (var i = 0; i < 8; i++)
        {
          'classId': i,
          'nameVi': 'Lớp $i',
          'color': '#006400',
          'ha': '12.5',
          'percent': 12.5,
        },
    ],
  },
});

class Repository extends MapRepository {
  Repository() : super(dio: Dio());
  List<FloodScenarioModel> scenarios = [
    FloodScenarioModel.fromJson(scenarioJson(1)),
    FloodScenarioModel.fromJson(scenarioJson(2, rain: 300)),
    FloodScenarioModel.fromJson(scenarioJson(3, rain: 999, withLayer: false)),
  ];
  int scenarioLoads = 0;
  Completer<List<FloodScenarioModel>>? scenarioRequest;
  final snapshots = <int, Completer<ForestSnapshot?>>{};
  @override
  Future<List<FloodScenarioModel>> getFloodScenarios({
    bool activeOnly = true,
    int limit = 100,
  }) async {
    scenarioLoads++;
    expect(activeOnly, true);
    return scenarioRequest == null ? scenarios : scenarioRequest!.future;
  }

  @override
  Future<List<FloodRun>> getFloodRuns() async => [
    for (var i = 1; i <= 2; i++)
      FloodRun(
        id: i,
        name: 'Kỳ $i',
        periodText: '2026-08-01 – 2026-08-20',
        status: 'SUCCEEDED',
      ),
  ];
  @override
  Future<List<FloodArtifact>> getFloodArtifacts() async => [
    for (var i = 1; i <= 3; i++)
      FloodArtifact(
        id: i,
        analysisRunId: i == 3 ? 2 : 1,
        code: 'flood_extent',
        labelVi: 'Vùng ngập $i',
        isPublic: true,
        registryLayerId: '${100 + i}',
      ),
    const FloodArtifact(
      id: 4,
      analysisRunId: 1,
      code: 'crop_affected',
      labelVi: 'Chưa publish',
      isPublic: true,
    ),
  ];
  @override
  Future<List<FloodHydrologyLegend>> getFloodLegends() async => [
    const FloodHydrologyLegend(
      code: 'flood_extent',
      label: 'Vùng ngập',
      entries: [(color: '#1f78b4', label: 'Ngập')],
    ),
  ];
  @override
  Future<ForestSnapshot?> getForestClassificationLatest() async => snapshot(1);
  @override
  Future<List<ForestSnapshot>> getForestClassificationHistory() async => [
    snapshot(1),
    snapshot(2),
  ];
  @override
  Future<ForestSnapshot?> getForestClassificationSnapshot(int id) =>
      (snapshots[id] ??= Completer<ForestSnapshot?>()).future;
}

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final FutureOr<Map<String, dynamic>> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(await respond(options)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class EmptyCatalog extends MapCatalogController {
  @override
  MapCatalogState build() => const MapCatalogState();
}

void main() {
  test(
    'scenario parses current conditions, preserves precision, missing layer disables',
    () {
      final scenario = FloodScenarioModel.fromJson(scenarioJson(1));
      expect(scenario.currentRainfall, 310.5);
      expect(scenario.tideRangeText, '≤ 2.15 m');
      expect(scenario.currentConditionsText, contains('Tự động từ trạm'));
      expect(scenario.currentConditionsText, contains('Thủ công'));
      expect(
        FloodScenarioModel.fromJson(
          scenarioJson(2, withLayer: false),
        ).canSelect,
        false,
      );
    },
  );

  test(
    'proxy has registry ID, bbox literal, no time/layers/styles/service or duplicate api prefix',
    () {
      final repository = Repository();
      final url = repository.floodWmsUrl('96', ticket: 'a+b&c');
      expect(url, contains('/api/v1/maps/layers/96/wms?'));
      expect(url, contains('bbox={bbox-epsg-3857}'));
      final uri = Uri.parse(url);
      expect(uri.queryParameters['ticket'], 'a+b&c');
      expect(uri.queryParameters['crs'], 'EPSG:3857');
      for (final key in ['time', 'layers', 'styles', 'service', 'srs']) {
        expect(uri.queryParameters.containsKey(key), false);
      }
      expect(
        Uri.parse(
          repository.floodWmsUrl('96'),
        ).queryParameters.containsKey('ticket'),
        false,
      );
      expect(() => repository.floodWmsUrl('../x'), throwsFormatException);
    },
  );

  test('production hydrology shape and numeric strings parse', () {
    final run = FloodRun.fromJson({
      'id': '11',
      'status': 'SUCCEEDED',
      'period': {
        'analysis': [
          {'start': '2026-06-30', 'end': '2026-07-30'},
        ],
      },
      'resultMetadata': {
        'areaStats': {'floodExtentAreaHa': '744.9'},
      },
    });
    expect(run.periodText, '2026-06-30 – 2026-07-30');
    expect(run.summary['Diện tích ngập (ha)'], 744.9);
    final artifact = FloodArtifact.fromJson({
      'id': '109',
      'analysisRunId': '11',
      'registryLayerId': '250',
      'code': 'encroachment_alert',
      'isPublic': true,
    });
    expect(artifact.registryLayerId, '250');
    expect(artifact.group, 'Tiêu thoát nước');
  });

  test(
    'forest supports production aliases and prefers WMS, falls back only to valid GEE XYZ',
    () {
      final item = snapshot(1);
      expect(item.legend.length, 8);
      expect(item.legend.first.areaHa, 12.5);
      expect(item.totalAreaHa, 100);
      final repository = Repository();
      final url = repository.forestTileUrl(item)!;
      expect(url, contains('bbox={bbox-epsg-3857}'));
      expect(Uri.parse(url).queryParameters['version'], '1.3.0');
      expect(Uri.parse(url).queryParameters['layers'], 'campha:forest_1');
      final alias = ForestSnapshot.fromJson({
        'id': '8',
        'year': 2026,
        'month': 8,
        'geoserver_layer': 'campha:forest_8',
        'province_summary': {'totalHa': 123, 'legend': []},
      });
      expect(alias.geoserverLayer, 'campha:forest_8');
      expect(alias.totalAreaHa, 123);
      const gee =
          'https://earthengine.googleapis.com/v1/maps/example/tiles/{z}/{x}/{y}';
      expect(
        repository.forestTileUrl(
          const ForestSnapshot(id: 1, year: 2026, month: 1, geeTileUrl: gee),
        ),
        gee,
      );
      expect(
        () => repository.forestTileUrl(
          const ForestSnapshot(
            id: 1,
            year: 2026,
            month: 1,
            geeTileUrl: 'http://evil.test/{z}/{x}/{y}',
          ),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'scenario auto-activates once; catalog and refresh never re-enable user-disabled scenario',
    () async {
      final repository = Repository();
      final container = ProviderContainer(
        overrides: [
          mapRepositoryProvider.overrideWithValue(repository),
          mapCatalogProvider.overrideWith(EmptyCatalog.new),
        ],
      );
      addTearDown(container.dispose);
      container.read(floodScenarioProvider);
      await Future<void>.delayed(Duration.zero);
      final controller = container.read(floodScenarioProvider.notifier);
      expect(container.read(floodScenarioProvider).selectedScenarioId, 2);
      container.read(mapCatalogProvider.notifier).disableAll();
      expect(container.read(floodScenarioProvider).selectedScenarioId, 2);
      controller.toggleScenario(repository.scenarios[2]);
      expect(container.read(floodScenarioProvider).selectedScenarioId, 2);
      controller.toggleScenario(repository.scenarios[1]);
      await controller.load();
      expect(container.read(floodScenarioProvider).selectedScenarioId, null);
      controller.toggleScenario(repository.scenarios[0]);
      controller.toggleScenario(repository.scenarios[1]);
      expect(container.read(floodScenarioProvider).selectedScenarioId, 2);
      expect(container.read(mapCatalogProvider).activeLayerIds, isEmpty);
      controller.resetForIdentityChange();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(floodScenarioProvider).selectedScenarioId, null);
    },
  );

  test(
    'empty scenario list loads once, no retry loop; dispose ignores pending load',
    () async {
      final repository = Repository()..scenarios = [];
      final container = ProviderContainer(
        overrides: [mapRepositoryProvider.overrideWithValue(repository)],
      );
      container.read(floodScenarioProvider);
      await Future<void>.delayed(Duration.zero);
      expect(repository.scenarioLoads, 1);
      expect(container.read(floodScenarioProvider).error, null);
      repository.scenarioRequest = Completer();
      final pending = container.read(floodScenarioProvider.notifier).load();
      container.dispose();
      repository.scenarioRequest!.complete([]);
      await pending;
    },
  );

  test(
    'hydrology multi-select is limited to chosen run and clears on period change',
    () async {
      final repository = Repository();
      final container = ProviderContainer(
        overrides: [mapRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(floodHydrologyProvider.notifier);
      await controller.load();
      final artifacts = container.read(floodHydrologyProvider).artifacts;
      controller.toggleArtifact(artifacts[0]);
      controller.toggleArtifact(artifacts[1]);
      controller.toggleArtifact(artifacts[2]);
      controller.toggleArtifact(artifacts[3]);
      expect(container.read(floodHydrologyProvider).visibleIds, {1, 2});
      controller.selectRun(2);
      expect(container.read(floodHydrologyProvider).visibleIds, isEmpty);
      expect(
        container
            .read(floodHydrologyProvider)
            .currentArtifacts
            .map((a) => a.id),
        [3],
      );
    },
  );

  test(
    'forest latest defaults and stale response guard keep newest selection',
    () async {
      final repository = Repository();
      final container = ProviderContainer(
        overrides: [mapRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(forestClassificationProvider.notifier);
      await controller.load();
      expect(container.read(forestClassificationProvider).opacity, 0.85);
      expect(container.read(forestClassificationProvider).isVisible, true);
      controller.setOpacity(0);
      expect(container.read(forestClassificationProvider).opacity, 0);
      controller.setOpacity(1);
      final old = controller.selectSnapshot(1);
      final current = controller.selectSnapshot(2);
      repository.snapshots[2]!.complete(snapshot(2));
      await current;
      repository.snapshots[1]!.complete(snapshot(1));
      await old;
      expect(container.read(forestClassificationProvider).snapshot!.id, 2);
    },
  );

  test(
    'repository paginates envelopes and deduplicates valid private tickets',
    () async {
      final adapter = Adapter(
        (options) => options.path.endsWith('tile-ticket')
            ? {
                'data': {
                  'ticket': 'ticket',
                  'expiresAt': DateTime.now()
                      .add(const Duration(minutes: 15))
                      .toIso8601String(),
                },
              }
            : {
                'data': {
                  'items': [
                    scenarioJson(options.queryParameters['page'] as int),
                  ],
                },
                'metadata': {'totalPages': 2},
              },
      );
      final repository = MapRepository(dio: Dio()..httpClientAdapter = adapter);
      expect((await repository.getFloodScenarios()).length, 2);
      expect(adapter.requests.first.queryParameters, {
        'activeOnly': true,
        'page': 1,
        'limit': 100,
      });
      await Future.wait([
        repository.validRasterTileTicket('96'),
        repository.validRasterTileTicket('96'),
      ]);
      expect(
        adapter.requests.where((r) => r.path.endsWith('tile-ticket')).length,
        1,
      );
      repository.clearTileTickets();
      await repository.validRasterTileTicket('96');
      expect(adapter.requests.last.queryParameters, {'access': 'view'});
      expect(
        adapter.requests.where((r) => r.path.endsWith('tile-ticket')).length,
        2,
      );
      expect(
        MapTileTicket(
          ticket: 'x',
          expiresAt: DateTime.now().add(const Duration(seconds: 59)),
        ).isExpiringSoon,
        true,
      );
    },
  );

  Future<void> pumpSheet(WidgetTester tester, Widget sheet) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [mapRepositoryProvider.overrideWithValue(Repository())],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: sheet),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('scenario missing layer switch disabled with warning', (
    tester,
  ) async {
    await pumpSheet(tester, const FloodScenarioSheet());
    await tester.scrollUntilVisible(find.text('Chưa có lớp bản đồ'), 200);
    final switches = tester.widgetList<Switch>(find.byType(Switch));
    expect(switches.any((s) => s.onChanged == null), true);
    expect(tester.takeException(), null);
  });

  testWidgets('hydrology renders groups and period selector without overflow', (
    tester,
  ) async {
    await pumpSheet(tester, const FloodHydrologySheet());
    expect(find.text('Ngập lụt & Thủy văn'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(tester.takeException(), null);
  });

  testWidgets(
    'forest renders 8 classes, default visibility and full opacity range',
    (tester) async {
      await pumpSheet(tester, const ForestClassificationSheet());
      expect(find.text('CHÚ GIẢI · 8 LỚP'), findsOneWidget);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 0.85);
      expect(slider.min, 0);
      expect(slider.max, 1);
      expect(tester.takeException(), null);
    },
  );
}
