import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/map/data/map_repository.dart';
import 'package:campha_moblie/features/map/presentation/map_search_screen.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a cancelled short query is not cancelled again', (tester) async {
    final adapter = _MapSearchAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_GuestSessionController.new),
          mapRepositoryProvider.overrideWithValue(MapRepository(dio: dio)),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MapSearchScreen(),
        ),
      ),
    );
    await tester.pump();

    final input = find.descendant(
      of: find.byKey(const ValueKey('map-search-input')),
      matching: find.byType(TextField),
    );
    await tester.enterText(input, 'ab');
    await tester.pump(const Duration(milliseconds: 350));
    expect(adapter.requests, 1);

    await tester.enterText(input, 'a');
    await tester.pump();
    expect(adapter.cancellations, 1);

    await tester.enterText(input, 'cd');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(adapter.requests, 2);
    expect(adapter.cancellations, 1);
    expect(find.text('Kết quả mới'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _GuestSessionController extends SessionController {
  @override
  SessionState build() => const SessionState.guest();
}

class _MapSearchAdapter implements HttpClientAdapter {
  int requests = 0;
  int cancellations = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    if (requests == 1) {
      await cancelFuture;
      cancellations++;
      throw DioException.requestCancelled(
        requestOptions: options,
        reason: 'query too short',
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'data': [
          {
            'layerId': '1',
            'layerCode': 'places',
            'layerName': 'Địa điểm',
            'feature_id': '2',
            'label': 'Kết quả mới',
            'location': {
              'type': 'Point',
              'coordinates': [107.33, 21.01],
            },
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
