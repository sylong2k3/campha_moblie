import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/error/crashlytics_service.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/domain/session_controller.dart';
import '../../shared/presentation/app_feedback.dart';
import '../data/notification_model.dart';
import '../domain/notification_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static final List<NotificationItem> _defaultAppNotifications = [
    NotificationItem(
      id: -1,
      type: 'system',
      title: 'Chào mừng bạn đến với MobileGIS Cẩm Phả',
      body:
          'Hệ thống bản đồ số và quản lý hiện trường thành phố Cẩm Phả. '
          'Tra cứu quy hoạch, lớp dữ liệu chuyên đề và theo dõi hiện trạng đô thị trực tiếp trên thiết bị.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationItem(
      id: -2,
      type: 'flood',
      title: 'Giám sát ngập lụt & kịch bản thủy văn',
      body:
          'Cập nhật dữ liệu quan trắc mưa ngập và mô hình mô phỏng ngập úng '
          'trên các lưu vực trọng điểm của thành phố Cẩm Phả theo thời gian thực.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationItem(
      id: -3,
      type: 'field_report.created',
      title: 'Tiếp nhận phản ánh hiện trường đô thị',
      body:
          'Người dân và cán bộ có thể gửi phản ánh hiện trường, định vị GPS, đính kèm hình ảnh '
          'và theo dõi tiến độ xử lý của cơ quan chức năng.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    NotificationItem(
      id: -4,
      type: 'system',
      title: 'Phân quyền và tài khoản công vụ',
      body:
          'Cán bộ chuyên môn (UBND, Phòng TN&MT) đăng nhập để thực hiện '
          'cập nhật dữ liệu bản đồ ngoại tuyến, kiểm tra hiện trường và xử lý hồ sơ báo cáo.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final isAuthenticated = session.isAuthenticated;
    final state = ref.watch(notificationListControllerProvider);
    final controller = ref.read(notificationListControllerProvider.notifier);
    final l10n = context.l10n;
    final items = isAuthenticated ? state.items : _defaultAppNotifications;

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
          if (isAuthenticated)
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
          // Filter Chips (Segmented Tab Pill)
          if (isAuthenticated)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.notificationsAll),
                      selected: !state.unreadOnly,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
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
            ),
          const Divider(height: 1),
          if (isAuthenticated && (state.isActing || state.isRefreshing))
            const LinearProgressIndicator(),
          if (isAuthenticated &&
              state.errorMessage != null &&
              state.items.isNotEmpty)
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
                if (isAuthenticated &&
                    notification.depth == 0 &&
                    notification is ScrollUpdateNotification &&
                    notification.metrics.extentAfter < 200) {
                  unawaited(controller.loadMore());
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: isAuthenticated
                    ? controller.refresh
                    : () async => Future<void>.delayed(
                          const Duration(milliseconds: 300),
                        ),
                child: CustomScrollView(
                  key: const ValueKey('notifications-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (!isAuthenticated)
                      const SliverToBoxAdapter(
                        child: _GuestNotificationBanner(),
                      ),
                    if (items.isEmpty)
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
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        sliver: SliverList.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _NotificationListTile(
                              key: ValueKey('notification-${item.id}'),
                              item: item,
                              onTap: state.isActing
                                  ? null
                                  : () => _open(context, ref, item),
                              onDelete: !isAuthenticated || state.isActing
                                  ? null
                                  : () => _delete(context, ref, item),
                            );
                          },
                        ),
                      ),
                    if (isAuthenticated && state.hasMore)
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
    if (session.isAuthenticated && !item.isRead) {
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
    final config = _NotificationTypeConfig.fromType(item.type, context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: config.containerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(config.icon, size: 13, color: config.primaryColor),
                        const SizedBox(width: 5),
                        Text(
                          config.label,
                          style: TextStyle(
                            color: config.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTime(context, item.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              if (item.body != null)
                SelectableText(
                  item.body!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              const SizedBox(height: 24),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.l10n.commonClose,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTypeConfig {
  final String label;
  final IconData icon;
  final Color primaryColor;
  final Color containerColor;

  const _NotificationTypeConfig({
    required this.label,
    required this.icon,
    required this.primaryColor,
    required this.containerColor,
  });

  factory _NotificationTypeConfig.fromType(String type, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (type.contains('flood') ||
        type.contains('water') ||
        type.contains('thuy_van')) {
      return _NotificationTypeConfig(
        label: 'THỦY VĂN & NGẬP',
        icon: Icons.water_damage_rounded,
        primaryColor: AppColors.statusNew,
        containerColor:
            isDark ? const Color(0xFF082F49) : const Color(0xFFE0F2FE),
      );
    } else if (type.contains('report') ||
        type.contains('created') ||
        type.contains('field')) {
      return _NotificationTypeConfig(
        label: 'HIỆN TRƯỜNG',
        icon: Icons.campaign_rounded,
        primaryColor: AppColors.statusInProgress,
        containerColor:
            isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
      );
    } else if (type.contains('status')) {
      return _NotificationTypeConfig(
        label: 'TIẾN ĐỘ XỬ LÝ',
        icon: Icons.task_alt_rounded,
        primaryColor: AppColors.statusResolved,
        containerColor:
            isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
      );
    } else if (type.contains('alert') || type.contains('warning')) {
      return _NotificationTypeConfig(
        label: 'CẢNH BÁO KHẨN',
        icon: Icons.warning_amber_rounded,
        primaryColor: AppColors.statusError,
        containerColor:
            isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
      );
    } else {
      return _NotificationTypeConfig(
        label: 'HỆ THỐNG',
        icon: Icons.verified_user_rounded,
        primaryColor: AppColors.primary,
        containerColor:
            isDark ? AppColors.primaryDeep : AppColors.clay,
      );
    }
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
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !item.isRead;
    final config = _NotificationTypeConfig.fromType(item.type, context);

    return Semantics(
      button: true,
      label:
          '${item.title}, ${config.label}, ${_formatTime(context, item.createdAt)}${isUnread ? ", Chưa đọc" : ""}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark
                  ? theme.colorScheme.surfaceContainerHigh
                  : Colors.white)
              : (isDark
                  ? theme.colorScheme.surfaceContainer
                  : theme.colorScheme.surfaceContainerLowest
                      .withValues(alpha: 0.85)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? theme.colorScheme.primary.withValues(alpha: 0.45)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            width: isUnread ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnread
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : theme.colorScheme.shadow.withValues(alpha: 0.03),
              blurRadius: isUnread ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Type Tag Badge + Time + Unread indicator
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: config.containerColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(config.icon, size: 13, color: config.primaryColor),
                            const SizedBox(width: 5),
                            Text(
                              config.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: config.primaryColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(context, item.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                      height: 1.25,
                    ),
                  ),
                  if (item.body != null && item.body!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.body!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Bottom link & delete action
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Xem chi tiết',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: context.l10n.notificationsDelete,
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: theme.colorScheme.outline,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestNotificationBanner extends StatelessWidget {
  const _GuestNotificationBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Thông báo công khai',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn đang xem thông tin chung từ hệ thống MobileGIS Cẩm Phả. Đăng nhập để nhận thông báo xử lý phản ánh hiện trường và các tin tức điều hành chuyên sâu.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => context.push(
                '${RoutePaths.login}?returnTo=${Uri.encodeQueryComponent(RoutePaths.notifications)}',
              ),
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text('Đăng nhập ngay'),
            ),
          ),
        ],
      ),
    );
  }
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
