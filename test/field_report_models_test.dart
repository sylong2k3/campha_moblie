import 'package:campha_moblie/features/field_reports/domain/field_report_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> report({String status = 'approved'}) => {
    'id': '9007199254740997',
    'reference_code': 'CP-2026-00000042',
    'description': 'Mặt đường sụt lún cần kiểm tra an toàn.',
    'status': status,
    'longitude': '107.335',
    'latitude': '21.01',
    'measured_geometry': null,
    'created_at': '2026-08-10T12:00:00Z',
    'updated_at': '2026-08-10T12:05:00Z',
    'photo_count': 1,
  };

  test('parses public paged envelope and preserves BIGINT IDs as strings', () {
    final page = FieldReportPage.fromEnvelope({
      'data': {
        'items': [report()],
      },
      'metadata': {'page': 1, 'limit': 20, 'total': 21, 'totalPages': 2},
    });
    expect(page.items.single.id, '9007199254740997');
    expect(page.items.single.location.longitude, 107.335);
    expect(page.hasMore, isTrue);
  });

  test('parses private detail photos and status history exactly', () {
    final detail = FieldReport.fromJson({
      ...report(status: 'under_review'),
      'sender_user_id': '9007199254740999',
      'sender_name': 'Nguyễn Văn A',
      'sender_email': 'a@example.test',
      'review_reason': 'Đang chuyển đơn vị phụ trách.',
      'reviewed_at': '2026-08-10T12:10:00Z',
      'photos': [
        {
          'id': '9007199254741001',
          'originalName': 'evidence.png',
          'sizeBytes': 2048,
          'url': 'https://objects.example.test/report.png?grant=x',
          'expiresAt': '2026-08-10T12:20:00Z',
        },
      ],
      'history': [
        {
          'previous_status': 'pending',
          'new_status': 'under_review',
          'reason': 'Tiếp nhận',
          'actor_user_id': '9007199254741002',
          'created_at': '2026-08-10T12:10:00Z',
        },
      ],
    });
    expect(detail.senderUserId, '9007199254740999');
    expect(detail.photos.single.id, '9007199254741001');
    expect(detail.photos.single.url.isAbsolute, isTrue);
    expect(detail.history.single.previousStatus, 'pending');
    expect(detail.history.single.newStatus, 'under_review');
  });

  test('parses camelCase presign and snake_case ready upload contracts', () {
    final grant = UploadGrant.fromJson({
      'id': '9007199254741003',
      'uploadUrl': 'http://localhost:9000/quarantine/evidence.png?signature=x',
      'expiresAt': '2026-08-10T12:15:00Z',
    });
    final ready = ReadyUpload.fromJson({
      'id': '9007199254741003',
      'lifecycle_status': 'ready',
      'scan_status': 'clean',
      'detected_mime': 'image/png',
      'size_bytes': '4096',
    });
    expect(grant.id, '9007199254741003');
    expect(grant.uploadUrl.isAbsolute, isTrue);
    expect(ready.mimeType, 'image/png');
    expect(ready.sizeBytes, 4096);
  });

  test('rejects unknown status and unsafe storage URLs', () {
    expect(
      () => FieldReport.fromJson(report(status: 'archived')),
      throwsFormatException,
    );
    for (final url in [
      '/relative/object',
      'file:///private/evidence.png',
      'content://provider/evidence',
    ]) {
      expect(
        () => FieldReportPhoto.fromJson({
          'id': '1',
          'originalName': 'evidence.png',
          'sizeBytes': 10,
          'url': url,
          'expiresAt': '2026-08-10T12:15:00Z',
        }),
        throwsFormatException,
      );
      expect(
        () => UploadGrant.fromJson({
          'id': '1',
          'uploadUrl': url,
          'expiresAt': '2026-08-10T12:15:00Z',
        }),
        throwsFormatException,
      );
    }
  });
}
