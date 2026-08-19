import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/domain/session_controller.dart';
import '../../shared/presentation/app_feedback.dart';
import '../data/cms_repository.dart';
import '../domain/cms_models.dart';
import 'cms_widgets.dart';

final newsDetailProvider = FutureProvider.autoDispose.family<NewsModel, String>(
  (ref, id) => ref.read(cmsRepositoryProvider).getNewsDetail(id),
);

final newsCommentsProvider = FutureProvider.autoDispose
    .family<PagedResult<NewsComment>, String>(
      (ref, id) => ref.read(cmsRepositoryProvider).getComments(id, limit: 100),
    );

class NewsDetailScreen extends ConsumerStatefulWidget {
  const NewsDetailScreen({
    super.key,
    required this.newsId,
    this.openComposer = false,
  });

  final String newsId;
  final bool openComposer;

  @override
  ConsumerState<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends ConsumerState<NewsDetailScreen> {
  final _commentController = TextEditingController();
  final _composerKey = GlobalKey();
  bool _submitting = false;
  String? _submitErrorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(newsDetailProvider(widget.newsId));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.newsDetailTitle),
        actions: [
          IconButton(
            key: const ValueKey('share-news'),
            tooltip: context.l10n.cmsShare,
            onPressed: detail.valueOrNull == null
                ? null
                : () => _shareArticle(detail.valueOrNull!),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const CmsLoadingList(),
        error: (error, _) => CmsErrorState(
          error: error,
          onRetry: () => ref.invalidate(newsDetailProvider(widget.newsId)),
        ),
        data: (news) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(newsDetailProvider(widget.newsId));
            ref.invalidate(newsCommentsProvider(widget.newsId));
            await ref.read(newsDetailProvider(widget.newsId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
            children: [
              _Article(news: news),
              const SizedBox(height: 28),
              _CommentsSection(newsId: widget.newsId),
              const SizedBox(height: 18),
              _Composer(
                key: _composerKey,
                controller: _commentController,
                submitting: _submitting,
                errorMessage: _submitErrorMessage,
                autofocus: widget.openComposer,
                onChanged: (_) {
                  if (_submitErrorMessage != null) {
                    setState(() => _submitErrorMessage = null);
                  }
                },
                onSubmit: _submitComment,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareArticle(NewsModel news) => SharePlus.instance.share(
    ShareParams(
      title: news.title,
      subject: news.title,
      text: '${news.title}\n\n${news.summary}\n\nGIS Cẩm Phả',
    ),
  );

  Future<void> _submitComment() async {
    final session = ref.read(sessionControllerProvider);
    final returnTo = '/news/${widget.newsId}?compose=1';
    if (!session.isAuthenticated) {
      context.push(
        '/auth/login?returnTo=${Uri.encodeQueryComponent(returnTo)}',
      );
      return;
    }
    final content = _commentController.text.trim();
    if (content.isEmpty ||
        content.length > 2000 ||
        content.contains(RegExp(r'[<>]'))) {
      setState(() => _submitErrorMessage = context.l10n.commentInvalid);
      return;
    }
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _submitErrorMessage = null;
    });
    try {
      final comment = await ref
          .read(cmsRepositoryProvider)
          .createComment(widget.newsId, content);
      if (!mounted) return;
      _commentController.clear();
      ref.invalidate(newsCommentsProvider(widget.newsId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            comment.status == 'pending'
                ? context.l10n.commentPending
                : context.l10n.commentSent,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _submitErrorMessage = error.localizedErrorMessage(context.l10n),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _Article extends StatelessWidget {
  const _Article({required this.news});
  final NewsModel news;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          context.l10n.newsOfficialBadge,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(news.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 10),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 7,
        runSpacing: 4,
        children: [
          const Icon(Icons.schedule, size: 18),
          Text(cmsDate(context, news.publishedAt)),
        ],
      ),
      if (news.summary.isNotEmpty) ...[
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            news.summary,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
      const SizedBox(height: 24),
      _SafeMarkdown(content: news.content ?? ''),
    ],
  );
}

class _SafeMarkdown extends StatelessWidget {
  const _SafeMarkdown({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeSafeContent(content);
    final blocks = normalized.split(RegExp(r'\n\s*\n'));
    if (blocks.every((block) => block.trim().isEmpty)) {
      return Text(context.l10n.newsContentEmpty);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rawBlock in blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: _block(context, rawBlock.trim()),
          ),
      ],
    );
  }

  String _normalizeSafeContent(String raw) {
    var value = raw.replaceAll('\r\n', '\n');
    if (!RegExp(r'<[^>]+>').hasMatch(value)) return value;
    value = value
        .replaceAll(RegExp(r'<\s*h1[^>]*>', caseSensitive: false), '\n\n# ')
        .replaceAll(RegExp(r'<\s*h2[^>]*>', caseSensitive: false), '\n\n## ')
        .replaceAll(RegExp(r'<\s*h3[^>]*>', caseSensitive: false), '\n\n### ')
        .replaceAll(RegExp(r'<\s*li[^>]*>', caseSensitive: false), '\n- ')
        .replaceAll(RegExp(r'<\s*(p|tr)[^>]*>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'<\s*(br|/p|/tr|/table)\s*/?>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<\s*(td|th)[^>]*>', caseSensitive: false), ' · ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return value.trim();
  }

  Widget _block(BuildContext context, String block) {
    if (block.startsWith('### ')) {
      return Text(
        block.substring(4),
        style: Theme.of(context).textTheme.titleMedium,
      );
    }
    if (block.startsWith('## ')) {
      return Text(
        block.substring(3),
        style: Theme.of(context).textTheme.titleLarge,
      );
    }
    if (block.startsWith('# ')) {
      return Text(
        block.substring(2),
        style: Theme.of(context).textTheme.headlineSmall,
      );
    }
    final lines = block.split('\n');
    if (lines.every((line) => RegExp(r'^[-*]\s+').hasMatch(line.trim()))) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 9),
                    child: SizedBox.square(
                      dimension: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line.trim().substring(2),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return Text(block, style: Theme.of(context).textTheme.bodyLarge);
  }
}

class _CommentsSection extends ConsumerWidget {
  const _CommentsSection({required this.newsId});
  final String newsId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(newsCommentsProvider(newsId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.forum_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                context.l10n.commentsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        comments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => CmsErrorState(
            error: error,
            onRetry: () => ref.invalidate(newsCommentsProvider(newsId)),
          ),
          data: (result) {
            if (result.items.isEmpty) {
              return AppInlineNotice(
                message: context.l10n.commentsEmpty,
                icon: Icons.forum_outlined,
                tone: AppFeedbackTone.neutral,
              );
            }
            return Column(
              children: [
                for (final comment in result.items) ...[
                  _CommentCard(comment: comment),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});
  final NewsComment comment;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: Text(comment.fullName.trim().characters.first.toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.fullName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  cmsDate(context, comment.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 7),
                Text(comment.content),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Composer extends ConsumerWidget {
  const _Composer({
    super.key,
    required this.controller,
    required this.submitting,
    required this.errorMessage,
    required this.autofocus,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool submitting;
  final String? errorMessage;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticated = ref.watch(sessionControllerProvider).isAuthenticated;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.commentWriteTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (errorMessage != null) ...[
              AppInlineNotice(
                message: errorMessage!,
                icon: Icons.error_outline,
                tone: AppFeedbackTone.error,
                liveRegion: true,
              ),
              const SizedBox(height: 8),
            ],
            if (authenticated)
              TextField(
                key: const ValueKey('comment-input'),
                controller: controller,
                autofocus: autofocus,
                enabled: !submitting,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                onChanged: onChanged,
                decoration: InputDecoration(hintText: context.l10n.commentHint),
              )
            else
              Text(context.l10n.commentLoginBody),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const ValueKey('comment-submit'),
              onPressed: submitting ? null : onSubmit,
              icon: submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(authenticated ? Icons.send_outlined : Icons.login),
              label: Text(
                authenticated
                    ? context.l10n.commentSend
                    : context.l10n.loginAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
