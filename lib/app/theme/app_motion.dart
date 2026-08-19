import 'package:flutter/material.dart';

/// Shared motion values. Keep platform-camera timings separate from UI motion.
abstract final class AppMotion {
  static const state = Duration(milliseconds: 160);
  static const surface = Duration(milliseconds: 220);
  static const page = Duration(milliseconds: 240);
  static const cameraMs = 450;
  static const cameraFarMs = 700;

  static const stateCurve = Curves.easeOut;
  static const surfaceCurve = Curves.easeOutCubic;

  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
