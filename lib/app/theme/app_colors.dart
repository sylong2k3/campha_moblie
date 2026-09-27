import 'package:flutter/material.dart';

/// Token ngoài ThemeData. Tất cả lấy từ bảng xanh–trung tính của ứng dụng.
/// Professional solid-color design — không dùng gradient.
class AppColors {
  const AppColors._();

  // ──── Brand Colors ────
  static const seed = Color(0xFF006B63);
  static const primary = Color(0xFF006B63);
  static const primaryDeep = Color(0xFF073B3A);
  static const primaryBright = Color(0xFF00A99D);
  static const primaryDark = Color(0xFF5ED8CA);
  static const secondary = Color(0xFF3E6375);
  static const coastal = Color(0xFF8FD8D2);
  static const clay = Color(0xFFD5EFEC);
  static const sand = Color(0xFFF2E8CF);

  // ──── Light Mode Surfaces ────
  static const background = Color(0xFFF5F8F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE5ECEA);
  static const border = Color(0xFFC4D1CE);
  static const textPrimary = Color(0xFF102321);
  static const textMuted = Color(0xFF425B57);

  // ──── Dark Mode Surfaces ────
  static const darkBackground = Color(0xFF071412);
  static const darkSurface = Color(0xFF101E1C);
  static const darkSurfaceMuted = Color(0xFF273936);
  static const darkBorder = Color(0xFF3D514D);
  static const darkTextPrimary = Color(0xFFE3EFEC);
  static const darkTextMuted = Color(0xFFB8CAC6);

  // ──── Status Colors ────
  static const statusNew = Color(0xFF1677A3);
  static const statusInProgress = Color(0xFFD97706);
  static const statusResolved = Color(0xFF087A5B);
  static const statusError = Color(0xFFB42318);
  static const statusPendingSync = Color(0xFF64748B);

  // ──── Semantic Feedback Colors ────
  static const warning = Color(0xFFF6C453);
  static const onWarning = Color(0xFF3D2A00);
  static const info = Color(0xFF8FD8D2);

  // Soft semantic backgrounds — dùng cho banners, badges, alerts
  static const successSoftLight = Color(0xFFE6F5EC);
  static const successSoftDark = Color(0xFF0D2818);
  static const warningSoftLight = Color(0xFFFFF8E6);
  static const warningSoftDark = Color(0xFF2D2300);
  static const infoSoftLight = Color(0xFFE8F7F6);
  static const infoSoftDark = Color(0xFF0A2220);
  static const errorSoftLight = Color(0xFFFEF0EE);
  static const errorSoftDark = Color(0xFF2D0A06);

  static Color successSoft(Brightness b) =>
      b == Brightness.dark ? successSoftDark : successSoftLight;
  static Color warningSoft(Brightness b) =>
      b == Brightness.dark ? warningSoftDark : warningSoftLight;
  static Color infoSoft(Brightness b) =>
      b == Brightness.dark ? infoSoftDark : infoSoftLight;
  static Color errorSoft(Brightness b) =>
      b == Brightness.dark ? errorSoftDark : errorSoftLight;

  // ──── Shimmer Loading ────
  static const shimmerBaseLight = Color(0xFFECF2F0);
  static const shimmerHighlightLight = Color(0xFFF8FAF9);
  static const shimmerBaseDark = Color(0xFF1A2926);
  static const shimmerHighlightDark = Color(0xFF253532);
  static Color shimmerBase(Brightness b) =>
      b == Brightness.dark ? shimmerBaseDark : shimmerBaseLight;
  static Color shimmerHighlight(Brightness b) =>
      b == Brightness.dark ? shimmerHighlightDark : shimmerHighlightLight;

  // ──── Shadows ────
  /// Shadow mềm cho card thông thường.
  static List<BoxShadow> cardShadow(Brightness b) => [
    BoxShadow(
      color: b == Brightness.dark
          ? const Color(0x28000000)
          : const Color(0x0A073B3A),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  /// Shadow nổi bật cho card featured/active.
  static List<BoxShadow> cardElevatedShadow(Brightness b) => [
    BoxShadow(
      color: b == Brightness.dark
          ? const Color(0x3D000000)
          : const Color(0x14006B63),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
