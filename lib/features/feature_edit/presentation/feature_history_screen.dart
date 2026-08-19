import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../shared/presentation/app_feedback.dart';
import '../../tools/domain/field_tools_models.dart';
import '../data/feature_edit_repository.dart';
import '../domain/feature_edit_models.dart';

final featureHistoryProvider = FutureProvider.autoDispose
    .family<List<FeatureVersion>, ({String layerId, String featureId})>(
      (ref, key) => ref
          .read(featureEditRepositoryProvider)
          .history(key.layerId, key.featureId),
    );

class FeatureHistoryScreen extends ConsumerStatefulWidget {
  const FeatureHistoryScreen({
    super.key,
    required this.layerId,
    required this.featureId,
  });
  final String layerId;
  final String featureId;

  @override
  ConsumerState<FeatureHistoryScreen> createState() =>
      _FeatureHistoryScreenState();
}

class _FeatureHistoryScreenState extends ConsumerState<FeatureHistoryScreen> {
  int? _restoringVersion;
  String? _restoreErrorMessage;

  String get layerId => widget.layerId;
  String get featureId => widget.featureId;

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    FeatureVersion target,
    int currentVersion,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.featureRestoreTitle),
        content: Text(
          context.l10n.featureRestoreCreatesVersion(target.version),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.featureRestoreAction),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    setState(() {
      _restoringVersion = target.version;
      _restoreErrorMessage = null;
    });
    try {
      await ref
          .read(featureEditRepositoryProvider)
          .restore(
            layerId: layerId,
            featureId: featureId,
            version: target.version,
            baseVersion: currentVersion,
          );
      ref.invalidate(
        featureHistoryProvider((layerId: layerId, featureId: featureId)),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.featureRestoreSuccess)),
        );
      }
    } catch (error) {
      ref.invalidate(
        featureHistoryProvider((layerId: layerId, featureId: featureId)),
      );
      if (context.mounted) {
        setState(
          () =>
              _restoreErrorMessage = error.localizedErrorMessage(context.l10n),
        );
      }
    } finally {
      if (mounted) setState(() => _restoringVersion = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (layerId: layerId, featureId: featureId);
    final history = ref.watch(featureHistoryProvider(key));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.featureHistoryTitle)),
      body: Column(
        children: [
          if (_restoreErrorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AppInlineNotice(
                message: _restoreErrorMessage!,
                icon: Icons.error_outline,
                tone: AppFeedbackTone.error,
                liveRegion: true,
              ),
            ),
          Expanded(
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AppStateMessage(
                icon: Icons.cloud_off_outlined,
                title: error.localizedErrorMessage(context.l10n),
                tone: AppFeedbackTone.error,
                actionLabel: context.l10n.commonRetry,
                onAction: () => ref.invalidate(featureHistoryProvider(key)),
                liveRegion: true,
              ),
              data: (items) {
                if (items.isEmpty) {
                  return AppStateMessage(
                    icon: Icons.history_outlined,
                    title: context.l10n.featureHistoryEmpty,
                    liveRegion: true,
                  );
                }
                final currentVersion = items.first.version;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ExpansionTile(
                        key: ValueKey('feature-version-${item.version}'),
                        leading: CircleAvatar(child: Text('${item.version}')),
                        title: Text(
                          '${context.l10n.featureVersion} ${item.version} · ${_actionLabel(context, item.action)}',
                        ),
                        subtitle: Text(
                          '${item.changedAt.toLocal()} · ${context.l10n.featureChangedBy} ${item.changedBy ?? '—'}'
                          '${index == 0 ? ' · ${context.l10n.featureCurrent}' : ''}',
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          16,
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.changedFields.isEmpty
                                  ? context.l10n.featureGeometryChanged
                                  : item.changedFields
                                        .map(
                                          (field) =>
                                              '${_humanize(field)}: ${item.beforeAttributes[field]} → ${item.afterAttributes[field]}',
                                        )
                                        .join('\n'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _GeometryPreview(geometry: item.afterGeometry),
                          if (index != 0) ...[
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              onPressed: _restoringVersion != null
                                  ? null
                                  : () => _restore(
                                      context,
                                      ref,
                                      item,
                                      currentVersion,
                                    ),
                              icon: _restoringVersion == item.version
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.restore),
                              label: Text(context.l10n.featureRestoreAction),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _actionLabel(BuildContext context, String action) => switch (action) {
  'update' => context.l10n.featureActionUpdate,
  'restore' => context.l10n.featureActionRestore,
  _ => context.l10n.featureActionChanged,
};

String _geometryLabel(BuildContext context, String type) => switch (type) {
  'Point' => context.l10n.draftPoint,
  'LineString' => context.l10n.draftLine,
  _ => context.l10n.draftPolygon,
};

String _humanize(String value) {
  final words = value
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'));
  return words
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class _GeometryPreview extends StatelessWidget {
  const _GeometryPreview({required this.geometry});
  final GeoJsonGeometry geometry;

  int _coordinateCount(Object value) {
    if (value is! List) return 0;
    if (value.length >= 2 && value[0] is num && value[1] is num) return 1;
    return value.fold(0, (total, item) => total + _coordinateCount(item));
  }

  @override
  Widget build(BuildContext context) {
    final type = _geometryLabel(context, geometry.type);
    final count = _coordinateCount(geometry.coordinates);
    return Semantics(
      label: context.l10n.mapGeometryTitle,
      value: '$type, $count ${context.l10n.featureVertices}',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('$type · $count ${context.l10n.featureVertices}'),
      ),
    );
  }
}
