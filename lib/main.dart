import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app/locale/locale_controller.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_controller.dart';
import 'core/l10n/l10n.dart';
import 'core/network/api_config.dart';
import 'core/push/push_coordinator.dart';
import 'core/push/push_service.dart';

Future<void> main() async {
  // Bọc runZonedGuarded để bắt cả lỗi bất đồng bộ ngoài zone lỗi mặc định
  // của Flutter (PushService.initFirebase đã gắn FlutterError.onError +
  // PlatformDispatcher.onError cho phần còn lại) — gửi lên Crashlytics để
  // tra nguyên nhân crash thật thay vì đoán qua log thiết bị.
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Tối ưu RAM theo chính sách Google Play & thiết bị Low-RAM:
      // Giới hạn bộ đệm ảnh trong RAM (mặc định 1000 ảnh / 100MB) xuống 100 ảnh / 25MB.
      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 25 * 1024 * 1024;

      // Giải phóng bộ đệm ảnh khi app chuyển vào nền để tránh bị Android Low Memory Killer thu hồi
      AppLifecycleListener(
        onHide: () => PaintingBinding.instance.imageCache.clearLiveImages(),
        onPause: () => PaintingBinding.instance.imageCache.clear(),
      );

      LicenseRegistry.addLicense(() async* {
        final license = await rootBundle.loadString('assets/fonts/OFL.txt');
        yield LicenseEntryWithLineBreaks(['Be Vietnam Pro'], license);
      });

      // Vẽ UI trước; Firebase/push là optional và tự no-op khi flavor chưa có
      // native config. Không giữ first frame để chờ platform initialization.
      unawaited(PushService.initFirebase());
      if (ApiConfig.mapboxToken.isNotEmpty) {
        MapboxOptions.setAccessToken(ApiConfig.mapboxToken);
      }
      // Nhãn của basemap Mapbox (địa danh, quốc gia, khu vực) dùng tiếng Việt.
      // Thiết lập này phải chạy trước khi bất kỳ MapWidget nào được khởi tạo.
      MapboxMapsOptions.setLanguage('vi');
      if (kReleaseMode || kProfileMode) {
        final configError = ApiConfig.validateForRelease();
        if (configError != null) throw StateError(configError);
      }

      runApp(const ProviderScope(child: MainApp()));
    },
    (_, stack) {
      // Firebase.apps rỗng nếu initFirebase() ở trên đã nuốt lỗi (chưa cấu
      // hình) — lúc đó gọi Crashlytics sẽ tự ném lỗi khác, nên phải guard.
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(
          StateError('zone_uncaught_error'),
          stack,
          fatal: true,
        );
      } else if (kDebugMode) {
        debugPrint('[CRASH] uncaught_error');
      }
    },
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    // Kích hoạt push/device lifecycle; no-op nếu Firebase chưa cấu hình.
    ref.watch(appPushCoordinatorProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
