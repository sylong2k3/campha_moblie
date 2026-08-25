import 'package:campha_moblie/app/theme/app_motion.dart';
import 'package:flutter/material.dart';

enum AppFeedbackTone { neutral, info, warning, error, success }

/// Notice nội tuyến cho trạng thái còn giữ được nội dung hiện tại.
class AppInlineNotice extends StatelessWidget {
  const AppInlineNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.tone = AppFeedbackTone.info,
    this.actionLabel,
    this.onAction,
    this.liveRegion = false,
  });

  final String message;
  final IconData icon;
  final AppFeedbackTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      AppFeedbackTone.error => (colors.errorContainer, colors.onErrorContainer),
      AppFeedbackTone.warning => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      AppFeedbackTone.success => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      AppFeedbackTone.info => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      AppFeedbackTone.neutral => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };
    final contentKey = ValueKey('${tone.name}:$message:${actionLabel ?? ''}');
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: AppStateSwitcher(
        stateKey: contentKey,
        animateSize: false,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stackAction =
                    actionLabel != null &&
                    onAction != null &&
                    (constraints.maxWidth < 360 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3);
                final content = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 21, color: foreground),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(message, style: TextStyle(color: foreground)),
                    ),
                    if (!stackAction &&
                        actionLabel != null &&
                        onAction != null) ...[
                      const SizedBox(width: 6),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: foreground,
                        ),
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                );
                if (!stackAction) return content;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: foreground,
                        ),
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Chuyển giữa loading/error/empty/content mà không làm UI bật đột ngột.
/// Child cần [stateKey] ổn định theo trạng thái, không theo từng frame dữ liệu.
class AppStateSwitcher extends StatelessWidget {
  const AppStateSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
    this.animateSize = true,
    this.alignment = Alignment.topCenter,
  });

  final Key stateKey;
  final Widget child;
  final bool animateSize;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.disabled(context)) {
      return KeyedSubtree(key: stateKey, child: child);
    }
    final switcher = AnimatedSwitcher(
      duration: AppMotion.surface,
      reverseDuration: AppMotion.state,
      switchInCurve: AppMotion.surfaceCurve,
      switchOutCurve: AppMotion.stateCurve,
      transitionBuilder: AppMotion.stateTransition,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: alignment,
        children: [...previousChildren, ?currentChild],
      ),
      child: KeyedSubtree(key: stateKey, child: child),
    );
    if (!animateSize) return switcher;
    return AnimatedSize(
      duration: AppMotion.surface,
      curve: AppMotion.surfaceCurve,
      alignment: alignment,
      child: switcher,
    );
  }
}

/// Trạng thái toàn vùng cho loading/error/empty có một lối phục hồi rõ.
class AppStateMessage extends StatelessWidget {
  const AppStateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.tone = AppFeedbackTone.neutral,
    this.liveRegion = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppFeedbackTone tone;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = switch (tone) {
      AppFeedbackTone.error => colors.error,
      AppFeedbackTone.warning => colors.tertiary,
      AppFeedbackTone.success => colors.primary,
      AppFeedbackTone.info => colors.secondary,
      AppFeedbackTone.neutral => colors.primary,
    };
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: iconColor),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (body case final body?) ...[
                  const SizedBox(height: 8),
                  Text(body, textAlign: TextAlign.center),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.refresh),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
