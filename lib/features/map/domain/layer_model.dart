import 'package:flutter/material.dart';

/// Màu mặc định khi server không cấu hình màu riêng cho layer.
const Color defaultLayerColor = Color(0xFF3B82F6);

/// Bảng 24 màu phân giải cao, độ tương phản cao để phân biệt rõ ràng giữa các
/// lớp dữ liệu (point, line, polygon, ranh giới, thủy hệ, công trình...).
const List<Color> defaultLayerColorPalette = [
  Color(0xFFE11D48), // Rose Red (Ranh giới, cảnh báo)
  Color(0xFF0284C7), // Sky Blue (Thủy hệ, sông hồ)
  Color(0xFF059669), // Emerald Green (Cây xanh, nông nghiệp, sinh thái)
  Color(0xFFD97706), // Amber (Giao thông, đường bộ)
  Color(0xFF7C3AED), // Vivid Purple (Quy hoạch, hành chính)
  Color(0xFFEA580C), // Deep Orange (Công trình, xây dựng)
  Color(0xFF0891B2), // Deep Cyan (Thoát nước, thủy văn)
  Color(0xFFDB2777), // Magenta Pink (Điểm cơ sở, y tế, giáo dục)
  Color(0xFF0D9488), // Teal (Tài nguyên, môi trường)
  Color(0xFF65A30D), // Lime (Công viên, mặt bằng xanh)
  Color(0xFF4F46E5), // Indigo (Dịch vụ công, tiện ích)
  Color(0xFF9A3412), // Rust Brown (Khai khoáng, bãi than, địa chất)
  Color(0xFF334155), // Slate (Lưới điện, hạ tầng kỹ thuật)
  Color(0xFFC026D3), // Fuchsia (Địa chính, khu vực đặc thù)
  Color(0xFF2563EB), // Royal Blue (Vùng ngập, mặt nước biển)
  Color(0xFF854D0E), // Bronze (Khu công nghiệp)
  Color(0xFFF43F5E), // Coral (Khu vực nguy cơ cao)
  Color(0xFF6B21A8), // Deep Violet (Ranh giới bảo tồn)
  Color(0xFF16A34A), // Forest Green (Rừng phòng hộ)
  Color(0xFFB45309), // Amber Brown (Kho bãi, đất trống)
  Color(0xFF0E7490), // Ocean Blue (Hệ thống cấp nước)
  Color(0xFFBE185D), // Dark Ruby (Điểm nóng môi trường)
  Color(0xFF4338CA), // Dark Indigo (Công trình ngầm)
  Color(0xFF15803D), // Deep Green (Đất canh tác nông nghiệp)
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
    final hex =
        legend['color']?.toString() ??
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
