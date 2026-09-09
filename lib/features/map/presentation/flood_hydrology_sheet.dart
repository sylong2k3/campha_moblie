import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../domain/flood_hydrology_controller.dart';

class FloodHydrologySheet extends ConsumerStatefulWidget {
  const FloodHydrologySheet({super.key});
  @override
  ConsumerState<FloodHydrologySheet> createState() =>
      _FloodHydrologySheetState();
}

class _FloodHydrologySheetState extends ConsumerState<FloodHydrologySheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted && !ref.read(floodHydrologyProvider).loaded) {
        ref.read(floodHydrologyProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(floodHydrologyProvider);
    final controller = ref.read(floodHydrologyProvider.notifier);
    final theme = Theme.of(context);
    final number = NumberFormat('#,##0.##', 'vi');
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 0.93,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
            child: Row(
              children: [
                Icon(Icons.flood_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ngập lụt & Thủy văn',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Tải lại',
                  onPressed: state.loading ? null : controller.load,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (state.loading) const LinearProgressIndicator(),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'KỲ QUAN TRẮC',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      state.error!.localizedErrorMessage(context.l10n),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                if (state.runs.isEmpty && !state.loading && state.error == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'Chưa có kỳ quan trắc ngập lụt',
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (state.runs.isNotEmpty)
                  DropdownButtonFormField<int>(
                    key: ValueKey('flood-run-${state.selectedRunId}'),
                    initialValue: state.selectedRunId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Chọn kỳ giám sát',
                    ),
                    items: state.runs
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(
                              r.periodText.isEmpty
                                  ? r.name
                                  : '${r.name} · ${r.periodText}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id != null) controller.selectRun(id);
                    },
                  ),
                if (state.selectedRun case final run?) ...[
                  const SizedBox(height: 12),
                  Text(run.name, style: theme.textTheme.titleMedium),
                  if (run.periodText.isNotEmpty)
                    Text(run.periodText, style: theme.textTheme.bodySmall),
                  if (run.summary.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            for (final stat in run.summary.entries)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(stat.key)),
                                    const SizedBox(width: 8),
                                    Text(
                                      number.format(stat.value),
                                      style: theme.textTheme.labelLarge,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
                if (state.currentArtifacts.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${state.visibleIds.length} lớp đang bật',
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: state.visibleIds.isEmpty
                            ? null
                            : controller.clearArtifacts,
                        child: const Text('Tắt lớp kỳ này'),
                      ),
                    ],
                  ),
                if (state.selectedRun != null &&
                    state.currentArtifacts.isEmpty &&
                    !state.loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Kỳ này chưa có lớp bản đồ công bố'),
                  ),
                for (final group in [
                  'Ngập lụt',
                  'Ảnh hưởng',
                  'Tiêu thoát nước',
                  'Kiểm tra chất lượng',
                ])
                  if (state.currentArtifacts.any((a) => a.group == group)) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 6),
                      child: Text(
                        group,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    for (final artifact in state.currentArtifacts.where(
                      (a) => a.group == group,
                    ))
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              key: ValueKey('flood-artifact-${artifact.id}'),
                              value: state.visibleIds.contains(artifact.id),
                              title: Text(artifact.labelVi),
                              subtitle: artifact.registryLayerId == null
                                  ? const Text('Chưa có lớp bản đồ')
                                  : null,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: artifact.registryLayerId == null
                                  ? null
                                  : (_) => controller.toggleArtifact(artifact),
                            ),
                            for (final legend in state.legends.where(
                              (l) =>
                                  l.code == artifact.code &&
                                  l.module == artifact.module,
                            ))
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    for (final entry in legend.entries)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: Color(
                                                int.tryParse(
                                                      'FF${entry.color.replaceAll('#', '')}',
                                                      radix: 16,
                                                    ) ??
                                                    0xFF94A3B8,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              entry.label,
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
