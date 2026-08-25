import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/permissions/user_role.dart';
import '../../auth/domain/session_controller.dart';
import '../../shared/presentation/app_feedback.dart';
import '../domain/cms_models.dart';
import '../domain/paged_controller.dart';
import 'cms_widgets.dart';

/// Lọc [items] theo vai trò (ẩn hẳn nội bộ nếu không có quyền) rồi theo
/// [filter] người dùng chọn trên thanh Tất cả/Công khai/Nội bộ.
List<T> _filterByVisibility<T>(
  List<T> items,
  bool Function(T) isInternal, {
  required bool canViewInternal,
  required CmsVisibilityFilter filter,
}) {
  final visible = canViewInternal
      ? items
      : items.where((item) => !isInternal(item));
  final scoped = switch (filter) {
    CmsVisibilityFilter.all => visible,
    CmsVisibilityFilter.public => visible.where((item) => !isInternal(item)),
    CmsVisibilityFilter.internal => visible.where(isInternal),
  };
  return scoped.toList(growable: false);
}

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
    with AutomaticKeepAliveClientMixin {
  int _segment = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(title: Text(l10n.navDocuments)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      size: 19,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.documentsVerifiedSource,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  key: const ValueKey('document-segments'),
                  segments: [
                    ButtonSegment(
                      value: 0,
                      icon: const Icon(Icons.description_outlined),
                      label: Text(l10n.documentsSegment),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: const Icon(Icons.map_outlined),
                      label: Text(l10n.pdfMapsSegment),
                    ),
                  ],
                  selected: {_segment},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      setState(() => _segment = value.first),
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _segment,
                children: [
                  for (final entry in const [
                    (0, _DocumentList()),
                    (1, _PdfMapList()),
                  ])
                    IgnorePointer(
                      ignoring: _segment != entry.$1,
                      child: AnimatedOpacity(
                        duration: AppMotion.of(context, AppMotion.state),
                        curve: AppMotion.stateCurve,
                        opacity: _segment == entry.$1 ? 1 : 0,
                        child: entry.$2,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentList extends ConsumerStatefulWidget {
  const _DocumentList();

  @override
  ConsumerState<_DocumentList> createState() => _DocumentListState();
}

class _DocumentListState extends ConsumerState<_DocumentList> {
  final _scroll = ScrollController();
  CmsVisibilityFilter _visibility = CmsVisibilityFilter.all;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 380) {
        ref.read(documentListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentListProvider);
    final controller = ref.read(documentListProvider.notifier);
    final role = UserRole.fromApiValue(
      ref.watch(sessionControllerProvider.select((s) => s.user?.roleCode)),
    );
    final canViewInternal = role.canViewInternalDocuments;
    final items = _filterByVisibility<CmsDocumentModel>(
      state.items,
      (item) => item.isInternal,
      canViewInternal: canViewInternal,
      filter: _visibility,
    );
    return _CmsListLayout<CmsDocumentModel>(
      searchHint: context.l10n.documentsSearchHint,
      state: state.copyWith(items: items),
      controller: controller,
      scrollController: _scroll,
      emptyIcon: Icons.description_outlined,
      emptyTitle: context.l10n.documentsEmptyTitle,
      emptyBody: context.l10n.documentsEmptyBody,
      filterBar: canViewInternal
          ? CmsVisibilityFilterBar(
              value: _visibility,
              onChanged: (value) => setState(() => _visibility = value),
            )
          : null,
      itemBuilder: (context, item) => _DocumentCard(item: item),
    );
  }
}

class _PdfMapList extends ConsumerStatefulWidget {
  const _PdfMapList();

  @override
  ConsumerState<_PdfMapList> createState() => _PdfMapListState();
}

class _PdfMapListState extends ConsumerState<_PdfMapList> {
  final _scroll = ScrollController();
  CmsVisibilityFilter _visibility = CmsVisibilityFilter.all;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 380) {
        ref.read(pdfMapListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pdfMapListProvider);
    final controller = ref.read(pdfMapListProvider.notifier);
    final role = UserRole.fromApiValue(
      ref.watch(sessionControllerProvider.select((s) => s.user?.roleCode)),
    );
    final canViewInternal = role.canViewInternalDocuments;
    final items = _filterByVisibility<PdfMapModel>(
      state.items,
      (item) => item.isInternal,
      canViewInternal: canViewInternal,
      filter: _visibility,
    );
    return _CmsListLayout<PdfMapModel>(
      searchHint: context.l10n.pdfSearchHint,
      state: state.copyWith(items: items),
      controller: controller,
      scrollController: _scroll,
      emptyIcon: Icons.picture_as_pdf_outlined,
      emptyTitle: context.l10n.pdfEmptyTitle,
      emptyBody: context.l10n.pdfEmptyBody,
      filterBar: canViewInternal
          ? CmsVisibilityFilterBar(
              value: _visibility,
              onChanged: (value) => setState(() => _visibility = value),
            )
          : null,
      itemBuilder: (context, item) => _PdfMapCard(item: item),
    );
  }
}

class _CmsListLayout<T> extends StatelessWidget {
  const _CmsListLayout({
    required this.searchHint,
    required this.state,
    required this.controller,
    required this.scrollController,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyBody,
    required this.itemBuilder,
    this.filterBar,
  });

  final String searchHint;
  final PagedState<T> state;
  final PagedController<T> controller;
  final ScrollController scrollController;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyBody;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget? filterBar;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: CmsSearchField(
          hint: searchHint,
          initialValue: state.query,
          onSearch: controller.search,
        ),
      ),
      ?filterBar,
      if (state.stale)
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: CmsStaleBanner(onRetry: controller.loadFirstPage),
        ),
      Expanded(child: _body(context)),
    ],
  );

  Widget _body(BuildContext context) {
    final bodyState = state.loading && state.items.isEmpty
        ? 'loading'
        : state.error != null && state.items.isEmpty
        ? 'error'
        : state.items.isEmpty
        ? 'empty'
        : 'content';
    return AppStateSwitcher(
      stateKey: ValueKey('cms-${T.toString()}-$bodyState'),
      animateSize: false,
      child: switch (bodyState) {
        'loading' => const CmsLoadingList(),
        'error' => CmsErrorState(
          error: state.error!,
          onRetry: controller.loadFirstPage,
        ),
        'empty' => CmsEmptyState(
          icon: emptyIcon,
          title: state.query.isEmpty
              ? emptyTitle
              : context.l10n.cmsNoSearchResult,
          body: state.query.isEmpty
              ? emptyBody
              : context.l10n.cmsTryAnotherSearch,
        ),
        _ => RefreshIndicator(
          onRefresh: controller.loadFirstPage,
          child: ListView.separated(
            key: PageStorageKey('cms-${T.toString()}'),
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
            itemCount: state.items.length + 1,
            separatorBuilder: (_, index) => index == state.items.length - 1
                ? const SizedBox.shrink()
                : const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == state.items.length) {
                return CmsAppendFooter(
                  loading: state.appending,
                  error: state.appendError,
                  onRetry: controller.loadMore,
                );
              }
              return itemBuilder(context, state.items[index]);
            },
          ),
        ),
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.item});
  final CmsDocumentModel item;

  @override
  Widget build(BuildContext context) => _FileCard(
    icon: Icons.description_outlined,
    title: item.title,
    eyebrow: item.documentCode,
    meta: '${item.issuingAgency} · ${cmsDate(context, item.issuedAt)}',
    fileInfo: '${item.originalName} · ${formatFileSize(item.sizeBytes)}',
    internal: item.isInternal,
    onTap: () => context.push('/documents/${item.id}'),
  );
}

class _PdfMapCard extends StatelessWidget {
  const _PdfMapCard({required this.item});
  final PdfMapModel item;

  @override
  Widget build(BuildContext context) => _FileCard(
    icon: Icons.picture_as_pdf_outlined,
    title: item.title,
    eyebrow: '${item.scaleLabel} · ${item.mapYear}',
    meta: item.preparingAgency,
    fileInfo: '${item.originalName} · ${formatFileSize(item.sizeBytes)}',
    internal: item.isInternal,
    onTap: () => context.push('/documents/pdf/${item.id}'),
  );
}

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.icon,
    required this.title,
    required this.eyebrow,
    required this.meta,
    required this.fileInfo,
    required this.internal,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String eyebrow;
  final String meta;
  final String fileInfo;
  final bool internal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colors.onSecondaryContainer, size: 25),
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
                            eyebrow,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (internal) const CmsInternalBadge(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      fileInfo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
