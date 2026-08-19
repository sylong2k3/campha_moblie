import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

final offlineSyncRepositoryProvider = Provider<OfflineSyncRepository>((ref) {
  return OfflineSyncRepository(dio: ref.watch(dioProvider));
});

class SyncResult {
  final int applied;
  final List<dynamic> conflicts;

  SyncResult({required this.applied, required this.conflicts});

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      applied: json['applied'] as int? ?? 0,
      conflicts: json['conflicts'] as List<dynamic>? ?? [],
    );
  }
}

class OfflineSyncRepository {
  OfflineSyncRepository({required this.dio});

  final Dio dio;

  Future<SyncResult> syncOfflineQueue(
    List<Map<String, dynamic>> changes,
  ) async {
    final response = await dio.post(
      ApiEndpoints.mobileSync,
      data: {'changes': changes},
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return SyncResult.fromJson(data);
  }
}
