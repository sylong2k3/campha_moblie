import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/feature_detail_model.dart';
import '../domain/flood_scenario_model.dart';
import '../domain/layer_model.dart';

final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => MapRepository(dio: ref.watch(dioProvider)),
);

class MapRepository {
  MapRepository({required this.dio});

  final Dio dio;
  final Map<String, MapTileTicket> _tileTicketCache = {};

  String get apiHost => Uri.parse(ApiConfig.baseUrl).host;

  String tileUrlTemplate(String layerId) =>
      '${ApiConfig.baseUrl}${ApiEndpoints.mobileTileTemplate(layerId)}';

  String rasterTileUrlTemplate(String geoserverLayer, {String? ticket}) {
    final baseUrl = ApiConfig.geoserverUrl.endsWith('/')
        ? '${ApiConfig.geoserverUrl}wms'
        : '${ApiConfig.geoserverUrl}/wms';
    final endpoint = Uri.parse(baseUrl).replace(
      queryParameters: {
        'service': 'WMS',
        'version': '1.1.1',
        'request': 'GetMap',
        'layers': geoserverLayer,
        'bbox': '{bbox-epsg-3857}',
        'width': '256',
        'height': '256',
        'srs': 'EPSG:3857',
        'format': 'image/png',
        'transparent': 'true',
        if (ticket != null && ticket.isNotEmpty) 'ticket': ticket,
      },
    );
    return endpoint.toString().replaceAll('%7B', '{').replaceAll('%7D', '}');
  }

  /// Vé xem tile (`access=view`) cho layer raster không `isPublic`, dùng
  /// nhúng vào [rasterTileUrlTemplate] thay cho header Authorization mà
  /// `RasterSource` của Mapbox không gắn được vào từng tile request. Cache
  /// theo layer và tự làm mới khi vé sắp hết hạn (~15 phút TTL server-side).
  Future<String> validRasterTileTicket(String layerId) async {
    const access = 'view';
    final cacheKey = '$layerId|$access';
    final cached = _tileTicketCache[cacheKey];
    if (cached != null && !cached.isExpiringSoon) return cached.ticket;
    final ticket = await _item(
      () => dio.get(
        ApiEndpoints.mapLayerTileTicket(layerId),
        queryParameters: {'access': access},
      ),
      MapTileTicket.fromJson,
    );
    _tileTicketCache[cacheKey] = ticket;
    return ticket.ticket;
  }

  Future<List<LayerModel>> getLayers({String? category}) => _list(
    () => dio.get(
      ApiEndpoints.webMapLayers,
      queryParameters: {
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
      },
    ),
    LayerModel.fromJson,
  );

  Future<List<FloodScenarioModel>> getFloodScenarios({
    bool activeOnly = false,
    int limit = 100,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.floodScenarios,
        queryParameters: {'activeOnly': activeOnly, 'limit': limit},
      );
      final body = response.data;
      final Map<String, dynamic> env = body is Map<String, dynamic>
          ? body
          : Map<String, dynamic>.from(body as Map);
      final dataObj = env['data'];
      List items = [];
      if (dataObj is Map && dataObj['items'] is List) {
        items = dataObj['items'] as List;
      } else if (dataObj is List) {
        items = dataObj;
      }
      return items
          .map(
            (e) => FloodScenarioModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw mapErrorToAppException(error);
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<LayerLegend> getLegend(String layerId) => _item(
    () => dio.get(ApiEndpoints.webMapLayerLegend(layerId)),
    LayerLegend.fromJson,
  );

  Future<List<BasemapModel>> getBasemaps() =>
      _list(() => dio.get(ApiEndpoints.webMapBasemaps), BasemapModel.fromJson);

  Future<List<MapSearchResult>> searchFeatures({
    required String query,
    String? layerId,
    String? bbox,
    int limit = 20,
    CancelToken? cancelToken,
  }) => _list(
    () => dio.get(
      ApiEndpoints.webMapFeatureSearch,
      queryParameters: {
        'q': query.trim(),
        'layerId': ?layerId,
        'bbox': ?bbox,
        'limit': limit,
      },
      cancelToken: cancelToken,
    ),
    MapSearchResult.fromJson,
  );

  Future<FeatureDetailModel> getFeatureDetail(
    String layerId,
    String featureId,
  ) => _item(
    () => dio.get(ApiEndpoints.mobileFeatureDetail(layerId, featureId)),
    FeatureDetailModel.fromJson,
  );

  /// WMS GetFeatureInfo — lấy thuộc tính điểm GeoServer raster/vector.
  /// Tạo bbox nhỏ quanh [lng]/[lat] (±[bufferDeg]°), gọi GetFeatureInfo
  /// với tâm là pixel (50,50) của ảnh 101×101. `BUFFER` mở rộng vùng dò
  /// theo pixel — bắt buộc với layer point vì GeoServer mặc định yêu cầu
  /// trúng chính xác pixel tâm feature (bán kính 0), khiến click hụt vài
  /// pixel sẽ không trả về gì dù tap đúng vào điểm trên màn hình.
  /// Trả về map properties hoặc null nếu không có feature tại vị trí đó.
  Future<Map<String, dynamic>?> getGeoServerFeatureInfo({
    required String geoserverLayer,
    required double lng,
    required double lat,
    String? ticket,
    double bufferDeg = 0.0008,
  }) async {
    final baseUrl = ApiConfig.geoserverUrl.endsWith('/')
        ? '${ApiConfig.geoserverUrl}wms'
        : '${ApiConfig.geoserverUrl}/wms';
    final minX = lng - bufferDeg;
    final minY = lat - bufferDeg;
    final maxX = lng + bufferDeg;
    final maxY = lat + bufferDeg;
    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'service': 'WMS',
        'version': '1.1.1',
        'request': 'GetFeatureInfo',
        'layers': geoserverLayer,
        'query_layers': geoserverLayer,
        'bbox': '$minX,$minY,$maxX,$maxY',
        'width': '101',
        'height': '101',
        'srs': 'EPSG:4326',
        'x': '50',
        'y': '50',
        // Bán kính dò theo pixel quanh (x,y) — GeoServer-specific, cần thiết
        // cho point/multipoint vì mặc định tolerance = 0.
        'buffer': '32',
        'info_format': 'application/json',
        'exceptions': 'application/json',
        'feature_count': '5',
        if (ticket != null && ticket.isNotEmpty) 'ticket': ticket,
      },
    );
    try {
      final response = await dio.getUri<dynamic>(uri);
      final body = response.data;
      final Map<String, dynamic> geojson = body is String
          ? Map<String, dynamic>.from(json.decode(body) as Map)
          : Map<String, dynamic>.from(body as Map);
      final features = geojson['features'];
      if (features is! List || features.isEmpty) return null;
      final props = (features.first as Map)['properties'];
      if (props is! Map || props.isEmpty) return null;
      return Map<String, dynamic>.from(props);
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<T>> _list<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request();
      return responseDataList(
        response.data,
      ).map(fromJson).toList(growable: false);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw mapErrorToAppException(error);
    } on FormatException {
      throw const UnknownException('Phản hồi máy chủ không đúng định dạng');
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<T> _item<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request();
      return fromJson(responseDataMap(response.data));
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
