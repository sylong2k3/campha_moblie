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
