import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_config.dart';
import '../../auth/domain/session_controller.dart';
import '../../shared/presentation/app_feedback.dart';
import '../data/field_report_repository.dart';
import '../domain/field_report_models.dart';
import '../domain/field_reports_controller.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FieldReport report,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.reportDelete),
        content: Text(context.l10n.reportDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.reportDelete),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    try {
      await ref.read(myReportsProvider.notifier).delete(report);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.localizedErrorMessage(context.l10n))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myReportsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.myReports)),
      body: RefreshIndicator(
        onRefresh: ref.read(myReportsProvider.notifier).loadFirstPage,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _MineStatusFilters(state: state)),
            if (state.loading && state.items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && state.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateMessage(
                  icon: Icons.cloud_off_outlined,
                  title: state.error!.localizedErrorMessage(context.l10n),
                  tone: AppFeedbackTone.error,
                  actionLabel: context.l10n.commonRetry,
                  onAction: ref.read(myReportsProvider.notifier).loadFirstPage,
                  liveRegion: true,
                ),
              )
            else if (state.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateMessage(
                  icon: Icons.assignment_outlined,
                  title: context.l10n.reportPublicEmpty,
                  liveRegion: true,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.separated(
                  itemCount: state.items.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == state.items.length) {
                      Future.microtask(
                        ref.read(myReportsProvider.notifier).loadMore,
                      );
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final report = state.items[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Semantics(
                        button: true,
                        label:
                            '${report.referenceCode}, ${_status(context, report.status)}, ${report.description}',
                        child: ListTile(
                          key: ValueKey('my-report-${report.id}'),
                          onTap: () =>
                              context.push(RoutePaths.reportDetail(report.id)),
                          leading: CircleAvatar(
                            child: Text('${report.photoCount}'),
                          ),
                          title: Text(report.referenceCode),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                _status(context, report.status),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                report.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            key: ValueKey('my-report-delete-${report.id}'),
                            tooltip: context.l10n.reportDelete,
                            onPressed: () => _delete(context, ref, report),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
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

class _MineStatusFilters extends ConsumerWidget {
  const _MineStatusFilters({required this.state});
  final FieldReportsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = <String?, String>{
      null: context.l10n.reportStatusAll,
      'pending': context.l10n.reportStatusPending,
      'under_review': context.l10n.reportStatusReview,
      'approved': context.l10n.reportStatusApproved,
      'rejected': context.l10n.reportStatusRejected,
      'resolved': context.l10n.reportStatusResolved,
    };
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        children: statuses.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  key: ValueKey('mine-status-${entry.key ?? 'all'}'),
                  selected: state.filter.status == entry.key,
                  onSelected: (_) =>
                      ref.read(myReportsProvider.notifier).setStatus(entry.key),
                  label: Text(entry.value),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class FieldReportDetailScreen extends ConsumerStatefulWidget {
  const FieldReportDetailScreen({super.key, required this.reportId});
  final String reportId;
  @override
  ConsumerState<FieldReportDetailScreen> createState() =>
      _FieldReportDetailScreenState();
}

class _FieldReportDetailScreenState
    extends ConsumerState<FieldReportDetailScreen> {
  late Future<FieldReport> _future;
  @override
  void initState() {
    super.initState();
    _reload();
    ref.listenManual<SessionState>(sessionControllerProvider, (previous, next) {
      if (previous?.user?.id == next.user?.id &&
          previous?.status == next.status) {
        return;
      }
      if (mounted) setState(_reload);
    });
  }

  void _reload() => _future = ref
      .read(fieldReportRepositoryProvider)
      .getDetail(widget.reportId);

  Future<void> _delete(FieldReport report) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.reportDelete),
        content: Text(context.l10n.reportDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.reportDelete),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await ref.read(myReportsProvider.notifier).delete(report);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.localizedErrorMessage(context.l10n))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.myReports)),
    body: FutureBuilder<FieldReport>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AppStateMessage(
            icon: Icons.cloud_off_outlined,
            title: snapshot.error!.localizedErrorMessage(context.l10n),
            tone: AppFeedbackTone.error,
            actionLabel: context.l10n.commonRetry,
            onAction: () => setState(_reload),
            liveRegion: true,
          );
        }
        final report = snapshot.requireData;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  report.referenceCode,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Chip(label: Text(_status(context, report.status))),
              ],
            ),
            const SizedBox(height: 18),
            _Section(
              icon: Icons.notes,
              title: context.l10n.reportDescriptionStep,
              child: Text(
                report.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (report.photos.isNotEmpty) ...[
              const SizedBox(height: 14),
              _Section(
                icon: Icons.photo_library_outlined,
                title: context.l10n.reportPhotos,
                child: SizedBox(
                  height: 220,
                  child: PageView.builder(
                    itemCount: report.photos.length,
                    itemBuilder: (context, index) {
                      final photo = report.photos[index];
                      return Semantics(
                        image: true,
                        label: context.l10n.reportPhotoPosition(
                          index + 1,
                          report.photos.length,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            ApiConfig.rewriteStorageUrl(photo.url.toString()),
                            fit: BoxFit.cover,
                            cacheWidth:
                                (MediaQuery.sizeOf(context).width *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            cacheHeight:
                                (220 * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) => Center(
                              child: FilledButton.icon(
                                onPressed: () => setState(_reload),
                                icon: const Icon(Icons.refresh),
                                label: Text(context.l10n.commonRetry),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _Section(
              icon: Icons.place_outlined,
              title: context.l10n.reportLocationStep,
              child: Text(
                '${report.location.latitude.toStringAsFixed(6)}, ${report.location.longitude.toStringAsFixed(6)}${report.measuredGeometry == null ? '' : '\n${report.measuredGeometry!.type}'}',
              ),
            ),
            if (report.reviewReason != null) ...[
              const SizedBox(height: 14),
              _Section(
                icon: Icons.rate_review_outlined,
                title: context.l10n.reportReviewReason,
                child: Text(report.reviewReason!),
              ),
            ],
            const SizedBox(height: 14),
            _Section(
              icon: Icons.timeline,
              title: context.l10n.reportHistory,
              child: report.history.isEmpty
                  ? Text(_status(context, report.status))
                  : Column(
                      children: report.history.reversed
                          .map(
                            (event) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.circle, size: 14),
                              title: Text(_status(context, event.newStatus)),
                              subtitle: Text(
                                '${event.createdAt.toLocal()}${event.reason == null ? '' : '\n${event.reason}'}',
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const ValueKey('report-detail-delete'),
              onPressed: () => _delete(report),
              icon: const Icon(Icons.delete_outline),
              label: Text(context.l10n.reportDelete),
            ),
          ],
        );
      },
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

String _status(BuildContext context, String status) => switch (status) {
  'pending' => context.l10n.reportStatusPending,
  'under_review' => context.l10n.reportStatusReview,
  'approved' => context.l10n.reportStatusApproved,
  'rejected' => context.l10n.reportStatusRejected,
  'resolved' => context.l10n.reportStatusResolved,
  _ => status,
};
