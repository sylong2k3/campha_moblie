import 'dart:async';
import 'dart:convert';

import 'package:campha_moblie/features/field_reports/domain/report_composer_controller.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fresh edits never masquerade as a restored draft', () {
    const fresh = ReportComposerState(restoring: false);
    final edited = fresh.copyWith(description: 'Mặt đường đang sụt lún');

    expect(edited.restoredFromDraft, isFalse);
    expect(edited.currentIssue, ReportComposerIssue.evidenceRequired);
  });

  test('readiness issue follows current report prerequisite', () {
    const media = ReportMediaItem(path: 'evidence.png', mimeType: 'image/png');
    const location = GeoCoordinate(107.33, 21.01);

    final locationMissing = const ReportComposerState(
      step: 1,
      media: [media],
      restoring: false,
    );
    final descriptionMissing = const ReportComposerState(
      step: 2,
      media: [media],
      location: location,
      restoring: false,
    );
    final truthMissing = descriptionMissing.copyWith(
      description: 'Mặt đường sụt lún cần kiểm tra.',
    );
    final ready = truthMissing.copyWith(truthConfirmed: true);

    expect(locationMissing.currentIssue, ReportComposerIssue.locationRequired);
    expect(
      descriptionMissing.currentIssue,
      ReportComposerIssue.descriptionRequired,
    );
    expect(
      truthMissing.currentIssue,
      ReportComposerIssue.truthConfirmationRequired,
    );
    expect(ready.currentIssue, isNull);
    expect(ready.canSubmit, isTrue);
  });

  test('meaningful persisted data sets restored draft flag', () async {
    SharedPreferences.setMockInitialValues({
      'field_report_unsent_v1': jsonEncode({
        'step': 0,
        'media': const [],
        'longitude': null,
        'latitude': null,
        'accuracyMeters': null,
        'geometry': null,
        'description': 'Nội dung bản nháp chưa gửi',
        'truthConfirmed': false,
      }),
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final restored = Completer<ReportComposerState>();
    final subscription = container.listen(reportComposerProvider, (_, next) {
      if (!next.restoring && !restored.isCompleted) restored.complete(next);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    final state = await restored.future.timeout(const Duration(seconds: 2));
    expect(state.restoredFromDraft, isTrue);
    expect(state.description, 'Nội dung bản nháp chưa gửi');
  });

  test(
    'clear removes persisted private draft and resets memory state',
    () async {
      SharedPreferences.setMockInitialValues({
        'field_report_unsent_v1': jsonEncode({
          'step': 2,
          'media': const [],
          'longitude': 107.33,
          'latitude': 21.01,
          'accuracyMeters': 4.0,
          'geometry': null,
          'description': 'Vị trí riêng tư chưa gửi',
          'truthConfirmed': true,
        }),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ready = Completer<void>();
      final subscription = container.listen(reportComposerProvider, (_, next) {
        if (!next.restoring && !ready.isCompleted) ready.complete();
      }, fireImmediately: true);
      addTearDown(subscription.close);
      await ready.future.timeout(const Duration(seconds: 2));

      await container.read(reportComposerProvider.notifier).clear();

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey('field_report_unsent_v1'), isFalse);
      expect(container.read(reportComposerProvider).description, isEmpty);
      expect(container.read(reportComposerProvider).location, isNull);
      expect(container.read(reportComposerProvider).media, isEmpty);
    },
  );

  test('allows locations outside Cam Pha bounds in report composer', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const outsideLocation = GeoCoordinate(105.85, 21.02); // Hanoi coordinates
    expect(outsideLocation.isInCamPhaBounds, isFalse);

    await container
        .read(reportComposerProvider.notifier)
        .setLocation(outsideLocation);

    final state = container.read(reportComposerProvider);
    expect(state.location, equals(outsideLocation));
    expect(state.locationReady, isTrue);
  });
}

