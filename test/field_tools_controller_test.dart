import 'dart:async';

import 'package:campha_moblie/features/tools/data/tools_repository.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_controller.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('measurement starts automatically only after enough points', () async {
    final repository = _FakeToolsRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(fieldToolsProvider.notifier);
    container.read(fieldToolsProvider);

    controller.startMeasure(area: false);
    controller.addMapPoint(const GeoCoordinate(107.33, 21));
    expect(repository.requests, isEmpty);
    expect(container.read(fieldToolsProvider).measurement, isNull);

    controller.addMapPoint(const GeoCoordinate(107.34, 21));
    expect(repository.requests, hasLength(1));
    expect(container.read(fieldToolsProvider).measurement, isNotNull);
    expect(container.read(fieldToolsProvider).loading, isTrue);

    repository.complete(0, lengthMeters: 1037);
    await _until(() => container.read(fieldToolsProvider).loading == false);
    expect(container.read(fieldToolsProvider).measurement?.lengthMeters, 1037);
  });

  test('latest automatic measurement wins after rapid map taps', () async {
    final repository = _FakeToolsRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(fieldToolsProvider.notifier);
    container.read(fieldToolsProvider);

    controller.startMeasure(area: false);
    controller.addMapPoint(const GeoCoordinate(107.33, 21));
    controller.addMapPoint(const GeoCoordinate(107.34, 21));
    controller.addMapPoint(const GeoCoordinate(107.35, 21));
    expect(repository.requests, hasLength(2));

    repository.complete(1, lengthMeters: 2000);
    await _until(
      () =>
          container.read(fieldToolsProvider).measurement?.lengthMeters == 2000,
    );

    repository.complete(0, lengthMeters: 1000);
    await _flush();
    expect(container.read(fieldToolsProvider).measurement?.lengthMeters, 2000);
  });

  test('undo and redo recalculate valid geometry automatically', () {
    final repository = _FakeToolsRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(fieldToolsProvider.notifier);
    container.read(fieldToolsProvider);

    controller.startMeasure(area: false);
    controller.addMapPoint(const GeoCoordinate(107.33, 21));
    controller.addMapPoint(const GeoCoordinate(107.34, 21));
    controller.addMapPoint(const GeoCoordinate(107.35, 21));
    expect(repository.requests, hasLength(2));

    controller.undo();
    expect(repository.requests, hasLength(3));
    controller.undo();
    expect(repository.requests, hasLength(3));
    expect(container.read(fieldToolsProvider).measurement, isNull);

    controller.redo();
    expect(repository.requests, hasLength(4));
  });
}

ProviderContainer _container(_FakeToolsRepository repository) =>
    ProviderContainer(
      overrides: [toolsRepositoryProvider.overrideWithValue(repository)],
    );

Future<void> _until(bool Function() condition) async {
  for (var attempt = 0; attempt < 100 && !condition(); attempt++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

Future<void> _flush() async {
  for (var attempt = 0; attempt < 5; attempt++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _FakeToolsRepository extends ToolsRepository {
  _FakeToolsRepository() : super(dio: Dio());

  final requests = <Completer<MeasurementResult>>[];

  @override
  Future<MeasurementResult> measure(GeoJsonGeometry geometry) {
    final request = Completer<MeasurementResult>();
    requests.add(request);
    return request.future;
  }

  void complete(int index, {required double lengthMeters}) {
    requests[index].complete(
      MeasurementResult(geometryType: 'LINESTRING', lengthMeters: lengthMeters),
    );
  }
}
