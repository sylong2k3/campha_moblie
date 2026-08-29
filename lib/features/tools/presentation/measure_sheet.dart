import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../domain/field_tools_controller.dart';
import 'map_tool_panel_shell.dart';

class MeasureSheet extends ConsumerWidget {
  const MeasureSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fieldToolsProvider);
    final controller = ref.read(fieldToolsProvider.notifier);
    final l10n = context.l10n;
    final isArea = state.mode == FieldToolMode.measureArea;
    final colors = Theme.of(context).colorScheme;
    final measurement = state.measurement;
    final requirement = isArea
        ? l10n.measureAreaRequired
        : l10n.measureDistanceRequired;

    return MapToolPanelShell(
      title: l10n.measureTitle,
      subtitle: measurement == null ? l10n.measureTapHint : null,
      icon: Icons.straighten_rounded,
      compact: measurement != null,
      actions: [
        IconButton(
          tooltip: l10n.fieldToolCancel,
          onPressed: () {
            controller.cancelTool();
            onClose();
          },
          icon: const Icon(Icons.close),
        ),
      ],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<FieldToolMode>(
                  segments: [
                    ButtonSegment(
                      value: FieldToolMode.measureDistance,
                      icon: const Icon(Icons.straighten_rounded, size: 18),
                      label: Text(l10n.measureDistance),
                    ),
                    ButtonSegment(
                      value: FieldToolMode.measureArea,
                      icon: const Icon(Icons.crop_square_rounded, size: 18),
                      label: Text(l10n.measureArea),
                    ),
                  ],
                  selected: {
                    isArea
                        ? FieldToolMode.measureArea
                        : FieldToolMode.measureDistance,
                  },
                  showSelectedIcon: false,
                  onSelectionChanged: (value) => controller.startMeasure(
                    area: value.first == FieldToolMode.measureArea,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                tooltip: l10n.measureUndo,
                onPressed: state.vertices.isEmpty ? null : controller.undo,
                icon: const Icon(Icons.undo_rounded),
              ),
              const SizedBox(width: 2),
              IconButton.filledTonal(
                tooltip: l10n.measureRedo,
                onPressed: state.redoVertices.isEmpty ? null : controller.redo,
                icon: const Icon(Icons.redo_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.state),
            transitionBuilder: AppMotion.stateTransition,
            child: state.error != null
                ? CompactToolNotice(
                    key: const ValueKey('measure-error'),
                    message: state.error!.localizedErrorMessage(l10n),
                    icon: Icons.error_outline,
                    isError: true,
                  )
                : measurement == null
                ? CompactToolNotice(
                    key: const ValueKey('measure-guidance'),
                    message: requirement,
                    icon: Icons.touch_app_outlined,
                  )
                : Semantics(
                    key: const ValueKey('measure-live-result'),
                    liveRegion: true,
                    label: measurement.formattedMetricValue,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              isArea
                                  ? Icons.select_all_rounded
                                  : Icons.route_rounded,
                              size: 20,
                              color: colors.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  measurement.formattedMetricValue,
                                  key: const ValueKey('measure-result-value'),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: colors.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                ),
                                Text(
                                  l10n.measurePointCount(state.vertices.length),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.onPrimaryContainer
                                            .withValues(alpha: 0.78),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: AppMotion.of(context, AppMotion.quick),
                            child: state.loading
                                ? SizedBox.square(
                                    key: const ValueKey(
                                      'measure-result-loading',
                                    ),
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      color: colors.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.check_circle_rounded,
                                    key: const ValueKey(
                                      'measure-result-official',
                                    ),
                                    color: colors.primary,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
