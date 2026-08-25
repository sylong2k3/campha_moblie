import 'package:campha_moblie/app/theme/app_motion.dart';
import 'package:campha_moblie/core/storage/token_storage.dart';
import 'package:campha_moblie/features/auth/data/auth_repository.dart';
import 'package:campha_moblie/features/auth/domain/auth_result.dart';
import 'package:campha_moblie/features/auth/presentation/login_screen.dart';
import 'package:campha_moblie/features/cms/presentation/cms_widgets.dart';
import 'package:campha_moblie/features/field_reports/domain/report_composer_controller.dart';
import 'package:campha_moblie/features/field_reports/presentation/create_field_report_screen.dart';
import 'package:campha_moblie/features/routing/domain/route_model.dart';
import 'package:campha_moblie/features/routing/presentation/route_sheet.dart';
import 'package:campha_moblie/features/shared/presentation/app_feedback.dart';
import 'package:campha_moblie/features/shared/presentation/app_search_field.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_controller.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_models.dart';
import 'package:campha_moblie/features/tools/presentation/map_tool_panel_shell.dart';
import 'package:campha_moblie/features/tools/presentation/measure_sheet.dart';
import 'package:campha_moblie/features/tools/presentation/location_weather_sheet.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_secure_storage.dart';

void main() {
  testWidgets('inline notice stacks its action at 320dp and 200% text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AppInlineNotice(
                message: 'Không thể tải dữ liệu bản đồ.',
                actionLabel: 'Thử lại',
                onAction: () {},
                liveRegion: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('Thử lại')).dy,
      greaterThan(
        tester.getTopLeft(find.text('Không thể tải dữ liệu bản đồ.')).dy,
      ),
    );
  });

  testWidgets('search clear uses immediate clear callback', (tester) async {
    final controller = TextEditingController(text: 'quy hoạch');
    addTearDown(controller.dispose);
    final changes = <String>[];
    var clearCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            controller: controller,
            hintText: 'Tìm kiếm',
            clearTooltip: 'Xóa tìm kiếm',
            onChanged: changes.add,
            onSubmitted: (_) {},
            onClear: () => clearCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(clearCount, 1);
    expect(changes, isEmpty);
  });

  testWidgets('state switcher respects reduced motion and replaces its child', (
    tester,
  ) async {
    var state = 0;
    late StateSetter setHostState;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return AppStateSwitcher(
                  stateKey: ValueKey(state),
                  child: Text('state-$state'),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(AppStateSwitcher),
        matching: find.byType(AnimatedSwitcher),
      ),
      findsNothing,
    );
    setHostState(() => state = 1);
    await tester.pump();
    expect(find.text('state-0'), findsNothing);
    expect(find.text('state-1'), findsOneWidget);
  });

  testWidgets('search suffix stays 48dp while clear changes to loading', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'quy hoạch');
    addTearDown(controller.dispose);
    var loading = false;
    late StateSetter setHostState;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return AppSearchField(
                controller: controller,
                hintText: 'Tìm kiếm',
                clearTooltip: 'Xóa',
                loading: loading,
                onChanged: (_) {},
                onSubmitted: (_) {},
              );
            },
          ),
        ),
      ),
    );

    final clearSlot = tester.getSize(
      find
          .ancestor(
            of: find.byKey(const ValueKey('search-clear')),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    setHostState(() => loading = true);
    await tester.pump(AppMotion.quick);
    final loadingSlot = tester.getSize(
      find
          .ancestor(
            of: find.byKey(const ValueKey('search-loading')),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(clearSlot.width, 48);
    expect(loadingSlot.width, clearSlot.width);
  });

  testWidgets('CMS clear cancels debounce and searches empty immediately', (
    tester,
  ) async {
    final searches = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CmsSearchField(
            hint: 'Tìm kiếm',
            initialValue: 'quy hoạch',
            onSearch: searches.add,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'quy hoạch mới');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(searches, ['']);
    await tester.pump(const Duration(milliseconds: 500));
    expect(searches, ['']);
  });
  testWidgets('route shows App Settings recovery when location is blocked', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fieldToolsProvider.overrideWith(_DeniedForeverToolsController.new),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RouteSheet(onClose: () {})),
        ),
      ),
    );

    expect(
      find.text('Quyền vị trí đã bị chặn. Mở cài đặt để cấp lại.'),
      findsOneWidget,
    );
    expect(find.text('Mở cài đặt'), findsOneWidget);
    expect(find.text('Chạm bản đồ để chọn điểm bắt đầu.'), findsNothing);
  });

  testWidgets('route shows only current instruction and advances with GPS', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fieldToolsProvider.overrideWith(_RouteResultToolsController.new),
        ],
        child: const _LocalizedApp(
          home: Scaffold(
            body: MapToolDraggableSheet(
              initialChildSize: 0.24,
              maxChildSize: 0.24,
              child: RouteSheet(onClose: _noop),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('route-compact-result')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('route-current-instruction')),
      findsOneWidget,
    );
    expect(find.text('1.0 km'), findsOneWidget);
    expect(find.text('Đi thẳng trên Đường Trần Phú'), findsOneWidget);
    expect(find.text('Rẽ phải vào Quốc lộ 18'), findsNothing);
    expect(find.text('Chỉ dẫn từng chặng'), findsNothing);
    expect(find.byKey(const ValueKey('route-inline-steps')), findsNothing);

    final sheet = find.byKey(const ValueKey('map-tool-draggable-surface'));
    final draggable = tester.widget<DraggableScrollableSheet>(
      find.byKey(const ValueKey('map-tool-draggable-sheet')),
    );
    expect(draggable.snapSizes, [0.14, 0.24]);
    expect(tester.getSize(sheet).height, closeTo(800 * 0.24, 1));

    final routeContext = tester.element(find.byType(RouteSheet));
    final container = ProviderScope.containerOf(routeContext);
    container
        .read(fieldToolsProvider.notifier)
        .updateRoutePosition(
          position: const GeoCoordinate(107.335, 21.005),
          accuracyMeters: 8,
          timestamp: DateTime(2026, 8, 12),
        );
    await tester.pump();

    expect(find.text('Đi thẳng trên Đường Trần Phú'), findsNothing);
    expect(find.text('Rẽ phải vào Quốc lộ 18'), findsOneWidget);
    expect(container.read(fieldToolsProvider).activeRouteStepIndex, 1);

    await tester.tap(find.byKey(const ValueKey('route-edit')));
    await tester.pump();
    final editedState = container.read(fieldToolsProvider);
    expect(editedState.route, isNull);
    expect(editedState.routeStart, isNotNull);
    expect(editedState.routeEnd, isNotNull);
  });

  testWidgets('measure tool uses the same bottom-attached draggable surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fieldToolsProvider.overrideWith(_MeasureToolsController.new),
        ],
        child: const _LocalizedApp(
          home: Scaffold(
            body: MapToolDraggableSheet(
              initialChildSize: 0.32,
              maxChildSize: 0.32,
              child: MeasureSheet(onClose: _noop),
            ),
          ),
        ),
      ),
    );

    final sheet = find.byKey(const ValueKey('map-tool-draggable-surface'));
    final draggable = tester.widget<DraggableScrollableSheet>(
      find.byKey(const ValueKey('map-tool-draggable-sheet')),
    );
    expect(draggable.snapSizes, [0.14, 0.32]);
    expect(tester.getBottomLeft(sheet).dy, closeTo(800, 0.1));
    expect(tester.getSize(sheet).height, closeTo(800 * 0.32, 1));

    final top = tester.getTopLeft(sheet);
    await tester.dragFrom(top + const Offset(200, 16), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(800 * 0.32, 1));
    expect(find.text('Đo đạc'), findsOneWidget);
  });

  testWidgets('location sheet shows complete privacy text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fieldToolsProvider.overrideWith(
            () => _ReadyToolsController(accuracyMeters: 100),
          ),
        ],
        child: const _LocalizedSheet(),
      ),
    );

    final text = tester.widget<Text>(
      find.text(
        'Chỉ lấy vị trí khi bạn bấm tiếp tục. Ứng dụng không theo dõi nền.',
      ),
    );
    expect(text.maxLines, isNull);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
  });

  testWidgets('location sheet labels accuracy above threshold as low', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fieldToolsProvider.overrideWith(
            () => _ReadyToolsController(accuracyMeters: 100),
          ),
        ],
        child: const _LocalizedSheet(),
      ),
    );

    expect(find.text('Độ chính xác thấp · sai số ±100.0 m'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('location sheet keeps acceptable accuracy neutral', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fieldToolsProvider.overrideWith(
            () => _ReadyToolsController(accuracyMeters: 5),
          ),
        ],
        child: const _LocalizedSheet(),
      ),
    );

    expect(find.text('Độ chính xác ±5.0 m'), findsOneWidget);
    expect(find.textContaining('Độ chính xác thấp'), findsNothing);
    expect(find.byIcon(Icons.gps_fixed), findsWidgets);
  });

  testWidgets('debug login shows horizontal role strip below forgot password', (
    tester,
  ) async {
    await tester.pumpWidget(const _LocalizedApp(home: LoginScreen()));

    final panel = find.byKey(const ValueKey('test-accounts-panel'));
    final forgot = find.byKey(const ValueKey('forgot-password-link'));
    expect(panel, findsOneWidget);
    expect(
      tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('test-accounts-scroll')),
          )
          .scrollDirection,
      Axis.horizontal,
    );
    expect(
      tester.getTopLeft(panel).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(forgot).dy),
    );
    for (final role in [
      'citizen',
      'ubnd_tp',
      'so_xd',
      'so_tnmt',
      'system_admin',
    ]) {
      expect(find.byKey(ValueKey('test-account-$role')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('test-account-citizen')));
    await tester.pump();

    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('login-email')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'citizen@campha.gov.vn',
    );
    final passwordEditor = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('login-password')),
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordEditor.controller.text, isEmpty);
    expect(passwordEditor.focusNode.hasFocus, isTrue);
  });

  testWidgets('configured debug role button submits login immediately', (
    tester,
  ) async {
    final repository = _CapturingAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          tokenStorageProvider.overrideWithValue(repository.tokenStorage),
        ],
        child: const _LocalizedApp(
          home: LoginScreen(debugTestAccountPassword: 'demo-password'),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('test-account-citizen')));
    await tester.pump();

    expect(repository.loginCalls, 1);
    expect(repository.email, 'citizen@campha.gov.vn');
    expect(repository.password, 'demo-password');
  });

  testWidgets('invalid login focuses first invalid field in visual order', (
    tester,
  ) async {
    await tester.pumpWidget(const _LocalizedApp(home: LoginScreen()));

    await tester.ensureVisible(find.byKey(const ValueKey('login-submit')));
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('login-email')),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );

    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      'citizen@campha.gov.vn',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('login-submit')));
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('login-password')),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
  });

  testWidgets('report description exposes correction and field focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportComposerProvider.overrideWith(
            () => _DescriptionIssueController(description: 'Ngắn'),
          ),
        ],
        child: const _LocalizedApp(home: CreateFieldReportScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Nhập mô tả có ít nhất 10 ký tự.'), findsWidgets);
    await tester.ensureVisible(find.byKey(const ValueKey('report-submit')));
    await tester.tap(find.byKey(const ValueKey('report-submit')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('report-description')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });

  testWidgets('report submit focuses missing truth confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportComposerProvider.overrideWith(
            () => _DescriptionIssueController(
              description: 'Mô tả hợp lệ cần được kiểm tra.',
            ),
          ),
        ],
        child: const _LocalizedApp(home: CreateFieldReportScreen()),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(const ValueKey('report-submit')));
    await tester.tap(find.byKey(const ValueKey('report-submit')));
    await tester.pump();

    expect(
      Focus.of(
        tester.element(find.byKey(const ValueKey('report-truth-confirm'))),
      ).hasFocus,
      isTrue,
    );
  });
}

