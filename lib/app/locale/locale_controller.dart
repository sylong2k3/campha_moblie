import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/app_preferences.dart';

/// Ngôn ngữ hiển thị của app, lưu trong [AppPreferences] (key `locale`).
/// Mặc định tiếng Việt.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final prefsAsync = ref.watch(appPreferencesProvider);
    return prefsAsync.when(
      data: (prefs) {
        final code = prefs.locale;
        return switch (code) {
          'en' => const Locale('en'),
          _ => const Locale('vi'),
        };
      },
      loading: () => const Locale('vi'),
      error: (error, stack) => const Locale('vi'),
    );
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await ref.read(appPreferencesProvider.future);
    await prefs.setLocale(locale.languageCode);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
