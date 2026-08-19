class RouteNames {
  const RouteNames._();

  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';
  static const forgotPassword = 'forgot-password';
  static const map = 'map';
  static const mapSearch = 'map-search';
  static const mapFeature = 'map-feature';
  static const mapFeatureEdit = 'map-feature-edit';
  static const mapFeatureHistory = 'map-feature-history';
  static const mapFeatureSync = 'map-feature-sync';
  static const reports = 'reports';
  static const reportCreate = 'report-create';
  static const reportMine = 'report-mine';
  static const reportDetail = 'report-detail';
  static const news = 'news';
  static const newsDetail = 'news-detail';
  static const documents = 'documents';
  static const documentDetail = 'document-detail';
  static const pdfMapDetail = 'pdf-map-detail';
  static const profile = 'profile';
  static const changePassword = 'change-password';
}

class RoutePaths {
  const RoutePaths._();

  static const splash = '/splash';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const map = '/map';
  static const mapSearch = '/map/search';
  static String mapFeature(String layerId, String featureId) =>
      '/map/feature/$layerId/$featureId';
  static String mapFeatureEdit(String layerId, String featureId) =>
      '${mapFeature(layerId, featureId)}/edit';
  static String mapFeatureHistory(String layerId, String featureId) =>
      '${mapFeature(layerId, featureId)}/history';
  static const mapFeatureSync = '/map/offline-changes';
  static const reports = '/reports';
  static const reportCreate = '/reports/new';
  static const reportMine = '/reports/mine';
  static String reportDetail(String id) => '/reports/$id';
  static const news = '/news';
  static String newsDetail(String id) => '/news/$id';
  static const documents = '/documents';
  static String documentDetail(String id) => '/documents/$id';
  static String pdfMapDetail(String id) => '/documents/pdf/$id';
  static const profile = '/profile';
  static const changePassword = '/profile/change-password';
}
