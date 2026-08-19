import 'package:flutter/foundation.dart';

import '../../../features/tools/domain/field_tools_models.dart';

const fieldReportStatuses = <String>{
  'pending',
  'under_review',
  'approved',
  'rejected',
  'resolved',
};

class FieldReportPage {
  const FieldReportPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
  final List<FieldReport> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  bool get hasMore => page < totalPages;

  factory FieldReportPage.fromEnvelope(Map<String, dynamic> envelope) {
    final data = _map(envelope['data'], 'data');
    final metadata = _map(envelope['metadata'], 'metadata');
    final rawItems = data['items'];
    if (rawItems is! List) {
      throw const FormatException('data.items is not a list');
    }
    return FieldReportPage(
      items: rawItems
          .map((item) => FieldReport.fromJson(_map(item, 'data.items[]')))
          .toList(growable: false),
      page: _integer(metadata['page'], 'metadata.page'),
      limit: _integer(metadata['limit'], 'metadata.limit'),
      total: _integer(metadata['total'], 'metadata.total'),
      totalPages: _integer(metadata['totalPages'], 'metadata.totalPages'),
    );
  }
}

class FieldReport {
  const FieldReport({
    required this.id,
    required this.referenceCode,
    required this.description,
    required this.status,
    required this.location,
    required this.photoCount,
    required this.createdAt,
    required this.updatedAt,
    this.measuredGeometry,
    this.senderUserId,
    this.senderName,
    this.senderEmail,
    this.reviewReason,
    this.reviewedAt,
    this.photos = const [],
    this.history = const [],
    this.distanceMeters,
    this.distinctReporters,
  });
  final String id;
  final String referenceCode;
  final String description;
  final String status;
  final GeoCoordinate location;
  final GeoJsonGeometry? measuredGeometry;
  final int photoCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? senderUserId;
  final String? senderName;
  final String? senderEmail;
  final String? reviewReason;
  final DateTime? reviewedAt;
  final List<FieldReportPhoto> photos;
  final List<FieldReportHistory> history;
  final double? distanceMeters;
  final int? distinctReporters;
  bool get isPublic => status == 'approved' || status == 'resolved';

  factory FieldReport.fromJson(Map<String, dynamic> json) {
    final status = _requiredString(json, 'status');
    if (!fieldReportStatuses.contains(status)) {
      throw FormatException('Unknown field report status: $status');
    }
    final photos = json['photos'];
    final history = json['history'];
    if (photos != null && photos is! List) {
      throw const FormatException('photos is not a list');
    }
    if (history != null && history is! List) {
      throw const FormatException('history is not a list');
    }
    return FieldReport(
      id: _requiredString(json, 'id'),
      referenceCode: _requiredString(json, 'reference_code'),
      description: _requiredString(json, 'description'),
      status: status,
      location: GeoCoordinate(
        _number(json['longitude'], 'longitude'),
        _number(json['latitude'], 'latitude'),
      ),
      measuredGeometry: json['measured_geometry'] == null
          ? null
          : GeoJsonGeometry.fromJson(
              _map(json['measured_geometry'], 'measured_geometry'),
            ),
      photoCount: _integer(json['photo_count'], 'photo_count'),
      createdAt: _date(json['created_at'], 'created_at'),
      updatedAt: _date(json['updated_at'], 'updated_at'),
      senderUserId: json['sender_user_id']?.toString(),
      senderName: json['sender_name']?.toString(),
      senderEmail: json['sender_email']?.toString(),
      reviewReason: json['review_reason']?.toString(),
      reviewedAt: _optionalDate(json['reviewed_at'], 'reviewed_at'),
      photos: photos == null
          ? const <FieldReportPhoto>[]
          : photos
                .map<FieldReportPhoto>(
                  (item) => FieldReportPhoto.fromJson(_map(item, 'photos[]')),
                )
                .toList(growable: false),
      history: history == null
          ? const <FieldReportHistory>[]
          : history
                .map<FieldReportHistory>(
                  (item) =>
                      FieldReportHistory.fromJson(_map(item, 'history[]')),
                )
                .toList(growable: false),
      distanceMeters: _optionalNumber(json['distance_m'], 'distance_m'),
      distinctReporters: json['distinct_reporters'] == null
          ? null
          : _integer(json['distinct_reporters'], 'distinct_reporters'),
    );
  }
}

