import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/session_controller.dart';
import '../../routing/presentation/route_sheet.dart';
import '../../shared/presentation/app_feedback.dart';
import '../../tools/domain/field_tools_controller.dart';
import '../../tools/domain/field_tools_models.dart';
import '../../tools/presentation/location_weather_sheet.dart';
import '../../tools/presentation/map_tool_panel_shell.dart';
import '../../tools/presentation/measure_sheet.dart';
import '../data/map_repository.dart';
import '../domain/layer_model.dart';
import '../domain/map_controller.dart';
import 'basemap_selection_sheet.dart';
import 'flood_scenario_sheet.dart';
import 'layer_catalog_sheet.dart';
import 'legend_card_widget.dart';

class MapHomeScreen extends ConsumerStatefulWidget {
  const MapHomeScreen({super.key});

  @override
  ConsumerState<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends ConsumerState<MapHomeScreen>
    with AutomaticKeepAliveClientMixin {
  static const _basemapSourceId = 'catalog-basemap-source';
  static const _basemapLayerId = 'catalog-basemap-layer';
  static const _fieldSourceId = 'field-tools-source';
  static const _fieldLineCasingLayerId = 'field-tools-line-casing';
  static const _fieldLineLayerId = 'field-tools-line';
  static const _fieldFillLayerId = 'field-tools-fill';
  static const _fieldPointLayerId = 'field-tools-points';
  static const _fieldLabelLayerId = 'field-tools-label';
  static const _fieldTapInteractionId = 'field-tools-map-tap';
  static const _rasterBounds = [106.78441, 20.06150, 107.85559, 22.07171];

  static String _vectorSourceId(String layerId) => 'mvt-$layerId';
  static String _vectorStyleLayerId(String layerId) => 'mvt-style-$layerId';
  static String _rasterSourceId(String layerId) => 'raster-$layerId';
  static String _rasterStyleLayerId(String layerId) => 'raster-style-$layerId';

  MapboxMap? _map;
  bool _styleReady = false;
  bool _mapAuthReady = false;
  bool _loaded = false;
  bool _fieldOverlaySyncing = false;
  FieldToolsState? _pendingFieldOverlay;
  String? _error;
  String? _selectedFeatureLabel;
  String? _currentStyleUri;
  bool _isSyncingCatalog = false;
  bool _needsSyncCatalog = false;
  FieldToolMode _activeToolPanel = FieldToolMode.idle;
  bool _showLegendCard = true;
  static final _camPhaCameraBounds = CameraBoundsOptions(
    bounds: CoordinateBounds(
      southwest: Point(coordinates: Position(106.78441, 20.06150)),
      northeast: Point(coordinates: Position(107.85559, 22.07171)),
      infiniteBounds: false,
    ),
    minZoom: 6.5,
    maxZoom: 20.0,
  );

  final ViewportState _initialViewport = CameraViewportState(
    center: Point(coordinates: Position(107.32, 21.07)),
    zoom: 9.6,
  );
  final Set<String> _renderedLayerIds = {};
  late final TokenStorage _tokenStorage;
  late final String _apiHost;
  StreamSubscription<geo.Position>? _routePositionSubscription;
  Timer? _rasterTicketRefreshTimer;

  /// Vé tile-ticket cho layer raster private hết hạn sau ~15 phút
  /// (`MAP_TILE_TICKET_TTL` server-side); làm mới sớm hơn nhiều để tile
  /// đang hiển thị không rơi vào khoảng bị 401 giữa hai lần refresh.
  static const _rasterTicketRefreshInterval = Duration(minutes: 5);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tokenStorage = ref.read(tokenStorageProvider);
    _apiHost = ref.read(mapRepositoryProvider).apiHost;
    _tokenStorage.addTokenChangeListener(_applyMapAuth);
    ref.listenManual<SessionState>(sessionControllerProvider, (previous, next) {
      final previousId = previous?.user?.id;
      final nextId = next.user?.id;
      if (previousId != nextId || previous?.status != next.status) {
        ref.read(mapCatalogProvider.notifier).resetForIdentityChange();
      }
    });
    ref.listenManual<FieldToolsState>(fieldToolsProvider, (previous, next) {
      if (previous?.route != next.route) {
        if (next.route == null) {
          unawaited(_stopRoutePositionTracking());
        } else {
          unawaited(_startRoutePositionTracking());
        }
      }
    });
    _rasterTicketRefreshTimer = Timer.periodic(
      _rasterTicketRefreshInterval,
      (_) => unawaited(_refreshPrivateRasterLayers()),
    );
  }

  @override
  void dispose() {
    _rasterTicketRefreshTimer?.cancel();
    unawaited(_stopRoutePositionTracking());
    _tokenStorage.removeTokenChangeListener(_applyMapAuth);
    _map?.removeInteraction(_fieldTapInteractionId);
    _map?.httpService.setCustomHeadersForHost(_apiHost, {});
    super.dispose();
  }

