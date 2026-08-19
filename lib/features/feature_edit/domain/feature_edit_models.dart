import '../../tools/domain/field_tools_models.dart';

class EditableFeatureSnapshot {
  const EditableFeatureSnapshot({
    required this.featureId,
    required this.attributes,
    required this.geometry,
    required this.version,
    this.updatedAt,
  });
  final String featureId;
  final Map<String, dynamic> attributes;
  final GeoJsonGeometry geometry;
  final int version;
  final DateTime? updatedAt;

  factory EditableFeatureSnapshot.fromJson(Map<String, dynamic> json) =>
      EditableFeatureSnapshot(
        featureId: _string(
          json['feature_id'] ?? json['featureId'],
          'featureId',
        ),
        attributes: Map.unmodifiable(_map(json['attributes'], 'attributes')),
        geometry: GeoJsonGeometry.fromJson(_map(json['geometry'], 'geometry')),
        version: _integer(json['version'], 'version'),
        updatedAt: json['updatedAt'] == null
            ? null
            : _date(json['updatedAt'], 'updatedAt'),
      );
}

class FeatureVersion {
  const FeatureVersion({
    required this.version,
    required this.action,
    required this.beforeAttributes,
    required this.afterAttributes,
    required this.beforeGeometry,
    required this.afterGeometry,
    required this.changedAt,
    this.restoredFromVersion,
    this.changedBy,
  });
  final int version;
  final String action;
  final Map<String, dynamic> beforeAttributes;
  final Map<String, dynamic> afterAttributes;
  final GeoJsonGeometry beforeGeometry;
  final GeoJsonGeometry afterGeometry;
  final int? restoredFromVersion;
  final String? changedBy;
  final DateTime changedAt;

  Set<String> get changedFields {
    final fields = <String>{...beforeAttributes.keys, ...afterAttributes.keys};
    return fields
        .where((key) => beforeAttributes[key] != afterAttributes[key])
        .toSet();
  }

  factory FeatureVersion.fromJson(Map<String, dynamic> json) => FeatureVersion(
    version: _integer(json['version'], 'version'),
    action: _string(json['action'], 'action'),
    beforeAttributes: Map.unmodifiable(
      _map(json['before_attributes'], 'before_attributes'),
    ),
    afterAttributes: Map.unmodifiable(
      _map(json['after_attributes'], 'after_attributes'),
    ),
    beforeGeometry: GeoJsonGeometry.fromJson(
      _map(json['before_geometry'], 'before_geometry'),
    ),
    afterGeometry: GeoJsonGeometry.fromJson(
      _map(json['after_geometry'], 'after_geometry'),
    ),
    restoredFromVersion: json['restored_from_version'] == null
        ? null
        : _integer(json['restored_from_version'], 'restored_from_version'),
    changedBy: json['changed_by']?.toString(),
    changedAt: _date(json['changed_at'], 'changed_at'),
  );
}

enum OfflineChangeStatus { pending, syncing, conflict, rejected }

class OfflineFeatureChange {
  const OfflineFeatureChange({
    required this.ownerId,
    required this.clientId,
    required this.clientChangeId,
    required this.layerId,
    required this.featureId,
    required this.baseVersion,
    required this.attributes,
    required this.createdAt,
    this.geometry,
    this.status = OfflineChangeStatus.pending,
    this.attempts = 0,
    this.nextAttemptAt,
    this.serverCurrent,
    this.errorCode,
  });
  final String ownerId;
  final String clientId;
  final String clientChangeId;
  final String layerId;
  final String featureId;
  final int baseVersion;
  final Map<String, dynamic> attributes;
  final GeoJsonGeometry? geometry;
  final OfflineChangeStatus status;
  final int attempts;
  final DateTime createdAt;
  final DateTime? nextAttemptAt;
  final EditableFeatureSnapshot? serverCurrent;
  final String? errorCode;

  Map<String, dynamic> toApiJson() {
    final parsedLayerId = int.tryParse(layerId);
    if (parsedLayerId == null || parsedLayerId < 1) {
      throw const FormatException('Invalid layerId');
    }
    return {
      'clientChangeId': clientChangeId,
      'layerId': parsedLayerId,
      'featureId': featureId,
      'baseVersion': baseVersion,
      if (attributes.isNotEmpty) 'attributes': attributes,
      if (geometry != null) 'geometry': geometry!.toJson(),
    };
  }
}

class SyncItem {
  const SyncItem({
    required this.clientChangeId,
    required this.layerId,
    required this.featureId,
    this.version,
    this.current,
    this.code,
    this.replayed = false,
  });
  final String clientChangeId;
  final String layerId;
  final String featureId;
  final int? version;
  final EditableFeatureSnapshot? current;
  final String? code;
  final bool replayed;

  factory SyncItem.fromJson(Map<String, dynamic> json) => SyncItem(
    clientChangeId: _string(json['clientChangeId'], 'clientChangeId'),
    layerId: _string(json['layerId'], 'layerId'),
    featureId: _string(json['featureId'], 'featureId'),
    version: json['version'] == null
        ? null
        : _integer(json['version'], 'version'),
    current: json['current'] == null
        ? null
        : EditableFeatureSnapshot.fromJson({
            ..._map(json['current'], 'current'),
            'featureId': json['featureId'],
          }),
    code: json['code']?.toString(),
    replayed: json['replayed'] == true,
  );
}

class SyncResult {
  const SyncResult({
    required this.applied,
    required this.conflicts,
    required this.rejected,
  });
  final List<SyncItem> applied;
  final List<SyncItem> conflicts;
  final List<SyncItem> rejected;
  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
    applied: _items(json['applied'], 'applied'),
    conflicts: _items(json['conflicts'], 'conflicts'),
    rejected: _items(json['rejected'], 'rejected'),
  );
}

List<SyncItem> _items(Object? value, String field) {
  if (value is! List) throw FormatException('$field is not a list');
  return value
      .map((item) => SyncItem.fromJson(_map(item, '$field[]')))
      .toList(growable: false);
}

Map<String, dynamic> _map(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('$field is not an object');
}

String _string(Object? value, String field) {
  final parsed = value?.toString().trim() ?? '';
  if (parsed.isEmpty) throw FormatException('Missing $field');
  return parsed;
}

int _integer(Object? value, String field) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed < 1) throw FormatException('Invalid $field');
  return parsed;
}

DateTime _date(Object? value, String field) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) throw FormatException('Invalid $field');
  return parsed;
}
