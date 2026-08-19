import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../tools/domain/field_tools_controller.dart';
import '../../tools/presentation/map_tool_panel_shell.dart';
import '../domain/route_model.dart';

class RouteSheet extends ConsumerStatefulWidget {
  const RouteSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<RouteSheet> createState() => _RouteSheetState();
}

class _RouteSheetState extends ConsumerState<RouteSheet> {
  bool? _editing;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fieldToolsProvider);
    _editing ??= state.route == null;
    final controller = ref.read(fieldToolsProvider.notifier);
    final l10n = context.l10n;
    final route = state.route;
    final compactResult =
        route != null && _editing == false && state.error == null;
    final locationBlocked = switch (state.locationStatus) {
      LocationStatus.serviceDisabled ||
      LocationStatus.denied ||
      LocationStatus.deniedForever => true,
      _ => false,
    };

    if (compactResult) {
      return MapToolPanelShell(
        key: const ValueKey('route-compact-result'),
        title: l10n.routeTitle,
        icon: Icons.route_outlined,
        compact: true,
        actions: [
          IconButton(
            key: const ValueKey('route-edit'),
            tooltip: l10n.routeSwap,
            onPressed: () {
              controller.editRouteEndpoints();
              setState(() => _editing = true);
            },
            icon: const Icon(Icons.edit_location_alt_outlined),
          ),
          IconButton(
            key: const ValueKey('route-cancel'),
            tooltip: l10n.fieldToolCancel,
            onPressed: () {
              controller.cancelTool();
              widget.onClose();
            },
            icon: const Icon(Icons.close),
          ),
        ],
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (route.steps.isNotEmpty)
              _NextStepCard(
                key: const ValueKey('route-current-instruction'),
                step:
                    route.steps[state.activeRouteStepIndex.clamp(
                      0,
                      route.steps.length - 1,
                    )],
              )
            else
              CompactToolNotice(
                message: l10n.routeInstructionFallback,
                icon: Icons.navigation_outlined,
              ),
            const SizedBox(height: 8),
            _RouteSummary(
              distance: _distance(route.distanceMeters),
              duration: l10n.routeMinutesShort(
                (route.durationSeconds / 60).ceil(),
              ),
            ),
          ],
        ),
      );
    }

    final instruction = state.routeStart == null
        ? l10n.routeStartRequired
        : state.routeEnd == null
        ? l10n.routeEndRequired
        : l10n.routeSelectHint;

    return MapToolPanelShell(
      title: l10n.routeTitle,
      icon: Icons.route_outlined,
      subtitle: instruction,
      actions: [
        IconButton(
          key: const ValueKey('route-cancel'),
          tooltip: l10n.fieldToolCancel,
          onPressed: () {
            controller.cancelTool();
            widget.onClose();
          },
          icon: const Icon(Icons.close),
        ),
      ],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Endpoint(
                  label: l10n.routeStart,
                  selected: state.routeStart != null,
                  icon: Icons.trip_origin,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Endpoint(
                  label: l10n.routeEnd,
                  selected: state.routeEnd != null,
                  icon: Icons.location_on_outlined,
                ),
              ),
              IconButton(
                key: const ValueKey('route-swap'),
                tooltip: l10n.routeSwap,
                onPressed: state.routeStart == null || state.routeEnd == null
                    ? null
                    : controller.swapRouteEndpoints,
                icon: const Icon(Icons.swap_horiz),
              ),
            ],
          ),
          if (locationBlocked) ...[
            const SizedBox(height: 8),
            _LocationRecovery(
              state: state,
              retry: () => _useGps(context, controller),
            ),
          ] else if (state.error case final error?) ...[
            const SizedBox(height: 8),
            CompactToolNotice(
              message: error.localizedErrorMessage(l10n),
              icon: Icons.error_outline,
              isError: true,
            ),
          ] else if (route != null) ...[
            const SizedBox(height: 8),
            _RouteSummary(
              distance: _distance(route.distanceMeters),
              duration: l10n.routeMinutesShort(
                (route.durationSeconds / 60).ceil(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                key: const ValueKey('route-use-gps'),
                onPressed: state.location == null
                    ? () => _useGps(context, controller)
                    : controller.useLocationAsRouteStart,
                icon: state.locationStatus == LocationStatus.locating
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(l10n.routeUseGps),
              ),
              FilledButton.icon(
                key: const ValueKey('route-find'),
                onPressed:
                    state.routeStart == null ||
                        state.routeEnd == null ||
                        state.loading
                    ? null
                    : () async {
                        await controller.findRoute();
                        if (mounted &&
                            ref.read(fieldToolsProvider).route != null) {
                          setState(() => _editing = false);
                        }
                      },
                icon: state.loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.route, size: 18),
                label: Text(l10n.routeFind),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _useGps(
    BuildContext context,
    FieldToolsController controller,
  ) async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) {
      if (context.mounted) {
        await _showLocationRecovery(
          context,
          context.l10n.locationServiceOff,
          geo.Geolocator.openLocationSettings,
        );
      }
      return;
    }
    final permission = await geo.Geolocator.checkPermission();
    if (!context.mounted) return;
    if (permission == geo.LocationPermission.deniedForever) {
      await _showLocationRecovery(
        context,
        context.l10n.locationDeniedForever,
        geo.Geolocator.openAppSettings,
      );
      return;
    }
    if (permission == geo.LocationPermission.denied &&
        !await _confirmLocationPrimer(context)) {
      return;
    }
    await controller.locate();
  }

  Future<bool> _confirmLocationPrimer(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.l10n.locationWeatherTitle),
          content: Text(dialogContext.l10n.locationPrimer),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.l10n.commonContinue),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _showLocationRecovery(
    BuildContext context,
    String message,
    Future<bool> Function() openSettings,
  ) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.locationWeatherTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.locationOpenSettings),
          ),
        ],
      ),
    );
    if (open == true) await openSettings();
  }
}

