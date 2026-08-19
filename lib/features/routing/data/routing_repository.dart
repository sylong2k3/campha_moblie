import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../tools/domain/field_tools_models.dart';
import '../domain/route_model.dart';

final routingRepositoryProvider = Provider<RoutingRepository>(
  (ref) => RoutingRepository(dio: ref.watch(dioProvider)),
);

class RoutingRepository {
  const RoutingRepository({required this.dio});

  final Dio dio;

  Future<RouteResult> findShortestRoute({
    required GeoCoordinate start,
    required GeoCoordinate end,
    String profile = 'driving',
    CancelToken? cancelToken,
  }) async {
    if (start.longitude == end.longitude && start.latitude == end.latitude) {
      throw const ValidationException('Điểm đầu và điểm cuối phải khác nhau');
    }
    if (!const {'driving', 'walking', 'cycling'}.contains(profile)) {
      throw const ValidationException('Loại phương tiện không được hỗ trợ');
    }
    try {
      final response = await dio.post(
        ApiEndpoints.mobileShortestRoute,
        data: {
          'start': start.toJson(),
          'end': end.toJson(),
          'profile': profile,
        },
        cancelToken: cancelToken,
      );
      final envelope = _map(response.data);
      return RouteResult.fromJson(_map(envelope['data']));
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw mapErrorToAppException(error);
    } on FormatException {
      throw const UnknownException('Phản hồi máy chủ không đúng định dạng');
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw const FormatException('value is not an object');
  return Map<String, dynamic>.from(value);
}
