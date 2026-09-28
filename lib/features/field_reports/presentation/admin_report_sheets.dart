import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_config.dart';
import '../../shared/presentation/app_feedback.dart';
import '../data/field_report_repository.dart';
import '../domain/field_report_models.dart';
import '../domain/field_reports_controller.dart';
import 'report_status.dart';

class AdminReportSheet extends ConsumerStatefulWidget {
  const AdminReportSheet({super.key, required this.reportId});
  final String reportId;

  @override
  ConsumerState<AdminReportSheet> createState() => _AdminReportSheetState();
}

class _AdminReportSheetState extends ConsumerState<AdminReportSheet> {
  late final FieldReportAccess _access;
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  CancelToken? _token;
  FieldReport? _report;
  Object? _error;
  String? _target;
  bool _loading = true;
  bool _saving = false;
  bool _conflict = false;

  bool get _allowed =>
      mounted &&
      _access.canRead &&
      ref.read(fieldReportAccessProvider) == _access;

  @override
  void initState() {
    super.initState();
    _access = ref.read(fieldReportAccessProvider);
    ref.listenManual(fieldReportAccessProvider, (_, next) {
      if (next == _access) return;
      _token?.cancel('report access changed');
      _reason.clear();
      setState(() {
        _report = null;
        _target = null;
        _loading = false;
        _saving = false;
      });
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _token?.cancel('report closed');
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_allowed) return;
    _token?.cancel('superseded');
    final token = _token = CancelToken();
    setState(() {
      _loading = true;
      _error = null;
      _report = null;
    });
    try {
      final report = await ref
          .read(fieldReportRepositoryProvider)
          .getAdminDetail(widget.reportId, cancelToken: token);
      if (!_allowed || token.isCancelled) return;
      setState(() {
        _report = report;
        _conflict = false;
        _target = null;
      });
    } catch (error) {
      if (_allowed && !token.isCancelled) setState(() => _error = error);
    } finally {
      if (_allowed && !token.isCancelled) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final report = _report;
    final status = _target;
    if (!_allowed ||
        !_access.canReview ||
        _saving ||
        _conflict ||
        report == null ||
        status == null ||
        !_form.currentState!.validate()) {
      return;
    }
    final token = _token = CancelToken();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(fieldReportRepositoryProvider)
          .review(
            report,
            status: status,
            reason: _reason.text,
            cancelToken: token,
          );
      if (!mounted || !_allowed || token.isCancelled) return;
      _reason.clear();
      if (ref.exists(fieldReportsProvider)) {
        final controller = ref.read(fieldReportsProvider.notifier);
        controller.applyReviewedReport(updated);
        unawaited(controller.refresh());
      }
      if (ref.exists(myReportsProvider)) {
        unawaited(ref.read(myReportsProvider.notifier).loadFirstPage());
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.reportReviewSaved)));
      await _load();
    } catch (error) {
      if (!_allowed || token.isCancelled) return;
      final code = error is DioException
          ? error.response?.statusCode
          : error is AppException
          ? error.statusCode
          : null;
      setState(() {
        _error = error;
        _conflict = code == 409;
        if (code == 401 || code == 403) _report = null;
      });
    } finally {
      if (_allowed) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(fieldReportAccessProvider);
    final l10n = context.l10n;
    if (access != _access || !access.canRead) {
      return AppStateMessage(
        icon: Icons.lock_outline,
        title: const ForbiddenException().localizedErrorMessage(l10n),
      );
    }
    final report = _report;
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.88,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.reportAdminView,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              AppInlineNotice(
                icon: Icons.lock_outline,
                message: l10n.reportPrivateNotice,
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: AppInlineNotice(
                    icon: Icons.error_outline,
                    message: _conflict
                        ? l10n.reportReviewConflict
                        : _error!.localizedErrorMessage(l10n),
                    tone: AppFeedbackTone.error,
                    actionLabel: l10n.commonRetry,
                    onAction: _saving ? null : _load,
                    liveRegion: true,
                  ),
                ),
              if (report != null && !_loading) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      report.referenceCode,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ReportStatusBadge(status: report.status),
                  ],
                ),
                const SizedBox(height: 16),
                SelectableText(
                  report.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _Info(
                  label: l10n.reportSender,
                  value: [
                    report.senderName,
                    report.senderEmail,
                    report.senderUserId,
                  ].whereType<String>().join('\n'),
                ),
                _Info(
                  label: l10n.reportLocationStep,
                  value:
                      '${report.location.latitude.toStringAsFixed(6)}, ${report.location.longitude.toStringAsFixed(6)}'
                      '${report.measuredGeometry == null ? '' : '\n${report.measuredGeometry!.type}'}',
                ),
                if (report.photos.isNotEmpty)
                  SizedBox(
                    height: 210,
                    child: PageView.builder(
                      itemCount: report.photos.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            ApiConfig.rewriteStorageUrl(
                              report.photos[index].url.toString(),
                            ),
                            fit: BoxFit.contain,
                            cacheWidth:
                                (MediaQuery.sizeOf(context).width *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            semanticLabel: l10n.reportPhotoPosition(
                              index + 1,
                              report.photos.length,
                            ),
                            errorBuilder: (_, _, _) => Center(
                              child: TextButton.icon(
                                onPressed: _saving ? null : _load,
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.commonRetry),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (report.reviewReason != null)
                  _Info(
                    label: l10n.reportReviewReason,
                    value: report.reviewReason!,
                  ),
                if (report.reviewedBy != null)
                  _Info(label: l10n.reportReviewer, value: report.reviewedBy!),
                if (report.reviewedAt != null)
                  _Info(
                    label: l10n.reportReviewedAt,
                    value: _date(context, report.reviewedAt!),
                  ),
                if (access.canReview &&
                    report.reviewTransitions.isNotEmpty) ...[
                  const Divider(height: 32),
                  Text(
                    l10n.reportReviewAction,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in report.reviewTransitions)
                        ChoiceChip(
                          key: ValueKey('review-status-$status'),
                          label: Text(reportStatusLabel(context, status)),
                          selected: _target == status,
                          onSelected: _saving || _conflict
                              ? null
                              : (_) => setState(() => _target = status),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _form,
                    child: TextFormField(
                      key: const ValueKey('report-review-reason'),
                      controller: _reason,
                      enabled: !_saving,
                      maxLength: 1000,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: l10n.reportReviewReason,
                        helperText: l10n.reportReviewReasonHint,
                        helperMaxLines: 3,
                        errorMaxLines: 3,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final reason = value?.trim() ?? '';
                        if ((_target == 'rejected' && reason.isEmpty) ||
                            (reason.isNotEmpty &&
                                (reason.length < 5 || reason.length > 1000))) {
                          return l10n.reportReviewReasonInvalid;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('report-review-submit'),
                    onPressed: _saving || _conflict || _target == null
                        ? null
                        : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(l10n.reportReviewSubmit),
                  ),
                ],
                const Divider(height: 32),
                Text(
                  l10n.reportHistory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final event in report.history.reversed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReportStatusBadge(status: event.newStatus),
                        const SizedBox(height: 6),
                        Text(_date(context, event.createdAt)),
                        if (event.actorUserId != null)
                          Text('${l10n.reportReviewer}: ${event.actorUserId}'),
                        if (event.reason != null) SelectableText(event.reason!),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _date(BuildContext context, DateTime date) {
  final local = date.toLocal();
  final l10n = MaterialLocalizations.of(context);
  return '${l10n.formatMediumDate(local)} ${l10n.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true)}';
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(value.isEmpty ? '—' : value),
      ],
    ),
  );
}

class ReportClustersSheet extends ConsumerStatefulWidget {
  const ReportClustersSheet({super.key});
  @override
  ConsumerState<ReportClustersSheet> createState() =>
      _ReportClustersSheetState();
}

class _ReportClustersSheetState extends ConsumerState<ReportClustersSheet> {
  late final FieldReportAccess _access;
  late DateTimeRange _range;
  double _radius = 100;
  double _minReporters = 2;
  CancelToken? _token;
  List<FieldReportCluster>? _clusters;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _access = ref.read(fieldReportAccessProvider);
    final now = DateTime.now();
    _range = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    ref.listenManual(fieldReportAccessProvider, (_, next) {
      if (next == _access) return;
      _token?.cancel('cluster access changed');
      setState(() {
        _clusters = null;
        _error = null;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _token?.cancel('clusters closed');
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_loading ||
        !_access.canStats ||
        ref.read(fieldReportAccessProvider) != _access) {
      return;
    }
    final token = _token = CancelToken();
    setState(() {
      _loading = true;
      _error = null;
      _clusters = null;
    });
    try {
      final clusters = await ref
          .read(fieldReportRepositoryProvider)
          .getClusters(
            from: _range.start.toUtc(),
            to: _range.end.toUtc(),
            radiusMeters: _radius.round(),
            minReporters: _minReporters.round(),
            cancelToken: token,
          );
      if (mounted && !token.isCancelled) setState(() => _clusters = clusters);
    } catch (error) {
      if (mounted && !token.isCancelled) setState(() => _error = error);
    } finally {
      if (mounted && !token.isCancelled) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(fieldReportAccessProvider);
    final l10n = context.l10n;
    if (access != _access || !access.canStats) {
      return AppStateMessage(
        icon: Icons.lock_outline,
        title: const ForbiddenException().localizedErrorMessage(l10n),
      );
    }
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Text(
              l10n.reportClustersTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            AppInlineNotice(
              icon: Icons.info_outline,
              message: l10n.reportClustersLimit,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range_outlined),
              title: Text(l10n.reportNearbyDateRange),
              subtitle: Text(
                '${_date(context, _range.start)} – ${_date(context, _range.end)}',
              ),
              onTap: _loading
                  ? null
                  : () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: now.subtract(const Duration(days: 365)),
                        lastDate: now,
                        initialDateRange: _range,
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _range = DateTimeRange(
                            start: picked.start,
                            end: DateTime(
                              picked.end.year,
                              picked.end.month,
                              picked.end.day + 1,
                            ).subtract(const Duration(microseconds: 1)),
                          );
                          _clusters = null;
                        });
                      }
                    },
            ),
            Text(l10n.reportNearbyRadius(_radius.round())),
            Slider(
              value: _radius,
              min: 10,
              max: 500,
              divisions: 49,
              label: '${_radius.round()} m',
              onChanged: _loading
                  ? null
                  : (value) => setState(() {
                      _radius = value;
                      _clusters = null;
                    }),
            ),
            Text('${l10n.reportClusterMinReporters}: ${_minReporters.round()}'),
            Slider(
              value: _minReporters,
              min: 2,
              max: 20,
              divisions: 18,
              label: '${_minReporters.round()}',
              onChanged: _loading
                  ? null
                  : (value) => setState(() {
                      _minReporters = value;
                      _clusters = null;
                    }),
            ),
            FilledButton.icon(
              key: const ValueKey('report-clusters-analyze'),
              onPressed: _loading ? null : _analyze,
              icon: const Icon(Icons.hub_outlined),
              label: Text(l10n.reportClusterAnalyze),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null)
              AppInlineNotice(
                icon: Icons.error_outline,
                message: _error!.localizedErrorMessage(l10n),
                tone: AppFeedbackTone.error,
                liveRegion: true,
              ),
            if (_clusters?.isEmpty == true)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.reportClustersEmpty),
              ),
            for (final cluster in _clusters ?? <FieldReportCluster>[])
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.reportClusterReports}: ${cluster.reportCount}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${l10n.reportClusterReporters}: ${cluster.reporterCount}',
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        '${cluster.location.latitude.toStringAsFixed(6)}, ${cluster.location.longitude.toStringAsFixed(6)}',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
