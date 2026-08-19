import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/field_tools_models.dart';

final toolsRepositoryProvider = Provider<ToolsRepository>(
  (ref) => ToolsRepository(dio: ref.watch(dioProvider)),
);

class ToolsRepository {
  const ToolsRepository({required this.dio});

  final Dio dio;

  Future<WeatherSnapshot> getCurrentWeather(GeoCoordinate coordinate) => _item(
    () => dio.get(
      ApiEndpoints.mobileWeatherCurrent,
      queryParameters: {
        'longitude': coordinate.longitude,
        'latitude': coordinate.latitude,
      },
    ),
    WeatherSnapshot.fromJson,
  );

  Future<List<NearbyFeature>> getNearby({
    required String layerId,
    required GeoCoordinate coordinate,
    int radiusMeters = 200,
    int limit = 20,
  }) async {
    if (radiusMeters < 10 || radiusMeters > 2000 || limit < 1 || limit > 100) {
      throw const ValidationException('Phạm vi tìm kiếm không hợp lệ');
    }
    try {
      final response = await dio.get(
        ApiEndpoints.mobileNearby(layerId),
        queryParameters: {
          'longitude': coordinate.longitude,
          'latitude': coordinate.latitude,
          'radiusMeters': radiusMeters,
          'limit': limit,
        },
      );
      final data = _envelopeData(response.data);
      if (data is! List) throw const FormatException('data is not a list');
      return data
          .map((item) => NearbyFeature.fromJson(_map(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw mapErrorToAppException(error);
    } on FormatException {
      throw const UnknownException('Phản hồi máy chủ không đúng định dạng');
    }
  }

  Future<MeasurementResult> measure(GeoJsonGeometry geometry) => _item(
    () => dio.post(
      ApiEndpoints.mobileMeasure,
      data: {'geometry': geometry.toJson()},
    ),
    MeasurementResult.fromJson,
  );

  Future<T> _item<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request();
      return fromJson(_map(_envelopeData(response.data)));
    } on DioException catch (error) {
      throw mapErrorToAppException(error);
    } on FormatException {
      throw const UnknownException('Phản hồi máy chủ không đúng định dạng');
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }
}

Object? _envelopeData(Object? response) {
  final envelope = _map(response);
  if (!envelope.containsKey('data')) {
    throw const FormatException('missing data');
  }
  return envelope['data'];
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw const FormatException('value is not an object');
  return Map<String, dynamic>.from(value);
}
