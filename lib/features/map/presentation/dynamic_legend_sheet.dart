import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/legend_models.dart';

/// Widget hiển thị Chú giải động (Dynamic Legend Sheet) theo chuẩn Mobile Map
/// Layer Integration Guide (Mục 5.3).
///
/// Tự động hiển thị các nhóm chú giải (lớp GIS đang bật + kịch bản ngập đang chọn).
/// Hỗ trợ cả chú giải phân lớp rời rạc (categorical/classes) và dải màu liên tục (gradient).
class DynamicLegendBottomSheet extends StatelessWidget {
  const DynamicLegendBottomSheet({super.key, required this.legends});

  final List<LegendGroup> legends;

  static Future<void> show(BuildContext context, List<LegendGroup> legends) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DynamicLegendBottomSheet(legends: legends),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (legends.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chú giải bản đồ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 24),
            Icon(
              Icons.layers_clear_outlined,
              size: 40,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có lớp dữ liệu hoặc kịch bản ngập nào được kích hoạt.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.palette_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chú giải bản đồ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${legends.length} nhóm đang hiển thị',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: legends.length,
              separatorBuilder: (_, _) => const Divider(height: 18),
              itemBuilder: (context, index) {
                final group = legends[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (group.isContinuous)
                      _buildGradientLegend(group, colorScheme)
                    else
                      ...group.entries.map(
                        (item) => _buildLegendRow(item, colorScheme),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(LegendEntry item, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.25),
                width: 0.7,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientLegend(LegendGroup group, ColorScheme colorScheme) {
    final colors = group.entries.map((e) => e.color).toList();
    final firstVal = group.entries.firstOrNull?.value ?? 0.0;
    final lastVal = group.entries.lastOrNull?.value ?? 100.0;
    final unit = group.unit != null && group.unit!.isNotEmpty
        ? ' ${group.unit}'
        : '';

    String formatVal(double val) =>
        val == val.roundToDouble() ? val.toStringAsFixed(0) : val.toString();

    return Column(
      children: [
        Container(
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: colors.length >= 2
                  ? colors
                  : [colors.firstOrNull ?? Colors.blue, Colors.blueGrey],
            ),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.25),
              width: 0.7,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${formatVal(firstVal)}$unit',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${formatVal(lastVal)}$unit',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
