import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Kết nối SQLite cục bộ dùng chung cho hàng đợi chỉnh sửa dữ liệu gốc.
/// Dùng `sqflite` thay vì `drift` vì dự án không dùng codegen.
///
/// Schema v2 có client ID và hàng đợi thay đổi phân vùng theo owner. Mọi thay
/// đổi schema phải tăng [schemaVersion] và thêm nhánh migration tương ứng.
class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  /// Truy cập trực tiếp khi feature cần tự viết SQL (raw query/insert/update).
  Database get raw => _db;

  static const _fileName = 'campha_gis.sqlite';
  static const schemaVersion = 2;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _fileName);
    final db = await openDatabase(
      path,
      version: schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await db.update(
      'feature_edit_queue',
      {'status': 'pending', 'error_code': 'RECOVERED_AFTER_RESTART'},
      where: 'status = ?',
      whereArgs: ['syncing'],
    );
    return AppDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) => _createV2(db);

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _createV2(db);
  }

  static Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS feature_edit_clients(
        owner_id TEXT PRIMARY KEY NOT NULL,
        client_id TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS feature_edit_queue(
        owner_id TEXT NOT NULL,
        client_id TEXT NOT NULL,
        client_change_id TEXT PRIMARY KEY NOT NULL,
        layer_id TEXT NOT NULL,
        feature_id TEXT NOT NULL,
        base_version INTEGER NOT NULL,
        attributes_json TEXT NOT NULL,
        geometry_json TEXT,
        status TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        next_attempt_at TEXT,
        server_current_json TEXT,
        error_code TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS feature_edit_queue_owner_status ON feature_edit_queue(owner_id,status,next_attempt_at)',
    );
  }

  Future<void> close() => _db.close();
}

final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await AppDatabase.open();
  ref.onDispose(() => unawaited(db.close()));
  return db;
}, name: 'appDatabaseProvider');
