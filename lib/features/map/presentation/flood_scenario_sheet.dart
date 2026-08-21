import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../shared/presentation/app_feedback.dart';
import '../domain/flood_scenario_controller.dart';
import '../domain/flood_scenario_model.dart';

class FloodScenarioSheet extends ConsumerWidget {
  const FloodScenarioSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(floodScenarioProvider);
    final controller = ref.read(floodScenarioProvider.notifier);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                Icon(
                  Icons.water_damage_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kịch bản ngập úng',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tải lại',
                  icon: const Icon(Icons.refresh),
                  onPressed: state.loading ? null : () => controller.load(),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (state.loading && state.scenarios.isEmpty)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null && state.scenarios.isEmpty)
            Expanded(
              child: AppStateMessage(
                icon: Icons.error_outline,
                title: state.error!.localizedErrorMessage(context.l10n),
                onAction: controller.load,
                actionLabel: 'Tải lại',
                tone: AppFeedbackTone.error,
              ),
            )
          else if (state.scenarios.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Không có kịch bản ngập úng nào.'),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: state.scenarios.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final scenario = state.scenarios[index];
                  final isSelected =
                      state.selectedScenarioCode == scenario.code;

                  return _ScenarioCard(
                    scenario: scenario,
                    isSelected: isSelected,
                    onTap: () => controller.toggleScenario(scenario),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.isSelected,
    required this.onTap,
  });

  final FloodScenarioModel scenario;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 3 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      scenario.nameVi,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    activeTrackColor: AppColors.primary,
                  ),
                ],
              ),
              if (scenario.rainfallRangeText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.grain_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Lượng mưa: ${scenario.rainfallRangeText}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if (scenario.description != null &&
                  scenario.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  scenario.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scenario.isActive
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      scenario.isActive ? 'Đang kích hoạt' : 'Chưa kích hoạt',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scenario.isActive
                            ? Colors.green.shade800
                            : Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (scenario.layerCode.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Layer: ${scenario.layerCode}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
