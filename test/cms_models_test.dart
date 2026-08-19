import 'package:campha_moblie/features/cms/domain/cms_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses news data.items plus top-level metadata with string ID', () {
    final page = PagedResult<NewsModel>.fromEnvelope({
      'data': {
        'items': [
          {
            'id': '9223372036854775807',
            'title': 'Tin Cẩm Phả',
            'summary': 'Tóm tắt',
            'visibility': 'public',
            'status': 'published',
            'published_at': '2026-08-03T05:22:01.504Z',
          },
        ],
      },
      'metadata': {'page': 1, 'limit': 20, 'total': 21, 'totalPages': 2},
    }, NewsModel.fromJson);
    expect(page.items.single.id, '9223372036854775807');
    expect(page.hasMore, isTrue);
    expect(page.total, 21);
  });

  test('parses exact document and PDF snake_case fields', () {
    final document = CmsDocumentModel.fromJson({
      'id': '2',
      'title': 'Kế hoạch PCTT',
      'document_code': 'KH-02',
      'issuing_agency': 'UBND Cẩm Phả',
      'issued_at': '2026-01-09T17:00:00.000Z',
      'description': 'Mô tả',
      'visibility': 'internal',
      'original_name': 'ke-hoach.pdf',
      'size_bytes': '2305600',
    });
    expect(document.documentCode, 'KH-02');
    expect(document.sizeBytes, 2305600);
    expect(document.isInternal, isTrue);

    final pdf = PdfMapModel.fromJson({
      'id': '5',
      'title': 'Bản đồ KTTV',
      'scale_label': '1:100.000',
      'map_year': 2025,
      'preparing_agency': 'Đài KTTV',
      'description': 'Mô tả',
      'visibility': 'public',
      'original_name': 'kttv.pdf',
      'size_bytes': '6800000',
    });
    expect(pdf.scaleLabel, '1:100.000');
    expect(pdf.mapYear, 2025);
  });

  test('parses approved comment and short-lived download grant', () {
    final comment = NewsComment.fromJson({
      'id': '25',
      'news_id': '8',
      'user_id': '10',
      'full_name': 'Nguyễn Thị Lan',
      'content': 'Ý kiến người dân',
      'status': 'approved',
      'created_at': '2026-08-03T05:22:48.418Z',
    });
    expect(comment.newsId, '8');
    expect(comment.status, 'approved');
    expect(comment.fullName, 'Nguyễn Thị Lan');

    // POST /comments không trả full_name — phải parse không lỗi
    final created = NewsComment.fromJson({
      'id': '45',
      'news_id': '4',
      'user_id': '2',
      'content': 'rrr',
      'status': 'pending',
      'created_at': '2026-08-13T09:46:50.159Z',
    });
    expect(created.fullName, '');

    final grant = DownloadGrant.fromJson({
      'url': 'https://storage.example/file.pdf?signature=x',
      'expiresAt': '2026-08-10T12:00:00Z',
      'fileName': 'file.pdf',
    });
    expect(grant.url.isScheme('https'), isTrue);
    expect(grant.fileName, 'file.pdf');
  });

  test('rejects download grants with unsafe external schemes', () {
    for (final url in [
      'file:///private/document.pdf',
      'content://provider/item',
    ]) {
      expect(
        () => DownloadGrant.fromJson({
          'url': url,
          'expiresAt': '2026-08-10T12:00:00Z',
          'fileName': 'file.pdf',
        }),
        throwsFormatException,
      );
    }
  });

  test('accepts permanent public document and PDF map grants', () async {
    final responses = [
      {
        'url':
            'https://apicampha.tourismpj.pro.vn/api/v1/storage/objects/6/file',
        'expiresAt': null,
        'fileName': 'QH-SDD-2021-2030-CamPha.pdf',
      },
      {
        'url':
            'https://apicampha.tourismpj.pro.vn/api/v1/storage/objects/72/file',
        'expiresAt': null,
        'fileName': 'saungap2024.pdf',
      },
    ];

    for (final response in responses) {
      var loads = 0;
      final parsed = DownloadGrant.fromJson(response);
      final grant = await freshDownloadGrant(
        load: () async {
          loads++;
          return parsed;
        },
      );

      expect(grant.expiresAt, isNull);
      expect(grant.fileName, response['fileName']);
      expect(loads, 1);
    }
  });

  test('rejects a download grant with a malformed non-null expiry', () {
    expect(
      () => DownloadGrant.fromJson({
        'url': 'https://storage.example/file.pdf',
        'expiresAt': 'not-a-date',
        'fileName': 'file.pdf',
      }),
      throwsFormatException,
    );
  });

  test('rejects old list envelope and missing required fields', () {
    expect(
      () => PagedResult<NewsModel>.fromEnvelope({
        'data': <dynamic>[],
        'metadata': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0},
      }, NewsModel.fromJson),
      throwsFormatException,
    );
    expect(
      () => CmsDocumentModel.fromJson({'id': '1', 'title': 'Missing fields'}),
      throwsFormatException,
    );
  });

  test('uses a valid download grant without refreshing', () async {
    final now = DateTime.utc(2026, 8, 11, 9);
    var loads = 0;
    final grant = await freshDownloadGrant(
      now: () => now,
      load: () async {
        loads++;
        return DownloadGrant(
          url: Uri.parse('https://storage.example/valid'),
          fileName: 'valid.pdf',
          expiresAt: now.add(const Duration(minutes: 1)),
        );
      },
    );

    expect(grant.fileName, 'valid.pdf');
    expect(loads, 1);
  });

  test('refreshes a near-expiry grant exactly once', () async {
    final now = DateTime.utc(2026, 8, 11, 9);
    var loads = 0;
    final grant = await freshDownloadGrant(
      now: () => now,
      load: () async {
        loads++;
        return DownloadGrant(
          url: Uri.parse('https://storage.example/$loads'),
          fileName: 'file.pdf',
          expiresAt: loads == 1
              ? now.add(const Duration(seconds: 2))
              : now.add(const Duration(minutes: 5)),
        );
      },
    );

    expect(grant.url.path, '/2');
    expect(loads, 2);
  });

  test('stops after one refresh when grants remain expired', () async {
    final now = DateTime.utc(2026, 8, 11, 9);
    var loads = 0;

    await expectLater(
      freshDownloadGrant(
        now: () => now,
        load: () async {
          loads++;
          return DownloadGrant(
            url: Uri.parse('https://storage.example/expired-$loads'),
            fileName: 'expired.pdf',
            expiresAt: now.subtract(const Duration(seconds: 1)),
          );
        },
      ),
      throwsA(isA<FormatException>()),
    );
    expect(loads, 2);
  });
}
