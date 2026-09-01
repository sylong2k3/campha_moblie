import 'package:flutter/material.dart';

import '../domain/layer_model.dart';

enum LegendGeometryType {
  point,
  line,
  polygon,
  raster,
}

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

  bool get isPointGeometry => isPoint || geometryType == LegendGeometryType.point;
  bool get isLineGeometry => geometryType == LegendGeometryType.line;
  bool get isPolygonGeometry => geometryType == LegendGeometryType.polygon;
  bool get isRasterGeometry => geometryType == LegendGeometryType.raster;
}

class LegendSymbolWidget extends StatelessWidget {
  const LegendSymbolWidget({
    super.key,
    required this.item,
    this.size = 1.0,
  });

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
          border: Border.all(
            color: Colors.white,
            width: 1.5 * size,
          ),
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
          border: Border.all(
            color: item.color,
            width: 1.6 * size,
          ),
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

/// Chú giải chuẩn cho lớp phủ ngập / lớp phủ đất
const List<LegendColorItem> defaultFloodLandCoverLegendItems = [
  LegendColorItem(
    label: 'Mặt nước',
    color: Color(0xFF0080FF),
    geometryType: LegendGeometryType.raster,
  ),
  LegendColorItem(
    label: 'Rừng LRTX có độ che phủ thưa',
    color: Color(0xFF004D00),
    geometryType: LegendGeometryType.raster,
  ),
  LegendColorItem(
    label: 'Dân cư đô thị',
    color: Color(0xFFFF9999),
    geometryType: LegendGeometryType.raster,
  ),
  LegendColorItem(
    label: 'Đất trống khô',
    color: Color(0xFFFFFF99),
    geometryType: LegendGeometryType.raster,
  ),
  LegendColorItem(
    label: 'Bãi khai thác than',
    color: Color(0xFF8B5A2B),
    geometryType: LegendGeometryType.raster,
  ),
  LegendColorItem(
    label: 'Cây bụi',
    color: Color(0xFF27AE60),
    geometryType: LegendGeometryType.raster,
  ),
  LegendColorItem(
    label: 'Đất trống trảng cỏ',
    color: Color(0xFFCCFF00),
    geometryType: LegendGeometryType.raster,
  ),
  LegendColorItem(
    label: 'Đất nông nghiệp',
    color: Color(0xFFFFCC99),
    geometryType: LegendGeometryType.raster,
  ),
];

/// Kiểm tra xem một layer có thuộc nhóm lớp phủ ngập / đất không (chỉ áp dụng raster / vùng phủ)
bool isFloodLandCoverLayer(LayerModel layer) {
  if (layer.isPoint) return false;
  final cat = layer.category.toLowerCase();
  final code = layer.code.toLowerCase();
  final name = layer.nameVi.toLowerCase();
  return cat.contains('phu') ||
      cat.contains('land_cover') ||
      code.contains('phu') ||
      code.contains('land_cover') ||
      name.contains('phủ') ||
      (layer.isRaster &&
          (cat.contains('ngap') ||
              code.contains('ngap') ||
              name.contains('ngập')));
}

/// Lấy danh sách item chú giải: ưu tiên tuyệt đối dữ liệu `legend` do server
/// trả về cho đúng layer đang xem; chỉ dùng bộ màu mặc định khi server không
/// cấu hình chú giải cho layer phủ ngập/đất. Với các lớp vector (point, line,
/// polygon), trả về ký hiệu và màu sắc nhận diện tương ứng.
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

  for (final entry in legend.legend.entries) {
    final key = entry.key;
    final val = entry.value;
    if (val is String && val.startsWith('#')) {
      final hex = val.replaceFirst('#', '');
      final colorInt = int.tryParse(
        hex.length == 6 ? 'FF$hex' : hex,
        radix: 16,
      );
      if (colorInt != null) {
        items.add(
          LegendColorItem(
            label: key,
            color: Color(colorInt),
            geometryType: geometryType,
            isPoint: layer?.isPoint ?? false,
          ),
        );
      }
    }
  }

  if (items.isNotEmpty) return items;

  if (layer != null) {
    if (isFloodLandCoverLayer(layer)) {
      return defaultFloodLandCoverLegendItems;
    }
    return [
      LegendColorItem(
        label: layer.nameVi,
        color: layer.displayColor,
        geometryType: geometryType,
        isPoint: layer.isPoint,
      ),
    ];
  }
  return items;
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
    final displayItems = items.isEmpty
        ? defaultFloodLandCoverLegendItems
        : items;
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
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Theme.of(context).colorScheme.outline,
                      ),
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