class FieldReportPhoto {
  const FieldReportPhoto({
    required this.id,
    required this.originalName,
    required this.sizeBytes,
    required this.url,
    required this.expiresAt,
  });
  final String id;
  final String originalName;
  final int sizeBytes;
  final Uri url;
  final DateTime expiresAt;
  factory FieldReportPhoto.fromJson(Map<String, dynamic> json) {
    final url = Uri.tryParse(_requiredString(json, 'url'));
    if (!_isSafeStorageUrl(url)) {
      throw const FormatException('Invalid report photo URL');
    }
    return FieldReportPhoto(
      id: _requiredString(json, 'id'),
      originalName: _requiredString(json, 'originalName'),
      sizeBytes: _integer(json['sizeBytes'], 'sizeBytes'),
      url: url!,
      expiresAt: _date(json['expiresAt'], 'expiresAt'),
    );
  }
}

class FieldReportHistory {
  const FieldReportHistory({
    required this.newStatus,
    required this.createdAt,
    this.previousStatus,
    this.reason,
    this.actorUserId,
  });
  final String? previousStatus;
  final String newStatus;
  final String? reason;
  final String? actorUserId;
  final DateTime createdAt;
  factory FieldReportHistory.fromJson(Map<String, dynamic> json) =>
      FieldReportHistory(
        previousStatus: json['previous_status']?.toString(),
        newStatus: _requiredString(json, 'new_status'),
        reason: json['reason']?.toString(),
        actorUserId: json['actor_user_id']?.toString(),
        createdAt: _date(json['created_at'], 'history.created_at'),
      );
}

class UploadGrant {
  const UploadGrant({
    required this.id,
    required this.uploadUrl,
    required this.expiresAt,
  });
  final String id;
  final Uri uploadUrl;
  final DateTime expiresAt;
  factory UploadGrant.fromJson(Map<String, dynamic> json) {
    final uploadUrl = Uri.tryParse(_requiredString(json, 'uploadUrl'));
    if (!_isSafeStorageUrl(uploadUrl)) {
      throw const FormatException('Invalid upload URL');
    }
    return UploadGrant(
      id: _requiredString(json, 'id'),
      uploadUrl: uploadUrl!,
      expiresAt: _date(json['expiresAt'], 'expiresAt'),
    );
  }
}

class ReadyUpload {
  const ReadyUpload({
    required this.id,
    required this.mimeType,
    required this.sizeBytes,
  });
  final String id;
  final String mimeType;
  final int sizeBytes;
  factory ReadyUpload.fromJson(Map<String, dynamic> json) {
    if (json['lifecycle_status'] != 'ready' || json['scan_status'] != 'clean') {
      throw const FormatException('Upload is not ready');
    }
    return ReadyUpload(
      id: _requiredString(json, 'id'),
      mimeType: _requiredString(json, 'detected_mime'),
      sizeBytes: _integer(json['size_bytes'], 'size_bytes'),
    );
  }
}

bool _isSafeStorageUrl(Uri? url) =>
    url != null &&
    url.hasAuthority &&
    (url.scheme == 'https' || (kDebugMode && url.scheme == 'http'));

Map<String, dynamic> _map(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('$field is not an object');
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field]?.toString().trim();
  if (value == null || value.isEmpty) throw FormatException('Missing $field');
  return value;
}

int _integer(Object? value, String field) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (parsed == null) throw FormatException('Invalid $field');
  return parsed;
}

double _number(Object? value, String field) {
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  if (parsed == null || !parsed.isFinite) {
    throw FormatException('Invalid $field');
  }
  return parsed;
}

double? _optionalNumber(Object? value, String field) =>
    value == null ? null : _number(value, field);
DateTime _date(Object? value, String field) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) throw FormatException('Invalid $field');
  return parsed;
}

DateTime? _optionalDate(Object? value, String field) =>
    value == null ? null : _date(value, field);
