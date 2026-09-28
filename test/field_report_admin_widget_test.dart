import 'dart:async';

import 'package:campha_moblie/app/theme/app_theme.dart';
import 'package:campha_moblie/core/error/app_exception.dart';
import 'package:campha_moblie/features/auth/domain/session_controller.dart';
import 'package:campha_moblie/features/auth/domain/user_model.dart';
import 'package:campha_moblie/features/field_reports/data/field_report_repository.dart';
import 'package:campha_moblie/features/field_reports/domain/field_report_models.dart';

import 'package:campha_moblie/features/field_reports/presentation/admin_report_sheets.dart';
import 'package:campha_moblie/features/field_reports/presentation/field_reports_screen.dart';
import 'package:campha_moblie/features/tools/domain/field_tools_models.dart';
import 'package:campha_moblie/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({bool approve = true, bool stats = true}) => UserModel(
  id: 'manager',
  email: 'manager@example.test',
  fullName: 'Manager',
  roleCode: 'so_tnmt',
  roleName: 'TNMT',
  permissions: {
    'field_report': {'read': true, 'approve': approve, 'stats': stats},
  },
  isActive: true,
  emailVerified: true,
  mustChangePassword: false,
  hasPassword: true,
);

FieldReport _report(String status, {bool private = true}) => FieldReport(
  id: '1',
  referenceCode: 'CP-001',
  description: 'Mặt đường đang sụt lún',
  status: status,
  location: const GeoCoordinate(107.3, 21),
  photoCount: 0,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 2),
  senderUserId: private ? 'citizen' : null,
  senderName: private ? 'Private sender' : null,
  senderEmail: private ? 'private@example.test' : null,
  reviewedBy: status != 'pending' ? 'manager' : null,
  reviewedAt: status != 'pending' ? DateTime.utc(2026, 9, 3) : null,
  history: status == 'pending'
      ? []
      : [
          FieldReportHistory(
            newStatus: status,
            createdAt: DateTime.utc(2026, 9, 3),
            actorUserId: 'manager',
            reason: 'Verified',
          ),
        ],
);

class _Session extends SessionController {
  _Session(this.user);
  final UserModel? user;
  @override
  SessionState build() => user == null
      ? const SessionState.guest()
      : SessionState.authenticated(user!);
  void logoutLocally() => state = const SessionState.guest();
}

