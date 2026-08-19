class GeoCoordinate {
  const GeoCoordinate(this.longitude, this.latitude);

  final double longitude;
  final double latitude;

  bool get isInCamPhaBounds =>
      longitude >= 107.15 &&
      longitude <= 107.65 &&
      latitude >= 20.88 &&
      latitude <= 21.32;

  List<double> toJson() => [longitude, latitude];

  factory GeoCoordinate.fromJson(Object? value) {
    if (value is! List || value.length != 2) {
      throw const FormatException('coordinate must have two values');
    }
    final longitude = value[0];
    final latitude = value[1];
    if (longitude is! num || latitude is! num) {
      throw const FormatException('coordinate values must be numbers');
    }
    final coordinate = GeoCoordinate(longitude.toDouble(), latitude.toDouble());
    if (!coordinate.isInCamPhaBounds) {
      throw const FormatException('coordinate is outside supported bounds');
    }
    return coordinate;
  }
}

class GeoJsonGeometry {
  const GeoJsonGeometry({required this.type, required this.coordinates});

  final String type;
  final Object coordinates;

  factory GeoJsonGeometry.point(GeoCoordinate point) =>
      GeoJsonGeometry(type: 'Point', coordinates: point.toJson());

  factory GeoJsonGeometry.line(List<GeoCoordinate> points) {
    if (points.length < 2 || points.length > 500) {
      throw const FormatException('LineString requires 2–500 points');
    }
    return GeoJsonGeometry(
      type: 'LineString',
      coordinates: points
          .map((point) => point.toJson())
          .toList(growable: false),
    );
  }

  factory GeoJsonGeometry.polygon(List<GeoCoordinate> points) {
    if (points.length < 3 || points.length > 499) {
      throw const FormatException('Polygon requires 3–499 vertices');
    }
    final ring = [...points, points.first];
    return GeoJsonGeometry(
      type: 'Polygon',
      coordinates: [
        ring.map((point) => point.toJson()).toList(growable: false),
      ],
    );
  }

  factory GeoJsonGeometry.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final raw = json['coordinates'];
    if (type == 'Point') {
      return GeoJsonGeometry.point(GeoCoordinate.fromJson(raw));
    }
    if (type == 'LineString' && raw is List) {
      // ponytail: Giới hạn 10k điểm; generalize/stream nếu sau này hỗ trợ tuyến dài hơn.
      if (raw.length < 2 || raw.length > 10000) {
        throw const FormatException('LineString requires 2–10000 points');
      }
      final points = raw.map(GeoCoordinate.fromJson).toList(growable: false);
      return GeoJsonGeometry(
        type: 'LineString',
        coordinates: points
            .map((point) => point.toJson())
            .toList(growable: false),
      );
    }
    if (type == 'Polygon' &&
        raw is List &&
        raw.isNotEmpty &&
        raw.first is List) {
      final ring = (raw.first as List)
          .map(GeoCoordinate.fromJson)
          .toList(growable: false);
      if (ring.length < 4 ||
          ring.first.longitude != ring.last.longitude ||
          ring.first.latitude != ring.last.latitude) {
        throw const FormatException('Polygon ring must be closed');
      }
      return GeoJsonGeometry(
        type: 'Polygon',
        coordinates: [
          ring.map((point) => point.toJson()).toList(growable: false),
        ],
      );
    }
    throw const FormatException('unsupported geometry');
  }

  Map<String, dynamic> toJson() => {'type': type, 'coordinates': coordinates};
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.observedAt,
    required this.location,
    required this.temperatureC,
    required this.windSpeedMps,
    required this.windDirectionDegrees,
    required this.description,
  });

  final DateTime observedAt;
  final String location;
  final double temperatureC;
  final double windSpeedMps;
  final int windDirectionDegrees;
  final String? description;

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) =>
      WeatherSnapshot(
        observedAt: _requiredDate(json, 'observedAt'),
        location: _requiredString(json, 'location'),
        temperatureC: _requiredDouble(json, 'temperatureC'),
        windSpeedMps: _requiredDouble(json, 'windSpeedMps'),
        windDirectionDegrees: _requiredInt(json, 'windDirectionDegrees'),
        description: json['description']?.toString(),
      );
}

class NearbyFeature {
  const NearbyFeature({
    required this.featureId,
    required this.distanceMeters,
    required this.location,
    required this.attributes,
  });

  final String featureId;
  final double distanceMeters;
  final GeoCoordinate location;
  final Map<String, Object?> attributes;

  String get label {
    for (final key in const ['name', 'NAME_2', 'name_vi', 'title']) {
      final value = attributes[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return featureId;
  }

  factory NearbyFeature.fromJson(Map<String, dynamic> json) {
    final location = _requiredMap(json, 'location');
    if (location['type'] != 'Point') {
      throw const FormatException('nearby location must be Point');
    }
    final attributes = Map<String, Object?>.from(json)
      ..remove('feature_id')
      ..remove('distance_m')
      ..remove('location');
    return NearbyFeature(
      featureId: _requiredString(json, 'feature_id'),
      distanceMeters: _requiredDouble(json, 'distance_m'),
      location: GeoCoordinate.fromJson(location['coordinates']),
      attributes: attributes,
    );
  }
}

class MeasurementResult {
  const MeasurementResult({
    required this.geometryType,
    this.lengthMeters,
    this.areaSquareMeters,
  });

  final String geometryType;
  final double? lengthMeters;
  final double? areaSquareMeters;

  String get formattedMetricValue {
    final length = lengthMeters;
    if (length != null) {
      return length >= 1000
          ? '${(length / 1000).toStringAsFixed(2)} km'
          : '${length.toStringAsFixed(2)} m';
    }
    final area = areaSquareMeters!;
    return area >= 10000
        ? '${(area / 10000).toStringAsFixed(2)} ha'
        : '${area.toStringAsFixed(2)} m²';
  }

  factory MeasurementResult.fromJson(Map<String, dynamic> json) {
    final type = _requiredString(json, 'geometry_type');
    final length = _nullableDouble(json['length_m']);
    final area = _nullableDouble(json['area_m2']);
    if ((type == 'LINESTRING' && length == null) ||
        (type == 'POLYGON' && area == null)) {
      throw const FormatException('measurement result does not match geometry');
    }
    return MeasurementResult(
      geometryType: type,
      lengthMeters: length,
      areaSquareMeters: area,
    );
  }
}

Map<String, dynamic> _asMap(Object? value, String key) {
  if (value is! Map) throw FormatException('$key is not an object');
  return Map<String, dynamic>.from(value);
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) =>
    _asMap(json[key], key);

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim();
  if (value == null || value.isEmpty) throw FormatException('$key is required');
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (parsed == null) throw FormatException('$key must be an integer');
  return parsed;
}

double _requiredDouble(Map<String, dynamic> json, String key) {
  final value = _nullableDouble(json[key]);
  if (value == null) throw FormatException('$key must be a number');
  return value;
}

double? _nullableDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = DateTime.tryParse(json[key]?.toString() ?? '');
  if (value == null) throw FormatException('$key must be an ISO date');
  return value;
}
