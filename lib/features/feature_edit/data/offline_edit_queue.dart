import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../../tools/domain/field_tools_models.dart';
import '../domain/feature_edit_models.dart';

final offlineEditQueueProvider = FutureProvider<OfflineEditQueue>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return OfflineEditQueue(database);
});

class OfflineEditQueue {
  const OfflineEditQueue(this._database);
  final AppDatabase _database;
  static const _uuid = Uuid();
  static const table = 'feature_edit_queue';
  static const clientTable = 'feature_edit_clients';

  Future<OfflineFeatureChange> enqueue({
    required String ownerId,
    required String layerId,
    required String featureId,
    required int baseVersion,
    required Map<String, dynamic> attributes,
    GeoJsonGeometry? geometry,
  }) async {
    if (attributes.isEmpty && geometry == null) {
      throw ArgumentError('Feature change is empty');
    }
    final clientId = await _clientId(ownerId);
    final item = OfflineFeatureChange(
      ownerId: ownerId,
      clientId: clientId,
      clientChangeId: _uuid.v4(),
      layerId: layerId,
      featureId: featureId,
      baseVersion: baseVersion,
      attributes: Map.unmodifiable(attributes),
      geometry: geometry,
      createdAt: DateTime.now().toUtc(),
    );
    await _database.raw.insert(table, _toRow(item));
    return item;
  }

