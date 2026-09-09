class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.data = const {},
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  NotificationItem copyWith({DateTime? readAt}) => NotificationItem(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    readAt: readAt ?? this.readAt,
    createdAt: createdAt,
  );

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: _integer(json['id'], 'data.items[].id', minimum: 1),
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      data: _mapOrEmpty(json['data']),
      readAt: json['read_at'] != null || json['readAt'] != null
          ? DateTime.tryParse((json['read_at'] ?? json['readAt']).toString())
          : null,
      createdAt:
          DateTime.tryParse(
            (json['created_at'] ?? json['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }
}

class NotificationPage {
  final List<NotificationItem> items;
  final int page;
  final int total;
  final int totalPages;

  const NotificationPage({
    required this.items,
    this.page = 1,
    required this.total,
    int? totalPages,
  }) : totalPages = totalPages ?? (total == 0 ? 0 : 1);

  bool get hasMore => page < totalPages;

  factory NotificationPage.fromEnvelope(Map<String, dynamic> envelope) {
    final data = _map(envelope['data'], 'data');
    final metadata = _map(envelope['metadata'], 'metadata');
    final rawItems = data['items'];
    if (rawItems is! List) {
      throw const FormatException('data.items is not a list');
    }
    return NotificationPage(
      items: rawItems
          .map((item) => NotificationItem.fromJson(_map(item, 'data.items[]')))
          .toList(growable: false),
      page: _integer(metadata['page'], 'metadata.page', minimum: 1),
      total: _integer(metadata['total'], 'metadata.total'),
      totalPages: _integer(metadata['totalPages'], 'metadata.totalPages'),
    );
  }
}

Map<String, dynamic> _map(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('$field is not an object');
}

Map<String, dynamic> _mapOrEmpty(Object? value) {
  if (value == null) return const {};
  return _map(value, 'data.items[].data');
}

int _integer(Object? value, String field, {int minimum = 0}) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed < minimum) {
    throw FormatException('$field is not a valid integer');
  }
  return parsed;
}

String? notificationReportId(Map<String, dynamic> data) {
  final raw =
      (data['reportId'] ??
              data['report_id'] ??
              data['id'] ??
              data['field_report_id'])
          ?.toString() ??
      '';
  if (!RegExp(r'^[1-9]\d*$').hasMatch(raw)) return null;
  final id = int.tryParse(raw);
  return id != null && id > 0 ? '$id' : null;
}
