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
  test('getLegendItems prefers server-provided colors even for flood layers', () {
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
  });

  test(
    'getLegendItems falls back to the default preset only when server '
    'legend is empty for a flood/land-cover layer',
    () {
      final legend = LayerLegend.fromJson({
        'layerId': '1',
        'code': 'lop_phu_sau_ngap_2015',
        'nameVi': 'Lớp phủ sau ngập Cẩm Phả năm 2015',
        'legend': <String, dynamic>{},
      });

      final items = getLegendItems(legend, _floodLayer());

      expect(items, defaultFloodLandCoverLegendItems);
    },
  );

  test(
    'getLegendItems returns an empty list for non flood layers with no '
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
