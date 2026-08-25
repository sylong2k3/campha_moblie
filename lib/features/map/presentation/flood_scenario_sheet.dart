import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
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
    final bodyState = state.loading && state.scenarios.isEmpty
        ? 'loading'
        : state.error != null && state.scenarios.isEmpty
        ? 'error'
        : state.scenarios.isEmpty
        ? 'empty'
        : 'content';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                const Icon(
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
                AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.quick),
                  child: state.loading
                      ? const SizedBox.square(
                          key: ValueKey('flood-refresh-loading'),
                          dimension: 48,
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          key: const ValueKey('flood-refresh-action'),
                          tooltip: 'Tải lại',
                          icon: const Icon(Icons.refresh),
                          onPressed: controller.load,
                        ),
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
          Expanded(
            child: AppStateSwitcher(
              stateKey: ValueKey('flood-$bodyState'),
              animateSize: false,
              child: switch (bodyState) {
                'loading' => const Center(child: CircularProgressIndicator()),
                'error' => AppStateMessage(
                  icon: Icons.error_outline,
                  title: state.error!.localizedErrorMessage(context.l10n),
                  onAction: controller.load,
                  actionLabel: 'Tải lại',
                  tone: AppFeedbackTone.error,
                  liveRegion: true,
                ),
                'empty' => const AppStateMessage(
                  icon: Icons.water_damage_outlined,
                  title: 'Không có kịch bản ngập úng nào.',
                  liveRegion: true,
                ),
                _ => ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: state.scenarios.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final scenario = state.scenarios[index];
                    return _ScenarioCard(
                      scenario: scenario,
                      isSelected: state.selectedScenarioCode == scenario.code,
                      onTap: () => controller.toggleScenario(scenario),
                    );
                  },
                ),
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
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.state),
        curve: AppMotion.stateCurve,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
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
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: isSelected,
                      onChanged: (_) => onTap(),
                      activeTrackColor: colorScheme.primary,
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
                        color: colorScheme.primary,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scenario.isActive
                            ? colorScheme.primaryContainer
                            : colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        scenario.isActive ? 'Đang kích hoạt' : 'Chưa kích hoạt',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scenario.isActive
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onTertiaryContainer,
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
      ),
    );
  }
}
