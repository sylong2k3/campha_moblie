import 'package:flutter/material.dart';

/// Token ngoài ThemeData. Tất cả lấy từ bảng xanh–trung tính của ứng dụng.
class AppColors {
  const AppColors._();

  static const seed = Color(0xFF16A34A);
  static const primary = Color(0xFF16A34A);
  static const primaryDeep = Color(0xFF073719);
  static const primaryBright = Color(0xFF22C55E);
  static const primaryDark = Color(0xFF22C55E);
  static const secondary = Color(0xFFF4F4F5);
  static const coastal = Color(0xFF97E0B3);
  static const clay = Color(0xFFC6F2D6);
  static const sand = Color(0xFFE7E7E7);

  static const background = Color(0xFFFCFCFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE7E7E7);
  static const border = Color(0xFFD1D1D1);
  static const textPrimary = Color(0xFF111111);
  static const textMuted = Color(0xFF393939);

  static const darkBackground = Color(0xFF080808);
  static const darkSurface = Color(0xFF151515);
  static const darkSurfaceMuted = Color(0xFF282828);
  static const darkBorder = Color(0xFF414141);
  static const darkTextPrimary = Color(0xFFF1F1F1);
  static const darkTextMuted = Color(0xFFCACACA);

  static const statusNew = Color(0xFF97E0B3);
  static const statusInProgress = Color(0xFFC6F2D6);
  static const statusResolved = Color(0xFF16A34A);
  static const statusError = Color(0xFFEF4444);
  static const statusPendingSync = Color(0xFF919191);

  static const warning = Color(0xFFE7E7E7);
  static const onWarning = Color(0xFF111111);
  static const info = Color(0xFF97E0B3);

  static const brandGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF073719), Color(0xFF16A34A), Color(0xFF22C55E)],
    stops: [0, 0.58, 1],
  );
  static const brandGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF073719), Color(0xFF0A4620), Color(0xFF185930)],
    stops: [0, 0.58, 1],
  );
  static const ambientGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC6F2D6), Color(0xFFF8F8F8), Color(0xFFFCFCFC)],
    stops: [0, 0.56, 1],
  );
  static const ambientGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF010101), Color(0xFF0E0E0E), Color(0xFF185930)],
    stops: [0, 0.6, 1],
  );

  static LinearGradient brandGradient(Brightness brightness) =>
      brightness == Brightness.dark ? brandGradientDark : brandGradientLight;

  static LinearGradient ambientGradient(Brightness brightness) =>
      brightness == Brightness.dark
      ? ambientGradientDark
      : ambientGradientLight;
}
