import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/interceptors/logging_interceptor.dart';
import '../../tools/domain/field_tools_models.dart';
import '../domain/field_report_models.dart';

final fieldReportRepositoryProvider = Provider<FieldReportRepository>((ref) {
  return FieldReportRepository(ref.watch(dioProvider));
});

class FieldReportRepository {
  FieldReportRepository(this._dio);
  final Dio _dio;

  Future<FieldReportPage> getPublic({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.fieldReportsPublic,
      queryParameters: {'page': page, 'limit': limit, 'status': ?status},
      cancelToken: cancelToken,
    );
    return FieldReportPage.fromEnvelope(_body(response));
  }

  Future<List<FieldReport>> getNearby({
    required GeoCoordinate location,
    required DateTime from,
    required DateTime to,
    int radiusMeters = 100,
    CancelToken? cancelToken,
  }) async {
    if (!to.isAfter(from) || to.difference(from).inDays > 366) {
      throw ArgumentError('Invalid nearby time range');
    }
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.fieldReportsNearby,
      queryParameters: {
        'longitude': location.longitude,
        'latitude': location.latitude,
        'radiusMeters': radiusMeters,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
      cancelToken: cancelToken,
    );
    final raw = _body(response)['data'];
    if (raw is! List) throw const FormatException('data is not a list');
    return raw
        .map((item) => FieldReport.fromJson(_map(item, 'data[]')))
        .toList(growable: false);
  }

  Future<FieldReportPage> getMine({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.fieldReportsMine,
      queryParameters: {'page': page, 'limit': limit, 'status': ?status},
      cancelToken: cancelToken,
    );
    return FieldReportPage.fromEnvelope(_body(response));
  }

  Future<FieldReport> getDetail(String id, {CancelToken? cancelToken}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.fieldReportDetail(id),
      cancelToken: cancelToken,
    );
    return FieldReport.fromJson(_map(_body(response)['data'], 'data'));
  }

  Future<FieldReport> create({
    required String description,
    required GeoCoordinate location,
    GeoJsonGeometry? measuredGeometry,
    List<String> photoIds = const [],
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.fieldReports,
      data: {
        'description': description.trim(),
        'longitude': location.longitude,
        'latitude': location.latitude,
        'measuredGeometry': ?measuredGeometry?.toJson(),
        'photoIds': photoIds.map(int.parse).toList(growable: false),
      },
    );
    return FieldReport.fromJson(_map(_body(response)['data'], 'data'));
  }

  Future<void> delete(String id, DateTime expectedUpdatedAt) async {
    await _dio.delete<void>(
      ApiEndpoints.fieldReportDetail(id),
      queryParameters: {
        'expectedUpdatedAt': expectedUpdatedAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<UploadGrant> presign({
    required String originalName,
    required String contentType,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.storageUploadPresign,
      data: {
        'category': 'field-photos',
        'originalName': originalName,
        'contentType': contentType,
        'expireSeconds': 900,
      },
    );
    return UploadGrant.fromJson(_map(_body(response)['data'], 'data'));
  }

  Future<void> uploadFile({
    required UploadGrant grant,
    required File file,
    required String contentType,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final storageDio = Dio()..interceptors.add(AppLoggingInterceptor());
    await storageDio.putUri<void>(
      grant.uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: await file.length(),
        },
        contentType: contentType,
      ),
      onSendProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<ReadyUpload> commit(String id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.storageUploadCommit(id),
    );
    return ReadyUpload.fromJson(_map(_body(response)['data'], 'data'));
  }

  Future<void> deleteUpload(String id) =>
      _dio.delete<void>(ApiEndpoints.storageObject(id));

  Future<void> registerDevice(String token, String platform) => _dio.put<void>(
    ApiEndpoints.deviceToken,
    data: {'token': token, 'platform': platform},
  );

  Future<void> unregisterDevice(String token) =>
      _dio.delete<void>(ApiEndpoints.deviceToken, data: {'token': token});
}

Map<String, dynamic> _body(Response<Map<String, dynamic>> response) {
  final data = response.data;
  if (data == null) throw const FormatException('Missing response body');
  return data;
}

Map<String, dynamic> _map(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('$field is not an object');
}
