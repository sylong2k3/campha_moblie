import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';

class CivicBrand extends StatelessWidget {
  const CivicBrand({super.key, this.compact = false, this.light = false});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final foreground = light
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 48,
          height: compact ? 38 : 48,
          decoration: BoxDecoration(
            color: light ? Colors.white.withValues(alpha: 0.14) : foreground,
            borderRadius: BorderRadius.circular(compact ? 12 : 15),
            border: light ? Border.all(color: Colors.white24) : null,
          ),
          child: Icon(
            Icons.map_outlined,
            color: Colors.white,
            size: compact ? 22 : 28,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.appTitle.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!compact)
                Text(
                  context.l10n.brandTagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.72),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: AppColors.ambientGradient(Theme.of(context).brightness),
    ),
    child: child,
  );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colors.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error.localizedErrorMessage(context.l10n),
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubmitLabel extends StatelessWidget {
  const SubmitLabel({super.key, required this.busy, required this.label});
  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) => busy
      ? const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Text(label);
}

String? requiredText(String? value, String message) =>
    value == null || value.trim().isEmpty ? message : null;

String? emailError(AppLocalizations l10n, String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return l10n.emailRequired;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return l10n.emailInvalid;
  }
  return null;
}

String? passwordError(
  AppLocalizations l10n,
  String? value, {
  bool enforceLength = false,
}) {
  if (value == null || value.isEmpty) return l10n.passwordRequired;
  if (enforceLength && value.length < 8) return l10n.passwordMinLength;
  if (value.length > 128) return l10n.passwordMaxLength;
  return null;
}
