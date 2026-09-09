import 'dart:async';

import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/auth/domain/user_model.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campha_moblie/features/notifications/data/notification_model.dart';
import 'package:campha_moblie/features/notifications/data/notification_repository.dart';
import 'package:campha_moblie/features/notifications/domain/notification_controller.dart';
import 'package:campha_moblie/features/notifications/presentation/notifications_screen.dart';
import 'package:campha_moblie/features/notifications/presentation/widgets/notification_bell_button.dart';

class _FakeNotificationRepository implements NotificationRepository {
  List<NotificationItem> items;
  int unread;
  final pages = <int>[];
  final tokens = <CancelToken?>[];
  int unreadCalls = 0;
  int writes = 0;
  bool failWrite = false;
  Future<NotificationPage> Function(int, bool)? listHandler;
  Future<int> Function()? countHandler;
  Future<void> Function()? writeHandler;

  _FakeNotificationRepository({required this.items, this.unread = 0});

  @override
  Future<NotificationPage> list({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
    CancelToken? cancelToken,
  }) async {
    pages.add(page);
    tokens.add(cancelToken);
    if (listHandler != null) return listHandler!(page, unreadOnly);
    final filtered = unreadOnly
        ? items.where((i) => !i.isRead).toList()
        : items;
    return NotificationPage(
      items: filtered.skip((page - 1) * limit).take(limit).toList(),
      page: page,
      total: filtered.length,
      totalPages: (filtered.length / limit).ceil(),
    );
  }

  @override
  Future<int> unreadCount({CancelToken? cancelToken}) async {
    unreadCalls++;
    tokens.add(cancelToken);
    return countHandler == null ? unread : countHandler!();
  }

  Future<void> _write(CancelToken? token) async {
    writes++;
    tokens.add(token);
    if (failWrite) throw StateError('private error must not appear in UI');
    await writeHandler?.call();
  }

  @override
  Future<void> markRead(int id, {CancelToken? cancelToken}) async {
    await _write(cancelToken);
    items = items
        .map((i) => i.id == id ? i.copyWith(readAt: DateTime.now()) : i)
        .toList();
    unread = (unread - 1).clamp(0, 999);
  }

  @override
  Future<void> markAllRead({CancelToken? cancelToken}) async {
    await _write(cancelToken);
    items = items.map((i) => i.copyWith(readAt: DateTime.now())).toList();
    unread = 0;
  }

  @override
  Future<void> delete(int id, {CancelToken? cancelToken}) async {
    await _write(cancelToken);
    items = items.where((i) => i.id != id).toList();
  }
}

SessionState _authenticated([String id = '1']) => SessionState.authenticated(
  UserModel.fromJson({
    'id': id,
    'role': {'code': 'citizen'},
  }),
);

class _Session extends SessionController {
  _Session([this.initial]);
  final SessionState? initial;
  @override
  SessionState build() => initial ?? _authenticated();
  void change(SessionState next) => state = next;
}

NotificationItem _item(int id, {Map<String, dynamic> data = const {}}) =>
    NotificationItem(
      id: id,
      type: 'general',
      title: 'Notification $id',
      body: 'Full content $id',
      data: data,
      createdAt: DateTime.utc(2026, 9, 9),
    );

ProviderContainer _container(
  _FakeNotificationRepository repo, {
  SessionState? session,
}) {
  final container = ProviderContainer(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repo),
      sessionControllerProvider.overrideWith(() => _Session(session)),
    ],
  );
  container.listen(notificationListControllerProvider, (_, _) {});
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

