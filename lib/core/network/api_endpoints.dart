/// Hằng số toàn bộ path API server, tương đối so với `ApiConfig.baseUrl`
/// (đã gồm `/api/v1`). Path có tham số là hàm nhận id.
///
/// Chỉ khai báo path đã có thật trên `server-campha` (`src/routes/index.js`)
/// — server hiện chỉ có core Auth/RBAC (`auth`, `admin/users`,
/// `admin/system-logs`); các domain nghiệp vụ khác (feedback, GIS, tin
/// tức...) sẽ thêm dần theo `ApiEndpoints` khi server có route thật, tránh
/// khai báo path "ma" không tồn tại.
class ApiEndpoints {
  const ApiEndpoints._();

  // ── Auth & hồ sơ (server-campha src/routes/auth.routes.js) ──────────────
  static const authRegister = '/auth/register';
  static const authLogin = '/auth/login';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';
  static const authMe = '/auth/me';
  static const authChangePassword = '/auth/change-password';
  static const authSetPassword = '/auth/set-password';
  static const authForgotPassword = '/auth/forgot-password';
  static const authResetPassword = '/auth/reset-password';
  static const authVerifyEmail = '/auth/verify-email';
  static const authResendVerification = '/auth/resend-verification';
  static const authGoogleMobile = '/auth/google/mobile';
  static const authOauthExchange = '/auth/oauth/exchange';

  // ── Quản trị người dùng (server-campha src/routes/user.routes.js) ───────
  static const adminUsers = '/admin/users';
  static String adminUserDetail(String id) => '/admin/users/$id';
  static String adminUserRole(String id) => '/admin/users/$id/role';
  static String adminUserActive(String id) => '/admin/users/$id/active';
  static String adminUserResetPassword(String id) =>
      '/admin/users/$id/reset-password';

  // ── Nhật ký hệ thống (server-campha src/routes/systemLog.routes.js) ─────
  static const adminSystemLogs = '/admin/system-logs';

  // ── WebGIS & Mobile GIS (server-campha src/routes/mobile-gis.routes.js & web-map.routes.js) ─
  static const webMapLayers = '/web-map/layers';
  static String webMapLayerDetail(String id) => '/web-map/layers/$id';
  static const webMapFeatureSearch = '/web-map/features/search';
  static String webMapFeatureDetail(String layerId, String featureId) =>
      '/web-map/layers/$layerId/features/$featureId';
  static String webMapLayerLegend(String layerId) =>
      '/web-map/layers/$layerId/legend';
  static const webMapBasemaps = '/web-map/basemaps';
  static String mapLayerTileTicket(String layerId) =>
      '/maps/layers/$layerId/tile-ticket';
  static String mobileTile(String layerId, int z, int x, int y) =>
      '/mobile/layers/$layerId/tiles/$z/$x/$y.mvt';
  static String mobileTileTemplate(String layerId) =>
      '/mobile/layers/$layerId/tiles/{z}/{x}/{y}.mvt';
  static String mobileFeatureDetail(String layerId, String featureId) =>
      '/mobile/layers/$layerId/features/$featureId';
  static String mobileNearby(String layerId) =>
      '/mobile/layers/$layerId/nearby';
  static const mobileMeasure = '/mobile/measure';
  static const mobileWeatherCurrent = '/mobile/weather/current';
  static const mobileShortestRoute = '/mobile/routes/shortest';
  static String mobileFeatureHistory(String layerId, String featureId) =>
      '/mobile/layers/$layerId/features/$featureId/history';
  static String mobileFeatureRestore(
    String layerId,
    String featureId,
    int version,
  ) => '/mobile/layers/$layerId/features/$featureId/restore/$version';
  static const mobileSync = '/mobile/sync';

  // ── Phản ánh hiện trường, upload và push device ───────────────────────────
  static const fieldReports = '/field-reports';
  static const fieldReportsPublic = '/field-reports/public';
  static const fieldReportsNearby = '/field-reports/nearby';
  static const fieldReportsMine = '/field-reports/mine';
  static String fieldReportDetail(String id) => '/field-reports/$id';
  static const storageUploadPresign = '/storage/uploads/presign';
  static String storageUploadCommit(String id) => '/storage/uploads/$id/commit';
  static String storageObject(String id) => '/storage/objects/$id';
  static String storageObjectFile(String id, {String? ticket}) =>
      ticket != null && ticket.isNotEmpty
          ? '/storage/objects/$id/file?ticket=${Uri.encodeQueryComponent(ticket)}'
          : '/storage/objects/$id/file';
  static const deviceToken = '/devices/push-token';

  // ── Tin tức & Văn bản báo cáo (server-campha src/routes/cms.routes.js) ─────
  static const cmsNews = '/cms/news';
  static String cmsNewsDetail(String id) => '/cms/news/$id';
  static String cmsNewsComments(String id) => '/cms/news/$id/comments';

  static const cmsDocuments = '/cms/documents';
  static String cmsDocumentDetail(String id) => '/cms/documents/$id';
  static String cmsDocumentDownload(String id) =>
      '/cms/documents/$id/download-url';

  static const cmsPdfMaps = '/cms/pdf-maps';
  static String cmsPdfMapDetail(String id) => '/cms/pdf-maps/$id';
  static String cmsPdfMapDownload(String id) =>
      '/cms/pdf-maps/$id/download-url';
}
