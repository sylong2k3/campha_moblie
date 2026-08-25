import 'package:campha_moblie/app/theme/app_colors.dart';
import 'package:campha_moblie/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Green neutral app theme', () {
    test('light and dark themes use the supplied schemes exactly', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(light.colorScheme, lightColorScheme);
      expect(light.colorScheme.primary, const Color(0xFF006B63));
      expect(light.colorScheme.secondary, const Color(0xFF3E6375));
      expect(light.colorScheme.tertiary, const Color(0xFF805610));
      expect(light.colorScheme.surface, const Color(0xFFF8FAF9));
      expect(light.colorScheme.error, const Color(0xFFB42318));
      expect(light.scaffoldBackgroundColor, lightColorScheme.surface);

      expect(dark.colorScheme, darkColorScheme);
      expect(dark.colorScheme.primary, const Color(0xFF5ED8CA));
      expect(dark.colorScheme.secondary, const Color(0xFFB7D1DC));
      expect(dark.colorScheme.tertiary, const Color(0xFFF6C453));
      expect(dark.colorScheme.surface, const Color(0xFF071412));
      expect(dark.colorScheme.error, const Color(0xFFFFB4AA));
      expect(dark.scaffoldBackgroundColor, darkColorScheme.surface);
    });

    test('legacy custom tokens follow the coastal GIS palette', () {
      expect(AppColors.primary, lightColorScheme.primary);
      expect(AppColors.primaryDark, darkColorScheme.primary);
      expect(AppColors.background, const Color(0xFFF5F8F7));
      expect(AppColors.darkBackground, darkColorScheme.surface);
      expect(AppColors.statusError, lightColorScheme.error);
      expect(AppColors.warning, const Color(0xFFF6C453));
      expect(AppColors.border, lightColorScheme.outlineVariant);
      expect(AppColors.darkBorder, darkColorScheme.outlineVariant);
    });

    test('selected navigation stays readable in both modes', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final selected = <WidgetState>{WidgetState.selected};
        final foreground = theme.navigationBarTheme.iconTheme
            ?.resolve(selected)
            ?.color;
        final background = theme.navigationBarTheme.indicatorColor;
        expect(foreground, isNotNull);
        expect(background, isNotNull);
        expect(foreground, isNot(background));
        expect(_contrast(foreground!, background!), greaterThanOrEqualTo(4.5));
        expect(
          theme.navigationBarTheme.labelBehavior,
          NavigationDestinationLabelBehavior.alwaysShow,
        );
        expect(theme.navigationBarTheme.height, greaterThanOrEqualTo(72));
      }
    });

    test('primary, error and warning actions pass WCAG AA', () {
      for (final scheme in [lightColorScheme, darkColorScheme]) {
        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.onErrorContainer, scheme.errorContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.onTertiaryContainer, scheme.tertiaryContainer),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('button token keeps finite width and 48px touch height', () {
      expect(AppTheme.buttonMinimumSize.width.isFinite, isTrue);
      expect(AppTheme.buttonMinimumSize.width, 0);
      expect(AppTheme.buttonMinimumSize.height, 48);
    });
  });
}

double _contrast(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
