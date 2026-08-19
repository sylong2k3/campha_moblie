import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF16A34A),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF16A34A),
  onPrimaryContainer: Color(0xFFFFFFFF),
  primaryFixed: Color(0xFFC6F2D6),
  primaryFixedDim: Color(0xFF97E0B3),
  onPrimaryFixed: Color(0xFF073719),
  onPrimaryFixedVariant: Color(0xFF0A4620),
  secondary: Color(0xFFF4F4F5),
  onSecondary: Color(0xFF000000),
  secondaryContainer: Color(0xFFF4F4F5),
  onSecondaryContainer: Color(0xFF000000),
  secondaryFixed: Color(0xFFFAFAFA),
  secondaryFixedDim: Color(0xFFF1F1F1),
  onSecondaryFixed: Color(0xFF46464D),
  onSecondaryFixedVariant: Color(0xFF64646F),
  tertiary: Color(0xFFF4F4F5),
  onTertiary: Color(0xFF000000),
  tertiaryContainer: Color(0xFFF4F4F5),
  onTertiaryContainer: Color(0xFF000000),
  tertiaryFixed: Color(0xFFFAFAFA),
  tertiaryFixedDim: Color(0xFFF1F1F1),
  onTertiaryFixed: Color(0xFF46464D),
  onTertiaryFixedVariant: Color(0xFF64646F),
  error: Color(0xFFEF4444),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFE6E6),
  onErrorContainer: Color(0xFF000000),
  surface: Color(0xFFFCFCFC),
  onSurface: Color(0xFF111111),
  surfaceDim: Color(0xFFE0E0E0),
  surfaceBright: Color(0xFFFDFDFD),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF8F8F8),
  surfaceContainer: Color(0xFFF3F3F3),
  surfaceContainerHigh: Color(0xFFEDEDED),
  surfaceContainerHighest: Color(0xFFE7E7E7),
  onSurfaceVariant: Color(0xFF393939),
  outline: Color(0xFF919191),
  outlineVariant: Color(0xFFD1D1D1),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF2A2A2A),
  onInverseSurface: Color(0xFFF1F1F1),
  inversePrimary: Color(0xFFAFFFCF),
  surfaceTint: Color(0xFF16A34A),
);

const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF22C55E),
  onPrimary: Color(0xFF000000),
  primaryContainer: Color(0xFF22C55E),
  onPrimaryContainer: Color(0xFF000000),
  primaryFixed: Color(0xFFC6F2D6),
  primaryFixedDim: Color(0xFF97E0B3),
  onPrimaryFixed: Color(0xFF073719),
  onPrimaryFixedVariant: Color(0xFF0A4620),
  secondary: Color(0xFF27272A),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFF27272A),
  onSecondaryContainer: Color(0xFFFFFFFF),
  secondaryFixed: Color(0xFFFAFAFA),
  secondaryFixedDim: Color(0xFFF1F1F1),
  onSecondaryFixed: Color(0xFF46464D),
  onSecondaryFixedVariant: Color(0xFF64646F),
  tertiary: Color(0xFF292524),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFF292524),
  onTertiaryContainer: Color(0xFFFFFFFF),
  tertiaryFixed: Color(0xFFFAFAFA),
  tertiaryFixedDim: Color(0xFFF1F1F1),
  onTertiaryFixed: Color(0xFF46464D),
  onTertiaryFixedVariant: Color(0xFF64646F),
  error: Color(0xFF7F1D1D),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFF410F0F),
  onErrorContainer: Color(0xFFFFFFFF),
  surface: Color(0xFF080808),
  onSurface: Color(0xFFF1F1F1),
  surfaceDim: Color(0xFF060606),
  surfaceBright: Color(0xFF2C2C2C),
  surfaceContainerLowest: Color(0xFF010101),
  surfaceContainerLow: Color(0xFF0E0E0E),
  surfaceContainer: Color(0xFF151515),
  surfaceContainerHigh: Color(0xFF1D1D1D),
  surfaceContainerHighest: Color(0xFF282828),
  onSurfaceVariant: Color(0xFFCACACA),
  outline: Color(0xFF777777),
  outlineVariant: Color(0xFF414141),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE8E8E8),
  onInverseSurface: Color(0xFF2A2A2A),
  inversePrimary: Color(0xFF185930),
  surfaceTint: Color(0xFF22C55E),
);

/// Theme bản đồ dùng chung. Hình khối tiết chế để dữ liệu GIS luôn là trọng tâm.
class AppTheme {
  const AppTheme._();

  static const buttonMinimumSize = Size(0, 48);

  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = isLight ? lightColorScheme : darkColorScheme;
    final actionForeground = isLight ? Colors.black : colorScheme.onPrimary;
    final selectedContainer = isLight
        ? colorScheme.primaryFixed
        : colorScheme.primaryContainer;
    final onSelectedContainer = isLight
        ? colorScheme.onPrimaryFixed
        : colorScheme.onPrimaryContainer;
    final selectedAccent = isLight
        ? colorScheme.onPrimaryFixedVariant
        : colorScheme.primary;
    final selectedIndicatorForeground = isLight
        ? colorScheme.onPrimaryFixedVariant
        : colorScheme.onPrimaryContainer;

    final baseTextTheme = isLight
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    final textTheme = baseTextTheme
        .apply(fontFamily: 'BeVietnamPro')
        .copyWith(
          headlineSmall: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 24,
            height: 1.22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          titleLarge: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          titleMedium: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 16,
            height: 1.45,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 14,
            height: 1.45,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
      scaffoldBackgroundColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: shape.copyWith(
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIconColor: colorScheme.primary,
        suffixIconColor: colorScheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _inputBorder(colorScheme.outlineVariant),
        enabledBorder: _inputBorder(colorScheme.outlineVariant),
        focusedBorder: _inputBorder(colorScheme.primary, width: 1.5),
        errorBorder: _inputBorder(colorScheme.error),
        focusedErrorBorder: _inputBorder(colorScheme.error, width: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinimumSize,
          backgroundColor: colorScheme.primary,
          foregroundColor: actionForeground,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          disabledForegroundColor: colorScheme.primary.withValues(alpha: 0.38),
          elevation: 0,
          shape: shape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinimumSize,
          foregroundColor: selectedAccent,
          side: BorderSide(color: colorScheme.outline),
          shape: shape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: selectedAccent,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 3,
        backgroundColor: colorScheme.primary,
        foregroundColor: actionForeground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: selectedContainer,
        secondarySelectedColor: selectedContainer,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: onSelectedContainer,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: onSelectedContainer,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? onSelectedContainer
                : colorScheme.onSurfaceVariant,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? selectedContainer
                : colorScheme.surfaceContainer,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outlineVariant),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: selectedContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? selectedIndicatorForeground
                : colorScheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? selectedAccent
                : colorScheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: selectedContainer,
        labelType: NavigationRailLabelType.none,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        selectedIconTheme: IconThemeData(color: selectedIndicatorForeground),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: selectedAccent,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainer),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
