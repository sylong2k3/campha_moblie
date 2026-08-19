import 'package:flutter/foundation.dart';

class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory PagedResult.fromEnvelope(
    Map<String, dynamic> envelope,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = _requiredMap(envelope, 'data');
    final metadata = _requiredMap(envelope, 'metadata');
    final rawItems = data['items'];
    if (rawItems is! List) {
      throw const FormatException('data.items is not a list');
    }
    return PagedResult(
      items: rawItems
          .map((item) => fromJson(_asMap(item, 'data.items[]')))
          .toList(growable: false),
      page: _int(metadata['page']),
      limit: _int(metadata['limit']),
      total: _int(metadata['total']),
      totalPages: _int(metadata['totalPages']),
    );
  }
}

class NewsModel {
  const NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.visibility,
    required this.status,
    this.content,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String visibility;
  final String status;
  final String? content;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory NewsModel.fromJson(Map<String, dynamic> json) => NewsModel(
    id: _requiredString(json, 'id'),
    title: _requiredString(json, 'title'),
    summary: json['summary']?.toString() ?? '',
    content: json['content']?.toString(),
    visibility: json['visibility']?.toString() ?? 'public',
    status: json['status']?.toString() ?? 'published',
    publishedAt: _date(json['published_at']),
    createdAt: _date(json['created_at']),
    updatedAt: _date(json['updated_at']),
  );
}

class NewsComment {
  const NewsComment({
    required this.id,
    required this.newsId,
    required this.userId,
    required this.fullName,
    required this.content,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String newsId;
  final String userId;
  final String fullName;
  final String content;
  final String status;
  final DateTime? createdAt;

  factory NewsComment.fromJson(Map<String, dynamic> json) => NewsComment(
    id: _requiredString(json, 'id'),
    newsId: _requiredString(json, 'news_id'),
    userId: _requiredString(json, 'user_id'),
    // POST /comments không join users nên full_name có thể vắng mặt
    fullName: json['full_name']?.toString().trim() ?? '',
    content: _requiredString(json, 'content'),
    status: json['status']?.toString() ?? 'pending',
    createdAt: _date(json['created_at']),
  );
}

class CmsDocumentModel {
  const CmsDocumentModel({
    required this.id,
    required this.title,
    required this.documentCode,
    required this.issuingAgency,
    required this.description,
    required this.visibility,
    required this.originalName,
    required this.sizeBytes,
    this.issuedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String documentCode;
  final String issuingAgency;
  final String description;
  final String visibility;
  final String originalName;
  final int sizeBytes;
  final DateTime? issuedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isInternal => visibility == 'internal';

  factory CmsDocumentModel.fromJson(Map<String, dynamic> json) =>
      CmsDocumentModel(
        id: _requiredString(json, 'id'),
        title: _requiredString(json, 'title'),
        documentCode: _requiredString(json, 'document_code'),
        issuingAgency: _requiredString(json, 'issuing_agency'),
        description: json['description']?.toString() ?? '',
        visibility: json['visibility']?.toString() ?? 'public',
        originalName: _requiredString(json, 'original_name'),
        sizeBytes: _int(json['size_bytes']),
        issuedAt: _date(json['issued_at']),
        createdAt: _date(json['created_at']),
        updatedAt: _date(json['updated_at']),
      );
}

class PdfMapModel {
  const PdfMapModel({
    required this.id,
    required this.title,
    required this.scaleLabel,
    required this.mapYear,
    required this.preparingAgency,
    required this.description,
    required this.visibility,
    required this.originalName,
    required this.sizeBytes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String scaleLabel;
  final int mapYear;
  final String preparingAgency;
  final String description;
  final String visibility;
  final String originalName;
  final int sizeBytes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isInternal => visibility == 'internal';

  factory PdfMapModel.fromJson(Map<String, dynamic> json) => PdfMapModel(
    id: _requiredString(json, 'id'),
    title: _requiredString(json, 'title'),
    scaleLabel: _requiredString(json, 'scale_label'),
    mapYear: _int(json['map_year']),
    preparingAgency: _requiredString(json, 'preparing_agency'),
    description: json['description']?.toString() ?? '',
    visibility: json['visibility']?.toString() ?? 'public',
    originalName: _requiredString(json, 'original_name'),
    sizeBytes: _int(json['size_bytes']),
    createdAt: _date(json['created_at']),
    updatedAt: _date(json['updated_at']),
  );
}

class DownloadGrant {
  const DownloadGrant({
    required this.url,
    required this.fileName,
    required this.expiresAt,
  });

  factory DownloadGrant.fromJson(Map<String, dynamic> json) {
    final url = Uri.tryParse(_requiredString(json, 'url'));
    final safeScheme =
        url?.scheme == 'https' || (kDebugMode && url?.scheme == 'http');
    final rawExpiresAt = json['expiresAt'];
    final expiresAt = _date(rawExpiresAt);
    if (url == null ||
        !url.hasAuthority ||
        !safeScheme ||
        (rawExpiresAt != null && expiresAt == null)) {
      throw const FormatException('Invalid download grant');
    }
    return DownloadGrant(
      url: url,
      fileName: _requiredString(json, 'fileName'),
      expiresAt: expiresAt,
    );
  }

  final Uri url;
  final String fileName;
  // Public files use a permanent API URL, so the backend returns null here.
  final DateTime? expiresAt;
}

Future<DownloadGrant> freshDownloadGrant({
  required Future<DownloadGrant> Function() load,
  DateTime Function() now = DateTime.now,
}) async {
  var grant = await load();
  final currentTime = now().toUtc();
  var expiresAt = grant.expiresAt;
  if (expiresAt == null) return grant;

  // Signed URL near expiry may die while system viewer starts; refresh once only.
  if (!expiresAt.isAfter(currentTime.add(const Duration(seconds: 5)))) {
    grant = await load();
    expiresAt = grant.expiresAt;
  }
  if (expiresAt != null && !expiresAt.isAfter(currentTime)) {
    throw const FormatException('Download grant expired after one refresh.');
  }
  return grant;
}

String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

Map<String, dynamic> envelopeDataMap(dynamic responseData) {
  final envelope = _asMap(responseData, 'response');
  return _requiredMap(envelope, 'data');
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) =>
    _asMap(json[key], key);

Map<String, dynamic> _asMap(dynamic value, String name) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  throw FormatException('$name is not an object');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim() ?? '';
  if (value.isEmpty) throw FormatException('$key is required');
  return value;
}

int _int(dynamic value) {
  if (value is int) return value;
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) throw const FormatException('Expected integer');
  return parsed;
}

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());
