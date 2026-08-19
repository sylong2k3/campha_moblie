import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';

class MapToolDraggableSheet extends StatelessWidget {
  const MapToolDraggableSheet({
    super.key,
    required this.child,
    required this.initialChildSize,
    required this.maxChildSize,
  }) : assert(
         initialChildSize >= minChildSize &&
             initialChildSize <= maxChildSize &&
             maxChildSize <= 1,
         'Sheet sizes must satisfy min <= initial <= max <= 1.',
       );

  static const minChildSize = 0.14;

  final Widget child;
  final double initialChildSize;
  final double maxChildSize;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    key: const ValueKey('map-tool-draggable-sheet'),
    initialChildSize: initialChildSize,
    minChildSize: minChildSize,
    maxChildSize: maxChildSize,
    snap: true,
    snapSizes: [minChildSize, maxChildSize],
    builder: (context, scrollController) => Material(
      key: const ValueKey('map-tool-draggable-surface'),
      elevation: 8,
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
      color: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [const _MapToolSheetDragHandle(), child],
      ),
    ),
  );
}

class _MapToolSheetDragHandle extends StatelessWidget {
  const _MapToolSheetDragHandle();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.fieldToolSheetDragHint,
    child: Padding(
      key: const ValueKey('map-tool-sheet-drag-handle'),
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Center(
        child: Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    ),
  );
}

class MapToolPanelShell extends StatelessWidget {
  const MapToolPanelShell({
    super.key,
    required this.title,
    required this.icon,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, compact ? 8 : 10, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subtitle case final value?)
                        Text(
                          value,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
            SizedBox(height: compact ? 8 : 10),
            body,
          ],
        ),
      ),
    );
  }
}

class CompactToolNotice extends StatelessWidget {
  const CompactToolNotice({
    super.key,
    required this.message,
    required this.icon,
    this.isError = false,
  });

  final String message;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isError
        ? colors.errorContainer
        : colors.surfaceContainer;
    final foreground = isError
        ? colors.onErrorContainer
        : colors.onSurfaceVariant;
    return Semantics(
      liveRegion: isError,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
