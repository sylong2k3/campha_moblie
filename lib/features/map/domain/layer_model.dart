import 'package:flutter/material.dart';

/// Màu mặc định khi server không cấu hình màu riêng cho layer.
const Color defaultLayerColor = Color(0xFF3B82F6);

/// Bảng màu mặc định xoay vòng theo layer để phân biệt trực quan trong danh
/// sách/legend khi server không cấu hình màu — không gán theo ý nghĩa ngữ
/// nghĩa, chỉ đơn thuần tránh việc mọi layer trông giống hệt nhau.
const List<Color> defaultLayerColorPalette = [
  Color(0xFF3B82F6), // Blue
  Color(0xFFF59E0B), // Amber
  Color(0xFF06B6D4), // Cyan
  Color(0xFF10B981), // Emerald
  Color(0xFFF97316), // Orange
  Color(0xFF6366F1), // Indigo
  Color(0xFF14B8A6), // Teal
  Color(0xFF84CC16), // Lime
];

class LayerModel {
  const LayerModel({
    required this.id,
    required this.code,
    required this.nameVi,
    required this.category,
    required this.geometryType,
    required this.storageKind,
    required this.srid,
    required this.isPublic,
    required this.legend,
    this.canEdit = false,
    this.editableFields = const [],
    this.geoserverLayer,
    this.styleName,
    this.minZoom,
    this.maxZoom,
  });

  final String id;
  final String code;
  final String nameVi;
  final String category;
  final String geometryType;
  final String storageKind;
  final int srid;
  final String? geoserverLayer;
  final String? styleName;
  final double? minZoom;
  final double? maxZoom;
  final Map<String, dynamic> legend;
  final bool isPublic;
  final bool canEdit;
  final List<String> editableFields;

  bool get isRaster =>
      geometryType.toUpperCase() == 'RASTER' || storageKind == 'geotiff_minio';
  bool get isPoint => geometryType.toUpperCase().contains('POINT');
  bool get isLine => geometryType.toUpperCase().contains('LINE');
  bool get isPolygon => geometryType.toUpperCase().contains('POLYGON');

  Color get displayColor {
    final hex = legend['color']?.toString() ??
        legend['fillColor']?.toString() ??
        legend['strokeColor']?.toString() ??
        legend['colorHex']?.toString();
    if (hex != null && hex.isNotEmpty) {
      var clean = hex.replaceAll('#', '').replaceAll('0x', '').trim();
      if (clean.length == 6) clean = 'FF$clean';
      if (clean.length == 8) {
        final val = int.tryParse(clean, radix: 16);
        if (val != null) return Color(val);
      }
    }

    final seedStr = '${category}_${code}_$id';
    final hash = seedStr.codeUnits.fold(
      0,
      (prev, elem) => (prev * 31 + elem) & 0x7FFFFFFF,
    );
    return defaultLayerColorPalette[hash % defaultLayerColorPalette.length];
  }

  factory LayerModel.fromJson(Map<String, dynamic> json) => LayerModel(
    id: _requiredString(json, 'id'),
    code: _requiredString(json, 'code'),
    nameVi: _requiredString(json, 'nameVi'),
    category: (json['categoryName'] ??
            json['category_name'] ??
            json['categoryNameVi'] ??
            json['category_name_vi'] ??
            json['category'])
        ?.toString()
        .trim()
        .isNotEmpty == true
        ? (json['categoryName'] ??
                json['category_name'] ??
                json['categoryNameVi'] ??
                json['category_name_vi'] ??
                json['category'])
            .toString()
        : 'khac',
    geometryType: _requiredString(json, 'geometryType'),
    storageKind: _requiredString(json, 'storageKind'),
    srid: _int(json['srid']),
    geoserverLayer: json['geoserverLayer']?.toString(),
    styleName: json['styleName']?.toString(),
    minZoom: _doubleOrNull(json['minZoom']),
    maxZoom: _doubleOrNull(json['maxZoom']),
    legend: _optionalMap(json['legend']),
    isPublic: json['isPublic'] == true,
    canEdit: json['canEdit'] == true,
    editableFields: _stringList(json['editableFields']),
  );
}

class LayerLegend {
  const LayerLegend({
    required this.layerId,
    required this.code,
    required this.nameVi,
    required this.legend,
    this.styleName,
    this.minZoom,
    this.maxZoom,
  });

  final String layerId;
  final String code;
  final String nameVi;
  final String? styleName;
  final double? minZoom;
  final double? maxZoom;
  final Map<String, dynamic> legend;

  bool get isEmpty => legend.isEmpty;