  /// Re-add source/layer cho các raster layer private đang hiển thị với vé
  /// tile-ticket mới, để tránh tile bắt đầu 401 khi vé cũ hết hạn.
  Future<void> _refreshPrivateRasterLayers() async {
    final map = _map;
    if (map == null || !_styleReady || !_mapAuthReady) return;
    final catalog = ref.read(mapCatalogProvider);
    for (final layer in catalog.layers) {
      if (!layer.isRaster || layer.isPublic) continue;
      if (!_renderedLayerIds.contains(layer.id)) continue;
      await _removeLayer(map, layer.id);
      if (!mounted || !identical(_map, map)) return;
      await _addLayer(map, layer, catalog.opacityOf(layer.id));
    }
  }

  Future<void> _startRoutePositionTracking() async {
    await _stopRoutePositionTracking();
    if (!await geo.Geolocator.isLocationServiceEnabled()) return;
    final permission = await geo.Geolocator.checkPermission();
    if (permission != geo.LocationPermission.always &&
        permission != geo.LocationPermission.whileInUse) {
      return;
    }
    _routePositionSubscription =
        geo.Geolocator.getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((position) {
          if (!mounted ||
              position.isMocked ||
              !position.accuracy.isFinite ||
              position.accuracy > 50) {
            return;
          }
          final controller = ref.read(fieldToolsProvider.notifier);
          controller.updateRoutePosition(
            position: GeoCoordinate(position.longitude, position.latitude),
            accuracyMeters: position.accuracy,
            timestamp: position.timestamp,
          );
          final state = ref.read(fieldToolsProvider);
          final route = state.route;
          if (route != null &&
              route.steps.isNotEmpty &&
              state.activeRouteStepIndex == route.steps.length - 1) {
            unawaited(_stopRoutePositionTracking());
          }
        });
  }

