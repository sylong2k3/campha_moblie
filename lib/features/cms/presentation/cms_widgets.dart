import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../shared/presentation/app_feedback.dart';
import '../../shared/presentation/app_search_field.dart';

String cmsDate(BuildContext context, DateTime? value) {
  if (value == null) return context.l10n.cmsDateUnknown;
  return DateFormat.yMMMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(value.toLocal());
}

class CmsSearchField extends StatefulWidget {
  const CmsSearchField({
    super.key,
    required this.hint,
    required this.onSearch,
    this.initialValue = '',
  });

  final String hint;
  final String initialValue;
  final ValueChanged<String> onSearch;

  @override
  State<CmsSearchField> createState() => _CmsSearchFieldState();
}

class _CmsSearchFieldState extends State<CmsSearchField> {
  late final TextEditingController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 400), () {
      widget.onSearch(value.trim());
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => AppSearchField(
    key: const ValueKey('cms-search'),
    controller: _controller,
    hintText: widget.hint,
    clearTooltip: context.l10n.cmsClearSearch,
    onChanged: _changed,
    onClear: () {
      _timer?.cancel();
      widget.onSearch('');
    },
    onSubmitted: (value) {
      _timer?.cancel();
      widget.onSearch(value.trim());
    },
  );
}

class CmsStaleBanner extends StatelessWidget {
  const CmsStaleBanner({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppInlineNotice(
    icon: Icons.cloud_off_outlined,
    tone: AppFeedbackTone.warning,
    message: context.l10n.cmsStaleData,
    actionLabel: context.l10n.commonRetry,
    onAction: onRetry,
    liveRegion: true,
  );
}

class CmsErrorState extends StatelessWidget {
  const CmsErrorState({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppStateMessage(
    icon: Icons.cloud_off_outlined,
    tone: AppFeedbackTone.error,
    title: error.localizedErrorMessage(context.l10n),
    actionLabel: context.l10n.commonRetry,
    onAction: onRetry,
    liveRegion: true,
  );
}

class CmsEmptyState extends StatelessWidget {
  const CmsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) =>
      AppStateMessage(icon: icon, title: title, body: body);
}

class CmsLoadingList extends StatelessWidget {
  const CmsLoadingList({super.key});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(18),
    itemCount: 5,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) => Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(context, 0.32),
            const SizedBox(height: 13),
            _bar(context, 0.9, height: 18),
            const SizedBox(height: 8),
            _bar(context, 0.68),
          ],
        ),
      ),
    ),
  );

  Widget _bar(BuildContext context, double fraction, {double height = 12}) =>
      FractionallySizedBox(
        widthFactor: fraction,
        alignment: Alignment.centerLeft,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      );
}

/// Phạm vi hiển thị theo `visibility` của văn bản/bản đồ PDF.
enum CmsVisibilityFilter { all, public, internal }

/// Thanh lọc Tất cả/Công khai/Nội bộ — chỉ có ý nghĩa với vai trò được xem
/// nội bộ, nên chỉ hiển thị khi [CmsVisibilityFilter.internal] là lựa chọn
/// hợp lệ (gọi nơi dùng tự quyết định qua điều kiện bên ngoài).
class CmsVisibilityFilterBar extends StatelessWidget {
  const CmsVisibilityFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CmsVisibilityFilter value;
  final ValueChanged<CmsVisibilityFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = {
      CmsVisibilityFilter.all: l10n.cmsVisibilityAll,
      CmsVisibilityFilter.public: l10n.cmsVisibilityPublic,
      CmsVisibilityFilter.internal: l10n.cmsVisibilityInternal,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in options.entries) ...[
                ChoiceChip(
                  key: ValueKey('cms-visibility-${entry.key.name}'),
                  label: Text(entry.value),
                  selected: value == entry.key,
                  onSelected: (_) => onChanged(entry.key),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Nhãn "Nội bộ" dùng lại trên cả card danh sách và trang chi tiết.
class CmsInternalBadge extends StatelessWidget {
  const CmsInternalBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 14, color: colors.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(
            context.l10n.cmsInternalBadge,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class CmsAppendFooter extends StatelessWidget {
  const CmsAppendFooter({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.cmsLoadMoreRetry),
        ),
      );
    }
    return const SizedBox(height: 18);
  }
}
