import 'package:campha_moblie/app/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_config.dart';
import '../../shared/presentation/app_feedback.dart';
import '../domain/field_tools_controller.dart';

class LocationWeatherSheet extends ConsumerStatefulWidget {
  const LocationWeatherSheet({super.key, required this.layerId});

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
      initialChildSize: 0.42,
      minChildSize: 0.28,
      maxChildSize: 0.9,
      builder: (context, scroll) => Material(
        color: colors.surfaceContainerLowest,
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
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
                    Icons.location_on_outlined,
                    size: 21,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
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
            const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                key: const ValueKey('weather-nearby-load'),
                onPressed: state.loading
                    ? null
                    : () => controller.loadWeatherAndNearby(widget.layerId),
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
                label: Text(l10n.nearbyTitle),
              ),
            ],
            AppStateSwitcher(
              stateKey: ValueKey(
                state.weather == null && state.nearby.isEmpty
                    ? 'weather-results-empty'
                    : 'weather-results',
              ),
              child: state.weather == null && state.nearby.isEmpty
                  ? const SizedBox.shrink()
                  : _WeatherResults(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherResults extends StatelessWidget {
  const _WeatherResults({required this.state});

  final FieldToolsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.weather case final weather?) ...[
          const SizedBox(height: 18),
          Text(l10n.weatherTemperature, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.thermostat,
                  value: '${weather.temperatureC.toStringAsFixed(1)} °C',
                  label: weather.description ?? l10n.weatherTemperature,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  icon: Icons.air,
                  value: '${weather.windSpeedMps.toStringAsFixed(1)} m/s',
                  label: l10n.weatherWind,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        Text(l10n.nearbyTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (state.nearby.isEmpty)
          Text(
            l10n.nearbyEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...state.nearby.map(
            (item) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.near_me_outlined),
                ),
                title: Text(item.label),
                subtitle: Text(
                  l10n.nearbyDistance(item.distanceMeters.toStringAsFixed(1)),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, item.featureId),
              ),
            ),
          ),
      ],
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

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
