import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/error_mapper.dart';
import '../../routing/data/routing_repository.dart';
import '../../routing/domain/route_model.dart';
import '../data/tools_repository.dart';
import 'field_tools_models.dart';

enum FieldToolMode { idle, measureDistance, measureArea, route }

enum LocationStatus {
  idle,
  locating,
  ready,
  serviceDisabled,
  denied,
  deniedForever,
  outsideBounds,
}

class FieldToolsState {
  const FieldToolsState({
    this.mode = FieldToolMode.idle,
    this.locationStatus = LocationStatus.idle,
    this.location,
    this.accuracyMeters,
    this.locationTime,
    this.weather,
    this.nearby = const [],
    this.vertices = const [],
    this.redoVertices = const [],
    this.measurement,
    this.routeStart,
    this.routeEnd,
    this.route,
    this.activeRouteStepIndex = 0,
    this.loading = false,
    this.error,
  });

  final FieldToolMode mode;
  final LocationStatus locationStatus;
  final GeoCoordinate? location;
  final double? accuracyMeters;
  final DateTime? locationTime;
  final WeatherSnapshot? weather;
  final List<NearbyFeature> nearby;
  final List<GeoCoordinate> vertices;
  final List<GeoCoordinate> redoVertices;
  final MeasurementResult? measurement;
  final GeoCoordinate? routeStart;
  final GeoCoordinate? routeEnd;
  final RouteResult? route;
  final int activeRouteStepIndex;
  final bool loading;
  final Object? error;

  bool get canMeasure => mode == FieldToolMode.measureDistance
      ? vertices.length >= 2
      : mode == FieldToolMode.measureArea && vertices.length >= 3;

  FieldToolsState copyWith({
    FieldToolMode? mode,
    LocationStatus? locationStatus,
    GeoCoordinate? location,
    double? accuracyMeters,
    DateTime? locationTime,
    WeatherSnapshot? weather,
    List<NearbyFeature>? nearby,
    List<GeoCoordinate>? vertices,
    List<GeoCoordinate>? redoVertices,
    MeasurementResult? measurement,
    GeoCoordinate? routeStart,
    GeoCoordinate? routeEnd,
    RouteResult? route,
    int? activeRouteStepIndex,
    bool? loading,
    Object? error,
    bool clearError = false,
    bool clearMeasurement = false,
    bool clearRouteResult = false,
    bool clearRouteEndpoints = false,
    bool replaceRouteEndpoints = false,
  }) => FieldToolsState(
    mode: mode ?? this.mode,
    locationStatus: locationStatus ?? this.locationStatus,
    location: location ?? this.location,
    accuracyMeters: accuracyMeters ?? this.accuracyMeters,
    locationTime: locationTime ?? this.locationTime,
    weather: weather ?? this.weather,
    nearby: nearby ?? this.nearby,
    vertices: vertices ?? this.vertices,
    redoVertices: redoVertices ?? this.redoVertices,
    measurement: clearMeasurement ? null : measurement ?? this.measurement,
    routeStart: clearRouteEndpoints
        ? null
        : replaceRouteEndpoints
        ? routeStart
        : routeStart ?? this.routeStart,
    routeEnd: clearRouteEndpoints
        ? null
        : replaceRouteEndpoints
        ? routeEnd
        : routeEnd ?? this.routeEnd,
    route: clearRouteEndpoints || clearRouteResult ? null : route ?? this.route,
    activeRouteStepIndex: clearRouteEndpoints || clearRouteResult
        ? 0
        : activeRouteStepIndex ?? this.activeRouteStepIndex,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
  );
}

class FieldToolsController extends Notifier<FieldToolsState> {
  CancelToken? _routeCancelToken;
  int _measureRevision = 0;

  @override
  FieldToolsState build() {
    ref.onDispose(() {
      _measureRevision++;
      _cancelRoute('controller disposed');
    });
    return const FieldToolsState();
  }

  void _cancelRoute(String reason) {
    final token = _routeCancelToken;
    _routeCancelToken = null;
    if (token != null && !token.isCancelled) token.cancel(reason);
  }

  Future<void> locate() async {
    state = state.copyWith(
      locationStatus: LocationStatus.locating,
      loading: true,
      clearError: true,
    );
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = state.copyWith(
          locationStatus: LocationStatus.serviceDisabled,
          loading: false,
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          locationStatus: LocationStatus.deniedForever,
          loading: false,
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          locationStatus: LocationStatus.denied,
          loading: false,
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final coordinate = GeoCoordinate(position.longitude, position.latitude);
      state = state.copyWith(
        locationStatus: LocationStatus.ready,
        location: coordinate,
        accuracyMeters: position.accuracy,
        locationTime: position.timestamp,
        loading: false,
      );
    } catch (error) {
      state = state.copyWith(
        locationStatus: LocationStatus.idle,
        loading: false,
        error: mapErrorToAppException(error),
      );
    }
  }

  Future<void> loadWeatherAndNearby(String? layerId) async {
    final coordinate = state.location;
    if (coordinate == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repository = ref.read(toolsRepositoryProvider);
      final results = await Future.wait<Object>([
        repository.getCurrentWeather(coordinate),
        if (layerId != null)
          repository.getNearby(layerId: layerId, coordinate: coordinate)
        else
          Future.value(const <NearbyFeature>[]),
      ]);
      state = state.copyWith(
        weather: results[0] as WeatherSnapshot,
        nearby: results[1] as List<NearbyFeature>,
        loading: false,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: mapErrorToAppException(error),
      );
    }
  }

  void startMeasure({required bool area}) {
    _measureRevision++;
    state = state.copyWith(
      mode: area ? FieldToolMode.measureArea : FieldToolMode.measureDistance,
      vertices: const [],
      redoVertices: const [],
      loading: false,
      clearMeasurement: true,
      clearRouteEndpoints: true,
      clearError: true,
    );
  }

