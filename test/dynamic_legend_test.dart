import 'package:campha_moblie/features/map/domain/flood_scenario_model.dart';
import 'package:campha_moblie/features/map/domain/layer_model.dart';
import 'package:campha_moblie/features/map/presentation/dynamic_legend_sheet.dart';
import 'package:campha_moblie/features/map/presentation/legend_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LegendEntry & LegendGroup domain tests', () {
    test('parses LegendEntry with 6-digit hex, 3-digit hex, and value', () {
      final entry6 = LegendEntry.fromJson({
        'label': 'Mặt nước',
        'color': '#0086FF',
      });
      expect(entry6.label, 'Mặt nước');
      expect(entry6.color, const Color(0xFF0086FF));
      expect(entry6.value, isNull);

      final entry3 = LegendEntry.fromJson({'label': 'Đỏ', 'color': '#F00'});
      expect(entry3.color, const Color(0xFFFF0000));

      final entryVal = LegendEntry.fromJson({'color': '#313695', 'value': 3.5});
      expect(entryVal.value, 3.5);
      expect(entryVal.color, const Color(0xFF313695));
    });

    test('parses LegendEntry localized labels (vi/en maps)', () {
      final entry = LegendEntry.fromJson({
        'label': {'vi': 'Vùng ngập sâu', 'en': 'Deep flood'},
        'color': '#081D58',
      });
      expect(entry.label, 'Vùng ngập sâu');
    });

    test('parses categorical LegendGroup (Canonical standard)', () {
      final group = LegendGroup.fromRaw('cp_do_thi', 'Lớp phủ đô thị', {
        'kind': 'class',
        'entries': [
          {'color': '#0086FF', 'label': 'Mặt nước'},
          {'color': '#FF9393', 'label': 'Đất ở'},
          {'color': '#006000', 'label': 'Đất lâm nghiệp'},
        ],
      });

      expect(group.id, 'cp_do_thi');
      expect(group.title, 'Lớp phủ đô thị');
      expect(group.isContinuous, isFalse);
      expect(group.entries, hasLength(3));
      expect(group.entries[0].label, 'Mặt nước');
      expect(group.entries[0].color, const Color(0xFF0086FF));
    });

    test('parses continuous LegendGroup (Gradient standard)', () {
      final group = LegendGroup.fromRaw(
        'flood_depth_hand',
        'Độ sâu ngập HAND',
        {
          'code': 'flood_depth_hand',
          'kind': 'continuous',
          'unit': 'm',
          'min': 0.0,
          'max': 5.0,
          'entries': [
            {'color': '#E0F3F8', 'value': 0.0},
            {'color': '#74ADD1', 'value': 1.5},
            {'color': '#313695', 'value': 3.0},
            {'color': '#081D58', 'value': 5.0},
          ],
        },
      );

      expect(group.isContinuous, isTrue);
      expect(group.unit, 'm');
      expect(group.entries, hasLength(4));
      expect(group.entries.first.value, 0.0);
      expect(group.entries.last.value, 5.0);
    });

    test('parses key-value map format legend', () {
      final group = LegendGroup.fromRaw('simple', 'Đơn giản', {
        'Mặt nước': '#0086FF',
        'Đất ở': '#FF9393',
      });

      expect(group.entries, hasLength(2));
      expect(
        group.entries.map((e) => e.label),
        containsAll(['Mặt nước', 'Đất ở']),
      );
    });
  });

  group('MapboxStyleConfig & LayerModel properties', () {
    test('parses MapboxStyleConfig with strokeDasharray and opacity', () {
      final style = MapboxStyleConfig.fromJson({
        'strokeColor': '#11ff00',
        'strokeDasharray': [2, 2],
        'rasterOpacity': 0.88,
        'visible_by_default': true,
      });

      expect(style.strokeColor, '#11ff00');
      expect(style.strokeDasharray, [2.0, 2.0]);
      expect(style.rasterOpacity, 0.88);
      expect(style.visibleByDefault, isTrue);
    });

    test(
      'LayerModel exposes computedDefaultEnabled, customStrokeDasharray and hasValidLegend',
      () {
        final layerWithDash = LayerModel.fromJson({
          'id': '94',
          'code': 'duong_ranh_gioi',
          'nameVi': 'Đường ranh giới',
          'category': 'ranh_gioi',
          'geometryType': 'MULTILINESTRING',
          'storageKind': 'postgis',
          'srid': 4326,
          'defaultStyle': {
            'strokeColor': '#11ff00',
            'strokeDasharray': [2, 2],
            'visible_by_default': true,
          },
          'legend': null,
          'isEnableDefault': true,
        });

        expect(layerWithDash.computedDefaultEnabled, isTrue);
        expect(layerWithDash.customStrokeDasharray, [2.0, 2.0]);
        expect(layerWithDash.customStrokeColor, const Color(0xFF11FF00));
        expect(layerWithDash.hasValidLegend, isFalse);
        expect(layerWithDash.legendGroup, isNull);

        final layerWithLegend = LayerModel.fromJson({
          'id': '186',
          'code': 'cp_do_thi_2024',
          'nameVi': 'Lớp phủ đô thị Cẩm Phả năm 2024',
          'category': 'quy_hoach',
          'geometryType': 'POLYGON',
          'storageKind': 'postgis',
          'srid': 4326,
          'legend': {
            'entries': [
              {'color': '#0086FF', 'label': 'Mặt nước'},
              {'color': '#FF9393', 'label': 'Đất ở'},
            ],
          },
        });

        expect(layerWithLegend.hasValidLegend, isTrue);
        expect(layerWithLegend.legendGroup!.entries, hasLength(2));
        expect(layerWithLegend.hasApiColor, isTrue);
        expect(layerWithLegend.apiColor, const Color(0xFF0086FF));

        expect(layerWithDash.hasApiColor, isTrue);
        expect(layerWithDash.apiColor, const Color(0xFF11FF00));

        final layerWithoutApiColor = LayerModel.fromJson({
          'id': '91',
          'code': 'dia_danh',
          'nameVi': 'Địa danh',
          'category': 'dia_danh',
          'geometryType': 'MULTIPOINT',
          'storageKind': 'postgis',
          'srid': 4326,
          'geoserverLayer': 'campha:dia_danh',
          'defaultStyle': null,
          'legend': null,
        });
        expect(layerWithoutApiColor.hasApiColor, isFalse);
        expect(layerWithoutApiColor.apiColor, isNull);
        expect(layerWithoutApiColor.displayColor, const Color(0xFFFF0000));
        expect(layerWithoutApiColor.usesGeoServerDefaultStyle, isTrue);
      },
    );
  });

  group('FloodScenarioModel integration', () {
    test(
      'parses FloodScenarioModel and exposes legendGroup from inline layer',
      () {
        final scenario = FloodScenarioModel.fromJson({
          'id': 10,
          'code': 'kb_100mm',
          'name_vi': 'Kịch bản mưa 100mm',
          'min_rainfall': 100.0,
          'is_active': true,
          'layer': {
            'id': '201',
            'code': 'ngap_100mm',
            'nameVi': 'Bản đồ ngập 100mm',
            'geometryType': 'RASTER',
            'storageKind': 'geotiff_minio',
            'srid': 4326,
            'defaultStyle': {'rasterOpacity': 0.88},
            'legend': {
              'entries': [
                {'color': '#081D58', 'label': 'Vùng ngập sâu > 1.0m'},
                {
                  'color': '#2563EB',
                  'label': 'Vùng ngập trung bình 0.5 - 1.0m',
                },
                {'color': '#74ADD1', 'label': 'Vùng ngập nông < 0.5m'},
              ],
            },
          },
        });

        expect(scenario.canSelect, isTrue);
        expect(scenario.hasValidLegend, isTrue);
        expect(scenario.legendGroup?.entries, hasLength(3));
        expect(scenario.layer?.customRasterOpacity, 0.88);
      },
    );
  });

  group('DynamicLegendBottomSheet UI widget tests', () {
    testWidgets('renders empty notice when legends list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DynamicLegendBottomSheet(legends: [])),
        ),
      );

      expect(
        find.text('Chưa có lớp dữ liệu hoặc kịch bản ngập nào được kích hoạt.'),
        findsOneWidget,
      );
      expect(find.text('Chú giải bản đồ'), findsOneWidget);
    });

    testWidgets('renders categorical group with labels and colored boxes', (
      tester,
    ) async {
      final group = LegendGroup.fromRaw('urban', 'Lớp phủ đô thị', {
        'entries': [
          {'color': '#0086FF', 'label': 'Mặt nước'},
          {'color': '#FF9393', 'label': 'Đất ở'},
        ],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DynamicLegendBottomSheet(legends: [group])),
        ),
      );

      expect(find.text('Chú giải bản đồ'), findsOneWidget);
      expect(find.text('1 nhóm đang hiển thị'), findsOneWidget);
      expect(find.text('Lớp phủ đô thị'), findsOneWidget);
      expect(find.text('Mặt nước'), findsOneWidget);
      expect(find.text('Đất ở'), findsOneWidget);
    });

    testWidgets('renders continuous gradient group with min and max labels', (
      tester,
    ) async {
      final gradientGroup = LegendGroup.fromRaw(
        'hand',
        'Độ sâu ngập liên tục',
        {
          'kind': 'continuous',
          'unit': 'm',
          'entries': [
            {'color': '#E0F3F8', 'value': 0.0},
            {'color': '#74ADD1', 'value': 1.5},
            {'color': '#081D58', 'value': 5.0},
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicLegendBottomSheet(legends: [gradientGroup]),
          ),
        ),
      );

      expect(find.text('Độ sâu ngập liên tục'), findsOneWidget);
      expect(find.text('0 m'), findsOneWidget);
      expect(find.text('5 m'), findsOneWidget);
    });

    testWidgets('LayerLegendCard shows expand button and triggers callback', (
      tester,
    ) async {
      var expanded = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayerLegendCard(
              title: 'Chú giải thử nghiệm',
              items: const [
                LegendColorItem(
                  label: 'Ranh giới',
                  color: Color(0xFF11FF00),
                  geometryType: LegendGeometryType.line,
                ),
              ],
              onExpand: () => expanded = true,
            ),
          ),
        ),
      );

      expect(find.text('Chú giải thử nghiệm'), findsOneWidget);
      expect(find.byKey(const ValueKey('map-legend-expand')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('map-legend-expand')));
      expect(expanded, isTrue);
    });
  });
}
