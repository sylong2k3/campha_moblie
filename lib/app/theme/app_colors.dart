import 'package:flutter/material.dart';

/// Token ngoài ThemeData. Tất cả lấy từ bảng xanh–trung tính của ứng dụng.
class AppColors {
  const AppColors._();

  static const seed = Color(0xFF006B63);
  static const primary = Color(0xFF006B63);
  static const primaryDeep = Color(0xFF073B3A);
  static const primaryBright = Color(0xFF00A99D);
  static const primaryDark = Color(0xFF5ED8CA);
  static const secondary = Color(0xFF3E6375);
  static const coastal = Color(0xFF8FD8D2);
  static const clay = Color(0xFFD5EFEC);
  static const sand = Color(0xFFF2E8CF);

  static const background = Color(0xFFF5F8F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE5ECEA);
  static const border = Color(0xFFC4D1CE);
  static const textPrimary = Color(0xFF102321);
  static const textMuted = Color(0xFF425B57);

  static const darkBackground = Color(0xFF071412);
  static const darkSurface = Color(0xFF101E1C);
  static const darkSurfaceMuted = Color(0xFF273936);
  static const darkBorder = Color(0xFF3D514D);
  static const darkTextPrimary = Color(0xFFE3EFEC);
  static const darkTextMuted = Color(0xFFB8CAC6);

  static const statusNew = Color(0xFF1677A3);
  static const statusInProgress = Color(0xFFD97706);
  static const statusResolved = Color(0xFF087A5B);
  static const statusError = Color(0xFFB42318);
  static const statusPendingSync = Color(0xFF64748B);

  static const warning = Color(0xFFF6C453);
  static const onWarning = Color(0xFF3D2A00);
  static const info = Color(0xFF8FD8D2);

  static const brandGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF073B3A), Color(0xFF006B63), Color(0xFF138A80)],
    stops: [0, 0.58, 1],
  );
  static const brandGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF041F1E), Color(0xFF073B3A), Color(0xFF075E58)],
    stops: [0, 0.58, 1],
  );
  static const ambientGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD5EFEC), Color(0xFFF1F6F4), Color(0xFFF8FAF9)],
    stops: [0, 0.56, 1],
  );
  static const ambientGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF071412), Color(0xFF102321), Color(0xFF073B3A)],
    stops: [0, 0.6, 1],
  );

  static LinearGradient brandGradient(Brightness brightness) =>
      brightness == Brightness.dark ? brandGradientDark : brandGradientLight;

  static LinearGradient ambientGradient(Brightness brightness) =>
      brightness == Brightness.dark
      ? ambientGradientDark
      : ambientGradientLight;
}
