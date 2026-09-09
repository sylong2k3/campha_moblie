import 'dart:async';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/error/app_exception.dart';
import '../data/map_repository.dart';

class ThematicRaster {
  const ThematicRaster({
    required this.sourceId,
    required this.name,
    this.registryLayerId,
    this.tileUrl,
    this.isPublic = true,
    this.opacity = 0.85,
    this.minZoom = 0,
    this.maxZoom = 22,
  });
  final String sourceId;
  final String name;
  final String? registryLayerId;
  final String? tileUrl;
  final bool isPublic;
  final double opacity;
  final double minZoom;
  final double maxZoom;
  String get layerId => '$sourceId-raster';
}

/// Renderer riêng cho ba overlay; không ghi state của catalog hay sở hữu MapboxMap.
class ThematicOverlayRenderer {
  ThematicOverlayRenderer({
    required this.map,
    required this.repository,
    required this.isAuthenticated,
    required this.onError,
  });
  final MapboxMap map;
  final MapRepository repository;
  final bool Function() isAuthenticated;
  final void Function(ThematicRaster, Object) onError;
  List<ThematicRaster> _desired = const [];
  final Set<String> _owned = {};
  final Map<String, String> _urls = {};
  final Set<String> _ticketRetried = {};
  final Map<String, DateTime> _retryAt = {};
  final Map<String, int> _retryCount = {};
  final Set<String> _blocked = {};
  String? _belowLayerId;
  bool _ready = false;
  bool _disposed = false;
  bool _syncing = false;
  bool _paused = false;
  int _revision = 0;
  Timer? _timer;
  Completer<void> _changed = Completer<void>();

  void _invalidate() {
    _revision++;
    _changed.complete();
    _changed = Completer<void>();
  }

  void update(List<ThematicRaster> layers, {String? belowLayerId}) {
    final ids = layers.map((l) => l.sourceId).toSet();
    _blocked.removeWhere((id) => !ids.contains(id));
    _ticketRetried.removeWhere((id) => !ids.contains(id));
    _retryAt.removeWhere((id, _) => !ids.contains(id));
    _retryCount.removeWhere((id, _) => !ids.contains(id));
    _desired = layers;
    _belowLayerId = belowLayerId;
    _scheduleRefresh();
    _queue();
  }

  void styleChanging() {
    _ready = false;
    _invalidate();
  }

  void styleLoaded() {
    _ready = true;
    _urls.clear();
    _queue();
  }

  void setPaused(bool paused) {
    _paused = paused;
    _scheduleRefresh();
    _queue();
  }

  void dispose() {
    _disposed = true;
    _invalidate();
    _timer?.cancel();
  }

  void _scheduleRefresh() {
    _timer?.cancel();
    if (_disposed || _paused || _desired.isEmpty) return;
    // Chỉ kiểm tra cache; không lấy ticket mới khi vé hiện tại còn hiệu lực.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _queue());
  }

  void _queue() {
    _invalidate();
    if (!_syncing && _ready && !_disposed && !_paused) unawaited(_sync());
  }

  bool _current(int revision) =>
      !_disposed && _ready && !_paused && revision == _revision;

