import 'dart:math' as math;

import '../../tools/domain/field_tools_models.dart';

class RouteResult {
  const RouteResult({
    required this.provider,
    required this.profile,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
    required this.steps,
    required this.snappedStart,
    required this.snappedEnd,
  });

  final String provider;
  final String profile;
  final double distanceMeters;
  final double durationSeconds;
  final GeoJsonGeometry geometry;
  final List<RouteStep> steps;
  final GeoCoordinate snappedStart;
  final GeoCoordinate snappedEnd;

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    final geometryRaw = json['geometry'];
    final startRaw = json['snapped_start'];
    final endRaw = json['snapped_end'];
    if (geometryRaw is! Map || startRaw is! Map || endRaw is! Map) {
      throw const FormatException(
        'route geometry and snapped points are required',
      );
    }
    final geometry = GeoJsonGeometry.fromJson(
      Map<String, dynamic>.from(geometryRaw),
    );
    if (geometry.type != 'LineString') {
      throw const FormatException('route geometry must be LineString');
    }
    final distanceMeters = _requiredDouble(json, 'distance_m');
    final durationSeconds = _requiredDouble(json, 'duration_s');
    if (distanceMeters < 0 || durationSeconds < 0) {
      throw const FormatException(
        'route distance and duration must be positive',
      );
    }
    final stepsRaw = json['steps'];
    if (stepsRaw != null && stepsRaw is! List) {
      throw const FormatException('route steps must be a list');
    }
    return RouteResult(
      provider: _requiredString(json, 'provider'),
      profile: _requiredString(json, 'profile'),
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      geometry: geometry,
      steps: stepsRaw == null
          ? const <RouteStep>[]
          : stepsRaw
                .map<RouteStep>(
                  (value) => RouteStep.fromJson(
                    Map<String, dynamic>.from(value as Map),
                  ),
                )
                .toList(growable: false),
      snappedStart: _point(Map<String, dynamic>.from(startRaw)),
      snappedEnd: _point(Map<String, dynamic>.from(endRaw)),
    );
  }

  static GeoCoordinate _point(Map<String, dynamic> json) {
    if (json['type'] != 'Point') {
      throw const FormatException('snapped endpoint must be Point');
    }
    return GeoCoordinate.fromJson(json['coordinates']);
  }
}

class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.maneuverType,
    required this.modifier,
    required this.name,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.location,
  });

  final String instruction;
  final String maneuverType;
  final String? modifier;
  final String? name;
  final double distanceMeters;
  final double durationSeconds;
  final GeoCoordinate location;

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final locationRaw = json['location'];
    if (locationRaw is! Map || locationRaw['type'] != 'Point') {
      throw const FormatException('route step location must be Point');
    }
    final distanceMeters = _requiredDouble(json, 'distance_m');
    final durationSeconds = _requiredDouble(json, 'duration_s');
    if (distanceMeters < 0 || durationSeconds < 0) {
      throw const FormatException(
        'route step distance and duration must be positive',
      );
    }
    return RouteStep(
      instruction: _requiredString(json, 'instruction'),
      maneuverType: _requiredString(json, 'maneuver_type'),
      modifier: _optionalString(json['modifier']),
      name: _optionalString(json['name']),
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      location: GeoCoordinate.fromJson(locationRaw['coordinates']),
    );
  }
}

String? _optionalString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim();
  if (value == null || value.isEmpty) throw FormatException('$key is required');
  return value;
}

double _requiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  if (parsed == null || !parsed.isFinite) {
    throw FormatException('$key must be a finite number');
  }
  return parsed;
}

int nextRouteStepIndex({
  required RouteResult route,
  required int currentStepIndex,
  required GeoCoordinate position,
  required double accuracyMeters,
}) {
  if (route.steps.length < 2) return 0;
  final current = currentStepIndex.clamp(0, route.steps.length - 1);
  if (current == route.steps.length - 1 ||
      !accuracyMeters.isFinite ||
      accuracyMeters < 0 ||
      accuracyMeters > 50) {
    return current;
  }
  final thresholdMeters = (accuracyMeters * 1.5).clamp(25.0, 50.0);
  final nextManeuver = route.steps[current + 1].location;
  return _distanceMeters(position, nextManeuver) <= thresholdMeters
      ? current + 1
      : current;
}

double _distanceMeters(GeoCoordinate a, GeoCoordinate b) {
  const earthRadiusMeters = 6371000.0;
  final latitudeA = a.latitude * math.pi / 180;
  final latitudeB = b.latitude * math.pi / 180;
  final latitudeDelta = (b.latitude - a.latitude) * math.pi / 180;
  final longitudeDelta = (b.longitude - a.longitude) * math.pi / 180;
  final haversine =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(latitudeA) *
          math.cos(latitudeB) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  return earthRadiusMeters *
      2 *
      math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
}
