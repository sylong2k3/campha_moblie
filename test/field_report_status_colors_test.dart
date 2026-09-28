import 'package:campha_moblie/app/theme/app_colors.dart';
import 'package:campha_moblie/app/theme/app_theme.dart';
import 'package:campha_moblie/features/field_reports/domain/field_report_models.dart';
import 'package:campha_moblie/features/field_reports/domain/field_reports_controller.dart';
import 'package:campha_moblie/features/field_reports/presentation/field_reports_screen.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_models.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campha_moblie/features/field_reports/data/field_report_repository.dart';
import 'package:campha_moblie/features/field_reports/presentation/admin_report_sheets.dart';
import 'package:dio/dio.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

FieldReport _report(String status, {String id = 'report-1'}) => FieldReport(
  id: id,
  referenceCode: 'PA-001',
  description: 'Report color regression',
  status: status,
  location: const GeoCoordinate(107.3, 21.0),
  photoCount: 0,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
);

class _Reports extends FieldReportsController {
  _Reports({this.admin = false});
  final bool admin;

  @override
  FieldReportsState build() => FieldReportsState(
    admin: admin,
    items: [_report(admin ? 'pending' : 'approved')],
    page: 1,
    totalPages: 1,
  );

  void updateStatus(String status) =>
      state = state.copyWith(items: [_report(status)]);
}

class _Cancelable extends Fake implements Cancelable {}

class _Circles extends Fake implements CircleAnnotationManager {
  List<CircleAnnotationOptions> options = [];
  List<CircleAnnotation> annotations = [];
  Function(CircleAnnotation)? onTap;

  @override
  Cancelable tapEvents({required Function(CircleAnnotation) onTap}) {
    this.onTap = onTap;
    return _Cancelable();
  }

  @override
  Future<void> deleteAll() async => annotations.clear();

  @override
  Future<List<CircleAnnotation?>> createMulti(
    List<CircleAnnotationOptions> annotations,
  ) async {
    options = annotations;
    return this.annotations = [
      for (final (index, option) in annotations.indexed)
        CircleAnnotation(
          id: 'circle-$index',
          geometry: option.geometry,
          circleColor: option.circleColor,
        ),
    ];
  }
}

class _Annotations extends Fake implements AnnotationManager {
  final circles = _Circles();

  @override
  Future<CircleAnnotationManager> createCircleAnnotationManager({
    String? id,
    String? below,
  }) async => circles;
}

class _Gestures extends Fake implements GesturesSettingsInterface {
  @override
  Future<void> updateSettings(GesturesSettings settings) async {}
}

class _Map extends Fake implements MapboxMap {
  @override
  final _Annotations annotations = _Annotations();
  @override
  final gestures = _Gestures();
  int cameraMoves = 0;

  @override
  Future<void> setBounds(CameraBoundsOptions options) async {}

  @override
  Future<void> flyTo(
    CameraOptions options,
    MapAnimationOptions? animation,
  ) async => cameraMoves++;
}

class _AdminDetails extends FieldReportRepository {
  _AdminDetails() : super(Dio());
  int calls = 0;
  final pages = <int>[];

