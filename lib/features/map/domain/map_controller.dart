import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_config.dart';
import '../data/map_repository.dart';
import 'layer_model.dart';

class MapCatalogState {
  const MapCatalogState({
    this.layers = const [],
    this.basemaps = const [],
    this.activeLayerIds = const {},
    this.opacityByLayer = const {},
    this.selectedBasemapCode,
    this.loading = false,
    this.stale = false,
    this.error,
  });

  final List<LayerModel> layers;
  final List<BasemapModel> basemaps;
  final Set<String> activeLayerIds;
  final Map<String, double> opacityByLayer;
  final String? selectedBasemapCode;
  final bool loading;
  final bool stale;
  final Object? error;

  int get activeCount => activeLayerIds.length;

  BasemapModel? get selectedBasemap {
    for (final item in basemaps) {
      if (item.code == selectedBasemapCode) return item;
    }
    return null;
  }

  double opacityOf(String layerId) => opacityByLayer[layerId] ?? 0.9;

  MapCatalogState copyWith({
    List<LayerModel>? layers,
    List<BasemapModel>? basemaps,
    Set<String>? activeLayerIds,
    Map<String, double>? opacityByLayer,
    String? selectedBasemapCode,
    bool? loading,
    bool? stale,
    Object? error,
    bool clearError = false,
  }) => MapCatalogState(
    layers: layers ?? this.layers,
    basemaps: basemaps ?? this.basemaps,
    activeLayerIds: activeLayerIds ?? this.activeLayerIds,
    opacityByLayer: opacityByLayer ?? this.opacityByLayer,
    selectedBasemapCode: selectedBasemapCode ?? this.selectedBasemapCode,
    loading: loading ?? this.loading,
    stale: stale ?? this.stale,
    error: clearError ? null : error ?? this.error,
  );
}

class MapCatalogController extends Notifier<MapCatalogState> {
  @override
  MapCatalogState build() {
    Future.microtask(load);
    return const MapCatalogState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true, stale: false);
    try {
      final repository = ref.read(mapRepositoryProvider);
      final results = await Future.wait([
        repository.getLayers(),
        repository.getBasemaps(),
      ]);
      final layers = results[0] as List<LayerModel>;
      final apiBasemaps = results[1] as List<BasemapModel>;

      final mapboxBasemaps = [
        if (ApiConfig.mapboxStyleStreet.isNotEmpty)
          BasemapModel(
            code: 'mapbox_streets',
            nameVi: 'Mapbox Đường phố (Tiếng Việt)',
            provider: 'mapbox',
            urlTemplate: ApiConfig.mapboxStyleStreet,
            attribution: '© Mapbox',
          ),
        if (ApiConfig.mapboxStyleSatelliteStreet.isNotEmpty)
          BasemapModel(
            code: 'mapbox_satellite_streets',
            nameVi: 'Mapbox Vệ tinh & Đường phố',
            provider: 'mapbox',
            urlTemplate: ApiConfig.mapboxStyleSatelliteStreet,
            attribution: '© Mapbox',
          ),
        if (ApiConfig.mapboxStyleOutdoor.isNotEmpty)
          BasemapModel(
            code: 'mapbox_outdoors',
            nameVi: 'Mapbox Địa hình / Ngoại cảnh',
            provider: 'mapbox',
            urlTemplate: ApiConfig.mapboxStyleOutdoor,
            attribution: '© Mapbox',
          ),
        if (ApiConfig.mapboxStyleSatellite.isNotEmpty)
          BasemapModel(
            code: 'mapbox_satellite',
            nameVi: 'Mapbox Vệ tinh',
            provider: 'mapbox',
            urlTemplate: ApiConfig.mapboxStyleSatellite,
            attribution: '© Mapbox',
          ),
      ];

      final basemaps = [
        ...mapboxBasemaps,
        ...apiBasemaps.where((b) => !b.code.startsWith('mapbox_')),
      ];

      final allowedIds = layers.map((layer) => layer.id).toSet();
      final retainedActive = state.activeLayerIds.intersection(allowedIds);
      Set<String> defaultActive = retainedActive;
      if (retainedActive.isEmpty && layers.isNotEmpty) {
        final defaultLayer = layers.firstWhere(
          (l) => l.code.toLowerCase() == 'ranhgioi_campha',
          orElse: () => layers.firstWhere(
            (l) =>
                l.nameVi.toLowerCase().contains('ranh giới') ||
                l.nameVi.toLowerCase().contains('ranh gioi') ||
                l.code.toLowerCase().contains('ranh_gioi') ||
                l.code.toLowerCase().contains('boundary'),
            orElse: () => layers.firstWhere(
              (l) => !l.isRaster,
              orElse: () => layers.first,
            ),
          ),
        );
        defaultActive = {defaultLayer.id};
      }
      state = state.copyWith(
        layers: layers,
        basemaps: basemaps,
        activeLayerIds: defaultActive,
        selectedBasemapCode:
            state.selectedBasemapCode ??
            (basemaps.isEmpty ? null : basemaps.first.code),
        loading: false,
        stale: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        loading: false,
        stale: state.layers.isNotEmpty,
        error: error,
      );
    }
  }

  void resetForIdentityChange() {
    if (state.layers.isNotEmpty || state.basemaps.isNotEmpty) {
      state = state.copyWith(loading: true, stale: true);
    } else {
      state = const MapCatalogState(loading: true);
    }
    Future.microtask(load);
  }

  void setLayerVisible(String layerId, bool visible) {
    final next = {...state.activeLayerIds};
    visible ? next.add(layerId) : next.remove(layerId);
    state = state.copyWith(activeLayerIds: next);
  }

  void setLayerOpacity(String layerId, double opacity) {
    state = state.copyWith(
      opacityByLayer: {
        ...state.opacityByLayer,
        layerId: opacity.clamp(0.15, 1.0),
      },
    );
  }

  void disableAll() => state = state.copyWith(activeLayerIds: {});

  void selectBasemap(String code) =>
      state = state.copyWith(selectedBasemapCode: code);
}

final mapCatalogProvider =
    NotifierProvider<MapCatalogController, MapCatalogState>(
      MapCatalogController.new,
    );

final mapLegendProvider = FutureProvider.autoDispose
    .family<LayerLegend, String>(
      (ref, layerId) => ref.read(mapRepositoryProvider).getLegend(layerId),
    );
