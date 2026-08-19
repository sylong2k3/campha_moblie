import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_config.dart';
import '../domain/field_tools_controller.dart';

class LocationWeatherSheet extends ConsumerWidget {
  const LocationWeatherSheet({super.key, required this.layerId});

  final String? layerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fieldToolsProvider);
    final controller = ref.read(fieldToolsProvider.notifier);
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.42,
      minChildSize: 0.28,
      maxChildSize: 0.9,
      builder: (context, scroll) => Material(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 21,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.locationWeatherTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        l10n.locationPrimer,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.locationStatus == LocationStatus.idle)
              FilledButton.icon(
                key: const ValueKey('location-start'),
                onPressed: controller.locate,
                icon: const Icon(Icons.gps_fixed),
                label: Text(l10n.locationStart),
              )
            else if (state.locationStatus == LocationStatus.locating)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.locationStatus == LocationStatus.ready ||
                state.locationStatus == LocationStatus.outsideBounds)
              _LocationCard(state: state)
            else
              _PermissionState(
                status: state.locationStatus,
                onRetry: controller.locate,
              ),
            if (state.error case final error?) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: Text(error.localizedErrorMessage(l10n)),
                ),
              ),
            ],
            if (state.locationStatus == LocationStatus.ready) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                key: const ValueKey('weather-nearby-load'),
                onPressed: state.loading
                    ? null
                    : () => controller.loadWeatherAndNearby(layerId),
                icon: const Icon(Icons.cloud_sync_outlined),
                label: Text(l10n.nearbyTitle),
              ),
            ],
            if (state.weather case final weather?) ...[
              const SizedBox(height: 18),
              Text(
                l10n.weatherTemperature,
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
            if (state.weather != null || state.nearby.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                l10n.nearbyTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (state.nearby.isEmpty)
                Text(l10n.nearbyEmpty)
              else
                ...state.nearby.map(
                  (item) => Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.near_me_outlined),
                      ),
                      title: Text(item.label),
                      subtitle: Text(
                        l10n.nearbyDistance(
                          item.distanceMeters.toStringAsFixed(1),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(context, item.featureId),
                    ),
                  ),
                ),
            ],
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
    return Card(
      color: outside
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${coordinate.latitude.toStringAsFixed(6)}, ${coordinate.longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.titleMedium,
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
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(accuracyLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionState extends StatelessWidget {
  const _PermissionState({required this.status, required this.onRetry});
  final LocationStatus status;
  final VoidCallback onRetry;

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
              onPressed: permanent
                  ? Geolocator.openAppSettings
                  : status == LocationStatus.serviceDisabled
                  ? Geolocator.openLocationSettings
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
          Icon(icon, color: colors.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colors.onSurface),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}
