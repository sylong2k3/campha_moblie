import 'dart:async';

import 'package:campha_moblie/core/error/app_exception.dart';
import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/auth/domain/user_model.dart';
import 'package:campha_moblie/features/field_reports/data/field_report_repository.dart';
import 'package:campha_moblie/features/field_reports/domain/field_report_models.dart';
import 'package:campha_moblie/features/field_reports/domain/field_reports_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user(
  String role, {
  String id = 'manager',
  bool active = true,
  Map<String, dynamic> permissions = const {
    'field_report': {'read': true, 'approve': true, 'stats': true},
  },
}) => UserModel(
  id: id,
  email: '$id@example.test',
  fullName: id,
  roleCode: role,
  roleName: role,
  permissions: permissions,
  isActive: active,
  emailVerified: true,
  mustChangePassword: false,
  hasPassword: true,
);

Map<String, dynamic> _json({String status = 'pending'}) => {
  'id': '1',
  'reference_code': 'CP-001',
  'description': 'Private report content',
  'status': status,
  'longitude': 107.3,
  'latitude': 21.0,
  'created_at': '2026-09-01T00:00:00Z',
  'updated_at': '2026-09-01T00:00:01.123456Z',
  'sender_user_id': '100',
  'sender_name': 'Private sender',
  'sender_email': 'private@example.test',
  'reviewed_by': '2',
  'review_reason': 'Internal reason',
};

FieldReportPage _page(bool admin, {int page = 1}) => FieldReportPage(
  items: [
    admin
        ? FieldReport.fromJson(_json())
        : FieldReport.fromPublicJson(_json(status: 'approved')),
  ],
  page: page,
  limit: 20,
  total: 21,
  totalPages: 2,
);

class _Session extends SessionController {
  _Session(this.initial);
  final SessionState initial;
  @override
  SessionState build() => initial;
  void change(UserModel? user) => state = user == null
      ? const SessionState.guest()
      : SessionState.authenticated(user);
}

class _Repository extends FieldReportRepository {
  _Repository() : super(Dio());
  final calls = <({bool admin, String? status, int page})>[];
  final tokens = <CancelToken>[];
  final limits = <int>[];
  bool paginated = false;
  Completer<FieldReportPage>? secondPage;
  Object? secondPageError;
  Completer<FieldReportPage>? pending;
  Object? error;

  Future<FieldReportPage> _list(
    bool admin,
    String? status,
    int page,
    int limit,
    CancelToken? token,
  ) async {
    calls.add((admin: admin, status: status, page: page));
    limits.add(limit);
    tokens.add(token!);
    if (error != null) throw error!;
    if (admin && pending != null) return pending!.future;
    if (paginated) {
      if (page == 2 && secondPageError != null) throw secondPageError!;
      if (page == 2 && secondPage != null) return secondPage!.future;
      final json = {
        ..._json(status: status ?? (admin ? 'pending' : 'approved')),
        'id': '$page',
      };
      return FieldReportPage(
        items: [
          admin ? FieldReport.fromJson(json) : FieldReport.fromPublicJson(json),
        ],
        page: page,
        limit: limit,
        total: 3,
        totalPages: 3,
      );
    }
    return _page(admin, page: page);
  }

