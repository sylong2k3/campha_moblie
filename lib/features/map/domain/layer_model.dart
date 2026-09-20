import 'package:flutter/material.dart';

import 'legend_models.dart';

export 'legend_models.dart';

/// Chuyển đổi mã màu hex (#RRGGBB, #AARRGGBB, #RGB) sang đối tượng Color.
Color? parseHexColor(dynamic hex) {
  if (hex == null) return null;
  var clean = hex.toString().replaceAll('#', '').replaceAll('0x', '').trim();
  if (clean.length == 3) {
    clean = clean.split('').map((c) => '$c$c').join();
  }
  if (clean.length == 6) clean = 'FF$clean';
  if (clean.length == 8) {
    final val = int.tryParse(clean, radix: 16);
    if (val != null) return Color(val);
  }
  return null;
}

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
    this.isEnableDefault = false,
    this.defaultStyle,
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
  final bool isEnableDefault;
  final Map<String, dynamic>? defaultStyle;

  bool get isRaster =>
      geometryType.toUpperCase() == 'RASTER' || storageKind == 'geotiff_minio';
  bool get isPoint => geometryType.toUpperCase().contains('POINT');
  bool get isLine => geometryType.toUpperCase().contains('LINE');
  bool get isPolygon => geometryType.toUpperCase().contains('POLYGON');

  Color? get customPointColor =>
      parseHexColor(defaultStyle?['circleColor']) ??
      parseHexColor(defaultStyle?['color']);

  Color? get customStrokeColor =>
      parseHexColor(defaultStyle?['strokeColor']) ??
      parseHexColor(defaultStyle?['lineColor']) ??
      parseHexColor(defaultStyle?['color']);

  Color? get customFillColor =>
      parseHexColor(defaultStyle?['fillColor']) ??
      parseHexColor(defaultStyle?['color']);

  Color? get customCircleStrokeColor =>
      parseHexColor(defaultStyle?['circleStrokeColor']);

  double? get customStrokeWidth => _doubleOrNull(defaultStyle?['strokeWidth']);
  double? get customCircleRadius =>
      _doubleOrNull(defaultStyle?['circleRadius']);
  double? get customCircleStrokeWidth =>
      _doubleOrNull(defaultStyle?['circleStrokeWidth']);
  double? get customFillOpacity => _doubleOrNull(defaultStyle?['fillOpacity']);
  double? get customStrokeOpacity =>
      _doubleOrNull(defaultStyle?['strokeOpacity']);
  double? get customCircleOpacity =>
      _doubleOrNull(defaultStyle?['circleOpacity']);
  double? get customRasterOpacity => _doubleOrNull(
    defaultStyle?['rasterOpacity'] ??
        defaultStyle?['raster_opacity'] ??
        defaultStyle?['opacity'],
  );

  MapboxStyleConfig get mapboxStyle => MapboxStyleConfig.fromJson(defaultStyle);
  List<double>? get customStrokeDasharray => mapboxStyle.strokeDasharray;

  bool get computedDefaultEnabled =>
      isEnableDefault ||
      (defaultStyle?['visible_by_default'] == true) ||
      (defaultStyle?['visibleByDefault'] == true);

  LegendGroup? get legendGroup {
    if (legend.isEmpty) return null;
    final group = LegendGroup.fromRaw(
      code.isNotEmpty ? code : id,
      nameVi,
      legend,
    );
    return group.entries.isNotEmpty ? group : null;
  }

  bool get hasValidLegend => legendGroup != null;

  /// Mã màu chính thức do API trả về (từ `defaultStyle` hoặc `legend`).
  /// Trả về null nếu backend không cấu hình màu riêng cho lớp này.
  Color? get apiColor {
    // 1. Ưu tiên cấu hình từ defaultStyle theo hình học
    Color? styleColor;
    if (isPoint) {
      styleColor = customPointColor ?? customStrokeColor ?? customFillColor;
    } else if (isLine) {
      styleColor = customStrokeColor ?? customFillColor;
    } else if (isPolygon) {
      styleColor = customFillColor ?? customStrokeColor;
    } else {
      styleColor = customFillColor ?? customStrokeColor ?? customPointColor;
    }
    if (styleColor != null) return styleColor;

    // 2. Ưu tiên cấu hình từ legend.entries (danh sách entries chuẩn từ API)
    final entries = legend['entries'];
    if (entries is List) {
      for (final entry in entries) {
        if (entry is! Map) continue;
        final color = parseHexColor(
          entry['color'] ?? entry['fill'] ?? entry['hex'] ?? entry['colorHex'],
        );
        if (color != null) return color;
      }
    }

    // 3. Đọc từ các trường color trực tiếp trong legend
    final hex =
        legend['color']?.toString() ??
        legend['fillColor']?.toString() ??
        legend['strokeColor']?.toString() ??
        legend['circleColor']?.toString() ??
        legend['colorHex']?.toString();
    return parseHexColor(hex);
  }

  /// True nếu lớp có cấu hình mã màu từ API (không dùng màu tự sinh fallback).
  bool get hasApiColor => apiColor != null;

  /// Màu mặc định từ GeoServer theo hình học chuẩn của SLD GeoServer
  /// khi lớp không có cấu hình màu riêng từ API:
  /// - Point / MultiPoint: #FF0000 (Red Square Point)
  /// - Line / MultiLineString: #0000FF (Blue Line)
  /// - Polygon / MultiPolygon: #AAAAAA (Default Polygon)
  Color? get geoserverDefaultColor {
    if (geoserverLayer == null || geoserverLayer!.trim().isEmpty) return null;
    if (isPoint) return const Color(0xFFFF0000);
    if (isLine) return const Color(0xFF0000FF);
    if (isPolygon) return const Color(0xFFAAAAAA);
    return const Color(0xFFAAAAAA);
  }

  /// True nếu lớp là vector, không có mã màu cấu hình từ API, nhưng có nguồn GeoServer.
  /// Lớp này sẽ được render qua WMS của GeoServer với `styles=` để dùng style mặc định từ GeoServer.
  bool get usesGeoServerDefaultStyle =>
      !isRaster && !hasApiColor && (geoserverLayer?.trim().isNotEmpty ?? false);

  /// Mã màu hiển thị của lớp: ưu tiên mã màu chính thức từ API,
  /// nếu không có thì lấy màu mặc định từ GeoServer (nếu có nguồn geoserverLayer).
  Color? get displayColor => apiColor ?? geoserverDefaultColor;

  factory LayerModel.fromJson(Map<String, dynamic> json) {
    final rawLegend =
        json['legend'] ?? json['legendConfig'] ?? json['legend_config'];
    Map<String, dynamic> legendMap;
    if (rawLegend is Map) {
      legendMap = _asMap(rawLegend, 'legend');
    } else if (rawLegend is List) {
      legendMap = {'entries': rawLegend};
    } else {
      legendMap = const {};
    }

    final metadata = _optionalMap(json['metadata']);
    final rawDefaultStyle =
        json['defaultStyle'] ??
        json['default_style'] ??
        metadata['defaultStyle'] ??
        metadata['default_style'];
    final defaultStyleMap = rawDefaultStyle == null
        ? null
        : _asMap(rawDefaultStyle, 'defaultStyle');

    // Cờ false rõ ràng từ API không được trường tương thích cũ ghi đè.
    final isDefault =
        (json['isEnableDefault'] ??
            json['is_enable_default'] ??
            defaultStyleMap?['visible_by_default']) ==
        true;

    return LayerModel(
      id: _requiredString(json, 'id'),
      code: _requiredString(json, 'code'),
      nameVi: _requiredString(json, 'nameVi'),
      category:
          (json['categoryName'] ??
                      json['category_name'] ??
                      json['categoryNameVi'] ??
                      json['category_name_vi'] ??
                      json['category'])
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
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
      legend: legendMap,
      isPublic: json['isPublic'] == true,
      canEdit: json['canEdit'] == true,
      editableFields: _stringList(json['editableFields']),
      isEnableDefault: isDefault,
      defaultStyle: defaultStyleMap,
    );
  }
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

  factory LayerLegend.fromJson(Map<String, dynamic> json) {
    final rawLegend =
        json['legend'] ?? json['legendConfig'] ?? json['legend_config'];
    Map<String, dynamic> legendMap;
    if (rawLegend is Map) {
      legendMap = _asMap(rawLegend, 'legend');
    } else if (rawLegend is List) {
      legendMap = {'entries': rawLegend};
    } else {
      legendMap = const {};
    }
    return LayerLegend(
      layerId: _requiredString(json, 'layerId'),
      code: _requiredString(json, 'code'),
      nameVi: _requiredString(json, 'nameVi'),
      styleName: json['styleName']?.toString(),
      minZoom: _doubleOrNull(json['minZoom']),
      maxZoom: _doubleOrNull(json['maxZoom']),
      legend: legendMap,
    );
  }
}

/// Vé truy cập tile WMS/WFS cho layer không `isPublic` — `RasterSource` của
/// Mapbox không gắn được header `Authorization` vào từng tile request, nên
/// server phát vé ngắn hạn nhúng vào query string thay cho header.
class MapTileTicket {
  const MapTileTicket({required this.ticket, required this.expiresAt});

  final String ticket;
  final DateTime expiresAt;

  static const _refreshMargin = Duration(seconds: 60);

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
