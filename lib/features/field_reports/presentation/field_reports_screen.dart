import 'dart:math' as math;

import 'package:campha_moblie/app/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../app/router/route_names.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/domain/session_controller.dart';
import '../../shared/presentation/app_feedback.dart';
import '../../tools/domain/field_tools_models.dart';
import '../domain/field_report_models.dart';
import '../domain/field_reports_controller.dart';

class FieldReportsScreen extends ConsumerStatefulWidget {
  const FieldReportsScreen({super.key});
  @override
  ConsumerState<FieldReportsScreen> createState() => _FieldReportsScreenState();
}

class _FieldReportsScreenState extends ConsumerState<FieldReportsScreen>
    with AutomaticKeepAliveClientMixin {
  bool _mapMode = false;
  bool _nearbyPending = false;

  @override
  bool get wantKeepAlive => true;

  List<FieldReport> _effectiveItems(FieldReportsState state) {
    final items = state.filter.nearbyLocation == null
        ? state.items
        : state.nearbyItems;
    final status = state.filter.status;
    return status == null
        ? items
        : items.where((item) => item.status == status).toList(growable: false);
  }

  Future<void> _nearby() async {
    final current = ref.read(fieldReportsProvider).filter;
    final now = DateTime.now().toUtc();
    final selection =
        await showModalBottomSheet<({DateTime from, DateTime to, int radius})>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => _NearbyFilterSheet(
            initialFrom: current.from ?? now.subtract(const Duration(days: 30)),
            initialTo: current.to ?? now,
            initialRadius: current.radiusMeters.clamp(10, 500),
          ),
        );
    if (selection == null || !mounted) return;
    setState(() => _nearbyPending = true);
    try {
      if (!await geo.Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          await _showLocationRecovery(
            context.l10n.locationServiceOff,
            geo.Geolocator.openLocationSettings,
          );
        }
        return;
      }
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        if (!mounted || !await _confirmLocationPrimer()) return;
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.deniedForever) {
        if (mounted) {
          await _showLocationRecovery(
            context.l10n.locationDeniedForever,
            geo.Geolocator.openAppSettings,
          );
        }
        return;
      }
      if (permission == geo.LocationPermission.denied) {
        if (mounted) {
          await _showLocationRecovery(
            context.l10n.locationDenied,
            geo.Geolocator.openAppSettings,
          );
        }
        return;
      }
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      await ref
          .read(fieldReportsProvider.notifier)
          .setNearby(
            location: GeoCoordinate(position.longitude, position.latitude),
            from: selection.from,
            to: selection.to,
            radiusMeters: selection.radius,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.localizedErrorMessage(context.l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _nearbyPending = false);
    }
  }

  Future<bool> _confirmLocationPrimer() async =>
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

  void _openProtected(String path) {
    final authenticated = ref.read(sessionControllerProvider).isAuthenticated;
    context.go(
      authenticated
          ? path
          : '${RoutePaths.login}?returnTo=${Uri.encodeQueryComponent(path)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(fieldReportsProvider);
    final items = _effectiveItems(state);
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('report-create-fab'),
        onPressed: () => _openProtected(RoutePaths.reportCreate),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l10n.reportCreate),
      ),
      body: RefreshIndicator(
        onRefresh: ref.read(fieldReportsProvider.notifier).refresh,
        child: CustomScrollView(
          key: const ValueKey('field-reports-scroll'),
          physics: _mapMode
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 164,
              toolbarHeight: 64,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 20,
              title: Text(
                l10n.reportsTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: colors.onPrimary),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton.filledTonal(
                    key: const ValueKey('my-reports-action'),
                    onPressed: () => _openProtected(RoutePaths.reportMine),
                    tooltip: l10n.myReports,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.onPrimary.withValues(alpha: 0.14),
                      foregroundColor: colors.onPrimary,
                    ),
                    icon: const Icon(Icons.assignment_ind_outlined),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _ReportsHero(
                  appName: l10n.appTitle,
                  subtitle: l10n.reportsSubtitle,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _ReportViewToggle(
                  key: const ValueKey('report-view-segment'),
                  mapMode: _mapMode,
                  listLabel: l10n.reportListView,
                  mapLabel: l10n.reportMapView,
                  onChanged: (value) => setState(() => _mapMode = value),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ReportFilters(
                selected: state.filter.status,
                nearby: state.filter.nearbyLocation != null,
                nearbyLoading:
                    _nearbyPending ||
                    (state.loading && state.filter.nearbyLocation != null),
                onNearby: _nearby,
              ),
            ),
            if (state.filter.nearbyLocation != null)
              SliverToBoxAdapter(
                child: _NearbyFilterEffect(
                  filter: state.filter,
                  loading: state.loading,
                ),
              ),
            if (state.stale)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: AppInlineNotice(
                    icon: Icons.cloud_off_outlined,
                    message: l10n.reportStale,
                    tone: AppFeedbackTone.warning,
                    actionLabel: l10n.commonRetry,
                    onAction: ref.read(fieldReportsProvider.notifier).refresh,
                    liveRegion: true,
                  ),
                ),
              ),
            if (state.loading && items.isEmpty)
              const SliverFillRemaining(child: _ReportLoadingList())
            else if (state.error != null && items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateMessage(
                  icon: Icons.cloud_off_outlined,
                  title: state.error!.localizedErrorMessage(l10n),
                  tone: AppFeedbackTone.error,
                  actionLabel: l10n.commonRetry,
                  onAction: ref.read(fieldReportsProvider.notifier).refresh,
                  liveRegion: true,
                ),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateMessage(
                  icon: Icons.campaign_outlined,
                  title: state.filter.status != null
                      ? l10n.reportFilteredEmpty
                      : l10n.reportPublicEmpty,
                  liveRegion: true,
                ),
              )
            else if (_mapMode)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ReportMap(items: items),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
                sliver: SliverList.builder(
                  itemCount:
                      items.length +
                      (state.filter.nearbyLocation == null && state.hasMore
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      Future.microtask(
                        ref.read(fieldReportsProvider.notifier).loadMore,
                      );
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReportCard(report: items[index]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportsHero extends StatelessWidget {
  const _ReportsHero({required this.appName, required this.subtitle});

  final String appName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentOpacity = ((constraints.maxHeight - 112) / 52).clamp(
          0.0,
          1.0,
        );
        return ColoredBox(
          color: colors.primary,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -18,
                bottom: -32,
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.campaign_outlined,
                    size: 144,
                    color: colors.onPrimary.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 76,
                bottom: 18,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: contentOpacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.onPrimary.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: colors.onPrimary.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: colors.onPrimary,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    appName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: colors.onPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.onPrimary.withValues(alpha: 0.86),
                            height: 1.4,
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
      },
    );
  }
}

class _ReportLoadingList extends StatelessWidget {
  const _ReportLoadingList();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      liveRegion: true,
      label: context.l10n.mapLoading,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBlock(color: color, width: 64, height: 72, radius: 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBlock(
                        color: color,
                        width: 118,
                        height: 13,
                        radius: 99,
                      ),
                      const SizedBox(height: 12),
                      _SkeletonBlock(
                        color: color,
                        width: double.infinity,
                        height: 16,
                        radius: 5,
                      ),
                      const SizedBox(height: 8),
                      _SkeletonBlock(
                        color: color,
                        width: 180,
                        height: 12,
                        radius: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.color,
    required this.width,
    required this.height,
    required this.radius,
  });

  final Color color;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _ReportViewToggle extends StatelessWidget {
  const _ReportViewToggle({
    super.key,
    required this.mapMode,
    required this.listLabel,
    required this.mapLabel,
    required this.onChanged,
  });

  final bool mapMode;
  final String listLabel;
  final String mapLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _ReportViewOption(
                selected: !mapMode,
                icon: Icons.view_agenda_outlined,
                label: listLabel,
                onTap: () => onChanged(false),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _ReportViewOption(
                selected: mapMode,
                icon: Icons.map_outlined,
                label: mapLabel,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportViewOption extends StatelessWidget {
  const _ReportViewOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final foreground = selected
        ? (isLight ? colors.onPrimaryFixedVariant : colors.primary)
        : colors.onSurfaceVariant;
    final background = selected
        ? (isLight
              ? colors.surfaceContainerLowest
              : colors.primary.withValues(alpha: 0.14))
        : Colors.transparent;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.state),
        curve: AppMotion.stateCurve,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? colors.outlineVariant : Colors.transparent,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportFilters extends ConsumerWidget {
  const _ReportFilters({
    this.selected,
    required this.nearby,
    required this.nearbyLoading,
    required this.onNearby,
  });
  final String? selected;
  final bool nearby;
  final bool nearbyLoading;
  final VoidCallback onNearby;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statuses = <String?, String>{
      null: l10n.reportStatusAll,
      'approved': l10n.reportStatusApproved,
      'resolved': l10n.reportStatusResolved,
    };
    return SizedBox(
      height: 52,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        scrollDirection: Axis.horizontal,
        children: [
          ...statuses.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: ValueKey('report-status-${entry.key ?? 'all'}'),
                selected: selected == entry.key,
                onSelected: (_) => ref
                    .read(fieldReportsProvider.notifier)
                    .setStatus(entry.key),
                label: Text(entry.value),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              key: const ValueKey('report-nearby-filter'),
              selected: nearby,
              avatar: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.state),
                child: nearbyLoading
                    ? const SizedBox(
                        key: ValueKey('report-nearby-loading'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        nearby
                            ? Icons.my_location_outlined
                            : Icons.near_me_outlined,
                        key: ValueKey('report-nearby-icon-$nearby'),
                        size: 18,
                      ),
              ),
              onSelected: (_) => nearby
                  ? ref.read(fieldReportsProvider.notifier).clearNearby()
                  : onNearby(),
              label: Text(context.l10n.reportNearby30Days),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyFilterEffect extends StatelessWidget {
  const _NearbyFilterEffect({required this.filter, required this.loading});

  final ReportFilter filter;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final from = filter.from?.toLocal();
    final to = filter.to?.toLocal();
    final dateRange = from == null || to == null
        ? null
        : '${from.day}/${from.month}/${from.year} – '
              '${to.day}/${to.month}/${to.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Semantics(
        liveRegion: true,
        child: TweenAnimationBuilder<double>(
          duration: AppMotion.of(context, AppMotion.surface),
          curve: AppMotion.surfaceCurve,
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: child,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: loading
                        ? Padding(
                            padding: const EdgeInsets.all(9),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          )
                        : Icon(
                            Icons.my_location_outlined,
                            color: colors.onPrimaryContainer,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.reportNearby30Days,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            ?dateRange,
                            context.l10n.reportNearbyRadius(
                              filter.radiusMeters,
                            ),
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.onPrimaryContainer.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NearbyFilterSheet extends StatefulWidget {
  const _NearbyFilterSheet({
    required this.initialFrom,
    required this.initialTo,
    required this.initialRadius,
  });
  final DateTime initialFrom;
  final DateTime initialTo;
  final int initialRadius;

  @override
  State<_NearbyFilterSheet> createState() => _NearbyFilterSheetState();
}

class _NearbyFilterSheetState extends State<_NearbyFilterSheet> {
  late DateTimeRange _range;
  late double _radius;

  @override
  void initState() {
    super.initState();
    _range = DateTimeRange(start: widget.initialFrom, end: widget.initialTo);
    _radius = widget.initialRadius.toDouble();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: _range.start.toLocal(),
        end: _range.end.toLocal(),
      ),
    );
    if (picked != null) setState(() => _range = picked);
  }

  void _apply() {
    final from = DateTime.utc(
      _range.start.year,
      _range.start.month,
      _range.start.day,
    );
    final to = DateTime.utc(
      _range.end.year,
      _range.end.month,
      _range.end.day,
      23,
      59,
      59,
    );
    if (!to.isAfter(from) || to.difference(from) > const Duration(days: 366)) {
      return;
    }
    Navigator.pop(context, (
      from: from,
      to: to,
      radius: _radius.round().clamp(10, 500),
    ));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.reportNearbyFilterTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ListTile(
            key: const ValueKey('report-nearby-date-range'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.date_range_outlined),
            title: Text(context.l10n.reportNearbyDateRange),
            subtitle: Text(
              '${_range.start.day}/${_range.start.month}/${_range.start.year} – '
              '${_range.end.day}/${_range.end.month}/${_range.end.year}',
            ),
            onTap: _pickRange,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.reportNearbyRadius(_radius.round()),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            key: const ValueKey('report-nearby-radius'),
            value: _radius,
            min: 10,
            max: 500,
            divisions: 49,
            label: '${_radius.round()} m',
            onChanged: (value) => setState(() => _radius = value),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('report-nearby-apply'),
            onPressed: _apply,
            icon: const Icon(Icons.near_me_outlined),
            label: Text(context.l10n.reportNearbyApply),
          ),
        ],
      ),
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final FieldReport report;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label:
          '${report.referenceCode}, ${_status(context, report.status)}, ${report.description}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('report-card-${report.id}'),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (context) => _PublicReportSheet(report: report),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_camera_back_outlined,
                        color: colors.onPrimaryContainer,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report.photoCount}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              report.referenceCode,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: colors.primary),
                            ),
                          ),
                          _StatusPill(status: report.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _relative(report.createdAt, l10n),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (report.distanceMeters != null) ...[
                            const SizedBox(width: 14),
                            Icon(
                              Icons.near_me_outlined,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${report.distanceMeters!.round()} m',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicReportSheet extends StatelessWidget {
  const _PublicReportSheet({required this.report});
  final FieldReport report;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                report.referenceCode,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            _StatusPill(status: report.status),
          ],
        ),
        const SizedBox(height: 18),
        Text(report.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(context.l10n.reportPhotos),
          subtitle: Text('${report.photoCount}'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.place_outlined),
          title: Text(context.l10n.reportLocationStep),
          subtitle: Text(
            '${report.location.latitude.toStringAsFixed(5)}, ${report.location.longitude.toStringAsFixed(5)}',
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule_outlined),
          title: Text(_relative(report.createdAt, context.l10n)),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolved = status == 'resolved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: resolved ? colors.secondaryContainer : colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _status(context, status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: resolved
              ? colors.onSecondaryContainer
              : colors.onTertiaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReportMap extends StatefulWidget {
  const _ReportMap({required this.items});
  final List<FieldReport> items;
  @override
  State<_ReportMap> createState() => _ReportMapState();
}

class _ReportMapState extends State<_ReportMap> {
  CircleAnnotationManager? _manager;
  MapboxMap? _map;
  String? _fittedReportSignature;
  final _reportsByAnnotationId = <String, FieldReport>{};

  ({Point center, double zoom}) _viewportForReports() {
    assert(widget.items.isNotEmpty);
    var minLongitude = widget.items.first.location.longitude;
    var maxLongitude = minLongitude;
    var minLatitude = widget.items.first.location.latitude;
    var maxLatitude = minLatitude;
    for (final report in widget.items.skip(1)) {
      minLongitude = math.min(minLongitude, report.location.longitude);
      maxLongitude = math.max(maxLongitude, report.location.longitude);
      minLatitude = math.min(minLatitude, report.location.latitude);
      maxLatitude = math.max(maxLatitude, report.location.latitude);
    }

    final latitude = (minLatitude + maxLatitude) / 2;
    final longitude = (minLongitude + maxLongitude) / 2;
    final longitudeSpan =
        (maxLongitude - minLongitude).abs() *
        math.cos(latitude * math.pi / 180);
    final span = math
        .max(longitudeSpan, (maxLatitude - minLatitude).abs())
        .clamp(0.0035, 1)
        .toDouble();
    final zoom = (math.log(360 / span) / math.ln2 - 1.25)
        .clamp(10.5, 15.5)
        .toDouble();
    return (
      center: Point(coordinates: Position(longitude, latitude)),
      zoom: zoom,
    );
  }

  String get _reportSignature => widget.items
      .map(
        (report) =>
            '${report.id}:${report.location.longitude}:${report.location.latitude}',
      )
      .join('|');

  void _openReportFromAnnotation(CircleAnnotation annotation) {
    final report = _reportsByAnnotationId[annotation.id];
    if (report == null || !mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _PublicReportSheet(report: report),
    );
  }

  Future<void> _render() async {
    final manager = _manager;
    if (manager == null) return;
    final reports = List<FieldReport>.unmodifiable(widget.items);
    await manager.deleteAll();
    final annotations = await manager.createMulti(
      reports
          .map(
            (report) => CircleAnnotationOptions(
              geometry: Point(
                coordinates: Position(
                  report.location.longitude,
                  report.location.latitude,
                ),
              ),
              circleRadius: 10,
              circleColor: report.status == 'resolved'
                  ? 0xFF2D6A4F
                  : 0xFFD97745,
              circleStrokeWidth: 3,
              circleStrokeColor: 0xFFFFFFFF,
            ),
          )
          .toList(growable: false),
    );
    if (!mounted || !identical(manager, _manager)) return;
    _reportsByAnnotationId.clear();
    for (final entry in annotations.indexed) {
      final annotation = entry.$2;
      if (annotation != null) {
        _reportsByAnnotationId[annotation.id] = reports[entry.$1];
      }
    }
    final map = _map;
    final signature = _reportSignature;
    if (map != null && _fittedReportSignature != signature) {
      _fittedReportSignature = signature;
      final viewport = _viewportForReports();
      await map.flyTo(
        CameraOptions(center: viewport.center, zoom: viewport.zoom),
        MapAnimationOptions(duration: AppMotion.camera(context)),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _ReportMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) _render();
  }

  ViewportState? _initialViewport;

  @override
  Widget build(BuildContext context) {
    final viewport = _viewportForReports();
    _initialViewport ??= CameraViewportState(
      center: viewport.center,
      zoom: viewport.zoom,
    );
    return MapWidget(
      key: const ValueKey('reports-map'),
      viewport: _initialViewport,
      onMapCreated: (map) async {
        _map = map;
        await map.setBounds(
          CameraBoundsOptions(
            bounds: CoordinateBounds(
              southwest: Point(coordinates: Position(106.3, 20.5)),
              northeast: Point(coordinates: Position(108.5, 21.7)),
              infiniteBounds: false,
            ),
            minZoom: 6.5,
            maxZoom: 20.0,
          ),
        );
        await map.gestures.updateSettings(
          GesturesSettings(
            scrollEnabled: true,
            pinchToZoomEnabled: true,
            doubleTapToZoomInEnabled: true,
            doubleTouchToZoomOutEnabled: true,
            quickZoomEnabled: true,
          ),
        );
        final manager = await map.annotations.createCircleAnnotationManager();
        if (!mounted) return;
        manager.tapEvents(onTap: _openReportFromAnnotation);
        _manager = manager;
        await _render();
      },
    );
  }
}

String _status(BuildContext context, String status) => switch (status) {
  'pending' => context.l10n.reportStatusPending,
  'under_review' => context.l10n.reportStatusReview,
  'approved' => context.l10n.reportStatusApproved,
  'rejected' => context.l10n.reportStatusRejected,
  'resolved' => context.l10n.reportStatusResolved,
  _ => status,
};

String _relative(DateTime date, dynamic l10n) {
  final difference = DateTime.now().difference(date.toLocal());
  if (difference.inDays > 0) return l10n.reportDaysAgo(difference.inDays);
  if (difference.inHours > 0) return l10n.reportHoursAgo(difference.inHours);
  return l10n.reportMinutesAgo(difference.inMinutes.clamp(1, 59));
}
