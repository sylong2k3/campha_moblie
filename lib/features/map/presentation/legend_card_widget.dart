import 'package:flutter/material.dart';

import '../domain/layer_model.dart';

class LegendColorItem {
  const LegendColorItem({required this.label, required this.color});

  final String label;
  final Color color;
}

/// Chú giải chuẩn cho lớp phủ ngập / lớp phủ đất
const List<LegendColorItem> defaultFloodLandCoverLegendItems = [
  LegendColorItem(label: 'Mặt nước', color: Color(0xFF0080FF)),
  LegendColorItem(label: 'Rừng LRTX có độ che phủ thưa', color: Color(0xFF004D00)),
  LegendColorItem(label: 'Dân cư đô thị', color: Color(0xFFFF9999)),
  LegendColorItem(label: 'Đất trống khô', color: Color(0xFFFFFF99)),
  LegendColorItem(label: 'Bãi khai thác than', color: Color(0xFF8B5A2B)),
  LegendColorItem(label: 'Cây bụi', color: Color(0xFF27AE60)),
  LegendColorItem(label: 'Đất trống trảng cỏ', color: Color(0xFFCCFF00)),
  LegendColorItem(label: 'Đất nông nghiệp', color: Color(0xFFFFCC99)),
];

/// Kiểm tra xem một layer có thuộc nhóm lớp phủ ngập / đất không
bool isFloodLandCoverLayer(LayerModel layer) {
  final cat = layer.category.toLowerCase();
  final code = layer.code.toLowerCase();
  final name = layer.nameVi.toLowerCase();
  return cat.contains('phu') ||
      cat.contains('ngap') ||
      cat.contains('land_cover') ||
      code.contains('phu') ||
      code.contains('ngap') ||
      code.contains('land_cover') ||
      name.contains('phủ') ||
      name.contains('ngập');
}

/// Lấy danh sách item chú giải: ưu tiên tuyệt đối dữ liệu `legend` do server
/// trả về cho đúng layer đang xem; chỉ dùng bộ màu mặc định khi server không
/// cấu hình chú giải cho layer phủ ngập/đất (không được ghi đè lên dữ liệu
/// thật, tránh trường hợp mọi layer phủ ngập đều hiện cùng một bảng màu).
List<LegendColorItem> getLegendItems(LayerLegend legend, [LayerModel? layer]) {
  final items = <LegendColorItem>[];
  for (final entry in legend.legend.entries) {
    final key = entry.key;
    final val = entry.value;
    if (val is String && val.startsWith('#')) {
      final hex = val.replaceFirst('#', '');
      final colorInt = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
      if (colorInt != null) {
        items.add(LegendColorItem(label: key, color: Color(colorInt)));
      }
    }
  }

  if (items.isNotEmpty) return items;

  if (layer != null && isFloodLandCoverLayer(layer)) {
    return defaultFloodLandCoverLegendItems;
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
  static const double _columnWidth = 190;

  @override
  Widget build(BuildContext context) {
    final displayItems =
        items.isEmpty ? defaultFloodLandCoverLegendItems : items;
    final columnCount = (displayItems.length / _rowsPerColumn).ceil();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(
          alpha: 0.95,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(
            alpha: 0.6,
          ),
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
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
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
                                Container(
                                  width: 20,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
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
