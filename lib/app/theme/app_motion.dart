import 'package:flutter/material.dart';

/// Shared motion values. Keep platform-camera timings separate from UI motion.
abstract final class AppMotion {
  static const quick = Duration(milliseconds: 120);
  static const state = Duration(milliseconds: 160);
  static const surface = Duration(milliseconds: 220);
  static const page = Duration(milliseconds: 240);
  static const cameraMs = 450;
  static const cameraFarMs = 700;

  static const stateCurve = Curves.easeOut;
  static const surfaceCurve = Curves.easeOutCubic;
  static const emphasizedCurve = Curves.easeInOutCubicEmphasized;

  static bool disabled(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration of(BuildContext context, Duration duration) =>
      disabled(context) ? Duration.zero : duration;

  static int camera(BuildContext context, {bool far = false}) =>
      disabled(context)
      ? 0
      : far
      ? cameraFarMs
      : cameraMs;

  static Widget stateTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: surfaceCurve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  /// Tạo delay cho hiệu ứng cascade khi danh sách item xuất hiện lần lượt.
  /// [index]: vị trí của item trong danh sách.
  /// Returns Duration delay phù hợp (tối đa ~400ms tại index 8).
  static Duration staggerDelay(int index) =>
      Duration(milliseconds: (index.clamp(0, 8) * 50));

  /// Animation builder cho item xuất hiện cascade: fade + slide lên.
  /// Dùng trong `AnimatedList` hoặc custom `TweenAnimationBuilder`.
  static Widget staggeredEntrance({
    required Widget child,
    required int index,
    required bool animate,
  }) {
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: surface + staggerDelay(index),
      curve: surfaceCurve,
      builder: (context, value, child) {
        if (disabled(context)) return child!;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Scale-in animation cho FAB, badge, hoặc phần tử popup.
  static Widget scaleIn({
    required Widget child,
    Duration? duration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: duration ?? state,
      curve: emphasizedCurve,
      builder: (context, value, child) {
        if (disabled(context)) return child!;
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: child,
    );
  }
}