  factory LayerLegend.fromJson(Map<String, dynamic> json) => LayerLegend(
    layerId: _requiredString(json, 'layerId'),
    code: _requiredString(json, 'code'),
    nameVi: _requiredString(json, 'nameVi'),
    styleName: json['styleName']?.toString(),
    minZoom: _doubleOrNull(json['minZoom']),
    maxZoom: _doubleOrNull(json['maxZoom']),
    legend: _optionalMap(json['legend']),
  );
}

/// Vé truy cập tile WMS/WFS cho layer không `isPublic` — `RasterSource` của
/// Mapbox không gắn được header `Authorization` vào từng tile request, nên
/// server phát vé ngắn hạn nhúng vào query string thay cho header.
class MapTileTicket {
  const MapTileTicket({required this.ticket, required this.expiresAt});

  final String ticket;
  final DateTime expiresAt;

  static const _refreshMargin = Duration(seconds: 30);

  /// true khi vé đã hết hạn hoặc sắp hết hạn trong [_refreshMargin] tới —
  /// dùng để chủ động lấy vé mới trước khi tile request bị 401.
  bool get isExpiringSoon =>
      DateTime.now().isAfter(expiresAt.subtract(_refreshMargin));

  factory MapTileTicket.fromJson(Map<String, dynamic> json) => MapTileTicket(
    ticket: _requiredString(json, 'ticket'),
    expiresAt: DateTime.parse(json['expiresAt'].toString()),
  );
}

class BasemapModel {
  const BasemapModel({
    required this.code,
    required this.nameVi,
    required this.provider,
    required this.urlTemplate,
    required this.attribution,
    this.minZoom,
    this.maxZoom,
  });

  final String code;
  final String nameVi;
  final String provider;
  final String urlTemplate;
  final String attribution;
  final double? minZoom;
  final double? maxZoom;

  bool get isMapboxStyle => urlTemplate.startsWith('mapbox://styles/');

  factory BasemapModel.fromJson(Map<String, dynamic> json) => BasemapModel(
    code: _requiredString(json, 'code'),
    nameVi: _requiredString(json, 'name_vi'),
    provider: _requiredString(json, 'provider'),
    urlTemplate: _requiredString(json, 'url_template'),
    attribution: json['attribution']?.toString() ?? '',
    minZoom: _doubleOrNull(json['min_zoom']),
    maxZoom: _doubleOrNull(json['max_zoom']),
  );
}

class MapSearchResult {
  const MapSearchResult({
    required this.layerId,
    required this.layerCode,
    required this.layerName,
    required this.featureId,
    required this.label,
    required this.longitude,
    required this.latitude,
  });

  final String layerId;
  final String layerCode;
  final String layerName;
  final String featureId;
  final String label;
  final double longitude;
  final double latitude;

  factory MapSearchResult.fromJson(Map<String, dynamic> json) {
    final location = _requiredMap(json, 'location');
    final coordinates = location['coordinates'];
    if (location['type'] != 'Point' ||
        coordinates is! List ||
        coordinates.length < 2) {
      throw const FormatException('location must be a GeoJSON Point');
    }
    return MapSearchResult(
      layerId: _requiredString(json, 'layerId'),
      layerCode: _requiredString(json, 'layerCode'),
      layerName: _requiredString(json, 'layerName'),
      featureId: _requiredString(json, 'feature_id'),
      label: _requiredString(json, 'label'),
      longitude: _double(coordinates[0]),
      latitude: _double(coordinates[1]),
    );
  }
}

Map<String, dynamic> responseDataMap(dynamic responseData) {
  final envelope = _asMap(responseData, 'response');
  return _requiredMap(envelope, 'data');
}

List<Map<String, dynamic>> responseDataList(dynamic responseData) {
  final envelope = _asMap(responseData, 'response');
  final data = envelope['data'];
  if (data is! List) throw const FormatException('data is not a list');
  return data.map((item) => _asMap(item, 'data[]')).toList(growable: false);
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) =>
    _asMap(json[key], key);

List<String> _stringList(dynamic value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('editableFields is not a list');
  }
  return List.unmodifiable(
    value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty),
  );
}

Map<String, dynamic> _optionalMap(dynamic value) {
  if (value == null) return const {};
  return _asMap(value, 'map');
}

Map<String, dynamic> _asMap(dynamic value, String name) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw FormatException('$name is not an object');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim() ?? '';
  if (value.isEmpty) throw FormatException('$key is required');
  return value;
}

int _int(dynamic value) {
  if (value is int) return value;
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) throw const FormatException('Expected integer');
  return parsed;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  if (parsed == null) throw const FormatException('Expected number');
  return parsed;
}

double? _doubleOrNull(dynamic value) => value == null ? null : _double(value);
