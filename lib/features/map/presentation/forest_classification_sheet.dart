import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../domain/forest_classification_controller.dart';
import '../domain/forest_classification_model.dart';
import 'legend_card_widget.dart';

class ForestClassificationSheet extends ConsumerStatefulWidget {
  const ForestClassificationSheet({super.key});
  @override
  ConsumerState<ForestClassificationSheet> createState() =>
      _ForestClassificationSheetState();
}

class _ForestClassificationSheetState
    extends ConsumerState<ForestClassificationSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted && !ref.read(forestClassificationProvider).loaded) {
        ref.read(forestClassificationProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forestClassificationProvider);
    final controller = ref.read(forestClassificationProvider.notifier);
    final snapshot = state.snapshot;
    final theme = Theme.of(context);
    final number = NumberFormat('#,##0.##', 'vi');
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 0.93,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
            child: Row(
              children: [
                Icon(Icons.forest_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Phân loại đối tượng',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Tải kỳ mới nhất',
                  onPressed: state.loading ? null : controller.load,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (state.loading) const LinearProgressIndicator(),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      state.error!.localizedErrorMessage(context.l10n),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                if (state.history.isNotEmpty)
                  DropdownButtonFormField<int>(
                    key: ValueKey('forest-period-${snapshot?.id}'),
                    initialValue: state.history.any((s) => s.id == snapshot?.id)
                        ? snapshot?.id
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kỳ phân loại đã công bố',
                    ),
                    items: state.history
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.periodText),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id != null) controller.selectSnapshot(id);
                    },
                  ),
                if (snapshot == null && !state.loading && state.error == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'Chưa có kết quả phân loại được công bố',
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (snapshot != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          key: const ValueKey('forest-visible'),
                          title: Text('Lớp phân loại ${snapshot.periodText}'),
                          subtitle: Text(
                            snapshot.geoserverLayer != null
                                ? 'GeoServer WMS'
                                : snapshot.geeTileUrl != null
                                ? 'Google Earth Engine'
                                : 'Chưa có lớp bản đồ',
                          ),
                          value: state.isVisible,
                          onChanged:
                              snapshot.geoserverLayer == null &&
                                  snapshot.geeTileUrl == null
                              ? null
                              : controller.setVisible,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Expanded(child: Text('Độ hiển thị')),
                              Text('${(state.opacity * 100).round()}%'),
                            ],
                          ),
                        ),
                        Slider(
                          key: const ValueKey('forest-opacity'),
                          value: state.opacity,
                          label: '${(state.opacity * 100).round()}%',
                          semanticFormatterCallback: (value) =>
                              '${(value * 100).round()} phần trăm',
                          onChanged: controller.setOpacity,
                        ),
                      ],
                    ),
                  ),
                  if (snapshot.totalAreaHa != null)
                    ListTile(
                      dense: true,
                      title: const Text('Tổng diện tích'),
                      trailing: Text(
                        '${number.format(snapshot.totalAreaHa)} ha',
                      ),
                    ),
                  if (snapshot.forestCoveragePct != null)
                    ListTile(
                      dense: true,
                      title: const Text('Tỷ lệ che phủ rừng'),
                      trailing: Text(
                        '${number.format(snapshot.forestCoveragePct)}%',
                      ),
                    ),
                  const SizedBox(height: 12),
                  _ForestLegendCard(
                    legend: snapshot.legend,
                    number: number,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String hex) => Color(
      int.tryParse('FF${hex.replaceAll('#', '')}', radix: 16) ?? 0xFF94A3B8);

class _ForestLegendCard extends StatelessWidget {
  const _ForestLegendCard({required this.legend, required this.number});
  final List<ForestLegendClass> legend;
  final NumberFormat number;

  static const int _rowsPerColumn = 3;
  static const double _rowHeight = 30;
  static const double _columnWidth = 220;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (legend.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Chưa có chú giải cho kỳ này'),
      );
    }
    final columnCount = (legend.length / _rowsPerColumn).ceil();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
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
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Chú giải · ${legend.length} lớp',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  final end =
                      (start + _rowsPerColumn).clamp(0, legend.length);
                  final columnItems = legend.sublist(start, end);
                  return SizedBox(
                    width: _columnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in columnItems)
                          SizedBox(
                            height: _rowHeight,
                            child: Row(
                              children: [
                                LegendSymbolWidget(
                                  item: LegendColorItem(
                                    label: entry.nameVi,
                                    color: _parseColor(entry.color),
                                    geometryType: LegendGeometryType.raster,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.nameVi,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (entry.areaHa != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${number.format(entry.areaHa)} ha',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
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
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Vuốt ngang để xem thêm',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
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
