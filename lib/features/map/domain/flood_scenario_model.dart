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
    this.currentRainfall,
    this.rainfallSource,
    this.currentTide,
    this.tideSource,
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
  final double? currentRainfall;
  final String? rainfallSource;
  final double? currentTide;
  final String? tideSource;
  final LayerModel? layer;

  bool get canSelect => isActive && layer != null;
  bool get hasCurrentConditions =>
      currentRainfall != null || currentTide != null;
  String get rainfallRangeText => _range(minRainfall, maxRainfall, 'mm');
  String get tideRangeText => _range(minTide, maxTide, 'm');
  String get currentConditionsText => [
    if (currentRainfall != null)
      'Mưa: ${_format(currentRainfall!)} mm${_source(rainfallSource)}',
    if (currentTide != null)
      'Triều: ${_format(currentTide!)} m${_source(tideSource)}',
  ].join('\n');

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
      currentRainfall: _doubleOrNull(json['current_rainfall']),
      rainfallSource: json['rainfall_source']?.toString(),
      currentTide: _doubleOrNull(json['current_tide']),
      tideSource: json['tide_source']?.toString(),
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
  final parsed = double.tryParse(value?.toString() ?? '');
  return parsed != null && parsed.isFinite ? parsed : null;
}

String _format(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

String _range(double? min, double? max, String unit) {
  if (min != null && max != null) {
    return '${_format(min)} – ${_format(max)} $unit';
  }
  if (min != null) return '≥ ${_format(min)} $unit';
  if (max != null) return '≤ ${_format(max)} $unit';
  return '';
}

String _source(String? value) => switch (value) {
  'MANUAL' => ' · Thủ công',
  'AUTO' => ' · Tự động từ trạm',
  _ => '',
};
