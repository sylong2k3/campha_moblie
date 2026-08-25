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
}
