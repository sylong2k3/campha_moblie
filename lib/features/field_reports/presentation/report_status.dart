import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/l10n/l10n.dart';

Color reportStatusColor(String status) => switch (status) {
  'resolved' => AppColors.statusResolved,
  'under_review' || 'in_progress' => AppColors.statusInProgress,
  'rejected' || 'error' => AppColors.statusError,
  _ => AppColors.statusNew,
};

String reportStatusLabel(BuildContext context, String status) =>
    switch (status) {
      'pending' => context.l10n.reportStatusPending,
      'under_review' => context.l10n.reportStatusReview,
      'approved' => context.l10n.reportStatusApproved,
      'rejected' => context.l10n.reportStatusRejected,
      'resolved' => context.l10n.reportStatusResolved,
      _ => status,
    };

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final fg = reportStatusColor(status);
    final brightness = Theme.of(context).brightness;
    final (bg, icon) = switch (status) {
      'resolved' => (
        AppColors.successSoft(brightness),
        Icons.check_circle_outline,
      ),
      'under_review' ||
      'in_progress' => (AppColors.warningSoft(brightness), Icons.autorenew),
      'rejected' ||
      'error' => (AppColors.errorSoft(brightness), Icons.error_outline),
      _ => (AppColors.infoSoft(brightness), Icons.fiber_new_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              reportStatusLabel(context, status),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
