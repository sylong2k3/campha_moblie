import 'package:campha_moblie/core/storage/token_storage.dart';
import 'package:campha_moblie/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_secure_storage.dart';

void main() {
  testWidgets('guest boots into canonical five-tab shell', (tester) async {
    final memoryStorage = MemorySecureStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStorageProvider.overrideWithValue(memoryStorage)],
        child: const MainApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(Icons.map), findsWidgets);
    expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
    expect(find.byIcon(Icons.newspaper_outlined), findsOneWidget);
    expect(find.byIcon(Icons.folder_copy_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Khám phá với tư cách khách'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-login')), findsOneWidget);
  });
}