  @override
  Future<FieldReportPage> getAdmin({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    pages.add(page);
    return FieldReportPage(
      items: [_report('pending', id: '$page')],
      page: page,
      limit: limit,
      total: 3,
      totalPages: 3,
    );
  }

  @override
  Future<FieldReport> getAdminDetail(
    String id, {
    CancelToken? cancelToken,
  }) async {
    calls++;
    return _report('pending');
  }
}

void main() {
  testWidgets(
    'map loads all pages and renders every marker without load-more',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _AdminDetails();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fieldReportRepositoryProvider.overrideWithValue(repository),
            fieldReportAccessProvider.overrideWithValue((
              ownerId: 'manager',
              roleCode: 'so_tnmt',
              canRead: true,
              canReview: true,
              canStats: false,
            )),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const FieldReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.pages, [1]);
      expect(find.byKey(const ValueKey('report-load-more')), findsOneWidget);
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();
      expect(repository.pages, [1, 1, 2, 3]);
      expect(find.text('Tải thêm phản ánh'), findsNothing);
      expect(find.byKey(const ValueKey('report-map-loading')), findsNothing);
      final map = _Map();
      tester.widget<MapWidget>(find.byType(MapWidget)).onMapCreated!(map);
      await tester.pumpAndSettle();
      expect(map.annotations.circles.options.length, 3);
      expect(map.cameraMoves, 1);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.windows}),
  );

  testWidgets('admin marker opens admin detail and loses access immediately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reports = _Reports(admin: true);
    final details = _AdminDetails();
    const FieldReportAccess access = (
      ownerId: 'manager',
      roleCode: 'so_tnmt',
      canRead: true,
      canReview: true,
      canStats: true,
    );
    final container = ProviderContainer(
      overrides: [
        fieldReportsProvider.overrideWith(() => reports),
        fieldReportRepositoryProvider.overrideWithValue(details),
        fieldReportAccessProvider.overrideWithValue(access),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FieldReportsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();
    final map = _Map();
    tester.widget<MapWidget>(find.byType(MapWidget)).onMapCreated!(map);
    await tester.pumpAndSettle();
    map.annotations.circles.onTap!(map.annotations.circles.annotations.single);
    await tester.pumpAndSettle();
    expect(details.calls, 1);
    expect(find.byType(AdminReportSheet), findsOneWidget);
    expect(
      find.byKey(const ValueKey('review-status-approved')),
      findsOneWidget,
    );
    container.updateOverrides([
      fieldReportsProvider.overrideWith(() => reports),
      fieldReportRepositoryProvider.overrideWithValue(details),
      fieldReportAccessProvider.overrideWithValue((
        ownerId: access.ownerId,
        roleCode: access.roleCode,
        canRead: false,
        canReview: false,
        canStats: false,
      )),
    ]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('review-status-approved')), findsNothing);
    expect(details.calls, 1);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.windows}));
  for (final brightness in Brightness.values) {
    testWidgets(
      'report circles match status badges and update without recentering ($brightness)',
      (tester) async {
        tester.view.physicalSize = const Size(430, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final reports = _Reports();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              fieldReportsProvider.overrideWith(() => reports),
              fieldReportAccessProvider.overrideWithValue((
                ownerId: null,
                roleCode: null,
                canRead: false,
                canReview: false,
                canStats: false,
              )),
            ],
            child: MaterialApp(
              theme: ThemeData(
                colorScheme: brightness == Brightness.light
                    ? lightColorScheme
                    : darkColorScheme,
              ),
              locale: const Locale('vi'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const FieldReportsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(FieldReportsScreen)),
        );
        final listBadge = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('report-card-report-1')),
            matching: find.text(l10n.reportStatusApproved),
          ),
        );
        expect(listBadge.style?.color, AppColors.statusNew);

        await tester.tap(find.byIcon(Icons.map_outlined));
        await tester.pumpAndSettle();
        final map = _Map();
        tester.widget<MapWidget>(find.byType(MapWidget)).onMapCreated!(map);
        await tester.pumpAndSettle();
        expect(map.cameraMoves, 1);
        expect(
          map.annotations.circles.options.single.circleColor,
          listBadge.style!.color!.toARGB32(),
        );

        final cases = {
          'approved': (l10n.reportStatusApproved, AppColors.statusNew),
          'resolved': (l10n.reportStatusResolved, AppColors.statusResolved),
          'pending': (l10n.reportStatusPending, AppColors.statusNew),
          'under_review': (l10n.reportStatusReview, AppColors.statusInProgress),
          'rejected': (l10n.reportStatusRejected, AppColors.statusError),
          'in_progress': ('in_progress', AppColors.statusInProgress),
          'error': ('error', AppColors.statusError),
          'unknown': ('unknown', AppColors.statusNew),
        };
        for (final entry in cases.entries) {
          reports.updateStatus(entry.key);
          await tester.pumpAndSettle();
          final circles = map.annotations.circles;
          final option = circles.options.single;
          expect(option.circleColor, entry.value.$2.toARGB32());
          expect(option.circleStrokeColor, Colors.white.toARGB32());
          expect(option.circleStrokeWidth, 3);
          expect(map.cameraMoves, 1);

          circles.onTap!(circles.annotations.single);
          await tester.pumpAndSettle();
          final sheet = find.byType(BottomSheet);
          if (!_report(entry.key).isPublic) {
            expect(sheet, findsNothing);
            continue;
          }
          final badge = tester.widget<Text>(
            find.descendant(of: sheet, matching: find.text(entry.value.$1)),
          );
          expect(badge.style?.color, entry.value.$2);
          expect(badge.style!.color!.toARGB32(), option.circleColor);
          Navigator.of(tester.element(sheet)).pop();
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant({TargetPlatform.windows}),
    );
  }
}
