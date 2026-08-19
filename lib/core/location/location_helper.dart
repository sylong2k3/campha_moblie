import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;

/// Lý do không lấy được vị trí — để UI hiển thị đúng thông báo hướng dẫn
/// (bật GPS vs cấp quyền vs lỗi thiết bị vs vị trí giả lập).
enum LocationFailure { serviceDisabled, permissionDenied, unavailable, mocked }

/// Kết quả xin vị trí hiện tại: có [position] khi thành công, ngược lại
/// [failure] cho biết vì sao.
class LocationResult {
  const LocationResult.success(geo.Position this.position) : failure = null;

  const LocationResult.failed(LocationFailure this.failure) : position = null;

  final geo.Position? position;
  final LocationFailure? failure;
}

/// Luồng xin quyền + lấy vị trí GPS chuẩn của app — dùng chung cho nút "vị
/// trí của tôi", tìm đường, đo đạc GPS-track... thay vì mỗi nơi tự viết lại
/// chuỗi kiểm tra service/permission.
Future<LocationResult> getCurrentLocation() async {
  try {
    if (!await geo.Geolocator.isLocationServiceEnabled()) {
      if (kDebugMode) debugPrint('[LOCATE] service_disabled');
      return const LocationResult.failed(LocationFailure.serviceDisabled);
    }
    if (!await ensureLocationPermission()) {
      if (kDebugMode) debugPrint('[LOCATE] permission_denied');
      return const LocationResult.failed(LocationFailure.permissionDenied);
    }
    final settings = Platform.isAndroid
        ? geo.AndroidSettings(
            accuracy: geo.LocationAccuracy.bestForNavigation,
            forceLocationManager: true,
            timeLimit: const Duration(seconds: 15),
          )
        : const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.bestForNavigation,
            timeLimit: Duration(seconds: 15),
          );
    final position = await geo.Geolocator.getCurrentPosition(
      locationSettings: settings,
    );
    // Vị trí đến từ app fake GPS / mock location provider — không dùng để
    // tránh bay tới toạ độ giả.
    if (position.isMocked) {
      if (kDebugMode) debugPrint('[LOCATE] mocked_position_blocked');
      return const LocationResult.failed(LocationFailure.mocked);
    }
    return LocationResult.success(position);
  } catch (_) {
    if (kDebugMode) debugPrint('[LOCATE] unavailable');
    return const LocationResult.failed(LocationFailure.unavailable);
  }
}

/// Chỉ kiểm tra + xin quyền (không lấy toạ độ) — cho các luồng tự quản lý
/// stream vị trí như GPS-track đo đạc.
Future<bool> ensureLocationPermission() async {
  var permission = await geo.Geolocator.checkPermission();
  if (permission == geo.LocationPermission.denied) {
    permission = await geo.Geolocator.requestPermission();
  }
  return permission == geo.LocationPermission.always ||
      permission == geo.LocationPermission.whileInUse;
}
