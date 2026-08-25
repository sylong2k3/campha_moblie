import 'package:campha_moblie/app/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../shared/presentation/app_feedback.dart';
import '../../shared/presentation/app_search_field.dart';
import '../domain/layer_model.dart';
import '../domain/map_controller.dart';
import 'legend_card_widget.dart';

class LayerCatalogSheet extends ConsumerStatefulWidget {
  const LayerCatalogSheet({super.key});

  @override
  ConsumerState<LayerCatalogSheet> createState() => _LayerCatalogSheetState();
}

class _LayerCatalogSheetState extends ConsumerState<LayerCatalogSheet> {
  final _searchController = TextEditingController();
  final Map<String, bool> _expandedByCategory = {};
  final Map<String, GlobalKey> _categoryKeys = {};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategoryExpanded(String categoryKey, bool expanded) {
    setState(() {
      if (expanded) {
        _expandedByCategory.clear();
        _expandedByCategory[categoryKey] = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final targetContext = _categoryKeys[categoryKey]?.currentContext;
          if (targetContext != null && mounted) {
            Scrollable.ensureVisible(
              targetContext,
              duration: AppMotion.of(context, AppMotion.surface),
              curve: AppMotion.surfaceCurve,
              alignment: 0.05,
            );
          }
        });
      } else {
        _expandedByCategory[categoryKey] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapCatalogProvider);
    final controller = ref.read(mapCatalogProvider.notifier);
    final filtered = state.layers
        .where((layer) {
          final q = _query.toLowerCase();
          return q.isEmpty ||
              layer.nameVi.toLowerCase().contains(q) ||
              layer.code.toLowerCase().contains(q);
        })
        .toList(growable: false);
    final categories = <String, List<LayerModel>>{};
    for (final layer in filtered) {
      categories.putIfAbsent(layer.category, () => []).add(layer);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.mapLayersTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.commonClose,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      context.l10n.mapActiveLayers(state.activeCount),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (state.activeCount > 0)
                      TextButton(
                        onPressed: controller.disableAll,
                        child: Text(context.l10n.mapDisableAll),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: AppSearchField(
              key: const ValueKey('layer-search'),
              controller: _searchController,
              hintText: context.l10n.mapLayerSearchHint,
              clearTooltip: context.l10n.cmsClearSearch,
              maxLength: 50,
              onChanged: (value) => setState(() => _query = value.trim()),
              onClear: () => setState(() => _query = ''),
              onSubmitted: (value) => setState(() => _query = value.trim()),
            ),
          ),
          if (state.stale || state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: AppInlineNotice(
                message:
                    state.error?.localizedErrorMessage(context.l10n) ??
                    context.l10n.mapCatalogStale,
                icon: Icons.cloud_off_outlined,
                tone: state.error == null
                    ? AppFeedbackTone.warning
                    : AppFeedbackTone.error,
                actionLabel: context.l10n.commonRetry,
                onAction: controller.load,
                liveRegion: true,
              ),
            ),
          Expanded(
            child: AppStateSwitcher(
              stateKey: ValueKey(
                state.loading && state.layers.isEmpty
                    ? 'layer-catalog-loading'
                    : categories.isEmpty
                    ? 'layer-catalog-empty'
                    : 'layer-catalog-content',
              ),
              animateSize: false,
              child: state.loading && state.layers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      children: [
                        if (categories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: AppInlineNotice(
                              message: context.l10n.mapNoLayersFound,
                              icon: Icons.layers_clear_outlined,
                              tone: AppFeedbackTone.neutral,
                              liveRegion: true,
                            ),
                          )
                        else
                          for (final category in categories.entries)
                            _CategorySection(
                              key: _categoryKeys.putIfAbsent(
                                category.key,
                                GlobalKey.new,
                              ),
                              category: category.key,
                              layers: category.value,
                              state: state,
                              controller: controller,
                              initiallyExpanded:
                                  _expandedByCategory[category.key] ?? false,
                              onExpansionChanged: (expanded) =>
                                  _onCategoryExpanded(category.key, expanded),
                            ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    super.key,
    required this.category,
    required this.layers,
    required this.state,
    required this.controller,
    required this.initiallyExpanded,
    required this.onExpansionChanged,
  });

  final String category;
  final List<LayerModel> layers;
  final MapCatalogState state;
  final MapCatalogController controller;
  final bool initiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      key: ValueKey('map-layer-category-$category-$initiallyExpanded'),
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      leading: const Icon(Icons.folder_copy_outlined),
      title: Text(_categoryLabel(category)),
      subtitle: Text('${layers.length}'),
      children: [
        for (final layer in layers)
          _LayerRow(
            layer: layer,
            state: state,
            controller: controller,
            // Đánh số riêng cho point (chọn icon) và cho line/polygon (chọn
            // màu) trong phạm vi category, để hai layer cùng loại hình học
            // không bao giờ trùng icon/màu với nhau.
            pointIconIndex: layer.isPoint
                ? layers.where((l) => l.isPoint).toList().indexOf(layer)
                : 0,
            colorIndex: layer.isPoint
                ? 0
                : layers.where((l) => !l.isPoint).toList().indexOf(layer),
          ),
      ],
    ),
  );

  String _categoryLabel(String value) {
    if (value.contains(' ') || value.contains('/')) return value;
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

/// Xoay vòng icon cho các layer dạng point — cùng loại hình học nhưng khác
/// icon để phân biệt trực quan thay vì chỉ dựa vào màu (dễ trùng nhau).
const List<IconData> _pointLayerIcons = [
  Icons.place_outlined,
  Icons.location_on_outlined,
  Icons.room_outlined,
  Icons.add_location_alt_outlined,
  Icons.near_me_outlined,
  Icons.pin_drop_outlined,
  Icons.flag_outlined,
  Icons.push_pin_outlined,
];

class _LayerRow extends ConsumerWidget {
  const _LayerRow({
    required this.layer,
    required this.state,
    required this.controller,
    required this.pointIconIndex,
    required this.colorIndex,
  });

  final LayerModel layer;
  final MapCatalogState state;
  final MapCatalogController controller;
  final int pointIconIndex;
  final int colorIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = state.activeLayerIds.contains(layer.id);
    final icon = layer.isPoint
        ? _pointLayerIcons[pointIconIndex % _pointLayerIcons.length]
        : layer.isLine
        ? Icons.timeline
        : Icons.hexagon_outlined;
    // Point phân biệt bằng icon nên giữ màu server/mặc định; line/polygon
    // phân biệt bằng màu nên lấy tuần tự trong bảng màu, đảm bảo không
    // trùng nhau trong cùng một category.
    final color = layer.isPoint
        ? layer.displayColor
        : defaultLayerColorPalette[colorIndex %
              defaultLayerColorPalette.length];
    return Column(
      children: [
        SwitchListTile(
          key: ValueKey('layer-toggle-${layer.id}'),
          value: active,
          onChanged: (value) => controller.setLayerVisible(layer.id, value),
          secondary: Icon(icon, color: color),
          title: Text(layer.nameVi),
          subtitle: Text(layer.code),
        ),
        if (active)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: context.l10n.mapLayerOpacity(
                      (state.opacityOf(layer.id) * 100).round(),
                    ),
                    child: Slider(
                      value: state.opacityOf(layer.id),
                      min: 0.15,
                      max: 1,
                      divisions: 17,
                      label: '${(state.opacityOf(layer.id) * 100).round()}%',
                      onChanged: (value) =>
                          controller.setLayerOpacity(layer.id, value),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.mapLegendAction,
                  onPressed: () => _showLegend(context, ref),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
          ),
        const Divider(),
      ],
    );
  }

  Future<void> _showLegend(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final legend = ref.watch(mapLegendProvider(layer.id));
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
            child: legend.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(error.localizedErrorMessage(context.l10n)),
              ),
              data: (data) {
                final items = getLegendItems(data, layer);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.nameVi.isEmpty ? layer.nameVi : data.nameVi,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty && data.isEmpty)
                      Text(context.l10n.mapLegendEmpty)
                    else
                      Column(
                        children: items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
