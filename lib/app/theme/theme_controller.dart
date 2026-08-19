import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_preferences.dart';

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefsAsync = ref.watch(appPreferencesProvider);
    return prefsAsync.when(
      data: (prefs) {
        switch (prefs.themeMode) {
          case 'dark':
            return ThemeMode.dark;
          case 'light':
            return ThemeMode.light;
          default:
            return ThemeMode.light;
        }
      },
      loading: () => ThemeMode.light,
      error: (error, stack) => ThemeMode.light,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setThemeMode(mode.name);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);
