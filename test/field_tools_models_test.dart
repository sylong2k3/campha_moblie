import 'package:campha_moblie/features/routing/domain/route_model.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates Cam Pha coordinates and closes polygon ring', () {
    const a = GeoCoordinate(107.32, 21.00);
    const b = GeoCoordinate(107.33, 21.01);
    const c = GeoCoordinate(107.34, 21.00);
    expect(a.isInCamPhaBounds, isTrue);
    expect(const GeoCoordinate(106, 21).isInCamPhaBounds, isFalse);
    expect(GeoJsonGeometry.line([a, b]).type, 'LineString');
    final polygon = GeoJsonGeometry.polygon([a, b, c]);
    final ring = (polygon.coordinates as List).first as List;
    expect(ring.first, ring.last);
  });

  test('parses exact live weather nearby and measure fixtures', () {
    final weather = WeatherSnapshot.fromJson({
      'observedAt': '2026-08-10T13:31:00.000Z',
      'location': 'Cam Pha Mines',
      'temperatureC': 29.53,
      'windSpeedMps': 1.78,
      'windDirectionDegrees': 226,
      'description': 'mây cụm',
    });
    final nearby = NearbyFeature.fromJson({
      'feature_id': '9007199254740993',
      'NAME_2': 'Cẩm Phả',
      'distance_m': '0.11',
      'location': {
        'type': 'Point',
        'coordinates': [107.303749, 21.002361],
      },
    });
    final measure = MeasurementResult.fromJson({
      'geometry_type': 'LINESTRING',
      'length_m': '1518.68',
      'area_m2': null,
    });
    expect(weather.temperatureC, 29.53);
    expect(nearby.featureId, '9007199254740993');
    expect(nearby.label, 'Cẩm Phả');
    expect(measure.lengthMeters, 1518.68);
  });

  test('parses exact Mapbox route and rejects malformed geometry', () {
    final route = RouteResult.fromJson({
      'provider': 'mapbox',
      'profile': 'driving',
      'distance_m': '1012.45',
      'duration_s': 124.5,
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [107.3301, 21.0],
          [107.3399, 21.0],
        ],
      },
      'steps': [
        {
          'instruction': 'Rẽ phải vào Quốc lộ 18',
          'maneuver_type': 'turn',
          'modifier': 'right',
          'name': 'Quốc lộ 18',
          'distance_m': 456.79,
          'duration_s': 98.77,
          'location': {
            'type': 'Point',
            'coordinates': [107.335, 21.005],
          },
        },
      ],
      'snapped_start': {
        'type': 'Point',
        'coordinates': [107.3301, 21.0],
      },
      'snapped_end': {
        'type': 'Point',
        'coordinates': [107.3399, 21.0],
      },
    });
    expect(route.provider, 'mapbox');
    expect(route.profile, 'driving');
    expect(route.distanceMeters, 1012.45);
    expect(route.durationSeconds, 124.5);
    expect(route.steps, hasLength(1));
    expect(route.steps.single.instruction, 'Rẽ phải vào Quốc lộ 18');
    expect(route.steps.single.modifier, 'right');
    expect(route.steps.single.distanceMeters, 456.79);
    expect(
      () => GeoJsonGeometry.fromJson({
        'type': 'Polygon',
        'coordinates': [
          [
            [107.3, 21.0],
            [107.4, 21.0],
            [107.4, 21.1],
            [107.3, 21.1],
          ],
        ],
      }),
      throwsFormatException,
    );
  });

  test('route instruction advances one step near next maneuver only', () {
    final route = RouteResult(
      provider: 'mapbox',
      profile: 'driving',
      distanceMeters: 1000,
      durationSeconds: 120,
      geometry: GeoJsonGeometry.line(const [
        GeoCoordinate(107.33, 21),
        GeoCoordinate(107.34, 21.01),
      ]),
      steps: const [
        RouteStep(
          instruction: 'Đi thẳng',
          maneuverType: 'depart',
          modifier: 'straight',
          name: null,
          distanceMeters: 400,
          durationSeconds: 50,
          location: GeoCoordinate(107.33, 21),
        ),
        RouteStep(
          instruction: 'Rẽ phải',
          maneuverType: 'turn',
          modifier: 'right',
          name: null,
          distanceMeters: 600,
          durationSeconds: 70,
          location: GeoCoordinate(107.335, 21.005),
        ),
      ],
      snappedStart: const GeoCoordinate(107.33, 21),
      snappedEnd: const GeoCoordinate(107.34, 21.01),
    );

    expect(
      nextRouteStepIndex(
        route: route,
        currentStepIndex: 0,
        position: const GeoCoordinate(107.33, 21),
        accuracyMeters: 8,
      ),
      0,
    );
    expect(
      nextRouteStepIndex(
        route: route,
        currentStepIndex: 0,
        position: const GeoCoordinate(107.335, 21.005),
        accuracyMeters: 8,
      ),
      1,
    );
    expect(
      nextRouteStepIndex(
        route: route,
        currentStepIndex: 0,
        position: const GeoCoordinate(107.335, 21.005),
        accuracyMeters: 80,
      ),
      0,
    );
    expect(
      nextRouteStepIndex(
        route: route,
        currentStepIndex: 1,
        position: const GeoCoordinate(107.33, 21),
        accuracyMeters: 8,
      ),
      1,
    );
  });

  test('formats official measurements as m, km, m² and ha', () {
    expect(
      const MeasurementResult(
        geometryType: 'LINESTRING',
        lengthMeters: 999.99,
      ).formattedMetricValue,
      '999.99 m',
    );
    expect(
      const MeasurementResult(
        geometryType: 'LINESTRING',
        lengthMeters: 1518.68,
      ).formattedMetricValue,
      '1.52 km',
    );
    expect(
      const MeasurementResult(
        geometryType: 'POLYGON',
        areaSquareMeters: 9999.99,
      ).formattedMetricValue,
      '9999.99 m²',
    );
    expect(
      const MeasurementResult(
        geometryType: 'POLYGON',
        areaSquareMeters: 1150834.32,
      ).formattedMetricValue,
      '115.08 ha',
    );
  });
}
