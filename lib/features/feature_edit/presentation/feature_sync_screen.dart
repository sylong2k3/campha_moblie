import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../shared/presentation/app_feedback.dart';
import '../domain/feature_edit_models.dart';
import '../domain/feature_sync_controller.dart';

class FeatureSyncScreen extends ConsumerWidget {
  const FeatureSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureSyncProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.featureSyncTitle),
        actions: [
          IconButton(
            key: const ValueKey('feature-sync-now'),
            onPressed: state.syncing
                ? null
                : ref.read(featureSyncProvider.notifier).syncNow,
            tooltip: context.l10n.featureSyncNow,
            icon: state.syncing
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: ref.read(featureSyncProvider.notifier).refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        '${context.l10n.featurePending}: ${state.pending}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${context.l10n.featureConflicts}: ${state.conflicts}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${context.l10n.featureRejected}: ${state.rejected}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.syncing)
              SliverToBoxAdapter(
                child: Semantics(
                  liveRegion: true,
                  label: context.l10n.featureSyncing,
                  child: const LinearProgressIndicator(),
                ),
              ),
            if (state.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppInlineNotice(
                    message: state.error!.localizedErrorMessage(context.l10n),
                    icon: Icons.sync_problem_outlined,
                    tone: AppFeedbackTone.error,
                    actionLabel: context.l10n.commonRetry,
                    onAction: state.syncing
                        ? null
                        : ref.read(featureSyncProvider.notifier).syncNow,
                    liveRegion: true,
                  ),
                ),
              ),
            if (state.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateMessage(
                  icon: Icons.cloud_done_outlined,
                  title: context.l10n.featureSyncEmpty,
                ),
              )
            else
              SliverList.separated(
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ChangeCard(
                    change: state.items[index],
                    busy: state.syncing,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChangeCard extends ConsumerWidget {
  const _ChangeCard({required this.change, required this.busy});
  final OfflineFeatureChange change;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflict = change.status == OfflineChangeStatus.conflict;
    final rejected = change.status == OfflineChangeStatus.rejected;
    return Card(
      child: ExpansionTile(
        key: ValueKey('offline-change-${change.clientChangeId}'),
        leading: Icon(
          conflict
              ? Icons.compare_arrows
              : rejected
              ? Icons.error_outline
              : Icons.cloud_off_outlined,
        ),
        title: Text('${context.l10n.mapFeatureId} ${change.featureId}'),
        subtitle: Text(
          '${_statusLabel(context, change.status)} · v${change.baseVersion}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(change.attributes.keys.join(', ')),
          ),
          if (change.serverCurrent != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${context.l10n.featureServerVersion}: ${change.serverCurrent!.version}\n${change.serverCurrent!.attributes}',
              ),
            ),
          ],
          if (rejected) ...[
            const SizedBox(height: 10),
            AppInlineNotice(
              message: context.l10n.featureSyncRejectedReason,
              icon: Icons.error_outline,
              tone: AppFeedbackTone.error,
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: busy ? null : () => _confirmDiscard(context, ref),
              icon: const Icon(Icons.delete_outline),
              label: Text(context.l10n.featureSyncDiscardAction),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.featureDiscardOfflineTitle),
        content: Text(dialogContext.l10n.featureDiscardOfflineBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.featureSyncDiscardAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(featureSyncProvider.notifier)
          .discard(change.clientChangeId);
    }
  }
}

String _statusLabel(BuildContext context, OfflineChangeStatus status) =>
    switch (status) {
      OfflineChangeStatus.pending => context.l10n.featurePending,
      OfflineChangeStatus.syncing => context.l10n.featureSyncing,
      OfflineChangeStatus.conflict => context.l10n.featureConflicts,
      OfflineChangeStatus.rejected => context.l10n.featureRejected,
    };