  Future<void> _sync() async {
    _syncing = true;
    try {
      while (!_disposed && _ready && !_paused) {
        final revision = _revision;
        final desired = [..._desired];
        final ids = desired.map((l) => l.sourceId).toSet();
        for (final id in _owned.toList()) {
          final retry = _retryAt[id];
          if (!ids.contains(id) ||
              _blocked.contains(id) ||
              (retry != null && retry.isAfter(DateTime.now()))) {
            await _remove(id);
          }
        }
        if (!_current(revision)) continue;
        for (final layer in desired) {
          if (!_current(revision)) break;
          final retry = _retryAt[layer.sourceId];
          if (_blocked.contains(layer.sourceId) ||
              (retry != null && retry.isAfter(DateTime.now()))) {
            continue;
          }
          try {
            String? ticket;
            if (!layer.isPublic) {
              if (!isAuthenticated()) {
                throw const UnauthorizedException(
                  'Đăng nhập để xem lớp bản đồ này',
                );
              }
              ticket = await Future.any<String?>([
                repository.validRasterTileTicket(layer.registryLayerId!),
                _changed.future.then((_) => null),
              ]);
            }
            if (!_current(revision)) break;
            final url = layer.registryLayerId == null
                ? layer.tileUrl!
                : repository.floodWmsUrl(
                    layer.registryLayerId!,
                    ticket: ticket,
                  );
            final sourceExists = await map.style.styleSourceExists(
              layer.sourceId,
            );
            if (!_current(revision)) break;
            _owned.add(layer.sourceId);
            if (!sourceExists) {
              await map.style.addSource(
                RasterSource(
                  id: layer.sourceId,
                  tiles: [url],
                  tileSize: 256,
                  minzoom: layer.minZoom,
                  maxzoom: layer.maxZoom,
                  volatile: true,
                ),
              );
            } else if (_urls[layer.sourceId] != url) {
              await map.style.setStyleSourceProperty(layer.sourceId, 'tiles', [
                url,
              ]);
            }
            if (!_current(revision)) break;
            _urls[layer.sourceId] = url;
            final exists = await map.style.styleLayerExists(layer.layerId);
            if (!_current(revision)) break;
            if (!exists) {
              final raster = RasterLayer(
                id: layer.layerId,
                sourceId: layer.sourceId,
                rasterOpacity: layer.opacity,
              );
              await map.style.addLayer(raster);
            }
            if (!_current(revision)) break;
            await map.style.setStyleLayerProperty(
              layer.layerId,
              'raster-opacity',
              layer.opacity,
            );
            if (!_current(revision)) break;
            final below = _belowLayerId;
            final position = below != null && await map.style.styleLayerExists(below)
                ? LayerPosition(below: below) : null;
            if (!_current(revision)) break;
            await map.style.moveStyleLayer(layer.layerId, position);
          } catch (error) {
            if (_current(revision)) _handleError(layer, error);
          }
        }
        if (_current(revision)) break;
      }
    } catch (error) {
      if (!_disposed && _desired.isNotEmpty) onError(_desired.first, error);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _remove(String id) async {
    if (_disposed || !_ready) return;
    if (await map.style.styleLayerExists('$id-raster')) {
      if (_disposed || !_ready) return;
      await map.style.removeStyleLayer('$id-raster');
    }
    if (_disposed || !_ready) return;
    if (await map.style.styleSourceExists(id)) {
      if (_disposed || !_ready) return;
      await map.style.removeStyleSource(id);
    }
    _owned.remove(id);
    _urls.remove(id);
  }

  bool handleMapError(MapLoadingErrorEventData event) {
    if (_disposed || !_ready || _paused) return false;
    final layer = _desired
        .where((l) => l.sourceId == event.sourceId)
        .firstOrNull;
    if (layer == null) return false;
    final message = event.message.toLowerCase();
    if (message.contains('cancel') || message.contains('supersed')) return true;
    // ponytail: SDK không có HTTP status riêng; chỉ phân loại khi message chứa mã,
    // nâng cấp sang status có cấu trúc khi Mapbox cung cấp trường đó.
    final status = RegExp(
      r'\b(401|403|404|422|429)\b',
    ).firstMatch(message)?.group(1);
    final error = switch (status) {
      '401' => const UnauthorizedException('Đăng nhập để xem lớp bản đồ này'),
      '403' => const ForbiddenException('Không đủ quyền xem lớp bản đồ'),
      '404' => const NotFoundException('Lớp bản đồ không còn tồn tại'),
      '422' => const SemanticValidationException(
        'Lớp bản đồ không hỗ trợ yêu cầu này',
      ),
      '429' => const RateLimitException(
        'Máy chủ giới hạn tải bản đồ. Đang chờ thử lại.',
      ),
      _ => const NetworkException(
        'Chưa tải được lớp bản đồ. Đang chờ thử lại.',
      ),
    };
    _handleError(layer, error);
    return true;
  }

  void _handleError(ThematicRaster layer, Object error) {
    final id = layer.sourceId;
    if (_blocked.contains(id) ||
        (_retryAt[id]?.isAfter(DateTime.now()) ?? false)) {
      return;
    }
    if (error is ForbiddenException &&
        !layer.isPublic &&
        _ticketRetried.add(id)) {
      repository.invalidateTileTicket(layer.registryLayerId!);
      _queue();
      return;
    }
    if (error is UnauthorizedException ||
        error is ForbiddenException ||
        error is NotFoundException ||
        error is SemanticValidationException ||
        error is FormatException) {
      _blocked.add(id);
    } else {
      final attempts = (_retryCount[id] ?? 0) + 1;
      _retryCount[id] = attempts;
      final backoff = 30 * (1 << (attempts - 1).clamp(0, 4));
      final serverWait = error is RateLimitException
          ? error.retryAfterSeconds ?? 0
          : 0;
      _retryAt[id] = DateTime.now().add(
        Duration(seconds: serverWait > backoff ? serverWait : backoff),
      );
    }
    _queue();
    onError(layer, error);
  }
}
