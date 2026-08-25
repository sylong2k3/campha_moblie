import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF006B63),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFD5EFEC),
  onPrimaryContainer: Color(0xFF073B3A),
  primaryFixed: Color(0xFFD5EFEC),
  primaryFixedDim: Color(0xFF8FD8D2),
  onPrimaryFixed: Color(0xFF062F2D),
  onPrimaryFixedVariant: Color(0xFF075E58),
  secondary: Color(0xFF3E6375),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFDCEAF0),
  onSecondaryContainer: Color(0xFF173746),
  secondaryFixed: Color(0xFFDCEAF0),
  secondaryFixedDim: Color(0xFFB7D1DC),
  onSecondaryFixed: Color(0xFF102D39),
  onSecondaryFixedVariant: Color(0xFF36596A),
  tertiary: Color(0xFF805610),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFDEA5),
  onTertiaryContainer: Color(0xFF2A1A00),
  tertiaryFixed: Color(0xFFFFDEA5),
  tertiaryFixedDim: Color(0xFFF6C453),
  onTertiaryFixed: Color(0xFF291900),
  onTertiaryFixedVariant: Color(0xFF624000),
  error: Color(0xFFB42318),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD5),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFF8FAF9),
  onSurface: Color(0xFF102321),
  surfaceDim: Color(0xFFDCE4E1),
  surfaceBright: Color(0xFFF8FAF9),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF2F6F4),
  surfaceContainer: Color(0xFFECF2F0),
  surfaceContainerHigh: Color(0xFFE5ECEA),
  surfaceContainerHighest: Color(0xFFDDE6E3),
  onSurfaceVariant: Color(0xFF425B57),
  outline: Color(0xFF718783),
  outlineVariant: Color(0xFFC4D1CE),
  shadow: Color(0xFF073B3A),
  scrim: Color(0xFF071412),
  inverseSurface: Color(0xFF243330),
  onInverseSurface: Color(0xFFEDF4F2),
  inversePrimary: Color(0xFF5ED8CA),
  surfaceTint: Color(0xFF006B63),
);

const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF5ED8CA),
  onPrimary: Color(0xFF003733),
  primaryContainer: Color(0xFF075E58),
  onPrimaryContainer: Color(0xFFD5EFEC),
  primaryFixed: Color(0xFFD5EFEC),
  primaryFixedDim: Color(0xFF8FD8D2),
  onPrimaryFixed: Color(0xFF062F2D),
  onPrimaryFixedVariant: Color(0xFF075E58),
  secondary: Color(0xFFB7D1DC),
  onSecondary: Color(0xFF173746),
  secondaryContainer: Color(0xFF2C4E5D),
  onSecondaryContainer: Color(0xFFDCEAF0),
  secondaryFixed: Color(0xFFDCEAF0),
  secondaryFixedDim: Color(0xFFB7D1DC),
  onSecondaryFixed: Color(0xFF102D39),
  onSecondaryFixedVariant: Color(0xFF36596A),
  tertiary: Color(0xFFF6C453),
  onTertiary: Color(0xFF432C00),
  tertiaryContainer: Color(0xFF624000),
  onTertiaryContainer: Color(0xFFFFDEA5),
  tertiaryFixed: Color(0xFFFFDEA5),
  tertiaryFixedDim: Color(0xFFF6C453),
  onTertiaryFixed: Color(0xFF291900),
  onTertiaryFixedVariant: Color(0xFF624000),
  error: Color(0xFFFFB4AA),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD5),
  surface: Color(0xFF071412),
  onSurface: Color(0xFFE3EFEC),
  surfaceDim: Color(0xFF071412),
  surfaceBright: Color(0xFF2D3D3A),
  surfaceContainerLowest: Color(0xFF030C0B),
  surfaceContainerLow: Color(0xFF0B1917),
  surfaceContainer: Color(0xFF101E1C),
  surfaceContainerHigh: Color(0xFF1A2926),
  surfaceContainerHighest: Color(0xFF253532),
  onSurfaceVariant: Color(0xFFB8CAC6),
  outline: Color(0xFF829691),
  outlineVariant: Color(0xFF3D514D),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE3EFEC),
  onInverseSurface: Color(0xFF243330),
  inversePrimary: Color(0xFF006B63),
  surfaceTint: Color(0xFF5ED8CA),
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
    final actionForeground = colorScheme.onPrimary;
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
      borderRadius: BorderRadius.circular(16),
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
        scrolledUnderElevation: 1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: 20,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: shape.copyWith(
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
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
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surfaceContainerLowest,
        showDragHandle: true,
        dragHandleColor: colorScheme.outline,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
        height: 76,
        backgroundColor: colorScheme.surfaceContainerLowest,
        indicatorColor: selectedContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: states.contains(WidgetState.selected) ? 25 : 23,
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
            letterSpacing: 0,
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
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        waitDuration: const Duration(milliseconds: 450),
        showDuration: const Duration(seconds: 2),
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
