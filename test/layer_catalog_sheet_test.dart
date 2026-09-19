import 'package:campha_moblie/features/map/domain/layer_model.dart';
import 'package:campha_moblie/features/map/domain/map_controller.dart';
import 'package:campha_moblie/features/map/presentation/layer_catalog_sheet.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('map layer categories expand independently', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapCatalogProvider.overrideWith(_TestMapCatalogController.new),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: LayerCatalogSheet()),
        ),
      ),
    );

    final floodCategory = find.text('Lop Phu Ngap');
    final boundaryCategory = find.text('Ranh Gioi');

    expect(find.byKey(const ValueKey('layer-toggle-flood')), findsNothing);
    expect(find.byKey(const ValueKey('layer-toggle-boundary')), findsNothing);
    final searchTop = tester.getTopLeft(
      find.byKey(const ValueKey('layer-search')),
    );

    await tester.tap(floodCategory);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('layer-search'))),
      searchTop,
    );
    expect(find.byKey(const ValueKey('layer-toggle-flood')), findsOneWidget);
    expect(find.byKey(const ValueKey('layer-toggle-boundary')), findsNothing);

    await tester.tap(floodCategory);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('layer-toggle-flood')), findsNothing);
    expect(find.byKey(const ValueKey('layer-toggle-boundary')), findsNothing);

    await tester.tap(boundaryCategory);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('layer-toggle-boundary')), findsOneWidget);
    expect(find.byKey(const ValueKey('layer-toggle-flood')), findsNothing);
  });

  testWidgets('enableAll and disableAll toggles all layers', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapCatalogProvider.overrideWith(_TestMapCatalogController.new),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: LayerCatalogSheet()),
        ),
      ),
    );

    // Initial state: 0 active layers -> shows "Bật tất cả", no "Tắt tất cả"
    expect(find.text('Bật tất cả'), findsOneWidget);
    expect(find.text('Tắt tất cả'), findsNothing);

    // Tap "Bật tất cả"
    await tester.tap(find.text('Bật tất cả'));
    await tester.pumpAndSettle();

    // Now all 2 layers active -> shows "Tắt tất cả", no "Bật tất cả"
    expect(find.text('2 lớp đang hiển thị'), findsOneWidget);
    expect(find.text('Tắt tất cả'), findsOneWidget);
    expect(find.text('Bật tất cả'), findsNothing);

    // Tap "Tắt tất cả"
    await tester.tap(find.text('Tắt tất cả'));
    await tester.pumpAndSettle();

    // 0 active layers again
    expect(find.text('0 lớp đang hiển thị'), findsOneWidget);
    expect(find.text('Bật tất cả'), findsOneWidget);
    expect(find.text('Tắt tất cả'), findsNothing);
  });

  testWidgets('displays default enable badge without color code', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapCatalogProvider.overrideWith(
            _TestMapCatalogControllerWithDefault.new,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: LayerCatalogSheet()),
        ),
      ),
    );

    final boundaryCategory = find.text('Ranh Gioi');
    await tester.tap(boundaryCategory);
    await tester.pumpAndSettle();

    expect(find.text('Mặc định'), findsOneWidget);
    expect(find.text('#FF0055'), findsNothing);
  });
}

class _TestMapCatalogControllerWithDefault extends MapCatalogController {
  @override
  MapCatalogState build() => const MapCatalogState(
    layers: [
      LayerModel(
        id: 'boundary',
        code: 'ranh_gioi',
        nameVi: 'Ranh giới',
        category: 'ranh_gioi',
        geometryType: 'LINESTRING',
        storageKind: 'postgis',
        srid: 3857,
        isPublic: true,
        isEnableDefault: true,
        defaultStyle: {'strokeColor': '#FF0055'},
        legend: {},
      ),
    ],
  );
}

class _TestMapCatalogController extends MapCatalogController {
  @override
  MapCatalogState build() => MapCatalogState(
    layers: const [
      LayerModel(
        id: 'flood',
        code: 'lop_phu_ngap',
        nameVi: 'Lớp phủ ngập',
        category: 'lop_phu_ngap',
        geometryType: 'RASTER',
        storageKind: 'geotiff_minio',
        srid: 3857,
        isPublic: true,
        legend: {},
      ),
      LayerModel(
        id: 'boundary',
        code: 'ranh_gioi',
        nameVi: 'Ranh giới',
        category: 'ranh_gioi',
        geometryType: 'LINESTRING',
        storageKind: 'postgis',
        srid: 3857,
        isPublic: true,
        legend: {},
      ),
    ],
  );
}
