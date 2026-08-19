class FeatureDetailModel {
  const FeatureDetailModel({
    required this.id,
    required this.layerId,
    required this.attributes,
    this.geometry,
    this.version,
  });

  final String id;
  final String layerId;
  final Map<String, dynamic> attributes;
  final Map<String, dynamic>? geometry;
  final int? version;

  String get geometryType => geometry?['type']?.toString() ?? 'Unknown';

  int get coordinateCount {
    int count(dynamic value) {
      if (value is! List) return 0;
      if (value.length >= 2 && value[0] is num && value[1] is num) return 1;
      return value.fold(0, (sum, item) => sum + count(item));
    }

    return count(geometry?['coordinates']);
  }

  factory FeatureDetailModel.fromJson(Map<String, dynamic> json) {
    final layerId = _requiredString(json, 'layerId');
    final feature = _requiredMap(json, 'feature');
    final geometry = feature['geometry'] == null
        ? null
        : _asMap(feature['geometry'], 'feature.geometry');
    final attributes = <String, dynamic>{};
    for (final entry in feature.entries) {
      if (entry.key == 'geometry' || entry.key == 'version') continue;
      attributes[entry.key] = entry.value;
    }
    final idEntry = attributes.entries
        .cast<MapEntry<String, dynamic>?>()
        .firstWhere(
          (entry) =>
              entry != null &&
              (entry.key == 'feature_id' ||
                  entry.key == 'source_fid' ||
                  entry.key == 'source_row' ||
                  entry.key == 'id'),
          orElse: () => null,
        );
    if (idEntry == null || idEntry.value == null) {
      throw const FormatException('Feature ID is missing');
    }
    final versionValue = feature['version'];
    return FeatureDetailModel(
      id: idEntry.value.toString(),
      layerId: layerId,
      attributes: Map.unmodifiable(attributes),
      geometry: geometry,
      version: versionValue is int
          ? versionValue
          : int.tryParse(versionValue?.toString() ?? ''),
    );
  }
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) =>
    _asMap(json[key], key);

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