  Future<void> _stopRoutePositionTracking() async {
    final subscription = _routePositionSubscription;
    _routePositionSubscription = null;
    await subscription?.cancel();
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    _mapAuthReady = false;
    _currentStyleUri = ApiConfig.mapboxStyleStreet.isEmpty
        ? MapboxStyles.STANDARD
        : ApiConfig.mapboxStyleStreet;
    await map.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(107.32, 21.07)),
        zoom: 9.6,
      ),
    );
    await map.setBounds(_camPhaCameraBounds);
    await _applyMapAuth();
    await map.compass.updateSettings(CompassSettings(enabled: false));
    await map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
  }

  Future<void> _applyMapAuth() async {
    final map = _map;
    if (map == null) return;
    _mapAuthReady = false;
    final token = await _tokenStorage.readAccessToken();
    if (!mounted || !identical(_map, map)) return;
    await map.httpService.setCustomHeadersForHost(
      _apiHost,
      token == null || token.isEmpty ? {} : {'Authorization': 'Bearer $token'},
    );
    if (mounted && identical(_map, map)) _mapAuthReady = true;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    _styleReady = true;
    _renderedLayerIds.clear();
    if (mounted) {
      setState(() => _error = null);
    }
    await _map?.setBounds(_camPhaCameraBounds);
    await _applyMapLanguage();
    await _applyMapAuth();
    if (!_mapAuthReady) return;
    final catalog = ref.read(mapCatalogProvider);
    await _applyBasemap(catalog.selectedBasemap);
    _installFieldTapInteraction();
    await _syncMap(catalog);
    await _syncFieldOverlay(ref.read(fieldToolsProvider));
  }

  /// Đặt nhãn bản đồ nền Mapbox (tên đường, địa danh...) hiển thị tiếng Việt.
  Future<void> _applyMapLanguage() async {
    try {
      await _map?.style.localizeLabels('vi', null);
    } catch (_) {
      // Style hiện tại (ví dụ raster-only) có thể không hỗ trợ localize.
    }
  }

  Future<void> _applyBasemap(BasemapModel? basemap) async {
    final map = _map;
    if (map == null || !_styleReady || basemap == null) return;
    try {
      await map.style.removeStyleLayer(_basemapLayerId);
      await map.style.removeStyleSource(_basemapSourceId);
    } catch (_) {
      // Style reload or initial state has no raster basemap yet.
    }
    if (basemap.isMapboxStyle) {
      if (_currentStyleUri != basemap.urlTemplate) {
        _currentStyleUri = basemap.urlTemplate;
        await map.loadStyleURI(basemap.urlTemplate);
        await _applyMapLanguage();
      }
      return;
    }
    _currentStyleUri = null;
    await map.style.addSource(
      RasterSource(
        id: _basemapSourceId,
        tiles: [basemap.urlTemplate],
        tileSize: 256,
        scheme: Scheme.XYZ,
        minzoom: basemap.minZoom ?? 0,
        maxzoom: basemap.maxZoom ?? 22,
        bounds: const [-180, -85, 180, 85],
        attribution: basemap.attribution,
      ),
    );
    await map.style.addLayer(
      RasterLayer(id: _basemapLayerId, sourceId: _basemapSourceId),
    );
  }

  Future<void> _syncCatalog(
    MapCatalogState? previous,
    MapCatalogState next,
  ) async {
    if (_isSyncingCatalog) {
      _needsSyncCatalog = true;
      return;
    }
    _isSyncingCatalog = true;
    try {
      final map = _map;
      if (map == null || !_styleReady || !_mapAuthReady) return;
      final basemapChanged =
          previous?.selectedBasemapCode != next.selectedBasemapCode;
      if (basemapChanged) {
        if (mounted) {
          setState(() => _error = null);
        }
        for (final layerId in _renderedLayerIds.toList(growable: false)) {
          await _removeLayer(map, layerId);
        }
        final basemap = next.selectedBasemap;
        final reloadsStyle =
            basemap?.isMapboxStyle == true &&
            _currentStyleUri != basemap!.urlTemplate;
        await _applyBasemap(basemap);
        if (reloadsStyle) return;
      }
      await _syncMap(next);
    } finally {
      _isSyncingCatalog = false;
      if (_needsSyncCatalog) {
        _needsSyncCatalog = false;
        if (mounted) {
          _syncCatalog(previous, ref.read(mapCatalogProvider));
        }
      }
    }
  }

  Future<void> _syncMap(MapCatalogState state) async {
    final map = _map;
    if (map == null || !_styleReady || !_mapAuthReady) return;
    var removedAny = false;
    for (final layer in state.layers) {
      final shouldRender = state.activeLayerIds.contains(layer.id);
      final styleLayerId = layer.isRaster
          ? _rasterStyleLayerId(layer.id)
          : _vectorStyleLayerId(layer.id);
      final rendered = await map.style.styleLayerExists(styleLayerId);
      if (rendered) {
        _renderedLayerIds.add(layer.id);
      } else {
        _renderedLayerIds.remove(layer.id);
      }
      if (shouldRender && !rendered) {
        await _addLayer(map, layer, state.opacityOf(layer.id));
        if (!layer.isRaster) {
          await Future.delayed(const Duration(milliseconds: 250));
        }
      } else if (!shouldRender && rendered) {
        await _removeLayer(map, layer.id);
        removedAny = true;
      } else if (shouldRender) {
        await _setOpacity(map, layer, state.opacityOf(layer.id));
      }
    }
    if (removedAny) {
      await _forceRedraw(map);
    }
  }

  /// `removeStyleLayer`/`removeStyleSource` cập nhật style ngay lập tức,
  /// nhưng khi bản đồ đang idle (không gesture), Mapbox GL Native đôi khi
  /// không tự vẽ lại frame mới -> layer vừa tắt vẫn còn hiện trên khung hình
  /// cũ cho đến khi người dùng pan/zoom. `triggerRepaint()` chỉ đánh dấu
  /// frame cần vẽ lại nhưng không đủ tin cậy để ép native tính lại render
  /// tree; mô phỏng đúng thao tác "di chuyển bản đồ" bằng một lần set lại
  /// camera ở đúng vị trí hiện tại thì buộc engine tính lại và vẽ lại ngay.
  Future<void> _forceRedraw(MapboxMap map) async {
    try {
      final cameraState = await map.getCameraState();
      await map.setCamera(
        CameraOptions(
          center: cameraState.center,
          zoom: cameraState.zoom,
          bearing: cameraState.bearing,
          pitch: cameraState.pitch,
        ),
      );
      await map.triggerRepaint();
    } catch (_) {
      // Best-effort; nếu map chưa sẵn sàng thì bỏ qua, lần sync sau sẽ thử lại.
    }
  }

  Future<void> _addLayer(
    MapboxMap map,
    LayerModel layer,
    double opacity,
  ) async {
    final renderError = context.l10n.mapLayerRenderError(layer.nameVi);
    try {
      if (layer.isRaster) {
        final geoserverLayer = layer.geoserverLayer;
        if (geoserverLayer == null || geoserverLayer.isEmpty) {
          throw const FormatException('Raster layer has no GeoServer layer');
        }
        final repository = ref.read(mapRepositoryProvider);
        final ticket = layer.isPublic
            ? null
            : await repository.validRasterTileTicket(layer.id);
        final sourceId = _rasterSourceId(layer.id);
        final styleLayerId = _rasterStyleLayerId(layer.id);
        try {
          await map.style.removeStyleLayer(styleLayerId);
          await map.style.removeStyleSource(sourceId);
        } catch (_) {}
        await map.style.addSource(
          RasterSource(
            id: sourceId,
            tiles: [
              repository.rasterTileUrlTemplate(geoserverLayer, ticket: ticket),
            ],
            tileSize: 256,
            scheme: Scheme.XYZ,
            minzoom: layer.minZoom ?? 0,
            maxzoom: layer.maxZoom ?? 22,
          ),
        );
        await map.style.addLayer(
          RasterLayer(
            id: styleLayerId,
            sourceId: sourceId,
            rasterOpacity: opacity,
          ),
        );
        await map.style.setStyleLayerProperty(
          styleLayerId,
          'raster-opacity',
          opacity,
        );
      } else {
        final sourceId = _vectorSourceId(layer.id);
        final styleLayerId = _vectorStyleLayerId(layer.id);
        final color = layer.displayColor.toARGB32();
        try {
          map.removeInteraction('identify-${layer.id}');
          await map.style.removeStyleLayer(styleLayerId);
          await map.style.removeStyleSource(sourceId);
        } catch (_) {}
        await map.style.addSource(
          VectorSource(
            id: sourceId,
            tiles: [ref.read(mapRepositoryProvider).tileUrlTemplate(layer.id)],
            bounds: _rasterBounds,
            minzoom: layer.minZoom ?? 0,
            maxzoom: layer.maxZoom ?? 22,
            volatile: true,
          ),
        );
        if (layer.isPoint) {
          await map.style.addLayer(
            CircleLayer(
              id: styleLayerId,
              sourceId: sourceId,
              sourceLayer: layer.code,
              circleColor: color,
              circleRadius: 5.5,
              circleOpacity: opacity,
              circleStrokeColor: Colors.white.toARGB32(),
              circleStrokeWidth: 1.5,
            ),
          );
        } else if (layer.isPolygon) {
          await map.style.addLayer(
            FillLayer(
              id: styleLayerId,
              sourceId: sourceId,
              sourceLayer: layer.code,
              fillColor: color,
              fillOpacity: opacity * 0.32,
              fillOutlineColor: color,
            ),
          );
        } else {
          await map.style.addLayer(
            LineLayer(
              id: styleLayerId,
              sourceId: sourceId,
              sourceLayer: layer.code,
              lineColor: color,
              lineWidth: 3,
              lineOpacity: opacity,
              lineCap: LineCap.ROUND,
              lineJoin: LineJoin.ROUND,
            ),
          );
        }
        map.addInteraction(
          TapInteraction(FeaturesetDescriptor(layerId: styleLayerId), (
            feature,
            context2,
          ) async {
            if (ref.read(fieldToolsProvider).mode != FieldToolMode.idle) return;
            final props = Map<String, dynamic>.from(feature.properties);
            final geoserverLayer = layer.geoserverLayer;
            final coord = GeoCoordinate(
              context2.point.coordinates.lng.toDouble(),
              context2.point.coordinates.lat.toDouble(),
            );
            // 1. Nếu vector feature chứa các thuộc tính từ MVT/GeoServer -> hiển thị modal trực tiếp
            if (props.isNotEmpty &&
                props.keys.any(
                  (k) => k != 'feature_id' && k != 'id' && k != 'layer',
                )) {
              _showRasterFeatureModal(layer.nameVi, props);
              return;
            }
            // 2. Thử WMS GetFeatureInfo nếu có geoserverLayer
            if (geoserverLayer != null && geoserverLayer.isNotEmpty) {
              final found = await _showGeoServerFeatureInfoFor(
                layer,
                geoserverLayer,
                coord,
              );
              if (found) return;
            }
            // 3. Nếu feature.properties có dữ liệu -> hiển thị modal
            if (props.isNotEmpty) {
              _showRasterFeatureModal(layer.nameVi, props);
              return;
            }
            // 4. Chỉ push route detail nếu layer được cấu hình chỉnh sửa (canEdit)
            final featureId =
                feature.properties['feature_id'] ?? feature.id?.id;
            if (layer.canEdit && featureId != null && mounted) {
              context.push('/map/feature/${layer.id}/$featureId');
            }
          }),
          interactionID: 'identify-${layer.id}',
        );
      }
      _renderedLayerIds.add(layer.id);
      if (mounted) {
        setState(() => _error = null);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = renderError);
      }
    }
  }

  Future<void> _removeLayer(MapboxMap map, String layerId) async {
    map.removeInteraction('identify-$layerId');
    for (final (styleLayerId, sourceId) in [
      (_vectorStyleLayerId(layerId), _vectorSourceId(layerId)),
      (_rasterStyleLayerId(layerId), _rasterSourceId(layerId)),
    ]) {
      try {
        await map.style.removeStyleLayer(styleLayerId);
        await map.style.removeStyleSource(sourceId);
      } catch (_) {
        // Style reload can remove resources first; desired state is already absent.
      }
    }
    _renderedLayerIds.remove(layerId);
  }

  Future<void> _setOpacity(
    MapboxMap map,
    LayerModel layer,
    double value,
  ) async {
    final id = layer.isRaster
        ? _rasterStyleLayerId(layer.id)
        : _vectorStyleLayerId(layer.id);
    try {
      if (layer.isRaster) {
        await map.style.setStyleLayerProperty(id, 'raster-opacity', value);
      } else if (layer.isPoint) {
        await map.style.setStyleLayerProperty(id, 'circle-opacity', value);
      } else if (layer.isPolygon) {
        await map.style.setStyleLayerProperty(id, 'fill-opacity', value * 0.32);
      } else {
        await map.style.setStyleLayerProperty(id, 'line-opacity', value);
      }
    } catch (_) {
      // Layer may be between style reload frames; next catalog update re-adds it.
    }
  }

  void _installFieldTapInteraction() {
    final map = _map;
    if (map == null) return;
    map.removeInteraction(_fieldTapInteractionId);
    map.addInteraction(
      TapInteraction.onMap((gesture) async {
        final state = ref.read(fieldToolsProvider);
        if (state.mode != FieldToolMode.idle) {
          ref
              .read(fieldToolsProvider.notifier)
              .addMapPoint(
                GeoCoordinate(
                  gesture.point.coordinates.lng.toDouble(),
                  gesture.point.coordinates.lat.toDouble(),
                ),
              );
          return;
        }

        final catalog = ref.read(mapCatalogProvider);
        if (catalog.activeLayerIds.isEmpty) return;

        final clickCoord = GeoCoordinate(
          gesture.point.coordinates.lng.toDouble(),
          gesture.point.coordinates.lat.toDouble(),
        );

        // Raster layers → WMS GetFeatureInfo → modal.
        for (final layerId in catalog.activeLayerIds) {
          final layer = catalog.layers
              .where((l) => l.id == layerId)
              .firstOrNull;
          if (layer == null || !layer.isRaster) continue;
          final geoserverLayer = layer.geoserverLayer;
          if (geoserverLayer == null || geoserverLayer.isEmpty) continue;
          final found = await _showGeoServerFeatureInfoFor(
            layer,
            geoserverLayer,
            clickCoord,
          );
          if (found) return;
        }
      }, stopPropagation: false),
      interactionID: _fieldTapInteractionId,
    );
  }

  /// Gọi WMS GetFeatureInfo cho layer nguồn GeoServer (raster hoặc vector
  /// point/multipoint được render bằng vector tile nhưng dữ liệu gốc đến
  /// từ GeoServer, không có rows trong DB nội bộ). Hiển thị modal nếu tìm
  /// thấy feature. Trả về true nếu đã hiển thị modal.
  Future<bool> _showGeoServerFeatureInfoFor(
    LayerModel layer,
    String geoserverLayer,
    GeoCoordinate coord,
  ) async {
    final mapRepo = ref.read(mapRepositoryProvider);
    try {
      String? ticket;
      if (!layer.isPublic) {
        ticket = await mapRepo.validRasterTileTicket(layer.id);
      }
      final props = await mapRepo.getGeoServerFeatureInfo(
        geoserverLayer: geoserverLayer,
        lng: coord.longitude,
        lat: coord.latitude,
        ticket: ticket,
      );
      if (props != null && mounted) {
        _showRasterFeatureModal(layer.nameVi, props);
        return true;
      }
    } catch (_) {
      // GeoServer unreachable hoặc không có feature tại vị trí này.
    }
    return false;
  }

  void _showRasterFeatureModal(String layerName, Map<String, dynamic> props) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final entries = props.entries
            .where((e) => e.value != null && e.value.toString().isNotEmpty)
            .toList();
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    layerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: entries.length,
                    separatorBuilder: (context, idx) =>
                        const Divider(height: 1, indent: 16),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                e.key,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                e.value.toString(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _syncFieldOverlay(FieldToolsState state) async {
    final map = _map;
    if (map == null || !_styleReady) return;
    if (state.mode == FieldToolMode.idle) {
      for (final id in const [
        _fieldLabelLayerId,
        _fieldPointLayerId,
        _fieldLineLayerId,
        _fieldLineCasingLayerId,
        _fieldFillLayerId,
      ]) {
        try {
          await map.style.removeStyleLayer(id);
        } catch (_) {}
      }
      try {
        await map.style.removeStyleSource(_fieldSourceId);
      } catch (_) {}
      return;
    }

    Map<String, dynamic>? geometry;
    final points = <GeoCoordinate>[
      ...state.vertices,
      if (state.routeStart != null) state.routeStart!,
      if (state.routeEnd != null) state.routeEnd!,
    ];
    if (state.route != null) {
      geometry = state.route!.geometry.toJson();
    } else if (state.mode == FieldToolMode.measureArea &&
        state.vertices.length >= 3) {
      geometry = GeoJsonGeometry.polygon(state.vertices).toJson();
    } else if (state.vertices.length >= 2) {
      geometry = GeoJsonGeometry.line(state.vertices).toJson();
    } else if (state.routeStart != null && state.routeEnd != null) {
      geometry = GeoJsonGeometry.line([
        state.routeStart!,
        state.routeEnd!,
      ]).toJson();
    }
    final labelPoint = state.measurement == null || state.vertices.isEmpty
        ? null
        : state.mode == FieldToolMode.measureArea
        ? _measurementAreaLabelPoint(state.vertices)
        : state.vertices.last;
    final features = <Map<String, dynamic>>[
      if (geometry != null)
        {'type': 'Feature', 'properties': const {}, 'geometry': geometry},
      ...points.map(
        (point) => {
          'type': 'Feature',
          'properties': const {},
          'geometry': GeoJsonGeometry.point(point).toJson(),
        },
      ),
      if (labelPoint != null)
        {
          'type': 'Feature',
          'properties': {
            'kind': 'measurement-label',
            'label': state.measurement!.formattedMetricValue,
          },
          'geometry': GeoJsonGeometry.point(labelPoint).toJson(),
        },
    ];
    final geoJsonData = jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });

    final sourceExists = await map.style.styleSourceExists(_fieldSourceId);
    if (sourceExists) {
      await map.style.setStyleSourceProperty(
        _fieldSourceId,
        'data',
        geoJsonData,
      );
      return;
    }

    if (features.isEmpty) return;
    await map.style.addSource(
      GeoJsonSource(id: _fieldSourceId, data: geoJsonData),
    );
    const clay = Color(0xFFC66F3D);
    const clayDark = Color(0xFF5A2A17);
    await map.style.addLayer(
      FillLayer(
        id: _fieldFillLayerId,
        sourceId: _fieldSourceId,
        filter: [
          '==',
          ['geometry-type'],
          'Polygon',
        ],
        fillColor: clay.toARGB32(),
        fillOpacity: 0.22,
        fillOutlineColor: clay.toARGB32(),
      ),
    );
    await map.style.addLayer(
      LineLayer(
        id: _fieldLineCasingLayerId,
        sourceId: _fieldSourceId,
        filter: [
          '==',
          ['geometry-type'],
          'LineString',
        ],
        lineColor: clayDark.toARGB32(),
        lineWidth: 8,
        lineOpacity: 0.72,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ),
    );
    await map.style.addLayer(
      LineLayer(
        id: _fieldLineLayerId,
        sourceId: _fieldSourceId,
        filter: [
          '==',
          ['geometry-type'],
          'LineString',
        ],
        lineColor: clay.toARGB32(),
        lineWidth: 5,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ),
    );
    await map.style.addLayer(
      CircleLayer(
        id: _fieldPointLayerId,
        sourceId: _fieldSourceId,
        filter: [
          'all',
          [
            '==',
            ['geometry-type'],
            'Point',
          ],
          [
            '!=',
            ['get', 'kind'],
            'measurement-label',
          ],
        ],
        circleColor: clay.toARGB32(),
        circleRadius: 7,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 2.5,
      ),
    );
    await map.style.addLayer(
      SymbolLayer(
        id: _fieldLabelLayerId,
        sourceId: _fieldSourceId,
        filter: [
          '==',
          ['get', 'kind'],
          'measurement-label',
        ],
        textFieldExpression: ['get', 'label'],
        textSize: 15,
        textFont: const ['DIN Pro Medium', 'Arial Unicode MS Regular'],
        textAllowOverlap: true,
        textIgnorePlacement: true,
        textPadding: 8,
        textOffset: const [0, -1.45],
        textColor: clayDark.toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 3,
        textHaloBlur: 0.5,
      ),
    );
  }

  Future<void> _openCatalog() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const LayerCatalogSheet(),
    );
  }

  Future<void> _openFloodScenarios() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FloodScenarioSheet(),
    );
  }

  Future<void> _openBasemapSelector() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => const BasemapSelectionSheet(),
    );
  }

  Future<void> _openSearch() async {
    final result = await context.push<MapSearchResult>('/map/search');
    if (result == null || !mounted) return;
    setState(() => _selectedFeatureLabel = result.label);
    await _map?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(result.longitude, result.latitude)),
        zoom: 16,
      ),
      MapAnimationOptions(duration: AppMotion.camera(context, far: true)),
    );
    if (!mounted) return;
    context.push('/map/feature/${result.layerId}/${result.featureId}');
  }

  Future<void> _openLocationWeather() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const LocationWeatherSheet(),
    );
  }

  void _openMeasure() {
    ref.read(fieldToolsProvider.notifier).startMeasure(area: false);
    setState(() => _activeToolPanel = FieldToolMode.measureDistance);
  }

  void _openRoute() {
    ref.read(fieldToolsProvider.notifier).startRoute();
    setState(() => _activeToolPanel = FieldToolMode.route);
  }

  void _closeToolPanel() {
    if (mounted) setState(() => _activeToolPanel = FieldToolMode.idle);
  }

  void _openTools() {
    final sheetItems = <_ToolItem>[
      _ToolItem(
        Icons.water_drop_outlined,
        'Kịch bản ngập úng',
        _openFloodScenarios,
      ),
      _ToolItem(
        Icons.location_searching_rounded,
        context.l10n.locationWeatherTitle,
        _openLocationWeather,
      ),
      _ToolItem(
        Icons.straighten_rounded,
        context.l10n.measureTitle,
        _openMeasure,
      ),
      _ToolItem(Icons.route_outlined, context.l10n.routeTitle, _openRoute),
      if (ref.read(sessionControllerProvider).user case final user?
          when user.roleCode == 'so_tnmt' &&
              user.hasPermission('map_feature', 'update'))
        _ToolItem(
          Icons.sync_problem_outlined,
          context.l10n.featureSyncTitle,
          () => context.push('/map/offline-changes'),
        ),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.fieldToolsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.fieldToolsSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 56,
                ),
                itemCount: sheetItems.length,
                itemBuilder: (context, index) {
                  final item = sheetItems[index];
                  return _ToolTile(
                    icon: item.icon,
                    title: item.title,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      item.onTap();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _recenter() =>
      _map?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(107.32, 21.07)),
          zoom: 9.6,
        ),
        MapAnimationOptions(duration: AppMotion.camera(context, far: true)),
      ) ??
      Future.value();

  void _queueFieldOverlay(FieldToolsState state) {
    _pendingFieldOverlay = state;
    if (_fieldOverlaySyncing) return;
    _fieldOverlaySyncing = true;
    unawaited(_drainFieldOverlay());
  }

  Future<void> _drainFieldOverlay() async {
    try {
      while (mounted && _pendingFieldOverlay != null) {
        final state = _pendingFieldOverlay!;
        _pendingFieldOverlay = null;
        await _syncFieldOverlay(state);
      }
    } finally {
      _fieldOverlaySyncing = false;
      if (mounted && _pendingFieldOverlay != null) {
        _queueFieldOverlay(_pendingFieldOverlay!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tokenMissing = ApiConfig.mapboxToken.isEmpty;
    if (tokenMissing) {
      return _MapConfigState(message: context.l10n.mapConfigMissing);
    }
    final catalog = ref.watch(mapCatalogProvider);
    final toolActive = _activeToolPanel != FieldToolMode.idle;
    ref.listen<MapCatalogState>(mapCatalogProvider, (previous, next) {
      unawaited(_syncCatalog(previous, next));
    });
    ref.listen<FieldToolsState>(fieldToolsProvider, (_, next) {
      _queueFieldOverlay(next);
    });

    final activeLayers = catalog.layers
        .where((l) => catalog.activeLayerIds.contains(l.id))
        .toList();
    final activeFloodLayer = activeLayers
        .where(isFloodLandCoverLayer)
        .firstOrNull;
    final hasFloodLandCover = activeFloodLayer != null;
    final floodLegendItems = activeFloodLayer == null
        ? const <LegendColorItem>[]
        : ref
              .watch(mapLegendProvider(activeFloodLayer.id))
              .maybeWhen(
                data: (data) => getLegendItems(data, activeFloodLayer),
                orElse: () => const <LegendColorItem>[],
              );

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('production-mapbox'),
            styleUri: ApiConfig.mapboxStyleStreet.isEmpty
                ? MapboxStyles.STANDARD
                : ApiConfig.mapboxStyleStreet,
            viewport: _initialViewport,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onMapLoadedListener: (_) {
              if (mounted) {
                setState(() {
                  _loaded = true;
                  _error = null;
                });
              }
              unawaited(_syncMap(ref.read(mapCatalogProvider)));
            },
            onMapLoadErrorListener: (event) {
              final message = event.message.toLowerCase();
              if (message.contains('cancel') || message.contains('supersed')) {
                return;
              }
              if (mounted) setState(() => _error = event.message);
            },
          ),
          if (!toolActive)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                child: Column(
                  children: [
                    Semantics(
                      button: true,
                      label: context.l10n.mapSearchHint,
                      child: Material(
                        elevation: 3,
                        shadowColor: AppColors.primaryDeep.withValues(
                          alpha: 0.16,
                        ),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.8),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const ValueKey('map-search-open'),
                          onTap: _openSearch,
                          child: SizedBox(
                            height: 54,
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.search_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedFeatureLabel ??
                                        context.l10n.mapSearchHint,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: _selectedFeatureLabel == null
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                                IconButton(
                                  tooltip: context.l10n.mapLayersCount(
                                    catalog.activeCount,
                                  ),
                                  onPressed: _openCatalog,
                                  icon: Badge.count(
                                    count: catalog.activeCount,
                                    isLabelVisible: catalog.activeCount > 0,
                                    child: const Icon(Icons.layers_outlined),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      AppInlineNotice(
                        message: context.l10n.mapTileError,
                        icon: Icons.cloud_off_outlined,
                        tone: AppFeedbackTone.error,
                        actionLabel: context.l10n.commonRetry,
                        onAction: () {
                          setState(() => _error = null);
                          _syncMap(catalog);
                        },
                        liveRegion: true,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Semantics(
                        container: true,
                        label: context.l10n.navMap,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MapControlGroup(
                              children: [
                                _MapControl(
                                  key: const ValueKey('map-basemap-open'),
                                  icon: Icons.public_outlined,
                                  tooltip: context.l10n.mapBasemapTitle,
                                  onTap: _openBasemapSelector,
                                ),
                                _MapControl(
                                  key: const ValueKey(
                                    'map-flood-scenarios-open',
                                  ),
                                  icon: Icons.water_drop_outlined,
                                  tooltip: 'Kịch bản ngập úng',
                                  onTap: _openFloodScenarios,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _MapControlGroup(
                              children: [
                                _MapControl(
                                  icon: Icons.explore_outlined,
                                  tooltip: context.l10n.mapRecenter,
                                  onTap: _recenter,
                                ),
                                _MapControl(
                                  icon: Icons.my_location_rounded,
                                  tooltip: context.l10n.mapGpsAction,
                                  onTap: _openLocationWeather,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.surface),
                      reverseDuration: AppMotion.of(context, AppMotion.state),
                      transitionBuilder: AppMotion.stateTransition,
                      child: hasFloodLandCover && _showLegendCard
                          ? Padding(
                              key: ValueKey(
                                'map-legend-${activeFloodLayer.id}',
                              ),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: LayerLegendCard(
                                title: activeFloodLayer.nameVi,
                                items: floodLegendItems,
                                onClose: () =>
                                    setState(() => _showLegendCard = false),
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('map-legend-hidden'),
                            ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasFloodLandCover) ...[
                          IconButton.filledTonal(
                            key: const ValueKey('map-legend-toggle'),
                            tooltip: 'Chú giải',
                            onPressed: () => setState(
                              () => _showLegendCard = !_showLegendCard,
                            ),
                            icon: Icon(
                              _showLegendCard
                                  ? Icons.palette_rounded
                                  : Icons.palette_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        FloatingActionButton.small(
                          key: const ValueKey('map-tools-open'),
                          heroTag: 'map-tools',
                          tooltip: context.l10n.fieldToolsTitle,
                          onPressed: _openTools,
                          child: const Icon(Icons.handyman_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: AppInlineNotice(
                    message: context.l10n.mapTileError,
                    icon: Icons.cloud_off_outlined,
                    tone: AppFeedbackTone.error,
                    actionLabel: context.l10n.commonRetry,
                    onAction: () => _syncMap(catalog),
                    liveRegion: true,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.surface),
              reverseDuration: AppMotion.of(context, AppMotion.state),
              transitionBuilder: AppMotion.stateTransition,
              child: _activeToolPanel == FieldToolMode.idle
                  ? const SizedBox.shrink(key: ValueKey('map-tool-panel-idle'))
                  : MapToolDraggableSheet(
                      key: ValueKey('map-tool-sheet-${_activeToolPanel.name}'),
                      initialChildSize: _toolSheetInitialSize(_activeToolPanel),
                      maxChildSize: _toolSheetMaxSize(_activeToolPanel),
                      child: switch (_activeToolPanel) {
                        FieldToolMode.measureDistance ||
                        FieldToolMode.measureArea => MeasureSheet(
                          onClose: _closeToolPanel,
                        ),
                        FieldToolMode.route => RouteSheet(
                          onClose: _closeToolPanel,
                        ),
                        _ => const SizedBox.shrink(),
                      },
                    ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 78,
            left: 14,
            right: 14,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.state),
                transitionBuilder: AppMotion.stateTransition,
                child: ((!_loaded || catalog.loading) && _error == null)
                    ? Semantics(
                        key: const ValueKey('map-loading-panel'),
                        liveRegion: true,
                        label: context.l10n.mapLoading,
                        child: Material(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLowest
                              .withValues(alpha: 0.96),
                          elevation: 2,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    context.l10n.mapLoading,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('map-loading-hidden'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _toolSheetInitialSize(FieldToolMode mode) => _toolSheetMaxSize(mode);

double _toolSheetMaxSize(FieldToolMode mode) => switch (mode) {
  FieldToolMode.route => 0.24,
  FieldToolMode.measureDistance || FieldToolMode.measureArea => 0.26,
  _ => MapToolDraggableSheet.minChildSize,
};

GeoCoordinate _measurementAreaLabelPoint(List<GeoCoordinate> points) {
  var twiceArea = 0.0;
  var longitudeMoment = 0.0;
  var latitudeMoment = 0.0;
  for (var index = 0; index < points.length; index++) {
    final current = points[index];
    final next = points[(index + 1) % points.length];
    final cross =
        current.longitude * next.latitude - next.longitude * current.latitude;
    twiceArea += cross;
    longitudeMoment += (current.longitude + next.longitude) * cross;
    latitudeMoment += (current.latitude + next.latitude) * cross;
  }
  if (twiceArea.abs() > 1e-12) {
    return GeoCoordinate(
      longitudeMoment / (3 * twiceArea),
      latitudeMoment / (3 * twiceArea),
    );
  }
  final longitude = points.fold(0.0, (sum, point) => sum + point.longitude);
  final latitude = points.fold(0.0, (sum, point) => sum + point.latitude);
  return GeoCoordinate(longitude / points.length, latitude / points.length);
}

class _ToolItem {
  const _ToolItem(this.icon, this.title, this.onTap);

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      shape: StadiumBorder(side: BorderSide(color: colors.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: colors.primary, size: 22),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapControlGroup extends StatelessWidget {
  const _MapControlGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 2,
    shadowColor: AppColors.primaryDeep.withValues(alpha: 0.14),
    color: Theme.of(
      context,
    ).colorScheme.surfaceContainerLowest.withValues(alpha: 0.97),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            SizedBox(
              width: 28,
              child: Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
        ],
      ],
    ),
  );
}

class _MapControl extends StatelessWidget {
  const _MapControl({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    onPressed: onTap,
    icon: Icon(icon),
  );
}

class _MapConfigState extends StatelessWidget {
  const _MapConfigState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.navMap)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );
}
