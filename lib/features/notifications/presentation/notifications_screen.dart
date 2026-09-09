import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/route_names.dart';
import '../../../core/error/crashlytics_service.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/domain/session_controller.dart';
import '../../shared/presentation/app_feedback.dart';
import '../data/notification_model.dart';
import '../domain/notification_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationListControllerProvider);
    final controller = ref.read(notificationListControllerProvider.notifier);
    final l10n = context.l10n;
    ref.listen(
      notificationListControllerProvider.select((s) => s.actionError),
      (_, error) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.notificationsActionError)),
          );
        }
      },
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.map);
            }
          },
        ),
        title: Text(l10n.notificationsTitle),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.notificationsMarkAllRead,
            icon: const Icon(Icons.done_all_rounded),
            onPressed: state.isActing || state.isLoading || state.items.isEmpty
                ? null
                : () => controller.markAllRead(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.notificationsAll),
                  selected: !state.unreadOnly,
                  onSelected: state.isActing
                      ? null
                      : (selected) {
                          if (selected) {
                            controller.loadInitial(unreadOnly: false);
                          }
                        },
                ),
                ChoiceChip(
                  label: Text(l10n.notificationsUnread),
                  selected: state.unreadOnly,
                  onSelected: state.isActing
                      ? null
                      : (selected) {
                          if (selected) {
                            controller.loadInitial(unreadOnly: true);
                          }
                        },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (state.isActing || state.isRefreshing)
            const LinearProgressIndicator(),
          if (state.errorMessage != null && state.items.isNotEmpty)
            AppInlineNotice(
              message: l10n.notificationsLoadError,
              tone: AppFeedbackTone.error,
              actionLabel: l10n.commonRetry,
              onAction: controller.refresh,
              liveRegion: true,
            ),
          // Content
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.depth == 0 &&
                    notification is ScrollUpdateNotification &&
                    notification.metrics.extentAfter < 200) {
                  unawaited(controller.loadMore());
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: CustomScrollView(
                  key: const ValueKey('notifications-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (state.items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : AppStateMessage(
                                icon: state.errorMessage != null
                                    ? Icons.error_outline_rounded
                                    : Icons.notifications_off_outlined,
                                title: state.errorMessage != null
                                    ? l10n.notificationsLoadError
                                    : state.unreadOnly
                                    ? l10n.notificationsUnreadEmpty
                                    : l10n.notificationsEmpty,
                                actionLabel: state.errorMessage != null
                                    ? l10n.commonRetry
                                    : null,
                                onAction: controller.refresh,
                              ),
                      )
                    else
                      SliverList.builder(
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return _NotificationListTile(
                            key: ValueKey('notification-${item.id}'),
                            item: item,
                            onTap: state.isActing
                                ? null
                                : () => _open(context, ref, item),
                            onDelete: state.isActing
                                ? null
                                : () => _delete(context, ref, item),
                          );
                        },
                      ),
                    if (state.hasMore)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: state.isLoadingMore
                              ? const Center(child: CircularProgressIndicator())
                              : TextButton(
                                  onPressed: state.isActing
                                      ? null
                                      : () {
                                          controller.clearActionError();
                                          unawaited(controller.loadMore());
                                        },
                                  child: Text(
                                    state.actionError != null
                                        ? l10n.commonRetry
                                        : l10n.notificationsLoadMore,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    final session = ref.read(sessionControllerProvider);
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notificationsDelete),
        content: Text(l10n.notificationsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (!context.mounted ||
        confirmed != true ||
        !identical(session, ref.read(sessionControllerProvider))) {
      return;
    }
    await ref
        .read(notificationListControllerProvider.notifier)
        .deleteNotification(item.id);
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    final session = ref.read(sessionControllerProvider);
    if (!item.isRead) {
      unawaited(
        ref
            .read(notificationListControllerProvider.notifier)
            .markRead(item.id),
      );
    }
    if (!context.mounted ||
        !identical(session, ref.read(sessionControllerProvider))) {
      return;
    }
    final reportId = notificationReportId(item.data);
    unawaited(
      CrashlyticsService.logEvent('notification_open', {
        'destination': reportId == null ? 'inbox_detail' : 'report',
      }),
    );
    if (reportId != null) {
      context.push(RoutePaths.notificationReportDetail(reportId));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (item.body != null) SelectableText(item.body!),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.commonClose),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationListTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _NotificationListTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !item.isRead;

    IconData iconData = Icons.notifications_rounded;
    Color iconBg = theme.colorScheme.primaryContainer;
    Color iconColor = theme.colorScheme.onPrimaryContainer;

    if (item.type.contains('created')) {
      iconData = Icons.campaign_rounded;
      iconBg = Colors.blue.withValues(alpha: 0.15);
      iconColor = Colors.blue.shade700;
    } else if (item.type.contains('status')) {
      iconData = Icons.sync_problem_rounded;
      iconBg = Colors.orange.withValues(alpha: 0.15);
      iconColor = Colors.orange.shade800;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: iconBg,
              child: Icon(iconData, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (item.body != null && item.body!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.body!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.85,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(context, item.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.l10n.notificationsDelete,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    final l10n = context.l10n;
    if (diff.inMinutes < 1) return l10n.notificationsJustNow;
    if (diff.inMinutes < 60) return l10n.reportMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.reportHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.notificationsDaysAgo(diff.inDays);
    return DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(dt.toLocal());
  }
}
