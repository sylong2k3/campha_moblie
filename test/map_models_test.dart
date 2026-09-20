import 'package:campha_moblie/features/map/data/map_repository.dart';
import 'package:campha_moblie/features/map/domain/feature_detail_model.dart';
import 'package:campha_moblie/features/map/domain/layer_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses serialized layer catalog with BIGINT-safe ID', () {
    final layer = LayerModel.fromJson({
      'id': '9223372036854775807',
      'code': 'ranhgioi_campha',
      'nameVi': 'Ranh giới hành chính Cẩm Phả',
      'category': 'ranh_gioi',
      'geometryType': 'MULTILINESTRING',
      'storageKind': 'postgis',
      'srid': 4326,
      'geoserverLayer': 'campha:ranhgioi_campha',
      'styleName': null,
      'minZoom': null,
      'maxZoom': 22,
      'legend': {},
      'isPublic': true,
      'canEdit': true,
      'editableFields': ['ten', 'ghi_chu'],
    });
    expect(layer.id, '9223372036854775807');
    expect(layer.isLine, isTrue);
    expect(layer.code, 'ranhgioi_campha');
    expect(layer.canEdit, isTrue);
    expect(layer.editableFields, ['ten', 'ghi_chu']);
  });

  test('recognizes GeoTIFF catalog layer as raster', () {
    final layer = LayerModel.fromJson({
      'id': '8',
      'code': 'lop_phu_sau_ngap_2015',
      'nameVi': 'Lớp phủ sau ngập Cẩm Phả năm 2015',
      'category': 'lop-phu-ngap',
      'geometryType': 'RASTER',
      'storageKind': 'geotiff_minio',
      'srid': 32648,
      'geoserverLayer': 'campha:lop_phu_sau_ngap_2015',
      'legend': {
        'type': 'rgb',
        'bands': ['red', 'green', 'blue'],
      },
      'isPublic': true,
    });

    expect(layer.isRaster, isTrue);
    expect(layer.isPoint, isFalse);
    expect(layer.isLine, isFalse);
    expect(layer.isPolygon, isFalse);
  });

  test(
    'keeps Mapbox placeholders in GeoServer WMS template and passes styles parameter',
    () {
      final repository = MapRepository(dio: Dio());
      final url = repository.rasterTileUrlTemplate(
        'campha:lop_phu_truoc_ngap_2015',
      );

      expect(url, contains('service=WMS'));
      expect(url, contains('bbox={bbox-epsg-3857}'));
      expect(url, contains('srs=EPSG%3A3857'));
      expect(url, contains('styles='));
      expect(url, isNot(contains('%7B')));
      expect(url, isNot(contains('%7D')));

      final customStyleUrl = repository.rasterTileUrlTemplate(
        'campha:lop_phu_truoc_ngap_2015',
        styleName: 'custom_sld',
      );
      expect(customStyleUrl, contains('styles=custom_sld'));
    },
  );

  test('parses snake_case basemap and search GeoJSON point', () {
    final basemap = BasemapModel.fromJson({
      'code': 'osm',
      'name_vi': 'Bản đồ nền sáng',
      'provider': 'Mapbox',
      'url_template': 'mapbox://styles/mapbox/streets-v12',
      'attribution': '© Mapbox',
      'min_zoom': 0,
      'max_zoom': 22,
    });
    expect(basemap.isMapboxStyle, isTrue);

    final result = MapSearchResult.fromJson({
      'layerId': '1',
      'layerCode': 'ranhgioi_campha',
      'layerName': 'Ranh giới Cẩm Phả',
      'feature_id': '99',
      'label': 'Phường Cẩm Trung',
      'location': {
        'type': 'Point',
        'coordinates': [107.33, 21.01],
      },
    });
    expect(result.featureId, '99');
    expect(result.longitude, 107.33);
  });

  test('parses feature allowlist fields and geometry summary', () {
    final feature = FeatureDetailModel.fromJson({
      'layerId': '1',
      'feature': {
        'source_fid': '9007199254740993',
        'ten': 'Cẩm Phả',
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [107.3, 21.0],
            [107.4, 21.1],
          ],
        },
        'version': 4,
      },
    });
    expect(feature.id, '9007199254740993');
    expect(feature.attributes['ten'], 'Cẩm Phả');
    expect(feature.coordinateCount, 2);
    expect(feature.version, 4);
  });

  test(
    'uses GeoServer default color in displayColor when server sets no color but has geoserverLayer',
    () {
      final layerWithGeoserver = LayerModel.fromJson({
        'id': '42',
        'code': 'song_tieu_thoat_nuoc',
        'nameVi': 'Sông tiêu thoát nước',
        'category': 'thuy_van',
        'geometryType': 'LINESTRING',
        'storageKind': 'postgis',
        'srid': 4326,
        'geoserverLayer': 'campha:song_tieu_thoat_nuoc',
        'legend': {},
        'isPublic': true,
      });

      expect(layerWithGeoserver.hasApiColor, isFalse);
      expect(layerWithGeoserver.apiColor, isNull);
      expect(layerWithGeoserver.geoserverDefaultColor, const Color(0xFF0000FF));
      expect(layerWithGeoserver.displayColor, const Color(0xFF0000FF));
      expect(layerWithGeoserver.usesGeoServerDefaultStyle, isTrue);

      final pointGeoserver = LayerModel.fromJson({
        'id': '44',
        'code': 'dia_danh',
        'nameVi': 'Địa danh',
        'category': 'dia_danh',
        'geometryType': 'MULTIPOINT',
        'storageKind': 'postgis',
        'srid': 4326,
        'geoserverLayer': 'campha:dia_danh',
        'legend': {},
        'isPublic': true,
      });
      expect(pointGeoserver.displayColor, const Color(0xFFFF0000));

      final polyGeoserver = LayerModel.fromJson({
        'id': '45',
        'code': 'ranh_gioi_khu_vuc',
        'nameVi': 'Ranh giới khu vực',
        'category': 'quy_hoach',
        'geometryType': 'MULTIPOLYGON',
        'storageKind': 'postgis',
        'srid': 4326,
        'geoserverLayer': 'campha:ranh_gioi_khu_vuc',
        'legend': {},
        'isPublic': true,
      });
      expect(polyGeoserver.displayColor, const Color(0xFFAAAAAA));

      final layerWithoutGeoserver = LayerModel.fromJson({
        'id': '43',
        'code': 'layer_no_geoserver',
        'nameVi': 'Lớp không có GeoServer',
        'category': 'khac',
        'geometryType': 'LINESTRING',
        'storageKind': 'postgis',
        'srid': 4326,
        'legend': {},
        'isPublic': true,
      });

      expect(layerWithoutGeoserver.hasApiColor, isFalse);
      expect(layerWithoutGeoserver.geoserverDefaultColor, isNull);
      expect(layerWithoutGeoserver.displayColor, isNull);
      expect(layerWithoutGeoserver.usesGeoServerDefaultStyle, isFalse);
    },
  );

  test('server-provided legend color takes priority over default', () {
    final layer = LayerModel.fromJson({
      'id': '43',
      'code': 'song_tieu_thoat_nuoc',
      'nameVi': 'Sông tiêu thoát nước',
      'category': 'thuy_van',
      'geometryType': 'LINESTRING',
      'storageKind': 'postgis',
      'srid': 4326,
      'legend': {'color': '#00AA00'},
      'isPublic': true,
    });

    expect(layer.displayColor, const Color(0xFF00AA00));
  });

  test('rejects malformed location and feature without ID', () {
    expect(
      () => MapSearchResult.fromJson({
        'layerId': '1',
        'layerCode': 'x',
        'layerName': 'X',
        'feature_id': '1',
        'label': 'X',
        'location': {'type': 'Polygon', 'coordinates': []},
      }),
      throwsFormatException,
    );
    expect(
      () => FeatureDetailModel.fromJson({
        'layerId': '1',
        'feature': {'ten': 'Không có ID'},
      }),
      throwsFormatException,
    );
  });

  test(
    'identifies boundary and hydrology layers while excluding flood overlay',
    () {
      final boundary = LayerModel.fromJson({
        'id': '1',
        'code': 'ranhgioi_campha',
        'nameVi': 'Ranh giới Cẩm Phả',
        'category': 'ranh_gioi',
        'geometryType': 'MULTILINESTRING',
        'storageKind': 'postgis',
        'srid': 4326,
        'legend': {},
        'isPublic': true,
      });
      final hydro = LayerModel.fromJson({
        'id': '2',
        'code': 'song_tieu_thoat_nuoc',
        'nameVi': 'Sông suối tiêu thoát nước',
        'category': 'thuy_van',
        'geometryType': 'LINESTRING',
        'storageKind': 'postgis',
        'srid': 4326,
        'legend': {},
        'isPublic': true,
      });
      final flood = LayerModel.fromJson({
        'id': '3',
        'code': 'lop_phu_sau_ngap_2015',
        'nameVi': 'Lớp phủ sau ngập 2015',
        'category': 'lop_phu_ngap',
        'geometryType': 'RASTER',
        'storageKind': 'geotiff_minio',
        'srid': 3857,
        'legend': {},
        'isPublic': true,
      });

      expect(boundary.isRaster, isFalse);
      expect(hydro.isRaster, isFalse);
      expect(flood.isRaster, isTrue);
    },
  );

  test('parses isEnableDefault from various API field formats', () {
    final camelCase = LayerModel.fromJson({
      'id': '1',
      'code': 'layer1',
      'nameVi': 'Lớp 1',
      'category': 'dia_danh',
      'geometryType': 'POINT',
      'storageKind': 'postgis',
      'srid': 4326,
      'isPublic': true,
      'isEnableDefault': true,
    });
    final snakeCase = LayerModel.fromJson({
      'id': '2',
      'code': 'layer2',
      'nameVi': 'Lớp 2',
      'category': 'giao_thong',
      'geometryType': 'LINESTRING',
      'storageKind': 'postgis',
      'srid': 4326,
      'isPublic': true,
      'is_enable_default': true,
    });
    final visibleByDefault = LayerModel.fromJson({
      'id': '3',
      'code': 'layer3',
      'nameVi': 'Lớp 3',
      'category': 'quy_hoach',
      'geometryType': 'POLYGON',
      'storageKind': 'postgis',
      'srid': 4326,
      'isPublic': true,
      'defaultStyle': {'visible_by_default': true},
    });
    final disabled = LayerModel.fromJson({
      'id': '4',
      'code': 'layer4',
      'nameVi': 'Lớp 4',
      'category': 'khac',
      'geometryType': 'POINT',
      'storageKind': 'postgis',
      'srid': 4326,
      'isPublic': true,
      'isEnableDefault': false,
    });

    expect(camelCase.isEnableDefault, isTrue);
    expect(snakeCase.isEnableDefault, isTrue);
    expect(visibleByDefault.isEnableDefault, isTrue);
    expect(disabled.isEnableDefault, isFalse);
  });

  test(
    'defaultStyle color takes precedence over legend and default palette',
    () {
      final layer = LayerModel.fromJson({
        'id': '10',
        'code': 'boundary_styled',
        'nameVi': 'Ranh giới',
        'category': 'ranh_gioi',
        'geometryType': 'LINESTRING',
        'storageKind': 'postgis',
        'srid': 4326,
        'isPublic': true,
        'defaultStyle': {'strokeColor': '#FF0055', 'strokeWidth': 4.0},
        'legend': {'color': '#00AA00'},
      });

      expect(layer.displayColor, const Color(0xFFFF0055));
      expect(layer.customStrokeColor, const Color(0xFFFF0055));
      expect(layer.customStrokeWidth, 4.0);
    },
  );

  test('legend entries color takes precedence over default palette', () {
    final layer = LayerModel.fromJson({
      'id': '11',
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

    expect(layer.displayColor, const Color(0xFF0086FF));
  });
}
