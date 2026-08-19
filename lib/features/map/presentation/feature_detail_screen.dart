import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router/route_names.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/domain/session_controller.dart';
import '../../cms/presentation/cms_widgets.dart';
import '../data/map_repository.dart';
import '../domain/feature_detail_model.dart';
import '../domain/map_controller.dart';

final mapFeatureProvider = FutureProvider.autoDispose
    .family<FeatureDetailModel, ({String layerId, String featureId})>((
      ref,
      key,
    ) async {
      ref.watch(
        sessionControllerProvider.select((session) => session.user?.id),
      );
      return ref
          .read(mapRepositoryProvider)
          .getFeatureDetail(key.layerId, key.featureId);
    });

class FeatureDetailScreen extends ConsumerWidget {
  const FeatureDetailScreen({
    super.key,
    required this.layerId,
    required this.featureId,
  });

  final String layerId;
  final String featureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (layerId: layerId, featureId: featureId);
    final feature = ref.watch(mapFeatureProvider(key));
    final user = ref.watch(sessionControllerProvider).user;
    final layer = ref
        .watch(mapCatalogProvider)
        .layers
        .where((item) => item.id == layerId)
        .firstOrNull;
    final editable =
        user?.roleCode == 'so_tnmt' &&
        user!.hasPermission('map_feature', 'update') &&
        layer?.canEdit == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.mapFeatureTitle),
        actions: [
          if (editable) ...[
            IconButton(
              key: const ValueKey('feature-history-action'),
              tooltip: context.l10n.featureHistoryTitle,
              onPressed: () =>
                  context.go(RoutePaths.mapFeatureHistory(layerId, featureId)),
              icon: const Icon(Icons.history),
            ),
            IconButton(
              key: const ValueKey('feature-edit-action'),
              tooltip: context.l10n.featureEditTitle,
              onPressed: feature.valueOrNull?.version == null
                  ? null
                  : () => context.go(
                      RoutePaths.mapFeatureEdit(layerId, featureId),
                    ),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
          IconButton(
            tooltip: context.l10n.cmsShare,
            onPressed: feature.valueOrNull == null
                ? null
                : () => _share(feature.valueOrNull!),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: feature.when(
        loading: () => const CmsLoadingList(),
        error: (error, _) => CmsErrorState(
          error: error,
          onRetry: () => ref.invalidate(mapFeatureProvider(key)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 34),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.mapFeatureId,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.75),
                          ),
                        ),
                        Text(
                          data.id,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              context.l10n.mapAttributesTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: data.attributes.isEmpty
                    ? Text(context.l10n.mapAttributesEmpty)
                    : Column(
                        children: [
                          for (final entry in data.attributes.entries) ...[
                            _AttributeRow(
                              label: _label(entry.key),
                              value: _value(entry.value),
                            ),
                            if (entry.key != data.attributes.keys.last)
                              const Divider(height: 24),
                          ],
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              context.l10n.mapGeometryTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.hexagon_outlined),
                title: Text(data.geometryType),
                subtitle: Text(
                  context.l10n.mapGeometryPoints(data.coordinateCount),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(FeatureDetailModel data) => SharePlus.instance.share(
    ShareParams(
      title: 'GIS Cẩm Phả · ${data.id}',
      text: 'GIS Cẩm Phả\n${data.id}\n/map/feature/$layerId/$featureId',
    ),
  );

  String _label(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  String _value(dynamic value) {
    if (value == null) return '—';
    if (value is Map || value is List) return value.toString();
    final text = value.toString().trim();
    return text.isEmpty ? '—' : text;
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: value,
    excludeSemantics: true,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final labelText = Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelText,
              const SizedBox(height: 6),
              SelectableText(value),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 118, child: labelText),
            const SizedBox(width: 12),
            Expanded(child: SelectableText(value)),
          ],
        );
      },
    ),
  );
}
