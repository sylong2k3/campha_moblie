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

void main() {
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

  test('getLegendItems falls back to the default preset only when server '
      'legend is empty for a flood/land-cover layer', () {
    final legend = LayerLegend.fromJson({
      'layerId': '1',
      'code': 'lop_phu_sau_ngap_2015',
      'nameVi': 'Lớp phủ sau ngập Cẩm Phả năm 2015',
      'legend': <String, dynamic>{},
    });

    final items = getLegendItems(legend, _floodLayer());

    expect(items, defaultFloodLandCoverLegendItems);
  });

  test('getLegendItems returns an empty list for non flood line/polygon layers with no '
      'server legend, instead of the flood preset', () {
    final legend = LayerLegend.fromJson({
      'layerId': '2',
      'code': 'ranhgioi_campha',
      'nameVi': 'Ranh giới hành chính Cẩm Phả',
      'legend': <String, dynamic>{},
    });

    final items = getLegendItems(legend);

    expect(items, isEmpty);
  });

  test('getLegendItems returns point legend item with layer name and color for point layer', () {
    const pointLayer = LayerModel(
      id: 'point-1',
      code: 'diem_ngap',
      nameVi: 'Điểm ngập úng đô thị',
      category: 'diem_ngap',
      geometryType: 'POINT',
      storageKind: 'postgis',
      srid: 4326,
      isPublic: true,
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
    expect(items.first.label, 'Điểm ngập úng đô thị');
    expect(items.first.color, pointLayer.displayColor);
    expect(items.first.isPoint, isTrue);
    expect(items.first.isPointGeometry, isTrue);
  });

  test('getLegendItems returns line and polygon items with appropriate geometryType', () {
    const lineLayer = LayerModel(
      id: 'line-1',
      code: 'ranh_gioi',
      nameVi: 'Ranh giới hành chính',
      category: 'ranh_gioi',
      geometryType: 'LINESTRING',
      storageKind: 'postgis',
      srid: 4326,
      isPublic: true,
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
    expect(lineItems.first.label, 'Ranh giới hành chính');
    expect(lineItems.first.isLineGeometry, isTrue);
    expect(lineItems.first.color, lineLayer.displayColor);

    expect(polyItems, hasLength(1));
    expect(polyItems.first.label, 'Khu dân cư đô thị');
    expect(polyItems.first.isPolygonGeometry, isTrue);
    expect(polyItems.first.color, polygonLayer.displayColor);
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
                items: defaultFloodLandCoverLegendItems,
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
}
