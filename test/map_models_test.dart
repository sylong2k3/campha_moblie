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

  test('keeps Mapbox placeholders in GeoServer WMS template', () {
    final repository = MapRepository(dio: Dio());
    final url = repository.rasterTileUrlTemplate(
      'campha:lop_phu_truoc_ngap_2015',
    );

    expect(url, contains('service=WMS'));
    expect(url, contains('bbox={bbox-epsg-3857}'));
    expect(url, contains('srs=EPSG%3A3857'));
    expect(url, isNot(contains('%7B')));
    expect(url, isNot(contains('%7D')));
  });

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

  test('falls back to the default palette when server sets no color', () {
    final layer = LayerModel.fromJson({
      'id': '42',
      'code': 'song_tieu_thoat_nuoc',
      'nameVi': 'Sông tiêu thoát nước',
      'category': 'thuy_van',
      'geometryType': 'LINESTRING',
      'storageKind': 'postgis',
      'srid': 4326,
      'legend': {},
      'isPublic': true,
    });

    expect(defaultLayerColorPalette, contains(layer.displayColor));
  });

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
}
