import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:campha_moblie/core/network/api_config.dart';
import 'package:campha_moblie/core/network/api_endpoints.dart';
import 'package:campha_moblie/core/storage/token_storage.dart';

/// Sprint 0 renderer spike. Không nối router sản phẩm; chạy bằng
/// `flutter run --flavor dev -t tool/map_spike/main.dart --dart-define-from-file=.env`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken(ApiConfig.mapboxToken);
  runApp(const ProviderScope(child: MapSpikeApp()));
}

class MapSpikeApp extends StatelessWidget {
  const MapSpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF214E43),
        useMaterial3: true,
      ),
      home: const MapSpikeScreen(),
    );
  }
}

class MapSpikeScreen extends ConsumerStatefulWidget {
  const MapSpikeScreen({super.key});

  @override
  ConsumerState<MapSpikeScreen> createState() => _MapSpikeScreenState();
}

class _MapSpikeScreenState extends ConsumerState<MapSpikeScreen> {
  static const _mvtSourceId = 'campha-mvt';
  static const _mvtLayerId = 'campha-boundary';
  static const _routeSourceId = 'spike-route';
  static const _routeLayerId = 'spike-route-line';
  static const _layerId = '1';
  static const _sourceLayer = 'ranhgioi_campha';

  MapboxMap? _map;
  bool _styleReady = false;
  bool _mvtAdded = false;
  bool _addingMvt = false;
  String _status = 'Đang tải Mapbox style…';
  String? _error;
  final Stopwatch _loadTimer = Stopwatch()..start();

  String get _apiHost => Uri.parse(ApiConfig.baseUrl).host;
  String get _tileUrl {
    final path = ApiEndpoints.mobileTile(
      _layerId,
      0,
      0,
      0,
    ).replaceAll('/0/0/0.mvt', '/{z}/{x}/{y}.mvt');
    return '${ApiConfig.baseUrl}$path';
  }

  @override
  void dispose() {
    _map?.httpService.setCustomHeadersForHost(_apiHost, {});
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    final token = await ref.read(tokenStorageProvider).readAccessToken();
    await _applyApiHeader(token);
  }

  Future<void> _applyApiHeader(String? token) async {
    final map = _map;
    if (map == null) return;
    await map.httpService.setCustomHeadersForHost(
      _apiHost,
      token == null || token.isEmpty ? {} : {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    try {
      await _addGeoJsonProof();
      if (!mounted) return;
      setState(() {
        _styleReady = true;
        _status = 'Basemap + GeoJSON sẵn sàng';
      });
    } catch (error) {
      _setError('Không thêm được GeoJSON overlay: $error');
    }
  }

  Future<void> _addGeoJsonProof() async {
    final map = _map;
    if (map == null) return;
    const route = {
      'type': 'Feature',
      'properties': {'kind': 'renderer-spike'},
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [107.302, 21.012],
          [107.318, 21.006],
          [107.336, 21.017],
        ],
      },
    };
    await map.style.addSource(
      GeoJsonSource(
        id: _routeSourceId,
        data: jsonEncode(route),
        lineMetrics: true,
      ),
    );
    await map.style.addLayer(
      LineLayer(
        id: _routeLayerId,
        sourceId: _routeSourceId,
        lineColor: const Color(0xFFC47745).toARGB32(),
        lineWidth: 5,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ),
    );
  }

  Future<void> _addLiveMvt() async {
    final map = _map;
    if (map == null || !_styleReady || _addingMvt || _mvtAdded) return;
    setState(() {
      _addingMvt = true;
      _error = null;
      _status = 'Đang gắn MVT backend…';
    });
    try {
      await _applyApiHeader(
        await ref.read(tokenStorageProvider).readAccessToken(),
      );
      await map.style.addSource(
        VectorSource(
          id: _mvtSourceId,
          tiles: [_tileUrl],
          bounds: const [107, 20.7, 108, 21.3],
          minzoom: 0,
          maxzoom: 22,
          volatile: true,
        ),
      );
      await map.style.addLayer(
        LineLayer(
          id: _mvtLayerId,
          sourceId: _mvtSourceId,
          sourceLayer: _sourceLayer,
          lineColor: const Color(0xFF214E43).toARGB32(),
          lineWidth: 3,
          lineOpacity: 0.95,
        ),
      );
      if (!mounted) return;
      setState(() {
        _mvtAdded = true;
        _status = 'Đã gắn MVT; chờ tile backend';
      });
    } catch (error) {
      _setError('Không gắn được MVT: $error');
    } finally {
      if (mounted) setState(() => _addingMvt = false);
    }
  }

  void _onMapLoaded(MapLoadedEventData _) {
    if (!mounted) return;
    _loadTimer.stop();
    setState(() => _status = 'Map render ${_loadTimer.elapsedMilliseconds} ms');
  }

  void _onMapError(MapLoadingErrorEventData event) {
    final source = event.sourceId == null ? '' : ' · ${event.sourceId}';
    _setError('${event.type.name}$source: ${event.message}');
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _status = 'Renderer có lỗi';
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokenMissing = ApiConfig.mapboxToken.isEmpty;
    return Scaffold(
      body: tokenMissing
          ? const _ConfigError()
          : Stack(
              children: [
                MapWidget(
                  key: const ValueKey('sprint0-mapbox-spike'),
                  styleUri: ApiConfig.mapboxStyleStreet.isEmpty
                      ? MapboxStyles.STANDARD
                      : ApiConfig.mapboxStyleStreet,
                  viewport: CameraViewportState(
                    center: Point(coordinates: Position(107.33, 21.01)),
                    zoom: 11.2,
                  ),
                  onMapCreated: _onMapCreated,
                  onStyleLoadedListener: _onStyleLoaded,
                  onMapLoadedListener: _onMapLoaded,
                  onMapLoadErrorListener: _onMapError,
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _EvidenceCard(
                      status: _status,
                      error: _error,
                      mvtAdded: _mvtAdded,
                      busy: _addingMvt,
                      onAddMvt: _styleReady ? _addLiveMvt : null,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.status,
    required this.error,
    required this.mvtAdded,
    required this.busy,
    required this.onAddMvt,
  });

  final String status;
  final String? error;
  final bool mvtAdded;
  final bool busy;
  final VoidCallback? onAddMvt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: colors.surface.withValues(alpha: 0.96),
          elevation: 3,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sprint 0 · Map renderer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(status),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(color: colors.error, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: mvtAdded || busy ? null : onAddMvt,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.layers_outlined),
                  label: Text(mvtAdded ? 'MVT đã gắn' : 'Kiểm tra MVT live'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'GeoJSON màu đất nung chứng minh overlay. MVT có thể báo 500 do blocker source_fid.',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigError extends StatelessWidget {
  const _ConfigError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Thiếu MAPBOX_TOKEN. Cấu hình public token bằng .env hoặc --dart-define; không hard-code token.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
