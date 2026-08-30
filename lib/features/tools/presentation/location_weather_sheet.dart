import 'dart:math' as math;

import 'package:campha_moblie/app/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_config.dart';
import '../../shared/presentation/app_feedback.dart';
import '../domain/field_tools_controller.dart';
import '../domain/field_tools_models.dart';

class LocationWeatherSheet extends ConsumerStatefulWidget {
  const LocationWeatherSheet({super.key, this.layerId});

  final String? layerId;

  @override
  ConsumerState<LocationWeatherSheet> createState() =>
      _LocationWeatherSheetState();
}

class _LocationWeatherSheetState extends ConsumerState<LocationWeatherSheet>
    with WidgetsBindingObserver {
  bool _openedSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _retryAfterSettings() async {
    if (!_openedSettings) return;
    _openedSettings = false;
    await ref.read(fieldToolsProvider.notifier).locate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _retryAfterSettings();
  }

  Future<void> _openSettings(LocationStatus status) async {
    _openedSettings = true;
    final opened = status == LocationStatus.deniedForever
        ? await Geolocator.openAppSettings()
        : await Geolocator.openLocationSettings();
    if (!opened) _openedSettings = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fieldToolsProvider);
    final controller = ref.read(fieldToolsProvider.notifier);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final locationState = switch (state.locationStatus) {
      LocationStatus.idle => FilledButton.icon(
        key: const ValueKey('location-start'),
        onPressed: controller.locate,
        icon: const Icon(Icons.gps_fixed),
        label: Text(l10n.locationStart),
      ),
      LocationStatus.locating => _LocationLoading(label: l10n.locationLocating),
      LocationStatus.ready ||
      LocationStatus.outsideBounds => _LocationCard(state: state),
      _ => _PermissionState(
        status: state.locationStatus,
        onRetry: controller.locate,
        onOpenSettings: () => _openSettings(state.locationStatus),
      ),
    };

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.46,
      minChildSize: 0.28,
      maxChildSize: 0.92,
      builder: (context, scroll) => Material(
        color: colors.surfaceContainerLowest,
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.cloud_outlined,
                    size: 22,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.locationWeatherTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.locationPrimer,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppStateSwitcher(
              key: const ValueKey('location-state-switcher'),
              stateKey: ValueKey('location-state-${state.locationStatus.name}'),
              child: locationState,
            ),
            AppStateSwitcher(
              stateKey: ValueKey(
                state.error == null ? 'location-error-empty' : 'location-error',
              ),
              child: state.error != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AppInlineNotice(
                        message: state.error!.localizedErrorMessage(l10n),
                        icon: Icons.cloud_off_outlined,
                        tone: AppFeedbackTone.error,
                        liveRegion: true,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (state.locationStatus == LocationStatus.ready) ...[
              const SizedBox(height: 14),
              if (state.weather == null)
                FilledButton.tonalIcon(
                  key: const ValueKey('weather-nearby-load'),
                  onPressed: state.loading ? null : controller.loadWeather,
                  icon: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.quick),
                    child: state.loading
                        ? const SizedBox.square(
                            key: ValueKey('weather-load-progress'),
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.cloud_sync_outlined,
                            key: ValueKey('weather-load-icon'),
                          ),
                  ),
                  label: const Text('Xem thời tiết hiện tại'),
                )
              else
                ModernWeatherCard(
                  weather: state.weather!,
                  onRefresh: controller.loadWeather,
                  isRefreshing: state.loading,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thẻ hiển thị thời tiết hiện đại, thanh lịch và có tính tái sử dụng cao.
class ModernWeatherCard extends StatelessWidget {
  const ModernWeatherCard({
    super.key,
    required this.weather,
    this.onRefresh,
    this.isRefreshing = false,
  });

  final WeatherSnapshot weather;
  final VoidCallback? onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final iconData = _getWeatherIcon(weather.description);
    final windDirection = _getWindDirection(weather.windDirectionDegrees);
    final windScale = _getWindSpeedScale(weather.windSpeedMps);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colors.surfaceContainerHigh,
                  colors.surfaceContainer,
                ]
              : [
                  colors.primaryContainer.withValues(alpha: 0.4),
                  colors.surfaceContainerLowest,
                ],
        ),
        border: Border.all(
          color: isDark
              ? colors.outlineVariant.withValues(alpha: 0.6)
              : colors.primary.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Location Badge & Refresh button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.place_rounded,
                      size: 15,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      weather.location.isNotEmpty ? weather.location : 'Cẩm Phả',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (onRefresh != null)
                IconButton(
                  onPressed: isRefreshing ? null : onRefresh,
                  tooltip: 'Cập nhật lại thời tiết',
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainer,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  icon: isRefreshing
                      ? SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Hero: Temperature & Dynamic Weather Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather.temperatureC.toStringAsFixed(1),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 2),
                          child: Text(
                            '°C',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (weather.description != null &&
                        weather.description!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colors.surfaceContainerHighest
                              : colors.secondaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          weather.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? colors.onSurface
                                : colors.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Weather Art Icon Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryContainer.withValues(alpha: 0.65),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  iconData,
                  size: 34,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colors.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),

          // Sub-metrics Grid (Tốc độ gió, Hướng gió)
          Row(
            children: [
              Expanded(
                child: _WeatherMetricTile(
                  icon: Icons.air_rounded,
                  label: 'Tốc độ gió',
                  value: '${weather.windSpeedMps.toStringAsFixed(1)} m/s',
                  subtitle: windScale,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WeatherMetricTile(
                  icon: Icons.explore_rounded,
                  label: 'Hướng gió',
                  value: '${weather.windDirectionDegrees}°',
                  subtitle: windDirection,
                  iconRotation: weather.windDirectionDegrees,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Footer timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: colors.onSurfaceVariant.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 4),
              Text(
                'Cập nhật: ${_formatObservedTime(weather.observedAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherMetricTile extends StatelessWidget {
  const _WeatherMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.iconRotation,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final int? iconRotation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceContainerLowest
            : colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconRotation != null)
                Transform.rotate(
                  angle: iconRotation! * math.pi / 180,
                  child: Icon(icon, size: 16, color: colors.primary),
                )
              else
                Icon(icon, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationLoading extends StatelessWidget {
  const _LocationLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.state});
  final FieldToolsState state;

  @override
  Widget build(BuildContext context) {
    final coordinate = state.location!;
    final outside = state.locationStatus == LocationStatus.outsideBounds;
    final accuracy = state.accuracyMeters;
    final lowAccuracy =
        accuracy != null && accuracy > ApiConfig.gpsAccuracyThresholdM;
    final accuracyLabel = accuracy == null
        ? context.l10n.locationAccuracyUnavailable
        : lowAccuracy
        ? context.l10n.locationAccuracyLow(accuracy.toStringAsFixed(1))
        : context.l10n.locationAccuracy(accuracy.toStringAsFixed(1));
    final colors = Theme.of(context).colorScheme;
    final statusColor = outside || lowAccuracy
        ? colors.error
        : accuracy == null
        ? colors.onSurfaceVariant
        : colors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: outside ? colors.errorContainer : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: outside
              ? colors.error.withValues(alpha: 0.35)
              : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${coordinate.latitude.toStringAsFixed(6)}, ${coordinate.longitude.toStringAsFixed(6)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (outside) ...[
            const SizedBox(height: 6),
            Text(context.l10n.locationOutsideBounds),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                lowAccuracy
                    ? Icons.warning_amber_rounded
                    : accuracy == null
                    ? Icons.help_outline
                    : Icons.gps_fixed,
                size: 18,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  accuracyLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: lowAccuracy ? colors.error : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionState extends StatelessWidget {
  const _PermissionState({
    required this.status,
    required this.onRetry,
    required this.onOpenSettings,
  });
  final LocationStatus status;
  final VoidCallback onRetry;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final permanent = status == LocationStatus.deniedForever;
    final message = switch (status) {
      LocationStatus.serviceDisabled => context.l10n.locationServiceOff,
      LocationStatus.deniedForever => context.l10n.locationDeniedForever,
      _ => context.l10n.locationDenied,
    };
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.location_disabled_outlined, size: 36),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: permanent || status == LocationStatus.serviceDisabled
                  ? onOpenSettings
                  : onRetry,
              child: Text(
                permanent || status == LocationStatus.serviceDisabled
                    ? context.l10n.locationOpenSettings
                    : context.l10n.commonRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Utilities ────────────────────────────────────────────────────────

IconData _getWeatherIcon(String? description) {
  final text = (description ?? '').toLowerCase();
  if (text.contains('dông') || text.contains('sấm') || text.contains('storm')) {
    return Icons.thunderstorm_rounded;
  }
  if (text.contains('mưa') || text.contains('rain') || text.contains('drizzle')) {
    return Icons.grain_rounded;
  }
  if (text.contains('mây') || text.contains('cloud') || text.contains('u ám')) {
    if (text.contains('ít') || text.contains('nắng')) {
      return Icons.wb_cloudy_rounded;
    }
    return Icons.cloud_rounded;
  }
  if (text.contains('nắng') ||
      text.contains('quang') ||
      text.contains('clear') ||
      text.contains('sun')) {
    return Icons.wb_sunny_rounded;
  }
  if (text.contains('sương') || text.contains('fog') || text.contains('mist')) {
    return Icons.foggy;
  }
  return Icons.wb_cloudy_rounded;
}

String _getWindDirection(int degrees) {
  final normalized = (degrees % 360 + 360) % 360;
  if (normalized >= 337.5 || normalized < 22.5) return 'Bắc (N)';
  if (normalized >= 22.5 && normalized < 67.5) return 'Đông Bắc (NE)';
  if (normalized >= 67.5 && normalized < 112.5) return 'Đông (E)';
  if (normalized >= 112.5 && normalized < 157.5) return 'Đông Nam (SE)';
  if (normalized >= 157.5 && normalized < 202.5) return 'Nam (S)';
  if (normalized >= 202.5 && normalized < 247.5) return 'Tây Nam (SW)';
  if (normalized >= 247.5 && normalized < 292.5) return 'Tây (W)';
  return 'Tây Bắc (NW)';
}

String _getWindSpeedScale(double speedMps) {
  if (speedMps < 0.3) return 'Lặng gió';
  if (speedMps < 1.6) return 'Gió nhẹ';
  if (speedMps < 3.4) return 'Gió hiu hiu';
  if (speedMps < 5.5) return 'Gió nhẹ';
  if (speedMps < 8.0) return 'Gió vừa';
  if (speedMps < 10.8) return 'Gió khá mạnh';
  if (speedMps < 13.9) return 'Gió mạnh';
  return 'Gió rất mạnh';
}

String _formatObservedTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;
  return '$hour:$minute · $day/$month/$year';
}

