// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'GIS Cẩm Phả';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonCancel => 'Huỷ';

  @override
  String get commonConfirm => 'Xác nhận';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonContinue => 'Tiếp tục';

  @override
  String get commonSave => 'Lưu thay đổi';

  @override
  String get errorNetwork => 'Không có kết nối mạng';

  @override
  String get errorValidation => 'Dữ liệu không hợp lệ';

  @override
  String get errorUnauthorized => 'Phiên đăng nhập đã hết hạn';

  @override
  String get errorForbidden => 'Bạn không có quyền thực hiện thao tác này';

  @override
  String get errorPasswordChangeRequired => 'Vui lòng đổi mật khẩu để tiếp tục';

  @override
  String get errorNotFound => 'Không tìm thấy dữ liệu';

  @override
  String get errorPayloadTooLarge => 'Tệp vượt quá dung lượng cho phép';

  @override
  String get errorRateLimit => 'Bạn thao tác quá nhanh, vui lòng thử lại sau';

  @override
  String get errorServer => 'Lỗi hệ thống, vui lòng thử lại sau';

  @override
  String get errorUnknown => 'Đã có lỗi xảy ra';

  @override
  String get roleSystemAdmin => 'Quản trị viên hệ thống';

  @override
  String get roleSoTnmt => 'Cán bộ Sở Tài nguyên và Môi trường';

  @override
  String get roleSoXd => 'Cán bộ Sở Xây dựng';

  @override
  String get roleUbndTp => 'Cán bộ UBND thành phố';

  @override
  String get roleCitizen => 'Người dân địa phương';

  @override
  String get roleGuest => 'Khách';

  @override
  String get roleSystemAdminShort => 'Admin';

  @override
  String get roleSoTnmtShort => 'Sở TNMT';

  @override
  String get roleSoXdShort => 'Sở XD';

  @override
  String get roleUbndTpShort => 'UBND TP';

  @override
  String get roleCitizenShort => 'Người dân';

  @override
  String get roleGuestShort => 'Khách';

  @override
  String get navMap => 'Bản đồ';

  @override
  String get navReports => 'Hiện trường';

  @override
  String get navNews => 'Tin tức';

  @override
  String get navDocuments => 'Tài liệu';

  @override
  String get navProfile => 'Cá nhân';

  @override
  String get splashTitle => 'Không gian số Cẩm Phả';

  @override
  String get splashSubtitle =>
      'Bản đồ, thông tin đô thị và hiện trường trong một ứng dụng';

  @override
  String get loginTitle => 'Chào mừng trở lại';

  @override
  String get loginSubtitle =>
      'Đăng nhập để sử dụng dịch vụ dành cho tài khoản của bạn.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Mật khẩu';

  @override
  String get loginAction => 'Đăng nhập';

  @override
  String get forgotPasswordAction => 'Quên mật khẩu?';

  @override
  String get noAccount => 'Chưa có tài khoản?';

  @override
  String get registerAction => 'Đăng ký';

  @override
  String get registerTitle => 'Tạo tài khoản công dân';

  @override
  String get registerSubtitle =>
      'Một tài khoản để gửi phản ánh và theo dõi dịch vụ đô thị.';

  @override
  String get fullNameLabel => 'Họ và tên';

  @override
  String get phoneLabel => 'Số điện thoại (không bắt buộc)';

  @override
  String get confirmPasswordLabel => 'Nhập lại mật khẩu';

  @override
  String get privacyConsent =>
      'Tôi đồng ý cung cấp thông tin này để sử dụng dịch vụ GIS Cẩm Phả.';

  @override
  String get alreadyAccount => 'Đã có tài khoản?';

  @override
  String get passwordMismatch => 'Mật khẩu nhập lại chưa khớp';

  @override
  String get verificationTitle => 'Kiểm tra hộp thư';

  @override
  String verificationBody(String email) {
    return 'Liên kết xác minh đã được gửi tới $email. Xác minh email trước khi đăng nhập.';
  }

  @override
  String get continueAsGuest => 'Tiếp tục với tư cách khách';

  @override
  String get forgotTitle => 'Khôi phục mật khẩu';

  @override
  String get forgotSubtitle =>
      'Nhập email. Nếu tài khoản tồn tại, hướng dẫn khôi phục sẽ được gửi an toàn.';

  @override
  String get sendInstructionAction => 'Gửi hướng dẫn';

  @override
  String get forgotSuccessTitle => 'Yêu cầu đã được ghi nhận';

  @override
  String get backToLogin => 'Quay lại đăng nhập';

  @override
  String get changePasswordTitle => 'Đổi mật khẩu';

  @override
  String get changePasswordSubtitle =>
      'Mật khẩu mới cần 8–128 ký tự và khác mật khẩu hiện tại.';

  @override
  String get oldPasswordLabel => 'Mật khẩu hiện tại';

  @override
  String get newPasswordLabel => 'Mật khẩu mới';

  @override
  String get changePasswordAction => 'Cập nhật mật khẩu';

  @override
  String get changePasswordSuccess =>
      'Mật khẩu đã đổi. Vui lòng đăng nhập lại.';

  @override
  String get profileGuestTitle => 'Khám phá với tư cách khách';

  @override
  String get profileGuestBody =>
      'Đăng nhập để gửi phản ánh, lưu bản vẽ và dùng nội dung theo quyền.';

  @override
  String get profileAccount => 'Tài khoản';

  @override
  String get profilePreferences => 'Trải nghiệm ứng dụng';

  @override
  String get profileSecurity => 'Bảo mật';

  @override
  String get logoutAction => 'Đăng xuất';

  @override
  String get logoutConfirmTitle => 'Đăng xuất khỏi thiết bị?';

  @override
  String get logoutConfirmBody =>
      'Phiên và dữ liệu riêng tư trên thiết bị sẽ được xoá.';

  @override
  String get languageLabel => 'Ngôn ngữ';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeLabel => 'Giao diện';

  @override
  String get themeSystem => 'Theo thiết bị';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get versionLabel => 'Phiên bản';

  @override
  String get mapWelcomeTitle => 'Bản đồ đô thị Cẩm Phả';

  @override
  String get mapWelcomeBody =>
      'Khám phá không gian thành phố trên nền bản đồ tương tác.';

  @override
  String get mapLoading => 'Đang tải nền bản đồ…';

  @override
  String get mapConfigMissing =>
      'Bản đồ chưa được cấu hình trên môi trường này.';

  @override
  String featureUpcomingTitle(String title) {
    return '$title đang được hoàn thiện';
  }

  @override
  String get featureUpcomingBody =>
      'Nền tảng và điều hướng đã sẵn sàng. Dữ liệu thật sẽ được nối đúng Sprint, không dùng nội dung giả.';

  @override
  String get reportsIntro =>
      'Theo dõi và gửi thông tin hiện trường trên địa bàn thành phố.';

  @override
  String get newsIntro => 'Tin tức chính thống, cập nhật từ hệ thống Cẩm Phả.';

  @override
  String get documentsIntro =>
      'Tra cứu văn bản, báo cáo và bản đồ PDF theo quyền truy cập.';

  @override
  String get cmsDateUnknown => 'Chưa rõ ngày';

  @override
  String get cmsClearSearch => 'Xoá tìm kiếm';

  @override
  String get cmsStaleData => 'Đang hiển thị dữ liệu đã tải; chưa thể làm mới.';

  @override
  String get cmsNoSearchResult => 'Không tìm thấy kết quả';

  @override
  String get cmsTryAnotherSearch => 'Thử từ khoá ngắn hơn hoặc nội dung khác.';

  @override
  String get cmsLoadMoreRetry => 'Tải trang tiếp theo';

  @override
  String get newsOfficialSource => 'Nguồn tin chính thức Cẩm Phả';

  @override
  String get newsSearchHint => 'Tìm theo tiêu đề tin tức';

  @override
  String get newsOfficialBadge => 'TIN CHÍNH THỐNG';

  @override
  String get newsReadMore => 'Đọc chi tiết';

  @override
  String get newsEmptyTitle => 'Chưa có tin tức';

  @override
  String get newsEmptyBody =>
      'Tin công khai sẽ xuất hiện tại đây khi được phát hành.';

  @override
  String get newsDetailTitle => 'Chi tiết tin tức';

  @override
  String get newsContentEmpty => 'Bài viết chưa có nội dung chi tiết.';

  @override
  String get cmsShare => 'Chia sẻ';

  @override
  String get commentsTitle => 'Bình luận cộng đồng';

  @override
  String get commentsEmpty => 'Chưa có bình luận được duyệt.';

  @override
  String get commentWriteTitle => 'Gửi ý kiến';

  @override
  String get commentHint => 'Nội dung 1–2000 ký tự';

  @override
  String get commentLoginBody =>
      'Đăng nhập để gửi ý kiến. Bạn sẽ quay lại bài viết này sau đăng nhập.';

  @override
  String get commentSend => 'Gửi bình luận';

  @override
  String get commentInvalid =>
      'Bình luận cần 1–2000 ký tự và không chứa thẻ HTML.';

  @override
  String get commentPending => 'Bình luận đã gửi và đang chờ duyệt.';

  @override
  String get commentSent => 'Bình luận đã được gửi.';

  @override
  String get documentsVerifiedSource => 'Kho dữ liệu đã xác minh';

  @override
  String get documentsSegment => 'Văn bản';

  @override
  String get pdfMapsSegment => 'Bản đồ PDF';

  @override
  String get documentsSearchHint => 'Tìm tiêu đề hoặc mã văn bản';

  @override
  String get pdfSearchHint => 'Tìm tiêu đề bản đồ PDF';

  @override
  String get documentsEmptyTitle => 'Chưa có văn bản';

  @override
  String get documentsEmptyBody =>
      'Văn bản phù hợp quyền truy cập sẽ xuất hiện tại đây.';

  @override
  String get pdfEmptyTitle => 'Chưa có bản đồ PDF';

  @override
  String get pdfEmptyBody => 'Bản đồ PDF công khai sẽ xuất hiện tại đây.';

  @override
  String get documentDetailTitle => 'Chi tiết văn bản';

  @override
  String get pdfDetailTitle => 'Chi tiết bản đồ PDF';

  @override
  String get cmsDescription => 'Mô tả';

  @override
  String get documentCodeLabel => 'Mã văn bản';

  @override
  String get issuingAgencyLabel => 'Cơ quan ban hành';

  @override
  String get issuedDateLabel => 'Ngày ban hành';

  @override
  String get scaleLabel => 'Tỷ lệ';

  @override
  String get mapYearLabel => 'Năm bản đồ';

  @override
  String get preparingAgencyLabel => 'Đơn vị thành lập';

  @override
  String get cmsOpenFile => 'Mở bằng ứng dụng trên thiết bị';

  @override
  String get cmsShareFile => 'Chia sẻ liên kết tạm thời';

  @override
  String get cmsSecureLinkNotice =>
      'Liên kết bảo mật chỉ được tạo khi thao tác và tự hết hạn.';

  @override
  String get cmsNoFileViewer => 'Thiết bị không có ứng dụng phù hợp để mở tệp.';

  @override
  String get cmsVisibilityAll => 'Tất cả';

  @override
  String get cmsVisibilityPublic => 'Công khai';

  @override
  String get cmsVisibilityInternal => 'Nội bộ';

  @override
  String get cmsInternalBadge => 'Nội bộ';

  @override
  String get cmsInternalAccessDeniedTitle => 'Văn bản nội bộ';

  @override
  String get cmsInternalAccessDeniedBody =>
      'Nội dung này chỉ dành cho cán bộ được phân quyền. Vui lòng liên hệ quản trị viên nếu cần hỗ trợ.';

  @override
  String get mapLayersTitle => 'Lớp dữ liệu bản đồ';

  @override
  String mapActiveLayers(int count) {
    return '$count lớp đang hiển thị';
  }

  @override
  String get mapDisableAll => 'Tắt tất cả';

  @override
  String get mapLayerSearchHint => 'Tìm lớp dữ liệu';

  @override
  String get mapCatalogStale => 'Đang dùng catalog đã tải; chưa thể làm mới.';

  @override
  String get mapNoLayersFound => 'Không tìm thấy lớp phù hợp';

  @override
  String get mapBasemapTitle => 'Bản đồ nền';

  @override
  String get mapBasemapEmpty => 'Chưa có bản đồ nền từ hệ thống.';

  @override
  String get mapLegendAction => 'Xem chú giải';

  @override
  String get mapLegendEmpty => 'Lớp này chưa cấu hình chú giải.';

  @override
  String get mapSearchTitle => 'Tìm kiếm trên bản đồ';

  @override
  String get mapSearchHint => 'Tìm địa danh hoặc đối tượng';

  @override
  String get mapSearchPrompt =>
      'Nhập ít nhất 2 ký tự để tìm trong các lớp được phép.';

  @override
  String get mapSearchEmpty => 'Không tìm thấy đối tượng phù hợp.';

  @override
  String get mapFeatureTitle => 'Thông tin đối tượng';

  @override
  String get mapFeatureId => 'Mã đối tượng';

  @override
  String get mapAttributesTitle => 'Thuộc tính';

  @override
  String get mapAttributesEmpty => 'Không có thuộc tính được phép hiển thị.';

  @override
  String get mapGeometryTitle => 'Hình học';

  @override
  String mapGeometryPoints(int count) {
    return '$count điểm tọa độ';
  }

  @override
  String mapLayerRenderError(String name) {
    return 'Không thể hiển thị lớp $name.';
  }

  @override
  String get mapTileError => 'Một lớp bản đồ chưa tải được';

  @override
  String get mapRecenter => 'Về trung tâm Cẩm Phả';

  @override
  String get mapGpsAction => 'Vị trí của tôi';

  @override
  String mapLayersCount(int count) {
    return 'Lớp dữ liệu ($count)';
  }

  @override
  String get mapInfoAction => 'Tra cứu đối tượng';

  @override
  String get mapTapInfoHint =>
      'Chạm trực tiếp vào đối tượng đang hiển thị để mở thông tin.';

  @override
  String get fieldToolsTitle => 'Công cụ hiện trường';

  @override
  String get fieldToolsSubtitle => 'Định vị, đo đạc và phân tích GIS';

  @override
  String get locationWeatherTitle => 'Vị trí & thời tiết';

  @override
  String get locationPrimer =>
      'Chỉ lấy vị trí khi bạn bấm tiếp tục. Ứng dụng không theo dõi nền.';

  @override
  String get locationStart => 'Xác định vị trí';

  @override
  String get locationServiceOff => 'Dịch vụ vị trí đang tắt.';

  @override
  String get locationDenied => 'Chưa được cấp quyền vị trí.';

  @override
  String get locationDeniedForever =>
      'Quyền vị trí đã bị chặn. Mở cài đặt để cấp lại.';

  @override
  String get locationOpenSettings => 'Mở cài đặt';

  @override
  String get locationOutsideBounds =>
      'Vị trí nằm ngoài phạm vi Cẩm Phả hỗ trợ.';

  @override
  String locationAccuracy(String meters) {
    return 'Độ chính xác ±$meters m';
  }

  @override
  String locationAccuracyLow(String meters) {
    return 'Độ chính xác thấp · sai số ±$meters m';
  }

  @override
  String get locationAccuracyUnavailable => 'Chưa có thông tin độ chính xác.';

  @override
  String get weatherUnavailable => 'Chưa thể lấy thời tiết lúc này.';

  @override
  String get weatherTemperature => 'Nhiệt độ';

  @override
  String get weatherWind => 'Gió';

  @override
  String get weatherObserved => 'Cập nhật';

  @override
  String get nearbyTitle => 'Đối tượng gần vị trí';

  @override
  String get nearbyEmpty => 'Không có đối tượng trong bán kính hiện tại.';

  @override
  String nearbyDistance(String meters) {
    return 'Cách $meters m';
  }

  @override
  String get measureTitle => 'Đo đạc';

  @override
  String get measureDistance => 'Khoảng cách';

  @override
  String get measureArea => 'Diện tích';

  @override
  String get measureTapHint => 'Chạm bản đồ để thêm điểm đo';

  @override
  String measurePointCount(int count) {
    return '$count điểm';
  }

  @override
  String get measureUndo => 'Hoàn tác';

  @override
  String get measureRedo => 'Làm lại';

  @override
  String get measureComplete => 'Xác nhận đo';

  @override
  String get measureOfficial => 'Hệ thống xác nhận';

  @override
  String measureLengthResult(String value) {
    return '$value m';
  }

  @override
  String measureAreaResult(String value) {
    return '$value m²';
  }

  @override
  String get routeTitle => 'Tìm đường';

  @override
  String get routeSelectHint =>
      'Chạm bản đồ lần lượt để chọn điểm đầu và điểm cuối. Tuyến được tính bằng Mapbox.';

  @override
  String get routeStart => 'Điểm đầu';

  @override
  String get routeEnd => 'Điểm cuối';

  @override
  String get routeUseGps => 'Dùng vị trí hiện tại';

  @override
  String get routeSwap => 'Đổi điểm đầu/cuối';

  @override
  String get routeFind => 'Tìm tuyến';

  @override
  String get routeSourceMapbox => 'Nguồn định tuyến: Mapbox';

  @override
  String routeDistance(String value) {
    return 'Chiều dài $value m';
  }

  @override
  String get fieldToolSheetDragHint =>
      'Kéo lên để xem thêm, kéo xuống để xem bản đồ';

  @override
  String get routeInstructionFallback => 'Tuyến đường đã sẵn sàng.';

  @override
  String get fieldToolCancel => 'Thoát công cụ';

  @override
  String get reportsTitle => 'Phản ánh hiện trường';

  @override
  String get reportsSubtitle => 'Theo dõi thay đổi đô thị từ cộng đồng Cẩm Phả';

  @override
  String get reportCreate => 'Gửi phản ánh';

  @override
  String get myReports => 'Phản ánh của tôi';

  @override
  String get reportListView => 'Danh sách';

  @override
  String get reportMapView => 'Bản đồ';

  @override
  String get reportStale =>
      'Đang hiển thị dữ liệu gần nhất. Kéo xuống để thử lại.';

  @override
  String get reportStatusAll => 'Tất cả';

  @override
  String get reportStatusPending => 'Chờ tiếp nhận';

  @override
  String get reportStatusReview => 'Đang xem xét';

  @override
  String get reportStatusApproved => 'Đã xác minh';

  @override
  String get reportStatusRejected => 'Từ chối';

  @override
  String get reportStatusResolved => 'Đã xử lý';

  @override
  String get reportPublicEmpty => 'Chưa có phản ánh công khai.';

  @override
  String get reportFilteredEmpty => 'Không có phản ánh phù hợp bộ lọc.';

  @override
  String reportDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String reportHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String reportMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String get reportEvidenceStep => 'Minh chứng';

  @override
  String get reportLocationStep => 'Vị trí';

  @override
  String get reportDescriptionStep => 'Nội dung';

  @override
  String get reportEvidenceHint => 'Thêm 1–5 ảnh PNG hoặc WebP';

  @override
  String get reportCamera => 'Chụp ảnh';

  @override
  String get reportGallery => 'Chọn ảnh';

  @override
  String get reportLocationHint =>
      'Chạm bản đồ để đặt hoặc điều chỉnh ghim trong phạm vi Cẩm Phả';

  @override
  String get reportDescriptionHint => 'Mô tả hiện trạng từ 10 đến 2000 ký tự';

  @override
  String get reportTruthConfirm =>
      'Tôi xác nhận thông tin và minh chứng là đúng sự thật.';

  @override
  String get reportNext => 'Tiếp tục';

  @override
  String get reportBack => 'Quay lại';

  @override
  String get reportSubmit => 'Gửi phản ánh';

  @override
  String get reportUploadPresign => 'Chuẩn bị tải lên';

  @override
  String get reportUploadUploading => 'Đang tải ảnh';

  @override
  String get reportUploadCommit => 'Đang kiểm tra an toàn';

  @override
  String get reportUploadReady => 'Ảnh đã sẵn sàng';

  @override
  String get reportDraftRestored => 'Đã khôi phục phản ánh chưa gửi';

  @override
  String get reportDelete => 'Xóa phản ánh';

  @override
  String get reportDeleteConfirm =>
      'Xóa phản ánh này? Thao tác không thể hoàn tác.';

  @override
  String get reportHistory => 'Tiến trình xử lý';

  @override
  String get reportPhotos => 'Minh chứng hình ảnh';

  @override
  String get reportReviewReason => 'Phản hồi xử lý';

  @override
  String get reportNearby30Days => 'Gần tôi · 30 ngày';

  @override
  String get featureEditTitle => 'Chỉnh sửa đối tượng';

  @override
  String get featureEditForbidden =>
      'Tài khoản không có quyền chỉnh sửa dữ liệu gốc.';

  @override
  String get featureEditUnavailable =>
      'Đối tượng hoặc phiên bản chưa hỗ trợ chỉnh sửa.';

  @override
  String get featureInvalidValue =>
      'Giá trị không đúng kiểu hoặc vượt giới hạn.';

  @override
  String get featureUnsavedTitle => 'Bỏ thay đổi chưa lưu?';

  @override
  String get featureUnsavedBody =>
      'Thuộc tính hoặc hình học đã thay đổi sẽ bị mất.';

  @override
  String get featureDiscard => 'Bỏ thay đổi';

  @override
  String get featureVertices => 'đỉnh';

  @override
  String get featureVersion => 'Phiên bản';

  @override
  String get featureCurrent => 'Hiện tại';

  @override
  String get featureSaveNow => 'Lưu lên máy chủ';

  @override
  String get featureSaveOffline => 'Lưu vào hàng đợi offline';

  @override
  String get featureHistoryTitle => 'Lịch sử đối tượng';

  @override
  String get featureHistoryEmpty => 'Chưa có lịch sử phiên bản.';

  @override
  String get featureGeometryChanged => 'Hình học được cập nhật';

  @override
  String get featureActionUpdate => 'Cập nhật';

  @override
  String get featureActionRestore => 'Khôi phục';

  @override
  String get featureActionChanged => 'Thay đổi';

  @override
  String get featureRestoreTitle => 'Khôi phục phiên bản';

  @override
  String featureRestoreCreatesVersion(int version) {
    return 'Khôi phục phiên bản $version sẽ tạo một phiên bản mới; không ghi đè lịch sử.';
  }

  @override
  String get featureRestoreAction => 'Khôi phục';

  @override
  String get featureRestoreSuccess => 'Đã tạo phiên bản khôi phục mới.';

  @override
  String get featureSyncTitle => 'Thay đổi offline';

  @override
  String get featureSyncNow => 'Đồng bộ ngay';

  @override
  String get featureSyncEmpty => 'Không có thay đổi offline.';

  @override
  String get featurePending => 'Chờ đồng bộ';

  @override
  String get featureConflicts => 'Xung đột';

  @override
  String get featureRejected => 'Bị từ chối';

  @override
  String get featureServerVersion => 'Phiên bản máy chủ';

  @override
  String get featureUndo => 'Hoàn tác đỉnh cuối';

  @override
  String get featureConflictTitle => 'Đối tượng đã thay đổi';

  @override
  String get featureConflictBody =>
      'Phiên bản máy chủ mới hơn. Không thể ghi đè. Tải bản máy chủ hoặc giữ thay đổi này trong hàng đợi offline.';

  @override
  String get featureReloadServer => 'Tải bản máy chủ';

  @override
  String get reportNearbyFilterTitle => 'Phản ánh gần vị trí hiện tại';

  @override
  String get reportNearbyDateRange => 'Khoảng thời gian';

  @override
  String reportNearbyRadius(int meters) {
    return 'Bán kính: $meters m';
  }

  @override
  String get reportNearbyApply => 'Dùng vị trí hiện tại';

  @override
  String get featureChangedBy => 'Người thay đổi';

  @override
  String get brandTagline => 'Đô thị trong tầm tay';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get emailRequired => 'Vui lòng nhập email';

  @override
  String get emailInvalid => 'Email chưa đúng định dạng';

  @override
  String get passwordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get passwordMinLength => 'Mật khẩu cần ít nhất 8 ký tự';

  @override
  String get passwordMaxLength => 'Mật khẩu tối đa 128 ký tự';

  @override
  String get passwordMustDiffer => 'Mật khẩu mới phải khác mật khẩu hiện tại';

  @override
  String get fullNameMinLength => 'Họ tên cần ít nhất 2 ký tự';

  @override
  String get fullNameMaxLength => 'Họ tên tối đa 255 ký tự';

  @override
  String get privacyConsentRequired => 'Xác nhận đồng ý trước khi đăng ký';

  @override
  String mapActiveTool(String name) {
    return 'Đang dùng: $name';
  }

  @override
  String mapLayerOpacity(int percent) {
    return 'Độ hiển thị $percent%';
  }

  @override
  String get measureDistanceRequired =>
      'Chạm thêm 1 điểm để bắt đầu đo khoảng cách.';

  @override
  String get measureAreaRequired => 'Chạm thêm điểm để tạo vùng đo diện tích.';

  @override
  String get routeStartRequired => 'Chọn điểm đầu trên bản đồ.';

  @override
  String get routeEndRequired => 'Chọn điểm cuối trên bản đồ.';

  @override
  String routeEstimatedMinutes(int minutes) {
    return 'Thời gian dự kiến: $minutes phút';
  }

  @override
  String routeMinutesShort(int minutes) {
    return '$minutes phút';
  }

  @override
  String get draftPoint => 'Điểm';

  @override
  String get draftLine => 'Đường';

  @override
  String get draftPolygon => 'Vùng';

  @override
  String reportStepProgress(int current, int total, String title) {
    return 'Bước $current/$total · $title';
  }

  @override
  String get reportDraftAutosaved => 'Bản nháp được tự động lưu trên thiết bị.';

  @override
  String get reportEvidenceRequired => 'Thêm ít nhất 1 ảnh để tiếp tục.';

  @override
  String get reportLocationRequired =>
      'Chọn vị trí trong phạm vi Cẩm Phả để tiếp tục.';

  @override
  String get reportDescriptionRequired => 'Nhập mô tả có ít nhất 10 ký tự.';

  @override
  String get reportTruthRequired =>
      'Xác nhận thông tin là đúng sự thật trước khi gửi.';

  @override
  String get reportCameraPrimerTitle => 'Cho phép dùng máy ảnh?';

  @override
  String get reportCameraPrimerBody =>
      'Máy ảnh chỉ mở khi bạn tiếp tục để chụp minh chứng. Ứng dụng không chụp hoặc ghi hình nền.';

  @override
  String get reportCameraPermissionDenied =>
      'Chưa được cấp quyền máy ảnh. Mở cài đặt để cấp lại.';

  @override
  String get reportPhotoLimit => 'Đã đủ 5 ảnh minh chứng.';

  @override
  String reportPhotoPosition(int current, int total) {
    return 'Ảnh $current trên $total';
  }

  @override
  String get locationLocating => 'Đang xác định vị trí…';

  @override
  String get featureNoChanges =>
      'Thay đổi ít nhất một thuộc tính hoặc tọa độ trước khi lưu.';

  @override
  String get featureLongitude => 'Kinh độ';

  @override
  String get featureLatitude => 'Vĩ độ';

  @override
  String get featureCoordinateOutOfBounds =>
      'Tọa độ phải nằm trong phạm vi Cẩm Phả.';

  @override
  String get featureDiscardOfflineTitle => 'Xóa thay đổi offline?';

  @override
  String get featureDiscardOfflineBody =>
      'Thay đổi chưa đồng bộ sẽ bị xóa khỏi thiết bị và không thể khôi phục.';

  @override
  String get featureSyncDiscardAction => 'Xóa thay đổi';

  @override
  String get featureSyncing => 'Đang đồng bộ';

  @override
  String get featureSyncRejectedReason =>
      'Thay đổi này không thể đồng bộ. Kiểm tra dữ liệu hoặc xóa khỏi hàng đợi.';

  @override
  String get reportDiscardDraftTitle => 'Xóa bản nháp phản ánh?';

  @override
  String get reportDiscardDraftBody =>
      'Ảnh, vị trí và nội dung chưa gửi sẽ bị xóa khỏi thiết bị và không thể khôi phục.';
}
