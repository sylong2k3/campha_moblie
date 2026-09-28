import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Cẩm Phả default map center & zoom — single source of truth.
abstract final class MapDefaults {
  static const longitude = 107.319395;
  static const latitude = 21.025420;
  static const defaultZoom = 9.84;
  static const minZoom = 8.5;
  static const maxZoom = 20.0;

  // ponytail: Khung chữ nhật chỉ chặn tâm camera ra biển xa; muốn bám sát bờ cần ranh giới đa giác.
  static const minLongitude = 102.0;
  static const minLatitude = 19.2;
  static const maxLongitude = 107.6;
  static const maxLatitude = 23.5;

  static final center = Point(coordinates: Position(longitude, latitude));

  static final cameraOptions = CameraOptions(center: center, zoom: defaultZoom);

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
