import 'package:flutter/material.dart';

import '../domain/layer_model.dart';

enum LegendGeometryType { point, line, polygon, raster }

class LegendColorItem {
  const LegendColorItem({
    required this.label,
    required this.color,
    this.geometryType = LegendGeometryType.polygon,
    this.isPoint = false,
  });

  final String label;
  final Color color;
  final LegendGeometryType geometryType;
  final bool isPoint;

  bool get isPointGeometry =>
      isPoint || geometryType == LegendGeometryType.point;
  bool get isLineGeometry => geometryType == LegendGeometryType.line;
  bool get isPolygonGeometry => geometryType == LegendGeometryType.polygon;
  bool get isRasterGeometry => geometryType == LegendGeometryType.raster;
}

class LegendSymbolWidget extends StatelessWidget {
  const LegendSymbolWidget({super.key, required this.item, this.size = 1.0});

  final LegendColorItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (item.isPointGeometry) {
      final dotSize = 14.0 * size;
      return Container(
        width: dotSize,
        height: dotSize,
        margin: EdgeInsets.symmetric(horizontal: 3.0 * size),
        decoration: BoxDecoration(
          color: item.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5 * size),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 2 * size,
              offset: Offset(0, 1 * size),
            ),
          ],
        ),
      );
    } else if (item.isLineGeometry) {
      return Container(
        width: 20.0 * size,
        height: 3.5 * size,
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(2 * size),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.35),
              blurRadius: 2 * size,
              offset: Offset(0, 1 * size),
            ),
          ],
        ),
      );
    } else if (item.isPolygonGeometry) {
      return Container(
        width: 20.0 * size,
        height: 14.0 * size,
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(3.0 * size),
          border: Border.all(color: item.color, width: 1.6 * size),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 2 * size,
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: 20.0 * size,
        height: 14.0 * size,
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(3.0 * size),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.3),
            width: 0.8 * size,
          ),
        ),
      );
    }
  }
}

/// Giữ thứ tự API nhưng loại mục lặp do cùng layer/source được tổng hợp lại.
List<LegendColorItem> deduplicateLegendItems(Iterable<LegendColorItem> items) {
  final unique = <String, LegendColorItem>{};
  for (final item in items) {
    final key = [
      item.label.trim().toLowerCase(),
      item.color.toARGB32(),
      item.geometryType.name,
      item.isPoint,
    ].join('|');
    unique.putIfAbsent(key, () => item);
  }
  return unique.values.toList(growable: false);
}

/// Chuyển dữ liệu `legend` từ API thành các mục hiển thị; hỗ trợ định dạng
/// `entries: [{ label, color }]` và key-value `{ "label": "#color" }`.
/// Nếu API chưa cấu hình chú giải và có [layer], trả một mục nhận diện bằng
/// tên lớp và màu đại diện; màu raster thực tế do WMS phía server quyết định.
List<LegendColorItem> getLegendItems(LayerLegend legend, [LayerModel? layer]) {
  final items = <LegendColorItem>[];
  final geometryType = layer == null
      ? LegendGeometryType.polygon
      : layer.isPoint
      ? LegendGeometryType.point
      : layer.isLine
      ? LegendGeometryType.line
      : layer.isRaster
      ? LegendGeometryType.raster
      : LegendGeometryType.polygon;

  // 1. Kiểm tra cấu hình legend theo chuẩn entries: [ { label, color }, ... ]
  final rawEntries = legend.legend['entries'];
  if (rawEntries is List && rawEntries.isNotEmpty) {
    for (var i = 0; i < rawEntries.length; i++) {
      final entry = rawEntries[i];
      if (entry is Map) {
        final labelRaw = entry['label'] ?? entry['name'] ?? 'Mục ${i + 1}';
        String label = '';
        if (labelRaw is Map) {
          label =
              labelRaw['vi']?.toString() ??
              labelRaw['en']?.toString() ??
              labelRaw['label']?.toString() ??
              '';
        } else {
          label = labelRaw.toString();
        }
        final color = parseHexColor(
          entry['color'] ?? entry['fill'] ?? entry['hex'] ?? entry['colorHex'],
        );
        if (color != null) {
          items.add(
            LegendColorItem(
              label: label.isEmpty ? 'Mục ${i + 1}' : label,
              color: color,
              geometryType: geometryType,
              isPoint: layer?.isPoint ?? false,
            ),
          );
        }
      }
    }
  }

  // 2. Kiểm tra cấu hình legend dạng key-value map: { "Mặt nước": "#0086FF", ... }
  if (items.isEmpty) {
    for (final entry in legend.legend.entries) {
      if (entry.key == 'entries') continue;
      final key = entry.key;
      final val = entry.value;
      if (val is String && (val.startsWith('#') || val.startsWith('0x'))) {
        final color = parseHexColor(val);
        if (color != null) {
          items.add(
            LegendColorItem(
              label: key,
              color: color,
              geometryType: geometryType,
              isPoint: layer?.isPoint ?? false,
            ),
          );
        }
      }
    }
  }

  if (items.isNotEmpty) return deduplicateLegendItems(items);
  if (layer == null) return items;

  // API chưa cấu hình `legend`: nhận diện lớp bằng tên và màu đại diện.
  // Không suy diễn các cấp phân loại hoặc màu pixel của ảnh raster.
  return [
    LegendColorItem(
      label: layer.nameVi,
      color: layer.displayColor,
      geometryType: geometryType,
      isPoint: layer.isPoint,
    ),
  ];
}

/// Lấy danh sách item chú giải trực tiếp từ đối tượng LayerModel.
List<LegendColorItem> getLegendItemsForLayer(LayerModel layer) {
  final layerLegend = LayerLegend(
    layerId: layer.id,
    code: layer.code,
    nameVi: layer.nameVi,
    legend: layer.legend,
    styleName: layer.styleName,
    minZoom: layer.minZoom,
    maxZoom: layer.maxZoom,
  );
  return getLegendItems(layerLegend, layer);
}

class LayerLegendCard extends StatelessWidget {
  const LayerLegendCard({
    super.key,
    required this.title,
    required this.items,
    this.onClose,
  });

  final String title;
  final List<LegendColorItem> items;
  final VoidCallback? onClose;

  static const int _rowsPerColumn = 3;
  static const double _rowHeight = 30;
  static const double _columnWidth = 200;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final displayItems = items;
    final columnCount = (displayItems.length / _rowsPerColumn).ceil();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title.isEmpty ? 'Chú Giải' : title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    key: const ValueKey('map-legend-close'),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 6),
            SizedBox(
              height: _rowHeight * _rowsPerColumn,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: columnCount,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, colIndex) {
                  final start = colIndex * _rowsPerColumn;
                  final end = (start + _rowsPerColumn).clamp(
                    0,
                    displayItems.length,
                  );
                  final columnItems = displayItems.sublist(start, end);
                  return SizedBox(
                    width: _columnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final item in columnItems)
                          SizedBox(
                            height: _rowHeight,
                            child: Row(
                              children: [
                                LegendSymbolWidget(item: item),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (columnCount > 1) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe_outlined,
                    size: 13,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Vuốt ngang để xem thêm',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
