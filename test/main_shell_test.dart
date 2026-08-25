import 'package:campha_moblie/core/storage/token_storage.dart';
import 'package:campha_moblie/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_secure_storage.dart';

void main() {
  testWidgets(
    'mobile shell keeps five labeled destinations at 1.3 text scale',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(MemorySecureStorage()),
          ],
          child: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: MainApp(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));

      final barFinder = find.byKey(const ValueKey('main-navigation-bar'));
      expect(barFinder, findsOneWidget);
      expect(find.text('Bản đồ'), findsOneWidget);
      expect(find.text('Hiện trường'), findsOneWidget);
      expect(find.text('Tin tức'), findsOneWidget);
      expect(find.text('Tài liệu'), findsOneWidget);
      expect(find.text('Cá nhân'), findsOneWidget);
      expect(find.byIcon(Icons.add_location_alt_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cá nhân'));
      await tester.pumpAndSettle();
      expect(find.text('Khám phá với tư cách khách'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