class _LocalizedSheet extends StatelessWidget {
  const _LocalizedSheet();

  @override
  Widget build(BuildContext context) => const _LocalizedApp(
    home: Scaffold(body: LocationWeatherSheet(layerId: null)),
  );
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp({required this.home});
  final Widget home;

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

class _ReadyToolsController extends FieldToolsController {
  _ReadyToolsController({required this.accuracyMeters});

  final double accuracyMeters;

  @override
  FieldToolsState build() => FieldToolsState(
    locationStatus: LocationStatus.ready,
    location: const GeoCoordinate(107.33, 21.01),
    accuracyMeters: accuracyMeters,
  );
}

class _DeniedForeverToolsController extends FieldToolsController {
  @override
  FieldToolsState build() => const FieldToolsState(
    mode: FieldToolMode.route,
    locationStatus: LocationStatus.deniedForever,
  );
}

class _MeasureToolsController extends FieldToolsController {
  @override
  FieldToolsState build() =>
      const FieldToolsState(mode: FieldToolMode.measureDistance);
}

class _RouteResultToolsController extends FieldToolsController {
  @override
  FieldToolsState build() => FieldToolsState(
    mode: FieldToolMode.route,
    routeStart: const GeoCoordinate(107.3301, 21),
    routeEnd: const GeoCoordinate(107.3399, 21),
    route: RouteResult.fromJson({
      'provider': 'mapbox',
      'profile': 'driving',
      'distance_m': 1012.45,
      'duration_s': 124.5,
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [107.3301, 21.0],
          [107.3399, 21.0],
        ],
      },
      'steps': [
        {
          'instruction': 'Đi thẳng trên Đường Trần Phú',
          'maneuver_type': 'depart',
          'modifier': 'straight',
          'name': 'Đường Trần Phú',
          'distance_m': 350.25,
          'duration_s': 80.5,
          'location': {
            'type': 'Point',
            'coordinates': [107.3301, 21.0],
          },
        },
        {
          'instruction': 'Rẽ phải vào Quốc lộ 18',
          'maneuver_type': 'turn',
          'modifier': 'right',
          'name': 'Quốc lộ 18',
          'distance_m': 662.2,
          'duration_s': 44.0,
          'location': {
            'type': 'Point',
            'coordinates': [107.335, 21.005],
          },
        },
      ],
      'snapped_start': {
        'type': 'Point',
        'coordinates': [107.3301, 21.0],
      },
      'snapped_end': {
        'type': 'Point',
        'coordinates': [107.3399, 21.0],
      },
    }),
  );
}

void _noop() {}

class _CapturingAuthRepository extends AuthRepository {
  _CapturingAuthRepository()
    : super(dio: Dio(), tokenStorage: TokenStorage(MemorySecureStorage()));

  int loginCalls = 0;
  String? email;
  String? password;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    this.email = email;
    this.password = password;
    throw StateError('Captured debug login.');
  }
}

class _DescriptionIssueController extends ReportComposerController {
  _DescriptionIssueController({required this.description});
  final String description;

  @override
  ReportComposerState build() => ReportComposerState(
    step: 2,
    media: const [ReportMediaItem(path: 'evidence.png', mimeType: 'image/png')],
    location: const GeoCoordinate(107.33, 21.01),
    description: description,
    restoring: false,
  );
}
