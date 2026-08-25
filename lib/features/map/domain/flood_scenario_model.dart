import 'layer_model.dart';

class FloodScenarioModel {
  const FloodScenarioModel({
    required this.id,
    required this.code,
    required this.nameVi,
    required this.layerCode,
    required this.isActive,
    this.minRainfall,
    this.maxRainfall,
    this.minTide,
    this.maxTide,
    this.description,
    this.layer,
  });

  final int id;
  final String code;
  final String nameVi;
  final String layerCode;
  final bool isActive;
  final double? minRainfall;
  final double? maxRainfall;
  final double? minTide;
  final double? maxTide;
  final String? description;
  final LayerModel? layer;

  String get rainfallRangeText {
    if (minRainfall != null && maxRainfall != null) {
      return '${minRainfall!.toStringAsFixed(0)} - ${maxRainfall!.toStringAsFixed(0)} mm';
    } else if (minRainfall != null) {
      return '>= ${minRainfall!.toStringAsFixed(0)} mm';
    } else if (maxRainfall != null) {
      return '< ${maxRainfall!.toStringAsFixed(0)} mm';
    }
    return '';
  }

  factory FloodScenarioModel.fromJson(Map<String, dynamic> json) {
    LayerModel? parsedLayer;
    final layerJson = json['layer'];
    if (layerJson is Map<String, dynamic>) {
      try {
        parsedLayer = LayerModel.fromJson(layerJson);
      } catch (_) {}
    }

    return FloodScenarioModel(
      id: _int(json['id']),
      code: json['code']?.toString() ?? '',
      nameVi: json['name_vi']?.toString() ?? json['nameVi']?.toString() ?? '',
      layerCode:
          json['layer_code']?.toString() ?? json['layerCode']?.toString() ?? '',
      isActive: json['is_active'] == true || json['isActive'] == true,
      minRainfall: _doubleOrNull(json['min_rainfall']),
      maxRainfall: _doubleOrNull(json['max_rainfall']),
      minTide: _doubleOrNull(json['min_tide']),
      maxTide: _doubleOrNull(json['max_tide']),
      description: json['description']?.toString(),
      layer: parsedLayer,
    );
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) throw const FormatException('Expected integer');
  return parsed;
}

double? _doubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
