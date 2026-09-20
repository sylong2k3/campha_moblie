import 'package:campha_moblie/features/map/domain/layer_model.dart';
import 'package:campha_moblie/features/map/presentation/legend_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LayerModel _floodLayer() => LayerModel(
  id: '1',
  code: 'lop_phu_sau_ngap_2015',
  nameVi: 'Lớp phủ sau ngập Cẩm Phả năm 2015',
  category: 'lop-phu-ngap',
  geometryType: 'RASTER',
  storageKind: 'geotiff_minio',
  srid: 32648,
  isPublic: true,
  legend: const {},
);

Map<String, dynamic> _layerJson() => {
  'id': '1',
  'code': 'test_layer',
  'nameVi': 'Lớp kiểm tra',
  'category': 'khac',
  'geometryType': 'LINESTRING',
  'storageKind': 'postgis',
  'srid': 4326,
};

void main() {
  test('explicit false overrides legacy default flags', () {
    expect(
      LayerModel.fromJson({
        ..._layerJson(),
        'isEnableDefault': false,
        'is_enable_default': true,
        'defaultStyle': {'visible_by_default': true},
      }).isEnableDefault,
      isFalse,
    );
    expect(
      LayerModel.fromJson({
        ..._layerJson(),
        'is_enable_default': false,
        'metadata': {
          'defaultStyle': {'visible_by_default': true},
        },
      }).isEnableDefault,
      isFalse,
    );
  });

  test(
    'missing flags fall back to metadata and malformed maps are rejected',
    () {
      expect(
        LayerModel.fromJson({
          ..._layerJson(),
          'metadata': {
            'default_style': {'visible_by_default': true},
          },
        }).isEnableDefault,
        isTrue,
      );
      for (final key in ['metadata', 'defaultStyle']) {
        expect(
          () => LayerModel.fromJson({..._layerJson(), key: 'invalid'}),
          throwsFormatException,
        );
      }
    },
  );

  test('displayColor skips invalid entries and supports colorHex', () {
    final layer = LayerModel.fromJson({
      ..._layerJson(),
      'legend': {
        'entries': [
          {'label': 'Invalid', 'color': 'not-a-color'},
          {'label': 'Valid', 'colorHex': '#123456'},
        ],
      },
    });
    expect(layer.displayColor, const Color(0xFF123456));
  });

  test(
    'getLegendItems prefers server-provided colors even for flood layers',
    () {
      final legend = LayerLegend.fromJson({
        'layerId': '1',
        'code': 'lop_phu_sau_ngap_2015',
        'nameVi': 'Lớp phủ sau ngập Cẩm Phả năm 2015',
        'legend': {'Mặt nước hồ chứa': '#004488'},
      });

      final items = getLegendItems(legend, _floodLayer());

      expect(items, hasLength(1));
      expect(items.single.label, 'Mặt nước hồ chứa');
      expect(items.single.color, const Color(0xFF004488));
    },
  );

  test('getLegendItems removes duplicate API entries', () {
    final legend = LayerLegend.fromJson({
      'layerId': '1',
      'code': 'duplicate',
      'nameVi': 'Lớp trùng',
      'legend': {
        'entries': [
          {'label': 'Mặt nước', 'color': '#0086FF'},
          {'label': 'Mặt nước', 'color': '#0086FF'},
        ],
      },
    });

    final items = getLegendItems(legend);

    expect(items, hasLength(1));
    expect(items.single.label, 'Mặt nước');
  });

  test('deduplicateLegendItems removes duplicates across sources', () {
    const item = LegendColorItem(
      label: 'Ranh giới',
      color: Color(0xFF123456),
      geometryType: LegendGeometryType.line,
    );

    expect(deduplicateLegendItems([item, item]), hasLength(1));
  });

  test(
    'getLegendItems returns empty when layer has no API color or legend',
    () {
      final legend = LayerLegend.fromJson({
        'layerId': '1',
        'code': 'lop_phu_sau_ngap_2015',
        'nameVi': 'Lớp phủ sau ngập Cẩm Phả năm 2015',
        'legend': <String, dynamic>{},
      });
      final layer = _floodLayer();

      final items = getLegendItems(legend, layer);

      expect(items, isEmpty);
    },
  );

  test(
    'getLegendItems returns an empty list for non flood line/polygon layers with no '
    'server legend, instead of the flood preset',
    () {
      final legend = LayerLegend.fromJson({
        'layerId': '2',
        'code': 'ranhgioi_campha',
        'nameVi': 'Ranh giới hành chính Cẩm Phả',
        'legend': <String, dynamic>{},
      });

      final items = getLegendItems(legend);

      expect(items, isEmpty);
    },
  );

  test(
    'getLegendItems uses GeoServer default colors when layer has geoserverLayer',
    () {
      const pointLayer = LayerModel(
        id: 'point-1',
        code: 'dia_danh',
        nameVi: 'Địa danh',
        category: 'dia_danh',
        geometryType: 'POINT',
        storageKind: 'postgis',
        srid: 4326,
        geoserverLayer: 'campha:dia_danh',
        isPublic: true,
        legend: {},
      );
      const lineLayer = LayerModel(
        id: 'line-1',
        code: 'ranhgioi_campha',
        nameVi: 'Ranh giới Cẩm Phả',
        category: 'ranh_gioi',
        geometryType: 'LINESTRING',
        storageKind: 'postgis',
        srid: 4326,
        geoserverLayer: 'campha:ranhgioi_campha',
        isPublic: true,
        legend: {},
      );
      const polyLayer = LayerModel(
        id: 'poly-1',
        code: 'ranh_gioi_khu_vuc',
        nameVi: 'Ranh giới khu vực',
        category: 'quy_hoach',
        geometryType: 'POLYGON',
        storageKind: 'postgis',
        srid: 4326,
        geoserverLayer: 'campha:ranh_gioi_khu_vuc',
        isPublic: true,
        legend: {},
      );

      final emptyLegend = LayerLegend.fromJson({
        'layerId': 'x',
        'code': 'x',
        'nameVi': 'x',
        'legend': <String, dynamic>{},
      });

      final pointItems = getLegendItems(emptyLegend, pointLayer);
      final lineItems = getLegendItems(emptyLegend, lineLayer);
      final polyItems = getLegendItems(emptyLegend, polyLayer);

      expect(pointItems.single.color, const Color(0xFFFF0000));
      expect(pointItems.single.isPointGeometry, isTrue);

      expect(lineItems.single.color, const Color(0xFF0000FF));
      expect(lineItems.single.isLineGeometry, isTrue);

      expect(polyItems.single.color, const Color(0xFFAAAAAA));
      expect(polyItems.single.isPolygonGeometry, isTrue);
    },
  );

  test(
    'getLegendItems identifies point layer when API color is configured',
    () {
      const pointLayer = LayerModel(
        id: 'point-1',
        code: 'diem_ngap',
        nameVi: 'Điểm ngập úng đô thị',
        category: 'diem_ngap',
        geometryType: 'POINT',
        storageKind: 'postgis',
        srid: 4326,
        isPublic: true,
        defaultStyle: {'circleColor': '#00AAFF'},
        legend: {},
      );
      final legend = LayerLegend.fromJson({
        'layerId': 'point-1',
        'code': 'diem_ngap',
        'nameVi': 'Điểm ngập úng đô thị',
        'legend': <String, dynamic>{},
      });

      final items = getLegendItems(legend, pointLayer);

      expect(items, hasLength(1));
      expect(items.single.label, pointLayer.nameVi);
      expect(items.single.color, const Color(0xFF00AAFF));
      expect(items.single.isPointGeometry, isTrue);
    },
  );

  test(
    'getLegendItems returns line and polygon items when layer has apiColor',
    () {
      const lineLayer = LayerModel(
        id: 'line-1',
        code: 'ranh_gioi',
        nameVi: 'Ranh giới hành chính',
        category: 'ranh_gioi',
        geometryType: 'LINESTRING',
        storageKind: 'postgis',
        srid: 4326,
        isPublic: true,
        defaultStyle: {'strokeColor': '#11FF00'},
        legend: {},
      );
      const polygonLayer = LayerModel(
        id: 'poly-1',
        code: 'khu_dan_cu',
        nameVi: 'Khu dân cư đô thị',
        category: 'quy_hoach',
        geometryType: 'POLYGON',
        storageKind: 'postgis',
        srid: 4326,
        isPublic: true,
        defaultStyle: {'fillColor': '#FFAA00'},
        legend: {},
      );

      final lineLegend = LayerLegend.fromJson({
        'layerId': 'line-1',
        'code': 'ranh_gioi',
        'nameVi': 'Ranh giới hành chính',
        'legend': <String, dynamic>{},
      });
      final polyLegend = LayerLegend.fromJson({
        'layerId': 'poly-1',
        'code': 'khu_dan_cu',
        'nameVi': 'Khu dân cư đô thị',
        'legend': <String, dynamic>{},
      });

      final lineItems = getLegendItems(lineLegend, lineLayer);
      final polyItems = getLegendItems(polyLegend, polygonLayer);

      expect(lineItems, hasLength(1));
      expect(lineItems.single.label, lineLayer.nameVi);
      expect(lineItems.single.color, const Color(0xFF11FF00));
      expect(lineItems.single.isLineGeometry, isTrue);
      expect(polyItems, hasLength(1));
      expect(polyItems.single.label, polygonLayer.nameVi);
      expect(polyItems.single.color, const Color(0xFFFFAA00));
      expect(polyItems.single.isPolygonGeometry, isTrue);
    },
  );

  testWidgets('legend close has accessible 48dp target and hides the card', (
    tester,
  ) async {
    var visible = true;
    var closes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => visible
                ? LayerLegendCard(
                    title: 'Chú giải',
                    items: const [
                      LegendColorItem(label: 'Lớp', color: Colors.blue),
                    ],
                    onClose: () {
                      closes++;
                      setState(() => visible = false);
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
    final close = find.byKey(const ValueKey('map-legend-close'));
    expect(tester.getSize(close).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
    expect(tester.widget<IconButton>(close).tooltip, 'Close');
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(closes, 1);
    expect(find.byType(LayerLegendCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'LayerLegendCard fills available width, stays compact, and scrolls '
    'horizontally when items overflow one column',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: LayerLegendCard(
                title: 'Lớp phủ sau ngập',
                items: const [
                  LegendColorItem(label: 'A', color: Colors.blue),
                  LegendColorItem(label: 'B', color: Colors.red),
                  LegendColorItem(label: 'C', color: Colors.green),
                  LegendColorItem(label: 'D', color: Colors.orange),
                ],
              ),
            ),
          ),
        ),
      );

      final cardFinder = find.byType(LayerLegendCard);
      expect(cardFinder, findsOneWidget);

      final cardSize = tester.getSize(cardFinder);
      expect(cardSize.width, 360);
      expect(cardSize.height, lessThan(200));

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Vuốt ngang để xem thêm'), findsOneWidget);
    },
  );

  testWidgets(
    'LayerLegendCard hides the scroll hint when items fit one column',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: LayerLegendCard(
                title: 'Nhỏ',
                items: const [
                  LegendColorItem(label: 'A', color: Colors.blue),
                  LegendColorItem(label: 'B', color: Colors.red),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Vuốt ngang để xem thêm'), findsNothing);
    },
  );

  testWidgets('LayerLegendCard renders nothing when API items are empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LayerLegendCard(title: 'Không có chú giải', items: []),
        ),
      ),
    );

    expect(find.text('Không có chú giải'), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });

  test('getLegendItems parses structured entries array from API', () {
    final legend = LayerLegend.fromJson({
      'layerId': '186',
      'code': 'cp_do_thi_2001',
      'nameVi': 'Lớp phủ đô thị',
      'legend': {
        'entries': [
          {'label': 'Mặt nước', 'color': '#0086FF'},
          {'label': 'Đất ở', 'color': '#FF9393'},
          {'label': 'Đất lâm nghiệp', 'color': '#006000'},
        ],
      },
    });

    final items = getLegendItems(legend);

    expect(items, hasLength(3));
    expect(items[0].label, 'Mặt nước');
    expect(items[0].color, const Color(0xFF0086FF));
    expect(items[1].label, 'Đất ở');
    expect(items[1].color, const Color(0xFFFF9393));
    expect(items[2].label, 'Đất lâm nghiệp');
    expect(items[2].color, const Color(0xFF006000));
  });

  test('getLegendItemsForLayer extracts entries directly from LayerModel', () {
    final layer = LayerModel.fromJson({
      'id': '186',
      'code': 'cp_do_thi_2001',
      'nameVi': 'Lớp phủ đô thị',
      'category': 'lop-phu',
      'geometryType': 'RASTER',
      'storageKind': 'geotiff_minio',
      'srid': 32648,
      'isPublic': true,
      'legend': {
        'entries': [
          {'label': 'Mặt nước', 'color': '#0086FF'},
          {'label': 'Đất ở', 'color': '#FF9393'},
        ],
      },
    });

    final items = getLegendItemsForLayer(layer);

    expect(items, hasLength(2));
    expect(items[0].label, 'Mặt nước');
    expect(items[0].color, const Color(0xFF0086FF));
  });
}
