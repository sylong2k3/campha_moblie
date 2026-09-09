import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;

/// Lý do không lấy được vị trí — để UI hiển thị đúng thông báo hướng dẫn
/// (bật GPS vs cấp quyền vs lỗi thiết bị vs hết thời gian chờ).
enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unavailable,
}

/// Kết quả xin vị trí hiện tại: có [position] khi thành công, ngược lại
/// [failure] cho biết vì sao.
class LocationResult {
  const LocationResult.success(geo.Position this.position) : failure = null;

  const LocationResult.failed(LocationFailure this.failure) : position = null;

  final geo.Position? position;
  final LocationFailure? failure;

  bool get isSuccess => position != null;
}

/// Kiểm tra thụ động mặc định; chỉ xin quyền khi người dùng chủ động định vị.
Future<LocationFailure?> checkLocationAccess({
  bool requestPermission = false,
}) async {
  try {
    if (!await geo.Geolocator.isLocationServiceEnabled()) {
      return LocationFailure.serviceDisabled;
    }
    final permission = requestPermission
        ? await ensureLocationPermissionDetailed()
        : await geo.Geolocator.checkPermission();
    return switch (permission) {
      geo.LocationPermission.always ||
      geo.LocationPermission.whileInUse => null,
      geo.LocationPermission.deniedForever =>
        LocationFailure.permissionDeniedForever,
      _ => LocationFailure.permissionDenied,
    };
  } catch (error) {
    if (kDebugMode) debugPrint('[LOCATE] access_check_failed: $error');
    return LocationFailure.unavailable;
  }
}

bool _isValidPosition(geo.Position position) =>
    position.latitude.isFinite &&
    position.latitude >= -90 &&
    position.latitude <= 90 &&
    position.longitude.isFinite &&
    position.longitude >= -180 &&
    position.longitude <= 180 &&
    position.accuracy.isFinite &&
    position.accuracy >= 0;

/// Lọc vị trí dự phòng và stream dẫn đường, không áp ngưỡng đo đạc 10 m.
bool isRecentAccuratePosition(geo.Position position) {
  final age = DateTime.now().difference(position.timestamp);
  // ponytail: cache tối đa 2 phút/100 m; đo đạc chính xác cần fix mới và ngưỡng riêng.
  return _isValidPosition(position) &&
      position.accuracy <= 100 &&
      !age.isNegative &&
      age <= const Duration(minutes: 2);
}

/// Luồng xin quyền + lấy vị trí GPS chuẩn của app — dùng chung cho nút "vị
/// trí của tôi", tìm đường, đo đạc GPS-track... thay vì mỗi nơi tự viết lại
/// chuỗi kiểm tra service/permission.
Future<LocationResult> getCurrentLocation({
  Duration timeLimit = const Duration(seconds: 10),
}) async {
  try {
    final accessFailure = await checkLocationAccess(requestPermission: true);
    if (accessFailure != null) return LocationResult.failed(accessFailure);

    // Trên Android dùng FusedLocationProviderClient mặc định (forceLocationManager: false).
    // Fused Provider kết hợp GPS + WiFi + Mạng di động giúp định vị tức thì và ổn định cả trong nhà.
    final settings = Platform.isAndroid
        ? geo.AndroidSettings(
            accuracy: geo.LocationAccuracy.high,
            timeLimit: timeLimit,
          )
        : geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            timeLimit: timeLimit,
          );

    geo.Position? position;
    try {
      position = await geo.Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
    } catch (error) {
      // Lỗi quyền/dịch vụ/cấu hình phải được báo, không lấy cache để che lỗi.
      if (error is! TimeoutException && error is! geo.PositionUpdateException) {
        rethrow;
      }
      final failure = error is TimeoutException
          ? LocationFailure.timeout
          : LocationFailure.unavailable;
      final accessFailure = await checkLocationAccess();
      if (accessFailure != null) return LocationResult.failed(accessFailure);
      position = await geo.Geolocator.getLastKnownPosition();
      final currentAccessFailure = await checkLocationAccess();
      if (currentAccessFailure != null) {
        return LocationResult.failed(currentAccessFailure);
      }
      if (position == null || !isRecentAccuratePosition(position)) {
        if (kDebugMode) debugPrint('[LOCATE] no_usable_recent_position');
        return LocationResult.failed(failure);
      }
      if (kDebugMode) debugPrint('[LOCATE] using_recent_cached_position');
    }

    if (!_isValidPosition(position)) {
      return const LocationResult.failed(LocationFailure.unavailable);
    }
    if (kDebugMode && position.isMocked) {
      debugPrint(
        '[LOCATE] using mock/emulator position: ${position.latitude}, ${position.longitude}',
      );
    }

    return LocationResult.success(position);
  } on geo.LocationServiceDisabledException {
    return const LocationResult.failed(LocationFailure.serviceDisabled);
  } on geo.PermissionDeniedException {
    return LocationResult.failed(
      await checkLocationAccess() ?? LocationFailure.permissionDenied,
    );
  } on TimeoutException {
    return const LocationResult.failed(LocationFailure.timeout);
  } catch (error) {
    if (kDebugMode) debugPrint('[LOCATE] unexpected_error: $error');
    return const LocationResult.failed(LocationFailure.unavailable);
  }
}

/// Kiểm tra + xin quyền chi tiết trả về [geo.LocationPermission].
Future<geo.LocationPermission> ensureLocationPermissionDetailed() async {
  var permission = await geo.Geolocator.checkPermission();
  if (permission == geo.LocationPermission.denied) {
    permission = await geo.Geolocator.requestPermission();
  }
  return permission;
}

/// Chỉ kiểm tra + xin quyền (không lấy toạ độ) — cho các luồng tự quản lý
/// stream vị trí như GPS-track đo đạc.
Future<bool> ensureLocationPermission() async {
  final permission = await ensureLocationPermissionDetailed();
  return permission == geo.LocationPermission.always ||
      permission == geo.LocationPermission.whileInUse;
}
