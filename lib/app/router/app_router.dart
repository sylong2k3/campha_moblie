import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/session_controller.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/cms/presentation/cms_file_detail_screen.dart';
import '../../features/cms/presentation/documents_screen.dart';
import '../../features/cms/presentation/news_detail_screen.dart';
import '../../features/cms/presentation/news_screen.dart';
import '../../features/field_reports/presentation/create_field_report_screen.dart';
import '../../features/field_reports/presentation/field_reports_screen.dart';
import '../../features/field_reports/presentation/my_reports_screen.dart';
import '../../features/feature_edit/presentation/feature_edit_screen.dart';
import '../../features/feature_edit/presentation/feature_history_screen.dart';
import '../../features/feature_edit/presentation/feature_sync_screen.dart';
import '../../features/map/presentation/feature_detail_screen.dart';
import '../../features/map/presentation/map_home_screen.dart';
import '../../features/map/presentation/map_search_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import 'main_shell.dart';
import 'route_names.dart';
import 'splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final path = state.uri.path;
      final isSplash = path == RoutePaths.splash;
      final isAuthRoute = path.startsWith('/auth/');

      if (session.isBootstrapping) {
        return isSplash ? null : RoutePaths.splash;
      }
      if (isSplash) return RoutePaths.map;

      if (session.isAuthenticated && isAuthRoute) {
        final returnTo = sanitizeReturnTo(
          state.uri.queryParameters['returnTo'],
        );
        return returnTo ?? RoutePaths.map;
      }

      final user = session.user;
      if (session.isAuthenticated &&
          user?.mustChangePassword == true &&
          path != RoutePaths.changePassword) {
        return RoutePaths.changePassword;
      }
      if (!session.isAuthenticated && path == RoutePaths.changePassword) {
        return '${RoutePaths.login}?returnTo=${Uri.encodeQueryComponent(RoutePaths.changePassword)}';
      }
      final protectedReport =
          path == RoutePaths.reportCreate ||
          path == RoutePaths.reportMine ||
          RegExp(r'^/reports/\d+$').hasMatch(path);
      final protectedFeatureEdit =
          path == RoutePaths.mapFeatureSync ||
          RegExp(
            r'^/map/feature/\d+/[A-Za-z0-9_-]{1,120}/(edit|history)$',
          ).hasMatch(path);
      if (!session.isAuthenticated &&
          (protectedReport || protectedFeatureEdit)) {
        return '${RoutePaths.login}?returnTo=${Uri.encodeQueryComponent(state.uri.toString())}';
      }
      if (protectedFeatureEdit &&
          (user?.roleCode != 'so_tnmt' ||
              user?.hasPermission('map_feature', 'update') != true)) {
        return RoutePaths.map;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => LoginScreen(
          returnTo: sanitizeReturnTo(state.uri.queryParameters['returnTo']),
        ),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.map,
                name: RouteNames.map,
                builder: (context, state) => const MapHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'search',
                    name: RouteNames.mapSearch,
                    builder: (context, state) => const MapSearchScreen(),
                  ),
                  GoRoute(
                    path: 'offline-changes',
                    name: RouteNames.mapFeatureSync,
                    builder: (context, state) => const FeatureSyncScreen(),
                  ),
                  GoRoute(
                    path: 'feature/:layerId/:featureId',
                    name: RouteNames.mapFeature,
                    builder: (context, state) => FeatureDetailScreen(
                      layerId: state.pathParameters['layerId']!,
                      featureId: state.pathParameters['featureId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: RouteNames.mapFeatureEdit,
                        builder: (context, state) => FeatureEditScreen(
                          layerId: state.pathParameters['layerId']!,
                          featureId: state.pathParameters['featureId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'history',
                        name: RouteNames.mapFeatureHistory,
                        builder: (context, state) => FeatureHistoryScreen(
                          layerId: state.pathParameters['layerId']!,
                          featureId: state.pathParameters['featureId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.reports,
                name: RouteNames.reports,
                builder: (context, state) => const FieldReportsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: RouteNames.reportCreate,
                    builder: (context, state) =>
                        const CreateFieldReportScreen(),
                  ),
                  GoRoute(
                    path: 'mine',
                    name: RouteNames.reportMine,
                    builder: (context, state) => const MyReportsScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: RouteNames.reportDetail,
                    builder: (context, state) => FieldReportDetailScreen(
                      reportId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.news,
                name: RouteNames.news,
                builder: (context, state) => const NewsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: RouteNames.newsDetail,
                    builder: (context, state) => NewsDetailScreen(
                      newsId: state.pathParameters['id']!,
                      openComposer: state.uri.queryParameters['compose'] == '1',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.documents,
                name: RouteNames.documents,
                builder: (context, state) => const DocumentsScreen(),
                routes: [
                  GoRoute(
                    path: 'pdf/:id',
                    name: RouteNames.pdfMapDetail,
                    builder: (context, state) => CmsFileDetailScreen(
                      id: state.pathParameters['id']!,
                      pdfMap: true,
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    name: RouteNames.documentDetail,
                    builder: (context, state) => CmsFileDetailScreen(
                      id: state.pathParameters['id']!,
                      pdfMap: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'change-password',
                    name: RouteNames.changePassword,
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

const _allowedReturnPaths = {
  RoutePaths.map,
  RoutePaths.mapSearch,
  RoutePaths.mapFeatureSync,
  RoutePaths.reports,
  RoutePaths.reportCreate,
  RoutePaths.reportMine,
  RoutePaths.news,
  RoutePaths.documents,
  RoutePaths.profile,
  RoutePaths.changePassword,
};

String? sanitizeReturnTo(String? raw) {
  if (raw == null || raw.isEmpty || raw.length > 300) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !raw.startsWith('/')) {
    return null;
  }
  if (raw.contains('..') || uri.path.startsWith('/auth/')) return null;
  final cmsDetail = RegExp(
    r'^/(news/\d+|documents/\d+|documents/pdf/\d+)$',
  ).hasMatch(uri.path);
  final mapFeature = RegExp(
    r'^/map/feature/\d+/[A-Za-z0-9_-]{1,120}(/(edit|history))?$',
  ).hasMatch(uri.path);
  final reportDetail = RegExp(r'^/reports/\d+$').hasMatch(uri.path);
  if (!_allowedReturnPaths.contains(uri.path) &&
      !cmsDetail &&
      !mapFeature &&
      !reportDetail) {
    return null;
  }
  return uri.toString();
}

/// Destination an toàn khi người dùng từ chối đăng nhập và tiếp tục như khách.
String guestReturnTo(String? raw) {
  final sanitized = sanitizeReturnTo(raw);
  if (sanitized == null) return RoutePaths.map;
  final uri = Uri.parse(sanitized);
  if (uri.path == RoutePaths.reportCreate ||
      uri.path == RoutePaths.reportMine ||
      RegExp(r'^/reports/\d+$').hasMatch(uri.path)) {
    return RoutePaths.reports;
  }
  if (uri.path == RoutePaths.mapFeatureSync) return RoutePaths.map;
  final protectedFeature = RegExp(
    r'^(/map/feature/\d+/[A-Za-z0-9_-]{1,120})/(edit|history)$',
  ).firstMatch(uri.path);
  if (protectedFeature != null) return protectedFeature.group(1)!;
  if (uri.path == RoutePaths.changePassword) return RoutePaths.profile;
  return sanitized;
}

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    subscription = ref.listen<SessionState>(
      sessionControllerProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref ref;
  late final ProviderSubscription<SessionState> subscription;

  @override
  void dispose() {
    subscription.close();
    super.dispose();
  }
}
