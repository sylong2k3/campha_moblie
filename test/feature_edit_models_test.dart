import 'package:flutter_test/flutter_test.dart';
import 'package:campha_moblie/features/feature_edit/domain/feature_edit_models.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_models.dart';

void main() {
  test('feature history parses snake_case and changed fields', () {
    final item = FeatureVersion.fromJson({
      'version': 2,
      'action': 'update',
      'before_attributes': {'name': 'A', 'speed': 20},
      'after_attributes': {'name': 'B', 'speed': 20},
      'before_geometry': {
        'type': 'Point',
        'coordinates': [107.2, 21.0],
      },
      'after_geometry': {
        'type': 'Point',
        'coordinates': [107.3, 21.0],
      },
      'restored_from_version': null,
      'changed_by': '9007199254740993',
      'changed_at': '2026-08-10T10:00:00Z',
    });
    expect(item.version, 2);
    expect(item.changedBy, '9007199254740993');
    expect(item.changedFields, {'name'});
  });

  test('offline change emits exact sync contract', () {
    final item = OfflineFeatureChange(
      ownerId: '9',
      clientId: '11111111-1111-4111-8111-111111111111',
      clientChangeId: '22222222-2222-4222-8222-222222222222',
      layerId: '7',
      featureId: 'abc_1',
      baseVersion: 4,
      attributes: const {'name': 'Mới'},
      geometry: GeoJsonGeometry.point(const GeoCoordinate(107.3, 21.0)),
      createdAt: DateTime.utc(2026),
    );
    expect(item.toApiJson(), {
      'clientChangeId': '22222222-2222-4222-8222-222222222222',
      'layerId': 7,
      'featureId': 'abc_1',
      'baseVersion': 4,
      'attributes': {'name': 'Mới'},
      'geometry': {
        'type': 'Point',
        'coordinates': [107.3, 21.0],
      },
    });
  });

  test('offline change rejects malformed layer ID before sync', () {
    final item = OfflineFeatureChange(
      ownerId: '9',
      clientId: '11111111-1111-4111-8111-111111111111',
      clientChangeId: '22222222-2222-4222-8222-222222222222',
      layerId: 'not-a-layer',
      featureId: 'abc_1',
      baseVersion: 4,
      attributes: const {},
      createdAt: DateTime.utc(2026),
    );
    expect(item.toApiJson, throwsFormatException);
  });

  test('sync result keeps applied conflict rejected separate', () {
    final result = SyncResult.fromJson({
      'applied': [
        {'clientChangeId': 'a', 'layerId': 7, 'featureId': '1', 'version': 3},
      ],
      'conflicts': [
        {
          'clientChangeId': 'b',
          'layerId': 7,
          'featureId': '2',
          'current': {
            'attributes': {'name': 'server'},
            'geometry': {
              'type': 'Point',
              'coordinates': [107.2, 21.0],
            },
            'version': 8,
            'updatedAt': '2026-08-10T10:00:00Z',
          },
        },
      ],
      'rejected': [
        {
          'clientChangeId': 'c',
          'layerId': 7,
          'featureId': '3',
          'code': 'FEATURE_NOT_FOUND',
        },
      ],
    });
    expect(result.applied.single.version, 3);
    expect(result.conflicts.single.current!.version, 8);
    expect(result.rejected.single.code, 'FEATURE_NOT_FOUND');
  });
}
