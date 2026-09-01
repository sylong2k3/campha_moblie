import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/map/data/map_repository.dart';
import 'package:campha_moblie/features/map/domain/layer_model.dart';
import 'package:campha_moblie/features/map/domain/map_controller.dart';
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
          mapCatalogProvider.overrideWith(_FirstTestCatalogController.new),
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

  testWidgets('search filters out results from disabled layers and passes single active layerId', (tester) async {
    String? requestedLayerId;
    final dio = Dio();
    final adapter = _CustomSearchAdapter(onSearch: (options) {
      requestedLayerId = options.queryParameters['layerId']?.toString();
      return {
        'data': [
          {
            'layerId': 'layer-active',
            'layerCode': 'layer_active',
            'layerName': 'Lớp đang bật',
            'feature_id': '1',
            'label': 'Điểm thuộc lớp bật',
            'location': {
              'type': 'Point',
              'coordinates': [107.33, 21.01],
            },
          },
          {
            'layerId': 'layer-disabled',
            'layerCode': 'layer_disabled',
            'layerName': 'Lớp bị tắt',
            'feature_id': '2',
            'label': 'Điểm thuộc lớp tắt',
            'location': {
              'type': 'Point',
              'coordinates': [107.34, 21.02],
            },
          },
        ],
      };
    });
    dio.httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_GuestSessionController.new),
          mapRepositoryProvider.overrideWithValue(MapRepository(dio: dio)),
          mapCatalogProvider.overrideWith(_SingleActiveLayerCatalogController.new),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MapSearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final input = find.descendant(
      of: find.byKey(const ValueKey('map-search-input')),
      matching: find.byType(TextField),
    );
    await tester.enterText(input, 'diem');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify single active layer id optimization was passed to backend
    expect(requestedLayerId, 'layer-active');

    // Verify only results from active layer are shown, disabled layer is filtered out
    expect(find.text('Điểm thuộc lớp bật'), findsOneWidget);
    expect(find.text('Điểm thuộc lớp tắt'), findsNothing);
  });

  testWidgets('search shows no active layers message and sends no network requests when all layers are disabled', (tester) async {
    var networkCalls = 0;
    final dio = Dio();
    final adapter = _CustomSearchAdapter(onSearch: (options) {
      networkCalls++;
      return {'data': []};
    });
    dio.httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_GuestSessionController.new),
          mapRepositoryProvider.overrideWithValue(MapRepository(dio: dio)),
          mapCatalogProvider.overrideWith(_NoActiveLayerCatalogController.new),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MapSearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final input = find.descendant(
      of: find.byKey(const ValueKey('map-search-input')),
      matching: find.byType(TextField),
    );
    await tester.enterText(input, 'diem');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Zero network calls made
    expect(networkCalls, 0);
    expect(find.text('Chưa có lớp dữ liệu nào được bật. Vui lòng bật lớp trên bản đồ để tìm kiếm đối tượng.'), findsOneWidget);
  });
}

class _FirstTestCatalogController extends MapCatalogController {
  @override
  MapCatalogState build() => const MapCatalogState(
    layers: [
      LayerModel(
        id: '1',
        code: 'places',
        nameVi: 'Địa điểm',
        category: 'cat1',
        geometryType: 'POINT',
        storageKind: 'postgis',
        srid: 4326,
        isPublic: true,
        legend: <String, dynamic>{},
      ),
    ],
    activeLayerIds: {'1'},
  );
}

class _SingleActiveLayerCatalogController extends MapCatalogController {
  @override
  MapCatalogState build() => const MapCatalogState(
    layers: [
      LayerModel(
        id: 'layer-active',
        code: 'layer_active',
        nameVi: 'Lớp đang bật',
        category: 'cat1',
        geometryType: 'POINT',
        storageKind: 'postgis',
        srid: 4326,
        isPublic: true,
        legend: <String, dynamic>{},
      ),
      LayerModel(
        id: 'layer-disabled',
        code: 'layer_disabled',
        nameVi: 'Lớp bị tắt',
        category: 'cat1',
        geometryType: 'POINT',
        storageKind: 'postgis',
        srid: 4326,
        isPublic: true,
        legend: <String, dynamic>{},
      ),
    ],
    activeLayerIds: {'layer-active'},
  );
}

class _NoActiveLayerCatalogController extends MapCatalogController {
  @override
  MapCatalogState build() => const MapCatalogState(
    layers: [
      LayerModel(
        id: 'layer-1',
        code: 'layer_1',
        nameVi: 'Lớp 1',
        category: 'cat1',
        geometryType: 'POINT',
        storageKind: 'postgis',
        srid: 4326,
        isPublic: true,
        legend: <String, dynamic>{},
      ),
    ],
    activeLayerIds: {},
  );
}

class _CustomSearchAdapter implements HttpClientAdapter {
  _CustomSearchAdapter({required this.onSearch});

  final Map<String, dynamic> Function(RequestOptions options) onSearch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = onSearch(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
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