class _Repository extends FieldReportRepository {
  _Repository() : super(Dio());
  String status = 'pending';
  int reviews = 0;
  int details = 0;
  int adminLists = 0;
  int publicLists = 0;
  int clusterCalls = 0;
  String? reviewReason;
  Object? failure;
  Completer<void>? holdReview;
  @override
  Future<FieldReportPage> getAdmin({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    adminLists++;
    return FieldReportPage(
      items: status == null || status == this.status
          ? [_report(this.status)]
          : [],
      page: 1,
      limit: 20,
      total: 1,
      totalPages: 1,
    );
  }

  @override
  Future<FieldReportPage> getPublic({
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    publicLists++;
    return FieldReportPage(
      items: [_report('approved', private: false)],
      page: 1,
      limit: 20,
      total: 1,
      totalPages: 1,
    );
  }

  @override
  Future<FieldReport> getAdminDetail(
    String id, {
    CancelToken? cancelToken,
  }) async {
    details++;
    return _report(status);
  }

  @override
  Future<FieldReport> review(
    FieldReport report, {
    required String status,
    String? reason,
    CancelToken? cancelToken,
  }) async {
    reviews++;
    reviewReason = reason;
    if (holdReview != null) await holdReview!.future;
    if (failure != null) throw failure!;
    this.status = status;
    return _report(status);
  }

  @override
  Future<List<FieldReportCluster>> getClusters({
    required DateTime from,
    required DateTime to,
    required int radiusMeters,
    int minReporters = 2,
    CancelToken? cancelToken,
  }) async {
    clusterCalls++;
    return [
      const FieldReportCluster(
        id: 0,
        reportCount: 7,
        reporterCount: 3,
        location: GeoCoordinate(107.3, 21),
      ),
    ];
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Repository repository,
  _Session session, {
  Widget home = const FieldReportsScreen(),
  double width = 430,
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(() => session),
        fieldReportRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: brightness == Brightness.light
              ? lightColorScheme
              : darkColorScheme,
        ),
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'manager sees all filters; public switch removes private scope; guest never sees admin actions',
    (tester) async {
      final repository = _Repository();
      final session = _Session(_user());
      await _pump(tester, repository, session);
      expect(repository.adminLists, 1);
      for (final status in [
        'pending',
        'under_review',
        'rejected',
        'approved',
        'resolved',
      ]) {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('report-status-$status')),
          140,
          scrollable: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.right,
          ),
        );
        expect(find.byKey(ValueKey('report-status-$status')), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('report-clusters-action')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('report-nearby-filter')), findsNothing);
      await _tap(tester, 'report-scope-public');
      expect(repository.publicLists, 1);
      expect(find.byKey(const ValueKey('report-status-pending')), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('report-nearby-filter')),
        140,
        scrollable: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.right,
        ),
      );
      expect(
        find.byKey(const ValueKey('report-nearby-filter')),
        findsOneWidget,
      );
      session.logoutLocally();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('report-scope-admin')), findsNothing);
      expect(
        find.byKey(const ValueKey('report-clusters-action')),
        findsNothing,
      );
      expect(repository.adminLists, 1);
    },
  );

  testWidgets(
    'review requires rejection reason, prevents duplicate writes, reloads history and clears PII on logout',
    (tester) async {
      final repository = _Repository();
      final session = _Session(_user());
      await _pump(tester, repository, session);
      await _tap(tester, 'report-card-1');
      expect(find.textContaining('private@example.test'), findsOneWidget);
      await _tap(tester, 'review-status-rejected');
      await _tap(tester, 'report-review-submit');
      expect(repository.reviews, 0);
      expect(find.text('Lý do phải có từ 5 đến 1.000 ký tự.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('report-review-reason')),
        'Không đủ bằng chứng',
      );
      repository.holdReview = Completer<void>();
      await tester.ensureVisible(
        find.byKey(const ValueKey('report-review-submit')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('report-review-submit')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('report-review-submit')));
      await tester.pump();
      expect(repository.reviews, 1);
      repository.holdReview!.complete();
      await tester.pumpAndSettle();
      expect(repository.status, 'rejected');
      expect(repository.details, 2);
      expect(repository.reviewReason, 'Không đủ bằng chứng');
      expect(find.byKey(const ValueKey('report-review-submit')), findsNothing);
      session.logoutLocally();
      await tester.pumpAndSettle();
      expect(find.textContaining('Private sender'), findsNothing);
      expect(find.textContaining('private@example.test'), findsNothing);
      expect(find.byType(AdminReportSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('409 blocks resubmit until reload and preserves reason', (
    tester,
  ) async {
    final repository = _Repository()..failure = const ConflictException();
    await _pump(
      tester,
      repository,
      _Session(_user()),
      home: const Scaffold(body: AdminReportSheet(reportId: '1')),
    );
    await _tap(tester, 'review-status-approved');
    await tester.enterText(
      find.byKey(const ValueKey('report-review-reason')),
      'Đã xác minh tại hiện trường',
    );
    await _tap(tester, 'report-review-submit');
    expect(repository.reviews, 1);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('report-review-submit')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('report-review-submit')),
          )
          .onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.textContaining('Phản ánh đã được người khác cập nhật'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('Phản ánh đã được người khác cập nhật'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('report-review-reason')), findsOneWidget);
    repository.failure = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('report-review-reason')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Đã xác minh tại hiện trường'), findsOneWidget);
    expect(repository.details, 2);
    expect(repository.reviews, 1);
    await _tap(tester, 'review-status-approved');
    await _tap(tester, 'report-review-submit');
    expect(repository.reviews, 2);
    expect(repository.reviewReason, 'Đã xác minh tại hiện trường');
  });

  testWidgets('read-only manager cannot review or analyze clusters', (
    tester,
  ) async {
    final repository = _Repository();
    await _pump(
      tester,
      repository,
      _Session(_user(approve: false, stats: false)),
    );
    expect(find.byKey(const ValueKey('report-clusters-action')), findsNothing);
    await _tap(tester, 'report-card-1');
    expect(find.byKey(const ValueKey('report-review-submit')), findsNothing);
    expect(find.textContaining('Private sender'), findsOneWidget);
    expect(repository.reviews, 0);
  });

  testWidgets('cluster action requests server aggregates', (tester) async {
    final repository = _Repository();
    await _pump(tester, repository, _Session(_user()));
    await _tap(tester, 'report-clusters-action');
    await _tap(tester, 'report-clusters-analyze');
    expect(repository.clusterCalls, 1);
    expect(find.text('Phản ánh: 7'), findsOneWidget);
    expect(find.text('Người gửi khác nhau: 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('admin tab and clusters fit 320px / 2x text ($brightness)', (
      tester,
    ) async {
      await _pump(
        tester,
        _Repository(),
        _Session(_user()),
        width: 320,
        textScale: 2,
        brightness: brightness,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('report-card-1')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await _tap(tester, 'report-clusters-action');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('report-clusters-analyze')),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ReportClustersSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await _tap(tester, 'report-clusters-analyze');
      await tester.scrollUntilVisible(
        find.text('Phản ánh: 7'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ReportClustersSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('admin sheet fits 320px / 2x text ($brightness)', (
      tester,
    ) async {
      await _pump(
        tester,
        _Repository(),
        _Session(_user()),
        width: 320,
        textScale: 2,
        brightness: brightness,
        home: const Scaffold(body: AdminReportSheet(reportId: '1')),
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
