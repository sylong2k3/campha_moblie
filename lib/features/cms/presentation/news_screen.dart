import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/cms_models.dart';
import '../domain/paged_controller.dart';
import 'cms_widgets.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 420) {
      ref.read(newsListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(newsListProvider);
    final controller = ref.read(newsListProvider.notifier);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(title: Text(l10n.navNews)),
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
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.verified_outlined,
                      size: 19,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.newsOfficialSource,
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
              child: CmsSearchField(
                hint: l10n.newsSearchHint,
                initialValue: state.query,
                onSearch: controller.search,
              ),
            ),
            if (state.stale)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: CmsStaleBanner(onRetry: controller.loadFirstPage),
              ),
            Expanded(child: _body(state, controller)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    PagedState<NewsModel> state,
    PagedController<NewsModel> controller,
  ) {
    final l10n = context.l10n;
    if (state.loading && state.items.isEmpty) return const CmsLoadingList();
    if (state.error != null && state.items.isEmpty) {
      return CmsErrorState(
        error: state.error!,
        onRetry: controller.loadFirstPage,
      );
    }
    if (state.items.isEmpty) {
      return CmsEmptyState(
        icon: Icons.newspaper_outlined,
        title: state.query.isEmpty
            ? l10n.newsEmptyTitle
            : l10n.cmsNoSearchResult,
        body: state.query.isEmpty
            ? l10n.newsEmptyBody
            : l10n.cmsTryAnotherSearch,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.loadFirstPage,
      child: ListView.separated(
        key: const PageStorageKey('news-list'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
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
          return _NewsCard(news: state.items[index], emphasized: index == 0);
        },
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news, required this.emphasized});

  final NewsModel news;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${news.title}. ${cmsDate(context, news.publishedAt)}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('news-${news.id}'),
          onTap: () => context.push('/news/${news.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (emphasized)
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.secondary],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(emphasized ? 20 : 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.l10n.newsOfficialBadge,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              cmsDate(context, news.publishedAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      news.title,
                      maxLines: emphasized ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: emphasized
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.titleMedium,
                    ),
                    if (news.summary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        news.summary,
                        maxLines: emphasized ? 4 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          context.l10n.newsReadMore,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colors.primary),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
