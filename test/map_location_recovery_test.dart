import 'dart:async';

import 'package:campha_moblie/core/storage/token_storage.dart';
import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/map/domain/map_controller.dart';
import 'package:campha_moblie/features/map/presentation/map_home_screen.dart';
import 'package:campha_moblie/features/routing/domain/route_model.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_controller.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_models.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;

import 'support/memory_secure_storage.dart';

void main() {
  late _Gps gps;
  late _Tools tools;
  late geo.GeolocatorPlatform original;

  setUp(() {
    original = geo.GeolocatorPlatform.instance;
    gps = _Gps();
    geo.GeolocatorPlatform.instance = gps;
  });
  tearDown(() async {
    geo.GeolocatorPlatform.instance = original;
    await gps.dispose();
  });

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(MemorySecureStorage()),
        sessionControllerProvider.overrideWith(_Guest.new),
        mapCatalogProvider.overrideWith(_Catalog.new),
        fieldToolsProvider.overrideWith(() => tools = _Tools()),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MapHomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  }

  Future<void> resume(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> locate(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('map-locate-user')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  _testGps('settings return retries location exactly once', (tester) async {
    gps.enabled = false;
    await mount(tester);
    await locate(tester);
    expect(find.text('Dịch vụ vị trí đang tắt.'), findsOneWidget);
    await tester.tap(find.text('Mở cài đặt'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(gps.settingsCalls, 1);
    expect(gps.currentCalls, 0);
    gps.enabled = true;
    await resume(tester);
    expect(gps.currentCalls, 1);
    expect(tools.state.location?.latitude, 21.05);
    await resume(tester);
    expect(gps.currentCalls, 1);
    expect(tester.takeException(), isNull);
  });

  for (final throwsError in [false, true]) {
    _testGps('settings failure ($throwsError) clears pending retry', (
      tester,
    ) async {
      gps.enabled = false;
      gps.settingsOpen = false;
      gps.settingsError = throwsError ? StateError('Settings failed') : null;
      await mount(tester);
      await locate(tester);
      await tester.tap(find.text('Mở cài đặt'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Đã có lỗi xảy ra'), findsOneWidget);
      gps.enabled = true;
      await resume(tester);
      expect(gps.currentCalls, 0);
      expect(tester.takeException(), isNull);
    });
  }

  _testGps('denying permission does not request again on dialog resume', (
    tester,
  ) async {
    gps.permission = geo.LocationPermission.denied;
    await mount(tester);
    await locate(tester);
    expect(gps.permissionRequests, 1);
    expect(find.text('Chưa được cấp quyền vị trí.'), findsOneWidget);
    await tester.tap(find.text('Huỷ'));
    await tester.pump(const Duration(milliseconds: 300));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(gps.permissionRequests, 1);
    expect(gps.currentCalls, 0);
  });

  _testGps('GPS outside CamPha displays coordinates without region warning', (
    tester,
  ) async {
    gps.pendingPosition = Completer<geo.Position>()
      ..complete(_position(latitude: 12.0045, longitude: 107.691198));
    await mount(tester);
    await locate(tester);
    expect(tools.state.locationStatus, LocationStatus.ready);
    expect(find.textContaining('ngoài phạm vi Cẩm Phả'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('map-tools-open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Vị trí & thời tiết'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('12.004500, 107.691198'), findsOneWidget);
    expect(find.textContaining('ngoài phạm vi Cẩm Phả'), findsNothing);
    expect(gps.currentCalls, 1);
    expect(tester.takeException(), isNull);
  });

  _testGps('rapid GPS taps share one in-flight location request', (
    tester,
  ) async {
    gps.pendingPosition = Completer<geo.Position>();
    await mount(tester);
    await locate(tester);
    await locate(tester);
    expect(gps.currentCalls, 1);
    gps.pendingPosition!.complete(_position());
    await tester.pump();
    expect(tools.state.location, isNotNull);
    expect(tester.takeException(), isNull);
  });

  _testGps('permission stream error stops both listeners and keeps route', (
    tester,
  ) async {
    await mount(tester);
    tools.setRoute();
    await tester.pump();
    expect(gps.positionStarts, 1);
    gps.permission = geo.LocationPermission.deniedForever;
    gps.positions.addError(geo.PermissionDeniedException('Revoked'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(gps.positions.hasListener, isFalse);
    expect(gps.services.hasListener, isFalse);
    expect(tools.state.route, same(_route));
    expect(
      find.text('Quyền vị trí đã bị chặn. Mở cài đặt để cấp lại.'),
      findsOneWidget,
    );
    expect(gps.permissionRequests, 0);
    expect(tester.takeException(), isNull);
  });

  _testGps('service off event stops tracking and settings restores it', (
    tester,
  ) async {
    await mount(tester);
    tools.setRoute();
    await tester.pump();
    gps.enabled = false;
    gps.services.add(geo.ServiceStatus.disabled);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(gps.positions.hasListener, isFalse);
    expect(gps.services.hasListener, isFalse);
    expect(find.text('Dịch vụ vị trí đang tắt.'), findsOneWidget);
    await tester.tap(find.text('Mở cài đặt'));
    await tester.pump(const Duration(milliseconds: 300));
    gps.enabled = true;
    await resume(tester);
    expect(gps.currentCalls, 1);
    expect(gps.positionStarts, 2);
    expect(gps.positions.hasListener, isTrue);
    expect(gps.services.hasListener, isTrue);
    expect(tools.state.route, same(_route));
    expect(tester.takeException(), isNull);
  });

  _testGps('route canceled during permission check never starts stale stream', (
    tester,
  ) async {
    gps.pendingPermission = Completer<geo.LocationPermission>();
    await mount(tester);
    tools.setRoute();
    await tester.pump();
    tools.cancelTool();
    gps.pendingPermission!.complete(geo.LocationPermission.whileInUse);
    await tester.pump();
    expect(gps.positionStarts, 0);
    expect(gps._controllers, isEmpty);
    expect(tools.state.route, isNull);
    expect(tester.takeException(), isNull);
  });

  _testGps('disposed screen cannot start stream after permission check', (
    tester,
  ) async {
    gps.pendingPermission = Completer<geo.LocationPermission>();
    await mount(tester);
    tools.setRoute();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    gps.pendingPermission!.complete(geo.LocationPermission.whileInUse);
    await tester.pump();
    expect(gps.positionStarts, 0);
    expect(gps._controllers, isEmpty);
    expect(tester.takeException(), isNull);
  });

  _testGps('resume detects permission revoked without stream error', (
    tester,
  ) async {
    await mount(tester);
    tools.setRoute();
    await tester.pump();
    gps.permission = geo.LocationPermission.deniedForever;
    await resume(tester);
    expect(gps.positions.hasListener, isFalse);
    expect(gps.positionStarts, 1);
    expect(
      find.text('Quyền vị trí đã bị chặn. Mở cài đặt để cấp lại.'),
      findsOneWidget,
    );
    expect(gps.permissionRequests, 0);
    expect(tester.takeException(), isNull);
  });

  _testGps('unexpected stream error is recoverable without losing route', (
    tester,
  ) async {
    await mount(tester);
    tools.setRoute();
    await tester.pump();
    gps.positions.addError(StateError('GPS stream failed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(gps.positions.hasListener, isFalse);
    expect(find.text('Thử lại'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(gps.positionStarts, 2);
    expect(tools.state.route, same(_route));
    expect(tester.takeException(), isNull);
  });

  _testGps('native stream start error cleans up service listener', (
    tester,
  ) async {
    await mount(tester);
    gps.startError = StateError('Native start failed');
    tools.setRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(gps.services.hasListener, isFalse);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(tools.state.route, same(_route));
    expect(tester.takeException(), isNull);
  });

  _testGps('native cancel failure still stops service listener', (
    tester,
  ) async {
    await mount(tester);
    tools.setRoute();
    await tester.pump();
    gps.cancelError = StateError('Native cancel failed');
    tools.cancelTool();
    await tester.pump();
    expect(gps.positions.hasListener, isFalse);
    expect(gps.services.hasListener, isFalse);
    expect(tester.takeException(), isNull);
  });

  _testGps(
    'stale stream positions are ignored but fresh positions update route',
    (tester) async {
      await mount(tester);
      tools.setRoute();
      await tester.pump();
      gps.positions.add(_position(age: const Duration(minutes: 3)));
      await tester.pump();
      expect(tools.state.location, isNull);
      gps.positions.add(_position());
      await tester.pump();
      expect(tools.state.location?.latitude, 21.05);
      gps.positions.add(_position(latitude: -33.8688, longitude: 151.2093));
      await tester.pump();
      expect(tools.state.location?.latitude, -33.8688);
      expect(tools.state.locationStatus, LocationStatus.ready);
      expect(tools.state.route, same(_route));
      expect(tester.takeException(), isNull);
    },
  );
}

// Windows không tạo native Mapbox view; vẫn dùng nút và lifecycle thật của màn.
void _testGps(String description, WidgetTesterCallback callback) => testWidgets(
  description,
  callback,
  variant: TargetPlatformVariant({TargetPlatform.windows}),
);

geo.Position _position({
  Duration age = Duration.zero,
  double latitude = 21.05,
  double longitude = 107.35,
}) => geo.Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime.now().subtract(age),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class _Gps extends geo.GeolocatorPlatform {
  bool enabled = true;
  bool settingsOpen = true;
  Object? settingsError;
  Object? startError;
  Object? cancelError;
  int currentCalls = 0;
  int settingsCalls = 0;
  int positionStarts = 0;
  int permissionRequests = 0;
  geo.LocationPermission permission = geo.LocationPermission.whileInUse;
  Completer<geo.LocationPermission>? pendingPermission;
  Completer<geo.Position>? pendingPosition;
  late StreamController<geo.Position> positions;
  late StreamController<geo.ServiceStatus> services;
  final _controllers = <StreamController<dynamic>>[];

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;

  @override
  Future<geo.LocationPermission> checkPermission() async =>
      pendingPermission == null ? permission : await pendingPermission!.future;

  @override
  Future<geo.LocationPermission> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<geo.Position> getCurrentPosition({
    geo.LocationSettings? locationSettings,
  }) async {
    currentCalls++;
    return pendingPosition == null
        ? _position()
        : await pendingPosition!.future;
  }

  @override
  Stream<geo.Position> getPositionStream({
    geo.LocationSettings? locationSettings,
  }) {
    positionStarts++;
    if (startError case final error?) throw error;
    positions = StreamController<geo.Position>(
      onCancel: () async {
        if (cancelError case final error?) throw error;
      },
    );
    _controllers.add(positions);
    return positions.stream;
  }

  @override
  Stream<geo.ServiceStatus> getServiceStatusStream() {
    services = StreamController<geo.ServiceStatus>(onCancel: () async {});
    _controllers.add(services);
    return services.stream;
  }

  @override
  Future<bool> openLocationSettings() async {
    settingsCalls++;
    if (settingsError case final error?) throw error;
    return settingsOpen;
  }

  @override
  Future<bool> openAppSettings() => openLocationSettings();

  Future<void> dispose() async {
    for (final controller in _controllers) {
      await controller.close();
    }
  }
}

class _Guest extends SessionController {
  @override
  SessionState build() => const SessionState.guest();
}

class _Catalog extends MapCatalogController {
  @override
  MapCatalogState build() => const MapCatalogState();
}

class _Tools extends FieldToolsController {
  @override
  FieldToolsState build() => const FieldToolsState();

  void setRoute() => state = state.copyWith(route: _route);

  @override
  Future<void> loadWeather() async {}
}

const _route = RouteResult(
  provider: 'mapbox',
  profile: 'driving',
  distanceMeters: 1000,
  durationSeconds: 100,
  geometry: GeoJsonGeometry(
    type: 'LineString',
    coordinates: [
      [107.35, 21.05],
      [107.36, 21.06],
    ],
  ),
  steps: [],
  snappedStart: GeoCoordinate(107.35, 21.05),
  snappedEnd: GeoCoordinate(107.36, 21.06),
);
