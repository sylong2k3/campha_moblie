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
      expect(light.colorScheme.primary, const Color(0xFF16A34A));
      expect(light.colorScheme.secondary, const Color(0xFFF4F4F5));
      expect(light.colorScheme.surface, const Color(0xFFFCFCFC));
      expect(light.colorScheme.error, const Color(0xFFEF4444));
      expect(light.scaffoldBackgroundColor, lightColorScheme.surface);

      expect(dark.colorScheme, darkColorScheme);
      expect(dark.colorScheme.primary, const Color(0xFF22C55E));
      expect(dark.colorScheme.secondary, const Color(0xFF27272A));
      expect(dark.colorScheme.surface, const Color(0xFF080808));
      expect(dark.colorScheme.error, const Color(0xFF7F1D1D));
      expect(dark.scaffoldBackgroundColor, darkColorScheme.surface);
    });

    test('legacy custom tokens also use only the supplied palette', () {
      expect(AppColors.primary, lightColorScheme.primary);
      expect(AppColors.primaryDark, darkColorScheme.primary);
      expect(AppColors.background, lightColorScheme.surface);
      expect(AppColors.darkBackground, darkColorScheme.surface);
      expect(AppColors.statusError, lightColorScheme.error);
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
