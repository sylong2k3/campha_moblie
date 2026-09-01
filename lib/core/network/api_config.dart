import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const _defineAppName = String.fromEnvironment('APP_NAME');
  static const _defineAppVersion = String.fromEnvironment('APP_VERSION');
  static const _defineBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _defineGeoserverUrl = String.fromEnvironment('GEOSERVER_URL');
  static const _defineGoogleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );
  static const _defineMapboxToken = String.fromEnvironment('MAPBOX_TOKEN');
  static const _defineMapboxStyleOutdoor = String.fromEnvironment(
    'MAPBOX_STYLE_OUTDOOR',
  );
  static const _defineMapboxStyleSatelliteStreet = String.fromEnvironment(
    'MAPBOX_STYLE_SATELLITE_STREET',
  );
  static const _defineMapboxStyleStreet = String.fromEnvironment(
    'MAPBOX_STYLE_STREET',
  );
  static const _defineMapboxStyleSatellite = String.fromEnvironment(
    'MAPBOX_STYLE_SATELLITE',
  );
  static const _defineWsUrl = String.fromEnvironment('WS_NOTIFICATIONS_URL');

  static String _value(String define, [String fallback = '']) =>
      define.isEmpty ? fallback : define;

  static String get appName => _value(_defineAppName, 'GIS Cẩm Phả');
  static String get appVersion => _value(_defineAppVersion, '1.0.0');
  static String get baseUrl =>
      _value(_defineBaseUrl, 'https://apicampha.tourismpj.pro.vn/api/v1');
  static String get geoserverUrl => _value(
    _defineGeoserverUrl,
    'https://geoserver.humgsoftware.pro.vn/geoserver',
  );
  static String get googleClientId => _value(_defineGoogleClientId);

  static bool get verboseLogging =>
      kDebugMode && const bool.fromEnvironment('VERBOSE_LOGGING');

  static int get apiTimeoutSeconds =>
      int.tryParse(const String.fromEnvironment('API_TIMEOUT_SECONDS')) ?? 30;

  static double get gpsAccuracyThresholdM =>
      double.tryParse(
        const String.fromEnvironment('GPS_ACCURACY_THRESHOLD_M'),
      ) ??
      10;

  static String get mapboxToken => _value(
    _defineMapboxToken,
    'pk.eyJ1IjoiaGlldWhhIiwiYSI6ImNtbDVia21obDAxcjUzZnNkcGpuOG05M3oifQ.68AhyFbI0QZitSIMKfmeGA',
  );
  static String get mapboxStyleOutdoor => _value(
    _defineMapboxStyleOutdoor,
    'mapbox://styles/hieuha/cmqknupw8005o01s83401bc52',
  );
  static String get mapboxStyleSatelliteStreet => _value(
    _defineMapboxStyleSatelliteStreet,
    'mapbox://styles/hieuha/cmqknuklz005v01qx9wqe44sf',
  );
  static String get mapboxStyleStreet => _value(
    _defineMapboxStyleStreet,
    'mapbox://styles/hieuha/cmqknut0o005w01qxer55caza',
  );
  static String get mapboxStyleSatellite => _value(
    _defineMapboxStyleSatellite,
    'mapbox://styles/hieuha/cmqknuev1009p01r5evrtgelg',
  );
  static String get wsNotificationsUrl => _value(_defineWsUrl);

  static String? validateForRelease({
    String? apiBaseUrl,
    String? mapboxAccessToken,
    String? geoserverBaseUrl,
    String? notificationsWebSocketUrl,
    String? googleOAuthClientId,
    int? timeoutSeconds,
    double? accuracyThresholdM,
  }) {
    final api = apiBaseUrl ?? baseUrl;
    final token = mapboxAccessToken ?? mapboxToken;
    final geoserver = geoserverBaseUrl ?? geoserverUrl;
    final websocket = notificationsWebSocketUrl ?? wsNotificationsUrl;
    final oauthClientId = googleOAuthClientId ?? googleClientId;
    final timeout = timeoutSeconds ?? apiTimeoutSeconds;
    final accuracy = accuracyThresholdM ?? gpsAccuracyThresholdM;

    final apiError = _validateProductionUrl(api, field: 'API_BASE_URL');
    if (apiError != null) return apiError;
    // Raster/WMS layer rendering (map_repository.dart) calls ApiConfig.geoserverUrl
    // unconditionally with no fallback — an empty value silently breaks every
    // raster layer at runtime instead of failing the build, so it must be
    // required here rather than only validated when present.
    if (geoserver.isEmpty) {
      return 'GEOSERVER_URL release không được để trống.';
    }
    final geoserverError = _validateProductionUrl(
      geoserver,
      field: 'GEOSERVER_URL',
    );
    if (geoserverError != null) return geoserverError;
    if (websocket.isNotEmpty) {
      final uri = Uri.tryParse(websocket);
      if (uri == null || !uri.hasAuthority || uri.scheme != 'wss') {
        return 'WS_NOTIFICATIONS_URL release phải là WSS URL hợp lệ.';
      }
    }
    if (token.isNotEmpty && (!token.startsWith('pk.') || token.length < 20)) {
      return 'MAPBOX_TOKEN release phải là public token hợp lệ.';
    }
    if (oauthClientId.isNotEmpty &&
        !oauthClientId.endsWith('.apps.googleusercontent.com')) {
      return 'GOOGLE_CLIENT_ID release phải là OAuth web client ID hợp lệ.';
    }
    if (timeout < 5 || timeout > 120) {
      return 'API_TIMEOUT_SECONDS release phải trong khoảng 5–120.';
    }
    if (!accuracy.isFinite || accuracy <= 0 || accuracy > 100) {
      return 'GPS_ACCURACY_THRESHOLD_M release phải trong khoảng 0–100.';
    }
    return null;
  }

  static String? _validateProductionUrl(String value, {required String field}) {
    final uri = Uri.tryParse(value);
    final host = uri?.host.toLowerCase() ?? '';
    if (uri == null || !uri.hasAuthority || uri.scheme != 'https') {
      return '$field release phải là HTTPS URL hợp lệ.';
    }
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        host.endsWith('.invalid')) {
      return '$field release không được dùng host local/placeholder.';
    }
    return null;
  }

  static Duration get connectTimeout => Duration(seconds: apiTimeoutSeconds);
  static Duration get receiveTimeout => Duration(seconds: apiTimeoutSeconds);

  static String get filesBaseUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  static String? absoluteFileUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    return path.startsWith('http') ? path : '$filesBaseUrl$path';
  }

  // Rewrites direct MinIO URLs (host:9000) to go through the API proxy.
  // The server may return presigned URLs pointing at the internal MinIO address
  // which mobile clients cannot reach; redirect them through the API host.
  static String rewriteStorageUrl(String url) {
    if (!url.contains(':9000')) return url;
    return url.replaceAll(RegExp(r'https?://[^/]+:9000'), filesBaseUrl);
  }
}
