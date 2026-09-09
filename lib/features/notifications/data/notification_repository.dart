import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import 'notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<NotificationPage> list({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
    CancelToken? cancelToken,
  }) async {
    if (page < 1 || limit < 1) {
      throw ArgumentError('page and limit must be positive');
    }
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.notificationsMine,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (unreadOnly) 'unreadOnly': true,
      },
      cancelToken: cancelToken,
    );
    final envelope = response.data;
    if (envelope == null) throw const FormatException('Missing response body');
    return NotificationPage.fromEnvelope(envelope);
  }

  Future<int> unreadCount({CancelToken? cancelToken}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.notificationsUnreadCount,
      cancelToken: cancelToken,
    );
    final data = response.data?['data'];
    final count = data is Map ? int.tryParse('${data['count']}') : null;
    if (count == null || count < 0) {
      throw const FormatException('Invalid unread count');
    }
    return count;
  }

  Future<void> markRead(int id, {CancelToken? cancelToken}) async {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    await _dio.patch<void>(
      ApiEndpoints.notificationRead(id),
      cancelToken: cancelToken,
    );
  }

  Future<void> markAllRead({CancelToken? cancelToken}) async {
    await _dio.patch<void>(
      ApiEndpoints.notificationsReadAll,
      cancelToken: cancelToken,
    );
  }

  Future<void> delete(int id, {CancelToken? cancelToken}) async {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    await _dio.delete<void>(
      ApiEndpoints.notificationDelete(id),
      cancelToken: cancelToken,
    );
  }
}