Widget _app(
  _FakeNotificationRepository repo, {
  Widget child = const NotificationsScreen(),
  SessionState? session,
  String language = 'vi',
}) => ProviderScope(
  overrides: [
    notificationRepositoryProvider.overrideWithValue(repo),
    sessionControllerProvider.overrideWith(() => _Session(session)),
  ],
  child: MaterialApp(
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void _regressions() {
  test(
    'repository uses metadata total and rejects malformed envelopes',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      var data = <String, dynamic>{
        'data': {
          'items': List.generate(20, (i) => {'id': i + 1}),
        },
        'metadata': {'page': 1, 'total': 45, 'totalPages': 3},
      };
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(Response(requestOptions: options, data: data));
          },
        ),
      );
      final repo = NotificationRepository(dio);
      final page = await repo.list();
      expect(page.total, 45);
      expect(page.items, hasLength(20));
      expect(page.hasMore, isTrue);
      data = {
        'data': {'items': []},
      };
      await expectLater(repo.list(), throwsFormatException);
      await expectLater(repo.unreadCount(), throwsFormatException);
      await expectLater(repo.markRead(0), throwsArgumentError);
      await expectLater(repo.delete(-1), throwsArgumentError);
    },
  );

  test('only positive canonical report IDs may navigate', () {
    for (final id in [
      null,
      0,
      -1,
      '0',
      '1.5',
      '../2',
      ' 2',
      '+2',
      'abc',
      '01',
    ]) {
      expect(notificationReportId({'reportId': id}), isNull);
    }
    expect(notificationReportId({'reportId': '42'}), '42');
    expect(notificationReportId({'reportId': 42}), '42');
    expect(notificationReportId({'report_id': '42'}), '42');
    expect(notificationReportId({'report_id': 42}), '42');
    expect(notificationReportId({'id': '42'}), '42');
    expect(notificationReportId({'id': 42}), '42');
    expect(notificationReportId({'field_report_id': '42'}), '42');
  });

  test('guest makes no private list or count calls', () async {
    final repo = _FakeNotificationRepository(items: [_item(1)]);
    final c = _container(repo, session: const SessionState.guest());
    c.listen(unreadNotificationCountProvider, (_, _) {});
    expect(await c.read(unreadNotificationCountProvider.future), 0);
    await _settle();
    expect(repo.pages, isEmpty);
    expect(repo.unreadCalls, 0);
  });

  test(
    'logout clears retained list and drops pending old account response',
    () async {
      final repo = _FakeNotificationRepository(items: [_item(1)]);
      final c = _container(repo);
      await _settle();
      expect(c.read(notificationListControllerProvider).items.single.id, 1);
      final delayed = Completer<NotificationPage>();
      repo.listHandler = (_, _) => delayed.future;
      final refresh = c
          .read(notificationListControllerProvider.notifier)
          .refresh();
      final token = repo.tokens.last;
      final session = c.read(sessionControllerProvider.notifier) as _Session;
      session.change(const SessionState.guest());
      await _settle();
      expect(c.read(notificationListControllerProvider).items, isEmpty);
      expect(token!.isCancelled, isTrue);
      repo.listHandler = null;
      repo.items = [_item(2)];
      session.change(_authenticated('2'));
      await _settle();
      delayed.complete(NotificationPage(items: [_item(1)], total: 1));
      await refresh;
      expect(c.read(notificationListControllerProvider).items.single.id, 2);
    },
  );

  test(
    'parallel loadMore sends one page request and deduplicates IDs',
    () async {
      final repo = _FakeNotificationRepository(
        items: List.generate(45, (i) => _item(i + 1)),
      );
      final c = _container(repo);
      await _settle();
      final pending = Completer<NotificationPage>();
      repo.listHandler = (_, _) => pending.future;
      final ctrl = c.read(notificationListControllerProvider.notifier);
      final first = ctrl.loadMore();
      final second = ctrl.loadMore();
      expect(repo.pages, [1, 2]);
      pending.complete(
        NotificationPage(
          items: [_item(20), _item(21)],
          page: 2,
          total: 45,
          totalPages: 3,
        ),
      );
      await Future.wait([first, second]);
      expect(c.read(notificationListControllerProvider).items, hasLength(21));
    },
  );

  test('filter and refresh discard older requests', () async {
    final repo = _FakeNotificationRepository(items: [_item(1)]);
    final c = _container(repo);
    await _settle();
    final old = Completer<NotificationPage>();
    final fresh = Completer<NotificationPage>();
    repo.listHandler = (_, unread) => unread ? fresh.future : old.future;
    final ctrl = c.read(notificationListControllerProvider.notifier);
    final all = ctrl.loadInitial(unreadOnly: false);
    final unread = ctrl.loadInitial(unreadOnly: true);
    fresh.complete(NotificationPage(items: [_item(2)], total: 1));
    await unread;
    old.complete(NotificationPage(items: [_item(1)], total: 1));
    await all;
    expect(c.read(notificationListControllerProvider).unreadOnly, isTrue);
    expect(c.read(notificationListControllerProvider).items.single.id, 2);
  });

  for (final action in ['initial', 'more', 'read', 'all', 'delete', 'count']) {
    test(
      'dispose cancels pending $action without reading disposed ref',
      () async {
        final repo = _FakeNotificationRepository(
          items: List.generate(45, (i) => _item(i + 1)),
        );
        final c = _container(repo);
        await _settle();
        final list = Completer<NotificationPage>();
        final write = Completer<void>();
        final count = Completer<int>();
        repo.listHandler = (_, _) => list.future;
        repo.writeHandler = () => write.future;
        repo.countHandler = () => count.future;
        final ctrl = c.read(notificationListControllerProvider.notifier);
        final Future<Object?> request = switch (action) {
          'initial' => ctrl.loadInitial(),
          'more' => ctrl.loadMore(),
          'read' => ctrl.markRead(1),
          'all' => ctrl.markAllRead(),
          'delete' => ctrl.deleteNotification(1),
          _ => c.read(unreadNotificationCountProvider.future),
        };
        final token = repo.tokens.last;
        c.invalidate(notificationListControllerProvider);
        c.invalidate(unreadNotificationCountProvider);
        expect(token!.isCancelled, isTrue);
        list.complete(NotificationPage(items: [_item(1)], total: 1));
        write.complete();
        count.complete(9);
        // Riverpod hoàn tất future của provider autoDispose bằng lỗi khi bị hủy
        // lúc đang tải; điều cần kiểm tra là request bị hủy và không có ghi state.
        await request.then(
          (_) {},
          onError: (Object error) {
            expect(action, 'count');
            expect(error, isStateError);
          },
        );
      },
    );
  }

  test(
    'unread writes reset shifted offset and mark all empties unread',
    () async {
      final repo = _FakeNotificationRepository(
        items: List.generate(45, (i) => _item(i + 1)),
      );
      final c = _container(repo);
      await _settle();
      final ctrl = c.read(notificationListControllerProvider.notifier);
      await ctrl.loadInitial(unreadOnly: true);
      await ctrl.markRead(1);
      expect(c.read(notificationListControllerProvider).items.first.id, 2);
      await ctrl.loadMore();
      expect(
        c.read(notificationListControllerProvider).items.map((i) => i.id),
        contains(21),
      );
      await ctrl.deleteNotification(2);
      expect(c.read(notificationListControllerProvider).page, 1);
      expect(c.read(notificationListControllerProvider).items.first.id, 3);
      await ctrl.markAllRead();
      expect(c.read(notificationListControllerProvider).items, isEmpty);
      expect(c.read(notificationListControllerProvider).hasMore, isFalse);
    },
  );

  test(
    'failed write preserves items; success survives refresh failure',
    () async {
      final repo = _FakeNotificationRepository(items: [_item(1)])
        ..failWrite = true;
      final c = _container(repo);
      await _settle();
      final ctrl = c.read(notificationListControllerProvider.notifier);
      expect(await ctrl.deleteNotification(1), isFalse);
      expect(c.read(notificationListControllerProvider).items, hasLength(1));
      expect(c.read(notificationListControllerProvider).actionError, isNotNull);
      repo.failWrite = false;
      repo.listHandler = (_, _) => Future.error(StateError('offline'));
      expect(await ctrl.deleteNotification(1), isTrue);
      expect(c.read(notificationListControllerProvider).items, isEmpty);
      expect(
        c.read(notificationListControllerProvider).errorMessage,
        isNotNull,
      );
    },
  );

  test('mutation invalidates old list and blocks duplicate writes', () async {
    final repo = _FakeNotificationRepository(items: [_item(1)]);
    final c = _container(repo);
    await _settle();
    final stale = Completer<NotificationPage>();
    final write = Completer<void>();
    repo.listHandler = (_, _) => stale.future;
    repo.writeHandler = () => write.future;
    final ctrl = c.read(notificationListControllerProvider.notifier);
    final refresh = ctrl.refresh();
    final deletion = ctrl.deleteNotification(1);
    expect(await ctrl.deleteNotification(1), isFalse);
    stale.complete(NotificationPage(items: [_item(1)], total: 1));
    repo.listHandler = null;
    write.complete();
    await Future.wait([refresh, deletion]);
    expect(repo.writes, 1);
    expect(c.read(notificationListControllerProvider).items, isEmpty);
  });

  testWidgets('empty inbox supports pull to refresh', (tester) async {
    final repo = _FakeNotificationRepository(items: []);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    repo.items = [_item(1)];
    await tester.drag(
      find.byKey(const ValueKey('notifications-scroll')),
      const Offset(0, 350),
    );
    await tester.pumpAndSettle();
    expect(find.text('Notification 1'), findsOneWidget);
  });

  testWidgets('delete asks confirmation; failure visible and retry possible', (
    tester,
  ) async {
    final repo = _FakeNotificationRepository(items: [_item(1)])
      ..failWrite = true;
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xóa thông báo'));
    await tester.pumpAndSettle();
    expect(repo.writes, 0);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(find.text('Notification 1'), findsOneWidget);
    expect(
      find.text('Thao tác chưa thành công. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.textContaining('private error'), findsNothing);
    repo.failWrite = false;
    await tester.tap(find.byTooltip('Xóa thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(find.text('Notification 1'), findsNothing);
  });

  testWidgets(
    'invalid report ID opens full text sheet in English with large text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = _FakeNotificationRepository(
        items: [
          _item(1, data: {'reportId': '-2'}),
        ],
      );
      await tester.pumpWidget(
        _app(
          repo,
          language: 'en',
          child: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
      await tester.tap(find.text('Notification 1'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('badge hides previous count while a new session loads', (
    tester,
  ) async {
    final repo = _FakeNotificationRepository(items: [], unread: 5);
    await tester.pumpWidget(
      _app(repo, child: const Scaffold(body: NotificationBellButton())),
    );
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(NotificationBellButton)),
    );
    final pending = Completer<int>();
    repo.countHandler = () => pending.future;
    (c.read(sessionControllerProvider.notifier) as _Session).change(
      _authenticated('2'),
    );
    await tester.pump();
    expect(find.text('5'), findsNothing);
    pending.complete(2);
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _regressions();
  group('Notification Model Tests', () {
    test('parses notification JSON correctly', () {
      final json = {
        'id': '101',
        'type': 'field_report.created',
        'title': 'Phản ánh mới',
        'body': 'Có phản ánh ngập lụt tại Trần Phú',
        'data': {'reportId': 42},
        'read_at': null,
        'created_at': '2026-09-09T10:00:00Z',
      };

      final item = NotificationItem.fromJson(json);
      expect(item.id, 101);
      expect(item.type, 'field_report.created');
      expect(item.title, 'Phản ánh mới');
      expect(item.body, 'Có phản ánh ngập lụt tại Trần Phú');
      expect(item.data['reportId'], 42);
      expect(item.isRead, isFalse);
      expect(item.readAt, isNull);
    });

    test('parses read notification correctly', () {
      final json = {
        'id': 102,
        'type': 'field_report.status_changed',
        'title': 'Cập nhật xử lý',
        'readAt': '2026-09-09T10:05:00Z',
        'createdAt': '2026-09-09T10:00:00Z',
      };

      final item = NotificationItem.fromJson(json);
      expect(item.id, 102);
      expect(item.isRead, isTrue);
      expect(item.readAt, isNotNull);
    });
  });

  group('NotificationBellButton Widget Tests', () {
    testWidgets('shows badge when unread count > 0', (tester) async {
      final fakeRepo = _FakeNotificationRepository(items: [], unread: 5);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
            sessionControllerProvider.overrideWith(_Session.new),
          ],
          child: const MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Row(children: [NotificationBellButton()]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('hides badge when unread count is 0', (tester) async {
      final fakeRepo = _FakeNotificationRepository(items: [], unread: 0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
            sessionControllerProvider.overrideWith(_Session.new),
          ],
          child: const MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Row(children: [NotificationBellButton()]),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });
  });

  group('NotificationsScreen Widget Tests', () {
    testWidgets('displays list of notifications and filter chips', (
      tester,
    ) async {
      final items = [
        NotificationItem(
          id: 1,
          type: 'field_report.created',
          title: 'Phản ánh mới tại Cẩm Thạch',
          body: 'Ngập nước sau mưa lớn',
          data: const {'reportId': '15'},
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        NotificationItem(
          id: 2,
          type: 'field_report.status_changed',
          title: 'Báo cáo đã duyệt',
          body: 'UBND TP đã tiếp nhận xử lý',
          readAt: DateTime.now(),
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

      final fakeRepo = _FakeNotificationRepository(items: items, unread: 1);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
            sessionControllerProvider.overrideWith(_Session.new),
          ],
          child: const MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chưa đọc'), findsOneWidget);
      expect(find.text('Phản ánh mới tại Cẩm Thạch'), findsOneWidget);
      expect(find.text('Báo cáo đã duyệt'), findsOneWidget);
    });

    testWidgets('displays empty state when no notifications exist', (
      tester,
    ) async {
      final fakeRepo = _FakeNotificationRepository(items: [], unread: 0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(fakeRepo),
            sessionControllerProvider.overrideWith(_Session.new),
          ],
          child: const MaterialApp(
            locale: Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có thông báo nào'), findsOneWidget);
    });
  });
}