  Future<List<OfflineFeatureChange>> ready(
    String ownerId, {
    int limit = 50,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _database.raw.query(
      table,
      where:
          'owner_id = ? AND status = ? AND (next_attempt_at IS NULL OR next_attempt_at <= ?)',
      whereArgs: [ownerId, OfflineChangeStatus.pending.name, now],
      orderBy: 'created_at ASC',
      limit: limit.clamp(1, 50),
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<List<OfflineFeatureChange>> list(String ownerId) async {
    final rows = await _database.raw.query(
      table,
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<int> count(String ownerId) async {
    final rows = await _database.raw.rawQuery(
      'SELECT COUNT(*) count FROM $table WHERE owner_id = ?',
      [ownerId],
    );
    return (rows.single['count'] as int?) ?? 0;
  }

  Future<void> markSyncing(String ownerId, Iterable<String> ids) =>
      _setStatus(ownerId, ids, OfflineChangeStatus.syncing);

  Future<void> resetPending(
    String ownerId,
    Iterable<String> ids,
    String errorCode,
  ) async {
    final values = ids.toList(growable: false);
    if (values.isEmpty) return;
    await _database.raw.update(
      table,
      {
        'status': OfflineChangeStatus.pending.name,
        'next_attempt_at': DateTime.now().toUtc().toIso8601String(),
        'error_code': errorCode,
      },
      where:
          'owner_id = ? AND client_change_id IN (${List.filled(values.length, '?').join(',')})',
      whereArgs: [ownerId, ...values],
    );
  }

  Future<void> markApplied(String ownerId, Iterable<String> ids) async {
    final values = ids.toList(growable: false);
    if (values.isEmpty) return;
    await _database.raw.delete(
      table,
      where:
          'owner_id = ? AND client_change_id IN (${List.filled(values.length, '?').join(',')})',
      whereArgs: [ownerId, ...values],
    );
  }

  Future<void> markConflict(
    String ownerId,
    String id,
    EditableFeatureSnapshot current,
  ) => _database.raw.update(
    table,
    {
      'status': OfflineChangeStatus.conflict.name,
      'server_current_json': jsonEncode(_snapshot(current)),
      'error_code': 'FEATURE_VERSION_CONFLICT',
    },
    where: 'owner_id = ? AND client_change_id = ?',
    whereArgs: [ownerId, id],
  );

  Future<void> markRejected(String ownerId, String id, String code) =>
      _database.raw.update(
        table,
        {'status': OfflineChangeStatus.rejected.name, 'error_code': code},
        where: 'owner_id = ? AND client_change_id = ?',
        whereArgs: [ownerId, id],
      );

  Future<void> retryLater(OfflineFeatureChange item) async {
    final attempts = item.attempts + 1;
    // ponytail: queue auto-retries only transport failures 5 times; manual review owns all server rejects/conflicts.
    final minutes = [1, 2, 5, 15, 30][attempts.clamp(1, 5) - 1];
    await _database.raw.update(
      table,
      {
        'status': attempts >= 5
            ? OfflineChangeStatus.rejected.name
            : OfflineChangeStatus.pending.name,
        'attempts': attempts,
        'next_attempt_at': attempts >= 5
            ? null
            : DateTime.now()
                  .toUtc()
                  .add(Duration(minutes: minutes))
                  .toIso8601String(),
        'error_code': attempts >= 5 ? 'RETRY_EXHAUSTED' : null,
      },
      where: 'owner_id = ? AND client_change_id = ?',
      whereArgs: [item.ownerId, item.clientChangeId],
    );
  }

  Future<void> discard(String ownerId, String id) => _database.raw.delete(
    table,
    where: 'owner_id = ? AND client_change_id = ?',
    whereArgs: [ownerId, id],
  );
  Future<void> purgeOwner(String ownerId) async {
    await _database.raw.transaction((transaction) async {
      await transaction.delete(
        table,
        where: 'owner_id = ?',
        whereArgs: [ownerId],
      );
      await transaction.delete(
        clientTable,
        where: 'owner_id = ?',
        whereArgs: [ownerId],
      );
    });
  }

  Future<void> _setStatus(
    String ownerId,
    Iterable<String> ids,
    OfflineChangeStatus status,
  ) async {
    final values = ids.toList(growable: false);
    if (values.isEmpty) return;
    await _database.raw.update(
      table,
      {'status': status.name},
      where:
          'owner_id = ? AND client_change_id IN (${List.filled(values.length, '?').join(',')})',
      whereArgs: [ownerId, ...values],
    );
  }

  Future<String> _clientId(String ownerId) async {
    final rows = await _database.raw.query(
      clientTable,
      columns: ['client_id'],
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      limit: 1,
    );
    if (rows.isNotEmpty) return rows.single['client_id']! as String;
    final value = _uuid.v4();
    await _database.raw.insert(clientTable, {
      'owner_id': ownerId,
      'client_id': value,
    });
    return value;
  }

  Map<String, Object?> _toRow(OfflineFeatureChange item) => {
    'owner_id': item.ownerId,
    'client_id': item.clientId,
    'client_change_id': item.clientChangeId,
    'layer_id': item.layerId,
    'feature_id': item.featureId,
    'base_version': item.baseVersion,
    'attributes_json': jsonEncode(item.attributes),
    'geometry_json': item.geometry == null
        ? null
        : jsonEncode(item.geometry!.toJson()),
    'status': item.status.name,
    'attempts': item.attempts,
    'created_at': item.createdAt.toIso8601String(),
  };

  OfflineFeatureChange _fromRow(Map<String, Object?> row) =>
      OfflineFeatureChange(
        ownerId: row['owner_id']! as String,
        clientId: row['client_id']! as String,
        clientChangeId: row['client_change_id']! as String,
        layerId: row['layer_id']! as String,
        featureId: row['feature_id']! as String,
        baseVersion: row['base_version']! as int,
        attributes: Map<String, dynamic>.from(
          jsonDecode(row['attributes_json']! as String) as Map,
        ),
        geometry: row['geometry_json'] == null
            ? null
            : GeoJsonGeometry.fromJson(
                Map<String, dynamic>.from(
                  jsonDecode(row['geometry_json']! as String) as Map,
                ),
              ),
        status: OfflineChangeStatus.values.byName(row['status']! as String),
        attempts: row['attempts']! as int,
        createdAt: DateTime.parse(row['created_at']! as String),
        nextAttemptAt: row['next_attempt_at'] == null
            ? null
            : DateTime.parse(row['next_attempt_at']! as String),
        serverCurrent: row['server_current_json'] == null
            ? null
            : EditableFeatureSnapshot.fromJson(
                Map<String, dynamic>.from(
                  jsonDecode(row['server_current_json']! as String) as Map,
                ),
              ),
        errorCode: row['error_code'] as String?,
      );

  Map<String, dynamic> _snapshot(EditableFeatureSnapshot value) => {
    'featureId': value.featureId,
    'attributes': value.attributes,
    'geometry': value.geometry.toJson(),
    'version': value.version,
    if (value.updatedAt != null)
      'updatedAt': value.updatedAt!.toIso8601String(),
  };
}