  @override
  Future<FieldReportPage> getPublic({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) => _list(false, status, page, limit, cancelToken);
  @override
  Future<FieldReportPage> getAdmin({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) => _list(true, status, page, limit, cancelToken);
}

void main() {
  ProviderContainer containerFor(_Session session, _Repository repository) {
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(() => session),
        fieldReportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(fieldReportsProvider, (_, _) {});
    return container;
  }

  for (final admin in [false, true]) {
    test(
      'map loads every page in one batch; list stays paged (admin: $admin)',
      () async {
        final repository = _Repository()..paginated = true;
        final session = _Session(
          admin
              ? SessionState.authenticated(_user('so_tnmt'))
              : const SessionState.guest(),
        );
        final container = containerFor(session, repository);
        await pumpEventQueue();
        expect(repository.calls.length, 1);
        expect(repository.limits.single, 20);
        final controller = container.read(fieldReportsProvider.notifier);
        final previousItems = container.read(fieldReportsProvider).items;
        repository.secondPage = Completer<FieldReportPage>();
        final loading = controller.setMapMode(true);
        await pumpEventQueue();
        expect(container.read(fieldReportsProvider).loading, isTrue);
        expect(container.read(fieldReportsProvider).items, same(previousItems));
        expect(repository.calls.map((call) => call.page), [1, 1, 2]);
        repository.secondPage!.complete(
          FieldReportPage(
            items: [
              ...previousItems, // Duplicate IDs across pages must not create duplicate markers.
              FieldReport.fromJson({
                ..._json(status: admin ? 'pending' : 'approved'),
                'id': '2',
              }),
            ],
            page: 2,
            limit: 100,
            total: 3,
            totalPages: 3,
          ),
        );
        await loading;
        repository.secondPage = null;
        final loaded = container.read(fieldReportsProvider);
        expect(loaded.items.map((item) => item.id), ['1', '2', '3']);
        expect(loaded.mapMode, isTrue);
        expect(loaded.hasMore || loaded.loading, isFalse);
        expect(repository.limits, [20, 100, 100, 100]);
        expect(repository.calls.every((call) => call.admin == admin), isTrue);
        await controller.refresh();
        expect(repository.calls.skip(4).map((call) => call.page), [1, 2, 3]);
        await controller.setStatus('approved');
        expect(repository.calls.skip(7).map((call) => call.status), [
          'approved',
          'approved',
          'approved',
        ]);
        await controller.setMapMode(false);
        await controller.refresh();
        expect(repository.calls.length, 11);
        expect(repository.limits.last, 20);
        expect(container.read(fieldReportsProvider).hasMore, isTrue);
        await controller.loadMore();
        expect(repository.calls.last.page, 2);
      },
    );
  }

  test(
    'failed map page stays incomplete, retry reloads all; 403 clears private data',
    () async {
      final repository = _Repository()..paginated = true;
      final container = containerFor(
        _Session(SessionState.authenticated(_user('so_xd'))),
        repository,
      );
      await pumpEventQueue();
      final controller = container.read(fieldReportsProvider.notifier);
      repository.secondPageError = StateError('offline');
      await controller.setMapMode(true);
      expect(repository.calls.map((call) => call.page), [1, 1, 2]);
      expect(container.read(fieldReportsProvider).items.length, 1);
      expect(container.read(fieldReportsProvider).stale, isTrue);
      expect(container.read(fieldReportsProvider).hasMore, isTrue);
      repository.secondPageError = null;
      await controller.refresh();
      expect(container.read(fieldReportsProvider).items.length, 3);
      repository.secondPageError = const ForbiddenException();
      await controller.refresh();
      expect(container.read(fieldReportsProvider).items, isEmpty);
      expect(container.read(fieldReportsProvider).mapMode, isTrue);
      expect(
        container.read(fieldReportsProvider).error,
        isA<ForbiddenException>(),
      );
    },
  );

  for (final change in ['logout', 'filter', 'public', 'list']) {
    test(
      'map cancels pending pages on $change and ignores late response',
      () async {
        final repository = _Repository()..paginated = true;
        final session = _Session(SessionState.authenticated(_user('so_tnmt')));
        final container = containerFor(session, repository);
        await pumpEventQueue();
        final controller = container.read(fieldReportsProvider.notifier);
        final delayed = repository.secondPage = Completer<FieldReportPage>();
        final loading = controller.setMapMode(true);
        await pumpEventQueue();
        final token = repository.tokens.last;
        repository.secondPage = null;
        switch (change) {
          case 'logout':
            session.change(null);
            expect(container.read(fieldReportsProvider).items, isEmpty);
            await pumpEventQueue();
          case 'filter':
            await controller.setStatus('approved');
          case 'public':
            await controller.setAdminView(false);
          case 'list':
            await controller.setMapMode(false);
        }
        expect(token.isCancelled, isTrue);
        final current = container.read(fieldReportsProvider);
        final calls = repository.calls.length;
        delayed.complete(_page(true, page: 2));
        await loading;
        expect(container.read(fieldReportsProvider), same(current));
        expect(repository.calls.length, calls);
        if (change == 'logout' || change == 'public') {
          expect(current.admin, isFalse);
          expect(
            current.items.every((item) => item.senderEmail == null),
            isTrue,
          );
        }
        expect(current.items.length, change == 'list' ? 1 : 3);
        expect(current.mapMode, change != 'list');
      },
    );
  }

  for (final role in ['ubnd_tp', 'so_tnmt', 'so_xd', 'system_admin']) {
    test(
      '$role defaults to admin list and keeps filters/pagination on admin API',
      () async {
        final repository = _Repository();
        final session = _Session(SessionState.authenticated(_user(role)));
        final container = containerFor(session, repository);
        await pumpEventQueue();
        expect(repository.calls.single.admin, isTrue);
        expect(
          container.read(fieldReportsProvider).items.single.senderName,
          'Private sender',
        );
        final controller = container.read(fieldReportsProvider.notifier);
        await controller.setStatus('under_review');
        expect(repository.calls.last.status, 'under_review');
        await controller.loadMore();
        expect(repository.calls.last.page, 2);
        expect(repository.calls.every((call) => call.admin), isTrue);
        await controller.setAdminView(false);
        expect(repository.calls.last, (admin: false, status: null, page: 1));
        expect(
          container.read(fieldReportsProvider).items.single.senderName,
          isNull,
        );
        await controller.setAdminView(true);
        expect(repository.calls.last.admin, isTrue);
      },
    );
  }

  for (final role in [null, 'citizen', 'unknown']) {
    test('$role never selects admin API even with permissions', () async {
      final repository = _Repository();
      final session = _Session(
        role == null
            ? const SessionState.guest()
            : SessionState.authenticated(_user(role)),
      );
      final container = containerFor(session, repository);
      await pumpEventQueue();
      expect(repository.calls.single.admin, isFalse);
      final access = container.read(fieldReportAccessProvider);
      expect(access.canRead || access.canReview || access.canStats, isFalse);
      final controller = container.read(fieldReportsProvider.notifier);
      expect(
        () => controller.setAdminView(true),
        throwsA(isA<ForbiddenException>()),
      );
      expect(() => controller.setStatus('pending'), throwsArgumentError);
    });
  }

  test('inactive manager and missing read permission stay public', () async {
    final session = _Session(
      SessionState.authenticated(_user('system_admin', active: false)),
    );
    final repository = _Repository();
    final container = containerFor(session, repository);
    await pumpEventQueue();
    expect(container.read(fieldReportsProvider).admin, isFalse);
    session.change(_user('so_tnmt', permissions: const {}));
    await pumpEventQueue();
    expect(container.read(fieldReportsProvider).admin, isFalse);
    session.change(
      _user(
        'so_tnmt',
        permissions: const {
          'field_report': {'read': true},
        },
      ),
    );
    await pumpEventQueue();
    expect(container.read(fieldReportsProvider).admin, isTrue);
    expect(container.read(fieldReportAccessProvider).canReview, isFalse);
    expect(container.read(fieldReportAccessProvider).canStats, isFalse);
  });

  for (final oldRequestFails in [false, true]) {
    test(
      'logout purges PII and ignores late admin ${oldRequestFails ? 'error' : 'response'}',
      () async {
        final repository = _Repository();
        final session = _Session(SessionState.authenticated(_user('so_xd')));
        final container = containerFor(session, repository);
        await pumpEventQueue();
        expect(
          container.read(fieldReportsProvider).items.single.senderEmail,
          isNotNull,
        );
        repository.pending = Completer<FieldReportPage>();
        final refresh = container.read(fieldReportsProvider.notifier).refresh();
        final token = repository.tokens.last;
        session.change(null);
        expect(container.read(fieldReportsProvider).items, isEmpty);
        expect(token.isCancelled, isTrue);
        await pumpEventQueue();
        if (oldRequestFails) {
          repository.pending!.completeError(
            DioException(
              requestOptions: RequestOptions(),
              response: Response(
                requestOptions: RequestOptions(),
                statusCode: 403,
              ),
            ),
          );
        } else {
          repository.pending!.complete(_page(true));
        }
        await refresh;
        expect(container.read(fieldReportsProvider).admin, isFalse);
        expect(
          container.read(fieldReportsProvider).items.single.senderEmail,
          isNull,
        );
        expect(container.read(fieldReportsProvider).error, isNull);
      },
    );
  }

  test(
    'same-user permission loss clears private list; equal capabilities do not reload',
    () async {
      final session = _Session(SessionState.authenticated(_user('ubnd_tp')));
      final repository = _Repository();
      final container = containerFor(session, repository);
      await pumpEventQueue();
      session.change(_user('ubnd_tp'));
      await pumpEventQueue();
      expect(repository.calls.length, 1);
      session.change(_user('ubnd_tp', permissions: const {}));
      expect(container.read(fieldReportsProvider).items, isEmpty);
      await pumpEventQueue();
      expect(repository.calls.last.admin, isFalse);
    },
  );

  test(
    '403 removes cached PII; confirmed review removes item from old status filter',
    () async {
      final session = _Session(
        SessionState.authenticated(_user('system_admin')),
      );
      final repository = _Repository();
      final container = containerFor(session, repository);
      await pumpEventQueue();
      final controller = container.read(fieldReportsProvider.notifier);
      await controller.setStatus('pending');
      controller.applyReviewedReport(
        FieldReport.fromJson(_json(status: 'approved')),
      );
      expect(container.read(fieldReportsProvider).items, isEmpty);
      await controller.setStatus(null);
      repository.error = const ForbiddenException();
      await controller.refresh();
      expect(container.read(fieldReportsProvider).items, isEmpty);
      expect(
        container.read(fieldReportsProvider).error,
        isA<ForbiddenException>(),
      );
    },
  );

  test(
    'repository sends exact review contract, without retry or public fallback',
    () async {
      final dio = Dio();
      final requests = <RequestOptions>[];
      var code = 200;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            if (code != 200) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(requestOptions: options, statusCode: code),
                  type: DioExceptionType.badResponse,
                ),
              );
            } else {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'data': _json(status: 'approved')},
                ),
              );
            }
          },
        ),
      );
      final repository = FieldReportRepository(dio);
      final report = FieldReport.fromJson(_json());
      await repository.review(
        report,
        status: 'approved',
        reason: '  Verified on site  ',
      );
      expect(requests.single.method, 'PATCH');
      expect(requests.single.path, '/admin/field-reports/1/review');
      expect(requests.single.data, {
        'status': 'approved',
        'reason': 'Verified on site',
        'expectedUpdatedAt': '2026-09-01T00:00:01.123456Z',
      });
      await expectLater(
        repository.review(report, status: 'rejected'),
        throwsArgumentError,
      );
      await expectLater(
        repository.review(report, status: 'resolved'),
        throwsArgumentError,
      );
      expect(requests.length, 1);
      for (final statusCode in [403, 409]) {
        code = statusCode;
        await expectLater(
          repository.review(report, status: 'approved'),
          throwsA(isA<DioException>()),
        );
      }
      expect(requests.length, 3);
      code = 403;
      await expectLater(
        repository.getAdminDetail('1'),
        throwsA(isA<DioException>()),
      );
      expect(requests.last.path, '/admin/field-reports/1');
      expect(requests.length, 4);
    },
  );

  test(
    'public parser strips internal fields; public photos can have no expiry',
    () {
      final report = FieldReport.fromPublicJson({
        ..._json(status: 'approved'),
        'photos': [
          {
            'id': '3',
            'originalName': 'photo.png',
            'sizeBytes': 100,
            'url': 'https://example.test/public/photo.png',
            'expiresAt': null,
          },
        ],
        'history': [
          {'actor_user_id': '2'},
        ],
      });
      expect(report.senderUserId, isNull);
      expect(report.senderName, isNull);
      expect(report.senderEmail, isNull);
      expect(report.reviewedBy, isNull);
      expect(report.reviewReason, isNull);
      expect(report.history, isEmpty);
      expect(report.photos.single.expiresAt, isNull);
      expect(() => FieldReport.fromPublicJson(_json()), throwsFormatException);
    },
  );

  test(
    'cluster endpoint validates range and parses aggregate counts',
    () async {
      final dio = Dio();
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'data': [
                    {
                      'cluster_id': 0,
                      'report_count': 8,
                      'reporter_count': 3,
                      'longitude': 107.3,
                      'latitude': 21.0,
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
      final repository = FieldReportRepository(dio);
      final from = DateTime.utc(2026, 9, 1), to = DateTime.utc(2026, 9, 28);
      final clusters = await repository.getClusters(
        from: from,
        to: to,
        radiusMeters: 200,
        minReporters: 3,
      );
      expect(requests.single.path, '/admin/field-reports/clusters');
      expect(requests.single.queryParameters['minReporters'], 3);
      expect(clusters.single.reportCount, 8);
      expect(clusters.single.reporterCount, 3);
      await expectLater(
        repository.getClusters(from: to, to: from, radiusMeters: 200),
        throwsArgumentError,
      );
      expect(requests.length, 1);
    },
  );
}
