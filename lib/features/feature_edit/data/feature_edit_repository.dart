import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../tools/domain/field_tools_models.dart';
import '../domain/feature_edit_models.dart';

final featureEditRepositoryProvider = Provider<FeatureEditRepository>(
  (ref) => FeatureEditRepository(ref.watch(dioProvider)),
);

class FeatureEditRepository {
  const FeatureEditRepository(this._dio);
  final Dio _dio;

  Future<EditableFeatureSnapshot> update({
    required String layerId,
    required String featureId,
    required int baseVersion,
    Map<String, dynamic> attributes = const {},
    GeoJsonGeometry? geometry,
  }) async {
    if (attributes.isEmpty && geometry == null) {
      throw ArgumentError('Feature change is empty');
    }
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.mobileFeatureDetail(layerId, featureId),
        data: {
          'baseVersion': baseVersion,
          if (attributes.isNotEmpty) 'attributes': attributes,
          if (geometry != null) 'geometry': geometry.toJson(),
        },
      );
      return EditableFeatureSnapshot.fromJson({
        ..._data(response),
        'featureId': featureId,
      });
    } on DioException catch (error) {
      throw mapErrorToAppException(error);
    } on FormatException {
      throw const UnknownException('Phản hồi máy chủ không đúng định dạng');
    }
  }

  Future<List<FeatureVersion>> history(String layerId, String featureId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.mobileFeatureHistory(layerId, featureId),
      );
      final raw = _body(response)['data'];
      if (raw is! List) throw const FormatException('data is not a list');
      return raw
          .map((item) => FeatureVersion.fromJson(_map(item, 'data[]')))
          .toList(growable: false);
    } on DioException catch (error) {
      throw mapErrorToAppException(error);
    } on FormatException {
      throw const UnknownException('Phản hồi máy chủ không đúng định dạng');
    }
  }

  Future<EditableFeatureSnapshot> restore({
    required String layerId,
    required String featureId,
    required int version,
    required int baseVersion,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.mobileFeatureRestore(layerId, featureId, version),
        data: {'baseVersion': baseVersion},
      );
      return EditableFeatureSnapshot.fromJson({
        ..._data(response),
        'featureId': featureId,
      });
    } on DioException catch (error) {
      throw mapErrorToAppException(error);
    } on FormatException {
      throw const UnknownException('Phản hồi máy chủ không đúng định dạng');
    }
  }

  Future<SyncResult> sync({
    required String clientId,
    required List<OfflineFeatureChange> changes,
  }) async {
    if (changes.isEmpty || changes.length > 50) {
      throw ArgumentError('Sync batch must contain 1–50 changes');
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.mobileSync,
        data: {
          'clientId': clientId,
          'changes': changes
              .map((item) => item.toApiJson())
              .toList(growable: false),
        },
      );
      return SyncResult.fromJson(_data(response));
    } on DioException catch (error) {
      throw mapErrorToAppException(error);
    } on FormatException {
      throw const UnknownException('Phản hồi máy chủ không đúng định dạng');
    }
  }
}

Map<String, dynamic> _body(Response<Map<String, dynamic>> response) {
  final body = response.data;
  if (body == null) throw const FormatException('Missing response body');
  return body;
}

Map<String, dynamic> _data(Response<Map<String, dynamic>> response) =>
    _map(_body(response)['data'], 'data');

Map<String, dynamic> _map(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('$field is not an object');
}
