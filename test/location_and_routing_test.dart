import 'dart:async';

import 'package:campha_moblie/core/error/app_exception.dart';
import 'package:campha_moblie/core/location/location_helper.dart';
import 'package:campha_moblie/features/tools/data/tools_repository.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_controller.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as geo;

void main() {
  group('Location permission and cache recovery', () {
    late geo.GeolocatorPlatform original;
    late _FakeGeolocator gps;

    setUp(() {
      original = geo.GeolocatorPlatform.instance;
      gps = _FakeGeolocator();
      geo.GeolocatorPlatform.instance = gps;
    });
    tearDown(() => geo.GeolocatorPlatform.instance = original);

    test('requests system permission once before fetching position', () async {
      gps.permission = geo.LocationPermission.denied;
      final result = await getCurrentLocation();
      expect(result.isSuccess, isTrue);
      expect(gps.permissionRequests, 1);
      expect(gps.currentCalls, 1);
      expect(gps.cachedCalls, 0);
    });

    test(
      'service disabled does not request permission or read cache',
      () async {
        gps.serviceEnabled = false;
        final result = await getCurrentLocation();
        expect(result.failure, LocationFailure.serviceDisabled);
        expect(gps.permissionRequests, 0);
        expect(gps.currentCalls, 0);
        expect(gps.cachedCalls, 0);
      },
    );

    for (final permission in [
      geo.LocationPermission.denied,
      geo.LocationPermission.deniedForever,
      geo.LocationPermission.unableToDetermine,
    ]) {
      test('permission $permission never returns cached success', () async {
        gps.permission = permission;
        gps.requestedPermission = permission;
        final result = await getCurrentLocation();
        expect(
          result.failure,
          permission == geo.LocationPermission.deniedForever
              ? LocationFailure.permissionDeniedForever
              : LocationFailure.permissionDenied,
        );
        expect(gps.currentCalls, 0);
        expect(gps.cachedCalls, 0);
      });
    }

    test('passive access check never opens permission dialog', () async {
      gps.permission = geo.LocationPermission.denied;
      expect(await checkLocationAccess(), LocationFailure.permissionDenied);
      expect(gps.permissionRequests, 0);
    });

    for (final error in [
      TimeoutException('GPS timeout'),
      geo.PositionUpdateException('No fix'),
    ]) {
      test('$error accepts recent accurate cache', () async {
        gps.currentError = error;
        gps.cached = _gpsPosition(
          age: const Duration(seconds: 119),
          accuracy: 100,
        );
        final result = await getCurrentLocation();
        expect(result.position, same(gps.cached));
        expect(gps.cachedCalls, 1);
      });
    }

    for (final entry in <String, geo.Position?>{
      'missing': null,
      'older than two minutes': _gpsPosition(age: const Duration(seconds: 121)),
      'future timestamp': _gpsPosition(age: const Duration(minutes: -1)),
      'inaccurate': _gpsPosition(accuracy: 100.1),
      'negative accuracy': _gpsPosition(accuracy: -1),
      'infinite accuracy': _gpsPosition(accuracy: double.infinity),
      'NaN accuracy': _gpsPosition(accuracy: double.nan),
      'invalid latitude': _gpsPosition(latitude: 91),
      'invalid longitude': _gpsPosition(longitude: 181),
      'NaN coordinate': _gpsPosition(latitude: double.nan),
    }.entries) {
      test('timeout rejects ${entry.key} cache', () async {
        gps.currentError = TimeoutException('GPS timeout');
        gps.cached = entry.value;
        final result = await getCurrentLocation();
        expect(result.failure, LocationFailure.timeout);
        expect(result.position, isNull);
      });
    }

    test('permission revoked during fix cannot fall back to cache', () async {
      gps.currentError = geo.PermissionDeniedException('Revoked');
      gps.onCurrent = () =>
          gps.permission = geo.LocationPermission.deniedForever;
      final result = await getCurrentLocation();
      expect(result.failure, LocationFailure.permissionDeniedForever);
      expect(gps.cachedCalls, 0);
      expect(gps.permissionRequests, 0);
    });

    test('service disabled during fix cannot fall back to cache', () async {
      gps.currentError = const geo.LocationServiceDisabledException();
      final result = await getCurrentLocation();
      expect(result.failure, LocationFailure.serviceDisabled);
      expect(gps.cachedCalls, 0);
    });

    test('timeout rechecks permission before reading cache', () async {
      gps.currentError = TimeoutException('GPS timeout');
      gps.onCurrent = () => gps.permission = geo.LocationPermission.denied;
      final result = await getCurrentLocation();
      expect(result.failure, LocationFailure.permissionDenied);
      expect(gps.cachedCalls, 0);
      expect(gps.permissionRequests, 0);
    });

    test('timeout rechecks service before reading cache', () async {
      gps.currentError = TimeoutException('GPS timeout');
      gps.onCurrent = () => gps.serviceEnabled = false;
      final result = await getCurrentLocation();
      expect(result.failure, LocationFailure.serviceDisabled);
      expect(gps.cachedCalls, 0);
    });

    test('unexpected plugin error is not hidden by cached success', () async {
      gps.currentError = StateError('Plugin failed');
      expect((await getCurrentLocation()).failure, LocationFailure.unavailable);
      expect(gps.cachedCalls, 0);
    });

    test('cache read failure is handled', () async {
      gps.currentError = TimeoutException('GPS timeout');
      gps.cacheError = StateError('Cache failed');
      expect((await getCurrentLocation()).failure, LocationFailure.unavailable);
    });

    test('locate accepts valid GPS outside CamPha', () async {
      gps.current = _gpsPosition(latitude: -33.8688, longitude: 151.2093);
      final container = ProviderContainer(
        overrides: [
          toolsRepositoryProvider.overrideWithValue(_FakeToolsRepository()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(fieldToolsProvider.notifier).locate();
      final state = container.read(fieldToolsProvider);
      expect(state.locationStatus, LocationStatus.ready);
      expect(state.location?.latitude, -33.8688);
      expect(state.location?.longitude, 151.2093);
      expect(state.error, isNull);
      expect(state.weather, isNull);
    });

    test('rejects malformed live coordinates without reading cache', () async {
      gps.current = _gpsPosition(latitude: double.nan);
      expect((await getCurrentLocation()).failure, LocationFailure.unavailable);
      expect(gps.cachedCalls, 0);
    });
  });

  group('LocationResult & LocationFailure', () {
    test('LocationResult.success sets position and isSuccess=true', () {
      final pos = geo.Position(
        longitude: 107.35,
        latitude: 21.05,
        timestamp: DateTime(2026, 9, 9),
        accuracy: 10.0,
        altitude: 5.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      );
      final result = LocationResult.success(pos);
      expect(result.isSuccess, isTrue);
      expect(result.position, equals(pos));
      expect(result.failure, isNull);
    });

    test('LocationResult.failed sets failure and isSuccess=false', () {
      const result = LocationResult.failed(LocationFailure.serviceDisabled);
      expect(result.isSuccess, isFalse);
      expect(result.position, isNull);
      expect(result.failure, equals(LocationFailure.serviceDisabled));
    });

    test('LocationFailure covers all key recovery conditions', () {
      expect(
        LocationFailure.values,
        containsAll([
          LocationFailure.serviceDisabled,
          LocationFailure.permissionDenied,
          LocationFailure.permissionDeniedForever,
          LocationFailure.timeout,
          LocationFailure.unavailable,
        ]),
      );
    });
  });

  group('FieldToolsController GPS & Route Location', () {
    late ProviderContainer container;
    late FieldToolsController controller;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          toolsRepositoryProvider.overrideWithValue(_FakeToolsRepository()),
        ],
      );
      controller = container.read(fieldToolsProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('setGpsLocation inside CamPha sets status to ready', () {
      // 107.35, 21.02 is inside Cam Pha bounds
      const insideCoord = GeoCoordinate(107.35, 21.02);
      expect(insideCoord.isInCamPhaBounds, isTrue);

      controller.setGpsLocation(
        coordinate: insideCoord,
        accuracyMeters: 8.5,
        timestamp: DateTime(2026, 9, 9, 14, 0),
      );

      final state = container.read(fieldToolsProvider);
      expect(state.locationStatus, equals(LocationStatus.ready));
      expect(state.location, equals(insideCoord));
      expect(state.accuracyMeters, 8.5);
    });

    test('setGpsLocation outside CamPha sets status to ready', () {
      // 105.85, 21.02 (Hanoi) is outside Cam Pha
      const outsideCoord = GeoCoordinate(105.85, 21.02);
      expect(outsideCoord.isInCamPhaBounds, isFalse);

      controller.setGpsLocation(
        coordinate: outsideCoord,
        accuracyMeters: 15.0,
        timestamp: DateTime(2026, 9, 9, 14, 0),
      );

      final state = container.read(fieldToolsProvider);
      expect(state.locationStatus, equals(LocationStatus.ready));
      expect(state.location, equals(outsideCoord));
    });

    test('route position accepts valid GPS outside CamPha', () {
      const coordinate = GeoCoordinate(-74.006, 40.7128);
      controller.updateRoutePosition(
        position: coordinate,
        accuracyMeters: 5,
        timestamp: DateTime.now(),
      );
      final state = container.read(fieldToolsProvider);
      expect(state.location, same(coordinate));
      expect(state.locationStatus, LocationStatus.ready);
      expect(state.error, isNull);
    });

    test('invalid coordinates and accuracy do not replace last GPS fix', () {
      const valid = GeoCoordinate(105.85, 21.02);
      final timestamp = DateTime.now();
      controller.setGpsLocation(
        coordinate: valid,
        accuracyMeters: 5,
        timestamp: timestamp,
      );
      for (final (coordinate, accuracy) in [
        (const GeoCoordinate(181, 0), 5.0),
        (const GeoCoordinate(0, -91), 5.0),
        (const GeoCoordinate(double.nan, 0), 5.0),
        (valid, double.infinity),
        (valid, -1.0),
      ]) {
        controller.setGpsLocation(
          coordinate: coordinate,
          accuracyMeters: accuracy,
          timestamp: timestamp,
        );
        controller.updateRoutePosition(
          position: coordinate,
          accuracyMeters: accuracy,
          timestamp: timestamp,
        );
        final state = container.read(fieldToolsProvider);
        expect(state.location, same(valid));
        expect(state.accuracyMeters, 5);
      }
    });

    test('useLocationAsRouteStart inside CamPha sets routeStart', () {
      const insideCoord = GeoCoordinate(107.35, 21.02);
      controller.setGpsLocation(
        coordinate: insideCoord,
        accuracyMeters: 5.0,
        timestamp: DateTime(2026, 9, 9, 14, 0),
      );

      controller.useLocationAsRouteStart();

      final state = container.read(fieldToolsProvider);
      expect(state.routeStart, equals(insideCoord));
      expect(state.error, isNull);
    });

    test(
      'useLocationAsRouteStart outside CamPha sets error ValidationException',
      () {
        const outsideCoord = GeoCoordinate(105.85, 21.02);
        controller.setGpsLocation(
          coordinate: outsideCoord,
          accuracyMeters: 5.0,
          timestamp: DateTime(2026, 9, 9, 14, 0),
        );

        controller.useLocationAsRouteStart();

        final state = container.read(fieldToolsProvider);
        expect(state.routeStart, isNull);
        expect(state.error, isA<ValidationException>());
        expect(
          (state.error as ValidationException).message,
          contains('Cẩm Phả'),
        );
      },
    );
  });
}

geo.Position _gpsPosition({
  Duration age = const Duration(seconds: 1),
  double accuracy = 5,
  double latitude = 21.05,
  double longitude = 107.35,
}) => geo.Position(
  longitude: longitude,
  latitude: latitude,
  timestamp: DateTime.now().subtract(age),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class _FakeGeolocator extends geo.GeolocatorPlatform {
  bool serviceEnabled = true;
  geo.LocationPermission permission = geo.LocationPermission.whileInUse;
  geo.LocationPermission requestedPermission =
      geo.LocationPermission.whileInUse;
  geo.Position current = _gpsPosition();
  geo.Position? cached = _gpsPosition();
  Object? currentError;
  Object? cacheError;
  void Function()? onCurrent;
  int permissionRequests = 0;
  int currentCalls = 0;
  int cachedCalls = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<geo.LocationPermission> checkPermission() async => permission;

  @override
  Future<geo.LocationPermission> requestPermission() async {
    permissionRequests++;
    return permission = requestedPermission;
  }

  @override
  Future<geo.Position> getCurrentPosition({
    geo.LocationSettings? locationSettings,
  }) async {
    currentCalls++;
    onCurrent?.call();
    if (currentError case final error?) throw error;
    return current;
  }

  @override
  Future<geo.Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    cachedCalls++;
    if (cacheError case final error?) throw error;
    return cached;
  }
}

class _FakeToolsRepository extends ToolsRepository {
  _FakeToolsRepository() : super(dio: Dio());

  @override
  Future<WeatherSnapshot> getCurrentWeather(GeoCoordinate coordinate) async {
    return WeatherSnapshot(
      observedAt: DateTime(2026, 9, 9, 14, 0),
      location: 'Cẩm Phả',
      temperatureC: 28.5,
      windSpeedMps: 3.5,
      windDirectionDegrees: 45,
      description: 'Nhiều mây',
    );
  }
}
