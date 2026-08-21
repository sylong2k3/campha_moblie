import 'package:campha_moblie/features/map/domain/flood_scenario_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FloodScenarioModel', () {
    test('parses scenario JSON correctly', () {
      final json = {
        'id': 1,
        'code': 'scenario_light',
        'name_vi': 'Kịch bản ngập nhẹ (Mưa < 50mm)',
        'min_rainfall': '0.00',
        'max_rainfall': '49.99',
        'min_tide': null,
        'max_tide': '1.99',
        'layer_code': 'lop_phu_sau_ngap_2015',
        'description': 'Kịch bản mưa nhỏ và triều thấp',
        'is_active': false,
        'layer': {
          'id': '8',
          'code': 'lop_phu_sau_ngap_2015',
          'nameVi': 'Lớp phủ sau ngập Cẩm Phả năm 2015',
          'category': 'lop-phu-ngap',
          'geometryType': 'RASTER',
          'storageKind': 'geotiff_minio',
          'srid': 32648,
          'geoserverLayer': 'campha:lop_phu_sau_ngap_2015',
          'isPublic': true,
          'isEnableDefault': true,
        },
      };

      final scenario = FloodScenarioModel.fromJson(json);

      expect(scenario.id, 1);
      expect(scenario.code, 'scenario_light');
      expect(scenario.nameVi, 'Kịch bản ngập nhẹ (Mưa < 50mm)');
      expect(scenario.layerCode, 'lop_phu_sau_ngap_2015');
      expect(scenario.isActive, false);
      expect(scenario.minRainfall, 0.0);
      expect(scenario.maxRainfall, 49.99);
      expect(scenario.rainfallRangeText, '0 - 50 mm');
      expect(scenario.layer?.id, '8');
      expect(scenario.layer?.code, 'lop_phu_sau_ngap_2015');
      expect(scenario.layer?.isRaster, true);
    });
  });
}
