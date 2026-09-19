import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Cẩm Phả default map center & zoom — single source of truth.
abstract final class MapDefaults {
  static const longitude = 107.32;
  static const latitude = 21.07;
  static const defaultZoom = 9.6;

  static final center = Point(coordinates: Position(longitude, latitude));

  static final cameraOptions = CameraOptions(
    center: center,
    zoom: defaultZoom,
  );
}
