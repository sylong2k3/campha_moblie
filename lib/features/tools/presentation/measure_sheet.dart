import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final requirement = isArea
        ? l10n.measureAreaRequired
        : l10n.measureDistanceRequired;

    return MapToolPanelShell(
      title: l10n.measureTitle,
      subtitle: state.measurement == null ? l10n.measureTapHint : null,
      icon: Icons.straighten,
      compact: state.measurement != null,
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
                      icon: const Icon(Icons.straighten, size: 17),
                      label: Text(l10n.measureDistance),
                    ),
                    ButtonSegment(
                      value: FieldToolMode.measureArea,
                      icon: const Icon(Icons.crop_square, size: 17),
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
              const SizedBox(width: 6),
              IconButton(
                tooltip: l10n.measureUndo,
                onPressed: state.vertices.isEmpty ? null : controller.undo,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                tooltip: l10n.measureRedo,
                onPressed: state.redoVertices.isEmpty ? null : controller.redo,
                icon: const Icon(Icons.redo),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.error case final error?)
            CompactToolNotice(
              message: error.localizedErrorMessage(l10n),
              icon: Icons.error_outline,
              isError: true,
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gesture, size: 19),
                  const SizedBox(width: 8),
                  Text(l10n.measurePointCount(state.vertices.length)),
                  if (state.measurement case final measurement?) ...[
                    const Spacer(),
                    Text(
                      measurement.formattedMetricValue,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ],
              ),
            ),
            if (state.measurement == null) ...[
              const SizedBox(height: 6),
              CompactToolNotice(
                message: requirement,
                icon: Icons.touch_app_outlined,
              ),
            ],
          ],
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              key: const ValueKey('measure-complete'),
              onPressed: state.canMeasure && !state.loading
                  ? controller.completeMeasure
                  : null,
              icon: state.loading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(l10n.measureComplete),
            ),
          ),
        ],
      ),
    );
  }
}
