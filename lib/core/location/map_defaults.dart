import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Cẩm Phả default map center & zoom — single source of truth.
abstract final class MapDefaults {
  static const longitude = 107.32;
  static const latitude = 21.11;
  static const defaultZoom = 9.6;
  static const minZoom = 8.5;
  static const maxZoom = 20.0;

  // Giới hạn không gian địa lý Cẩm Phả: [107.0, 20.7, 108.0, 21.35]
  static const minLongitude = 107.0;
  static const minLatitude = 20.7;
  static const maxLongitude = 108.0;
  static const maxLatitude = 21.35;

  static final center = Point(coordinates: Position(longitude, latitude));

  static final cameraOptions = CameraOptions(
    center: center,
    zoom: defaultZoom,
  );

  static final cameraBounds = CameraBoundsOptions(
    bounds: CoordinateBounds(
      southwest: Point(coordinates: Position(minLongitude, minLatitude)),
      northeast: Point(coordinates: Position(maxLongitude, maxLatitude)),
      infiniteBounds: false,
    ),
    minZoom: minZoom,
    maxZoom: maxZoom,
  );
}