class _LocationRecovery extends StatelessWidget {
  const _LocationRecovery({required this.state, required this.retry});

  final FieldToolsState state;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = switch (state.locationStatus) {
      LocationStatus.serviceDisabled => l10n.locationServiceOff,
      LocationStatus.deniedForever => l10n.locationDeniedForever,
      _ => l10n.locationDenied,
    };
    return Row(
      children: [
        Expanded(
          child: CompactToolNotice(
            message: message,
            icon: Icons.location_disabled_outlined,
            isError: true,
          ),
        ),
        const SizedBox(width: 6),
        TextButton(
          onPressed: state.locationStatus == LocationStatus.serviceDisabled
              ? geo.Geolocator.openLocationSettings
              : state.locationStatus == LocationStatus.deniedForever
              ? geo.Geolocator.openAppSettings
              : retry,
          child: Text(
            state.locationStatus == LocationStatus.denied
                ? l10n.commonRetry
                : l10n.locationOpenSettings,
          ),
        ),
      ],
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.label,
    required this.selected,
    required this.icon,
  });

  final String label;
  final bool selected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? colors.primaryContainer : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.touch_app_outlined,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({super.key, required this.step});

  final RouteStep step;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_maneuverIcon(step), size: 30, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.instruction,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _distance(step.distanceMeters),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _maneuverIcon(RouteStep step) {
  if (step.maneuverType == 'arrive') return Icons.flag_outlined;
  return switch (step.modifier) {
    'left' || 'slight left' || 'sharp left' => Icons.turn_left,
    'right' || 'slight right' || 'sharp right' => Icons.turn_right,
    'uturn' => Icons.u_turn_left,
    _ => Icons.straight,
  };
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.distance, required this.duration});

  final String distance;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelLarge;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _SummaryItem(
            icon: Icons.alt_route,
            value: distance,
            style: textStyle?.copyWith(fontWeight: FontWeight.w700),
          ),
          _SummaryItem(
            icon: Icons.schedule_outlined,
            value: duration,
            style: textStyle,
          ),
          Text(
            'Mapbox',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.style,
  });

  final IconData icon;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18),
      const SizedBox(width: 7),
      Text(value, style: style),
    ],
  );
}

String _distance(double meters) => meters >= 1000
    ? '${(meters / 1000).toStringAsFixed(1)} km'
    : '${meters.toStringAsFixed(0)} m';