  void startRoute() {
    _measureRevision++;
    state = state.copyWith(
      mode: FieldToolMode.route,
      vertices: const [],
      redoVertices: const [],
      loading: false,
      clearMeasurement: true,
      clearRouteEndpoints: true,
      clearError: true,
    );
  }

  void addMapPoint(GeoCoordinate point) {
    if (!point.isInCamPhaBounds) return;
    if (state.mode == FieldToolMode.route) {
      if (state.routeStart == null) {
        state = state.copyWith(
          routeStart: point,
          clearRouteResult: true,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          routeEnd: point,
          clearRouteResult: true,
          clearError: true,
        );
      }
      return;
    }
    if (state.mode != FieldToolMode.measureDistance &&
        state.mode != FieldToolMode.measureArea) {
      return;
    }
    state = state.copyWith(
      vertices: [...state.vertices, point],
      redoVertices: const [],
      clearMeasurement: true,
      clearError: true,
    );
    _refreshMeasurement();
  }

  void undo() {
    if (state.vertices.isEmpty) return;
    final removed = state.vertices.last;
    state = state.copyWith(
      vertices: state.vertices.sublist(0, state.vertices.length - 1),
      redoVertices: [...state.redoVertices, removed],
      clearMeasurement: true,
      clearError: true,
    );
    _refreshMeasurement();
  }

  void redo() {
    if (state.redoVertices.isEmpty) return;
    final point = state.redoVertices.last;
    state = state.copyWith(
      vertices: [...state.vertices, point],
      redoVertices: state.redoVertices.sublist(
        0,
        state.redoVertices.length - 1,
      ),
      clearMeasurement: true,
      clearError: true,
    );
    _refreshMeasurement();
  }

  void _refreshMeasurement() {
    final revision = ++_measureRevision;
    if (!state.canMeasure) {
      state = state.copyWith(loading: false, clearMeasurement: true);
      return;
    }
    final geometry = state.mode == FieldToolMode.measureArea
        ? GeoJsonGeometry.polygon(state.vertices)
        : GeoJsonGeometry.line(state.vertices);
    final preview = MeasurementResult.preview(
      area: state.mode == FieldToolMode.measureArea,
      points: state.vertices,
    );
    state = state.copyWith(
      measurement: preview,
      loading: true,
      clearError: true,
    );
    ref
        .read(toolsRepositoryProvider)
        .measure(geometry)
        .then((result) {
          if (revision != _measureRevision) return;
          state = state.copyWith(measurement: result, loading: false);
        })
        .catchError((Object error) {
          if (revision != _measureRevision) return;
          state = state.copyWith(
            loading: false,
            error: mapErrorToAppException(error),
          );
        });
  }

  Future<void> findRoute() async {
    final start = state.routeStart;
    final end = state.routeEnd;
    if (start == null || end == null) return;
    _cancelRoute('route endpoints changed');
    final cancelToken = CancelToken();
    _routeCancelToken = cancelToken;
    state = state.copyWith(
      loading: true,
      clearError: true,
      clearRouteResult: true,
    );
    try {
      final result = await ref
          .read(routingRepositoryProvider)
          .findShortestRoute(start: start, end: end, cancelToken: cancelToken);
      if (!cancelToken.isCancelled &&
          identical(_routeCancelToken, cancelToken)) {
        state = state.copyWith(route: result, loading: false);
      }
    } catch (error) {
      if (!cancelToken.isCancelled &&
          identical(_routeCancelToken, cancelToken)) {
        state = state.copyWith(
          loading: false,
          error: mapErrorToAppException(error),
        );
      }
    } finally {
      if (identical(_routeCancelToken, cancelToken)) {
        _routeCancelToken = null;
      }
    }
  }

  void useLocationAsRouteStart() {
    final location = state.location;
    if (location != null && location.isInCamPhaBounds) {
      state = state.copyWith(
        routeStart: location,
        clearRouteResult: true,
        clearError: true,
      );
    }
  }

  void updateRoutePosition({
    required GeoCoordinate position,
    required double accuracyMeters,
    required DateTime timestamp,
  }) {
    if (!position.isInCamPhaBounds) return;
    final route = state.route;
    final nextIndex = route == null
        ? state.activeRouteStepIndex
        : nextRouteStepIndex(
            route: route,
            currentStepIndex: state.activeRouteStepIndex,
            position: position,
            accuracyMeters: accuracyMeters,
          );
    state = state.copyWith(
      location: position,
      accuracyMeters: accuracyMeters,
      locationTime: timestamp,
      locationStatus: LocationStatus.ready,
      activeRouteStepIndex: nextIndex,
    );
  }

  void editRouteEndpoints() {
    _cancelRoute('route editing started');
    state = state.copyWith(clearRouteResult: true, clearError: true);
  }

  void swapRouteEndpoints() {
    final start = state.routeStart;
    final end = state.routeEnd;
    state = state.copyWith(
      routeStart: end,
      routeEnd: start,
      replaceRouteEndpoints: true,
      clearRouteResult: true,
      clearError: true,
    );
  }

  void cancelTool() {
    _measureRevision++;
    _cancelRoute('tool cancelled');
    state = FieldToolsState(
      locationStatus: state.locationStatus,
      location: state.location,
      accuracyMeters: state.accuracyMeters,
      locationTime: state.locationTime,
      weather: state.weather,
      nearby: state.nearby,
    );
  }

  void clearSensitiveState() {
    _measureRevision++;
    _cancelRoute('session changed');
    state = const FieldToolsState();
  }
}

final fieldToolsProvider =
    NotifierProvider<FieldToolsController, FieldToolsState>(
      FieldToolsController.new,
    );
