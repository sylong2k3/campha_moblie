import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_config.dart';
import '../../../core/permissions/user_role.dart';
import '../../auth/domain/session_controller.dart';
import '../../shared/presentation/app_feedback.dart';
import '../data/cms_repository.dart';
import '../domain/cms_models.dart';
import 'cms_widgets.dart';

bool _isInternal(Object data) => switch (data) {
  CmsDocumentModel item => item.isInternal,
  PdfMapModel item => item.isInternal,
  _ => false,
};

class CmsFileDetailScreen extends ConsumerStatefulWidget {
  const CmsFileDetailScreen({
    super.key,
    required this.id,
    required this.pdfMap,
  });

  final String id;
  final bool pdfMap;

  @override
  ConsumerState<CmsFileDetailScreen> createState() =>
      _CmsFileDetailScreenState();
}

class _CmsFileDetailScreenState extends ConsumerState<CmsFileDetailScreen> {
  late Future<Object> _detail;
  bool _opening = false;
  bool _sharing = false;
  Object? _actionError;
  Object? _data;

  @override
  void initState() {
    super.initState();
    _load();
    ref.listenManual<SessionState>(sessionControllerProvider, (previous, next) {
      if (previous?.user?.id == next.user?.id &&
          previous?.status == next.status) {
        return;
      }
      if (mounted) setState(_load);
    });
  }

  void _load() {
    final repository = ref.read(cmsRepositoryProvider);
    _detail =
        (widget.pdfMap
                ? repository.getPdfMapDetail(widget.id)
                : repository.getDocumentDetail(widget.id))
            .then((value) => _data = value);
  }

  @override
  Widget build(BuildContext context) {
    final role = UserRole.fromApiValue(
      ref.watch(sessionControllerProvider.select((s) => s.user?.roleCode)),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pdfMap
              ? context.l10n.pdfDetailTitle
              : context.l10n.documentDetailTitle,
        ),
      ),
      body: FutureBuilder<Object>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CmsLoadingList();
          }
          if (snapshot.hasError) {
            return CmsErrorState(
              error: snapshot.error!,
              onRetry: () => setState(_load),
            );
          }
          final data = snapshot.data!;
          if (_isInternal(data) && !role.canViewInternalDocuments) {
            return AppStateMessage(
              icon: Icons.lock_outline,
              title: context.l10n.cmsInternalAccessDeniedTitle,
              body: context.l10n.cmsInternalAccessDeniedBody,
            );
          }
          return _content(data);
        },
      ),
    );
  }

  Widget _content(Object data) {
    final title = switch (data) {
      CmsDocumentModel item => item.title,
      PdfMapModel item => item.title,
      _ => '',
    };
    final description = switch (data) {
      CmsDocumentModel item => item.description,
      PdfMapModel item => item.description,
      _ => '',
    };
    final originalName = switch (data) {
      CmsDocumentModel item => item.originalName,
      PdfMapModel item => item.originalName,
      _ => '',
    };
    final size = switch (data) {
      CmsDocumentModel item => item.sizeBytes,
      PdfMapModel item => item.sizeBytes,
      _ => 0,
    };

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              widget.pdfMap ? Icons.map_outlined : Icons.description_outlined,
              size: 68,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 22),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: data is CmsDocumentModel
                  ? _documentMetadata(data)
                  : _pdfMetadata(data as PdfMapModel),
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              context.l10n.cmsDescription,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyLarge),
          ],
          const SizedBox(height: 22),
          Card(
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(originalName),
              subtitle: Text('PDF · ${formatFileSize(size)}'),
            ),
          ),
          if (_actionError != null) ...[
            const SizedBox(height: 12),
            AppInlineNotice(
              message: _actionError!.localizedErrorMessage(context.l10n),
              icon: Icons.error_outline,
              tone: AppFeedbackTone.error,
              liveRegion: true,
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const ValueKey('file-open'),
            onPressed: _opening || _sharing
                ? null
                : () => _runFileAction(share: false),
            icon: _opening
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.open_in_new),
            label: Text(context.l10n.cmsOpenFile),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('file-share'),
            onPressed: _opening || _sharing
                ? null
                : () => _runFileAction(share: true),
            icon: _sharing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            label: Text(context.l10n.cmsShareFile),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.cmsSecureLinkNotice,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentMetadata(CmsDocumentModel item) => Column(
    children: [
      _MetaRow(
        icon: Icons.tag,
        label: context.l10n.documentCodeLabel,
        value: item.documentCode,
      ),
      const Divider(height: 24),
      _MetaRow(
        icon: Icons.account_balance_outlined,
        label: context.l10n.issuingAgencyLabel,
        value: item.issuingAgency,
      ),
      const Divider(height: 24),
      _MetaRow(
        icon: Icons.calendar_today_outlined,
        label: context.l10n.issuedDateLabel,
        value: cmsDate(context, item.issuedAt),
      ),
    ],
  );

  Widget _pdfMetadata(PdfMapModel item) => Column(
    children: [
      _MetaRow(
        icon: Icons.straighten,
        label: context.l10n.scaleLabel,
        value: item.scaleLabel,
      ),
      const Divider(height: 24),
      _MetaRow(
        icon: Icons.calendar_today_outlined,
        label: context.l10n.mapYearLabel,
        value: '${item.mapYear}',
      ),
      const Divider(height: 24),
      _MetaRow(
        icon: Icons.account_balance_outlined,
        label: context.l10n.preparingAgencyLabel,
        value: item.preparingAgency,
      ),
    ],
  );

  Future<void> _runFileAction({required bool share}) async {
    final session = ref.read(sessionControllerProvider);
    final returnTo = widget.pdfMap
        ? '/documents/pdf/${widget.id}'
        : '/documents/${widget.id}';
    if (!session.isAuthenticated) {
      context.push(
        '/auth/login?returnTo=${Uri.encodeQueryComponent(returnTo)}',
      );
      return;
    }
    final data = _data;
    final role = UserRole.fromApiValue(session.user?.roleCode);
    if (data != null && _isInternal(data) && !role.canViewInternalDocuments) {
      setState(
        () => _actionError = ForbiddenException(
          context.l10n.cmsInternalAccessDeniedBody,
        ),
      );
      return;
    }
    final ownerId = session.user?.id;
    final noViewerMessage = context.l10n.cmsNoFileViewer;
    setState(() {
      _actionError = null;
      _sharing = share;
      _opening = !share;
    });
    try {
      final repository = ref.read(cmsRepositoryProvider);
      final grant =
          await freshDownloadGrant(
            load: widget.pdfMap
                ? () => repository.getPdfMapDownloadGrant(widget.id)
                : () => repository.getDocumentDownloadGrant(widget.id),
          ).onError<FormatException>(
            (_, _) => throw const UnknownException(
              'Liên kết tải tệp đã hết hạn. Vui lòng thử lại.',
            ),
          );
      if (ownerId != ref.read(sessionControllerProvider).user?.id) return;
      final shareUrl = ApiConfig.rewriteStorageUrl(grant.url.toString());
      if (share) {
        await SharePlus.instance.share(
          ShareParams(
            subject: grant.fileName,
            text: shareUrl,
          ),
        );
      } else {
        final opened = await launchUrl(
          Uri.parse(shareUrl),
          mode: LaunchMode.externalApplication,
        );
        if (!opened) throw StateError(noViewerMessage);
      }
    } catch (error) {
      if (mounted) setState(() => _actionError = error);
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
          _sharing = false;
        });
      }
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: value,
    excludeSemantics: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 3),
              SelectableText(value),
            ],
          ),
        ),
      ],
    ),
  );
}
