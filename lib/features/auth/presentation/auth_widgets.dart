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
    final iconBg = light ? Colors.white.withValues(alpha: 0.14) : foreground;
    final double size = compact ? 38 : 48;
    final double iconSize = compact ? 22 : 28;
    final double radius = compact ? 12 : 15;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light ? iconBg : foreground,
            borderRadius: BorderRadius.circular(radius),
            border: light ? Border.all(color: Colors.white24) : null,
          ),
          child: Icon(
            Icons.map_outlined,
            color: light ? foreground : Colors.white,
            size: iconSize,
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
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: CustomPaint(
        painter: _GridPatternPainter(
          color: brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.025)
              : AppColors.primary.withValues(alpha: 0.03),
        ),
        child: child,
      ),
    );
  }
}

/// Subtle grid pattern overlay cho Auth backdrop — gợi nhớ hệ toạ độ bản đồ.
class _GridPatternPainter extends CustomPainter {
  _GridPatternPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Subtle corner dots at intersections
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPatternPainter oldDelegate) =>
      color != oldDelegate.color;
}

class ErrorBanner extends StatefulWidget {
  const ErrorBanner({super.key, required this.error});
  final Object error;

  @override
  State<ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<ErrorBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shake;

  bool _animationInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationInitialized) return;
    _animationInitialized = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _shake,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shake.value, 0),
                child: child,
              ),
              child: Icon(Icons.error_outline, color: colors.onErrorContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.error.localizedErrorMessage(context.l10n),
                style: TextStyle(
                  color: colors.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
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
