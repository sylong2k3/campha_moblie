import 'dart:async';
import 'dart:typed_data';

import 'package:campha_moblie/features/routing/data/routing_repository.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_controller.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('route requests own and cancel their token once', () async {
    final adapter = _PendingRouteAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        routingRepositoryProvider.overrideWithValue(
          RoutingRepository(dio: dio),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      dio.close(force: true);
    });
    final controller = container.read(fieldToolsProvider.notifier);
    container.read(fieldToolsProvider);
    controller.startRoute();
    controller.addMapPoint(const GeoCoordinate(107.33, 21.0));
    controller.addMapPoint(const GeoCoordinate(107.34, 21.01));

    final first = controller.findRoute();
    await adapter.firstStarted.future;
    final second = controller.findRoute();
    await adapter.secondStarted.future;
    controller.cancelTool();
    await Future.wait([first, second]);

    expect(adapter.requests, 2);
    expect(adapter.cancellations, 2);
    expect(container.read(fieldToolsProvider).loading, isFalse);
  });
}

class _PendingRouteAdapter implements HttpClientAdapter {
  int requests = 0;
  int cancellations = 0;
  final firstStarted = Completer<void>();
  final secondStarted = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    if (requests == 1) firstStarted.complete();
    if (requests == 2) secondStarted.complete();
    await cancelFuture;
    cancellations++;
    throw DioException.requestCancelled(
      requestOptions: options,
      reason: 'cancelled',
    );
  }

  @override
  void close({bool force = false}) {}
}
