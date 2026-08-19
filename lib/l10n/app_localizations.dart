import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'GIS Cẩm Phả'**
  String get appTitle;

  /// No description provided for @commonRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get commonClose;

  /// No description provided for @commonContinue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get commonContinue;

  /// No description provided for @commonSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get commonSave;

  /// No description provided for @errorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối mạng'**
  String get errorNetwork;

  /// No description provided for @errorValidation.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu không hợp lệ'**
  String get errorValidation;

  /// No description provided for @errorUnauthorized.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hạn'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền thực hiện thao tác này'**
  String get errorForbidden;

  /// No description provided for @errorPasswordChangeRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng đổi mật khẩu để tiếp tục'**
  String get errorPasswordChangeRequired;

  /// No description provided for @errorNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy dữ liệu'**
  String get errorNotFound;

  /// No description provided for @errorPayloadTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'Tệp vượt quá dung lượng cho phép'**
  String get errorPayloadTooLarge;

  /// No description provided for @errorRateLimit.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thao tác quá nhanh, vui lòng thử lại sau'**
  String get errorRateLimit;

  /// No description provided for @errorServer.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi hệ thống, vui lòng thử lại sau'**
  String get errorServer;

  /// No description provided for @errorUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Đã có lỗi xảy ra'**
  String get errorUnknown;

  /// No description provided for @roleSystemAdmin.
  ///
  /// In vi, this message translates to:
  /// **'Quản trị viên hệ thống'**
  String get roleSystemAdmin;

  /// No description provided for @roleSoTnmt.
  ///
  /// In vi, this message translates to:
  /// **'Cán bộ Sở Tài nguyên và Môi trường'**
  String get roleSoTnmt;

  /// No description provided for @roleSoXd.
  ///
  /// In vi, this message translates to:
  /// **'Cán bộ Sở Xây dựng'**
  String get roleSoXd;

  /// No description provided for @roleUbndTp.
  ///
  /// In vi, this message translates to:
  /// **'Cán bộ UBND thành phố'**
  String get roleUbndTp;

  /// No description provided for @roleCitizen.
  ///
  /// In vi, this message translates to:
  /// **'Người dân địa phương'**
  String get roleCitizen;

  /// No description provided for @roleGuest.
  ///
  /// In vi, this message translates to:
  /// **'Khách'**
  String get roleGuest;

  /// No description provided for @roleSystemAdminShort.
  ///
  /// In vi, this message translates to:
  /// **'Admin'**
  String get roleSystemAdminShort;

  /// No description provided for @roleSoTnmtShort.
  ///
  /// In vi, this message translates to:
  /// **'Sở TNMT'**
  String get roleSoTnmtShort;

  /// No description provided for @roleSoXdShort.
  ///
  /// In vi, this message translates to:
  /// **'Sở XD'**
  String get roleSoXdShort;

  /// No description provided for @roleUbndTpShort.
  ///
  /// In vi, this message translates to:
  /// **'UBND TP'**
  String get roleUbndTpShort;

  /// No description provided for @roleCitizenShort.
  ///
  /// In vi, this message translates to:
  /// **'Người dân'**
  String get roleCitizenShort;

  /// No description provided for @roleGuestShort.
  ///
  /// In vi, this message translates to:
  /// **'Khách'**
  String get roleGuestShort;

  /// No description provided for @navMap.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ'**
  String get navMap;

  /// No description provided for @navReports.
  ///
  /// In vi, this message translates to:
  /// **'Hiện trường'**
  String get navReports;

  /// No description provided for @navNews.
  ///
  /// In vi, this message translates to:
  /// **'Tin tức'**
  String get navNews;

  /// No description provided for @navDocuments.
  ///
  /// In vi, this message translates to:
  /// **'Tài liệu'**
  String get navDocuments;

  /// No description provided for @navProfile.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get navProfile;

  /// No description provided for @splashTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không gian số Cẩm Phả'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ, thông tin đô thị và hiện trường trong một ứng dụng'**
  String get splashSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để sử dụng dịch vụ dành cho tài khoản của bạn.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get passwordLabel;

  /// No description provided for @loginAction.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get loginAction;

  /// No description provided for @forgotPasswordAction.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgotPasswordAction;

  /// No description provided for @noAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản?'**
  String get noAccount;

  /// No description provided for @registerAction.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get registerAction;

  /// No description provided for @registerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản công dân'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Một tài khoản để gửi phản ánh và theo dõi dịch vụ đô thị.'**
  String get registerSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get fullNameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại (không bắt buộc)'**
  String get phoneLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu'**
  String get confirmPasswordLabel;

  /// No description provided for @privacyConsent.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đồng ý cung cấp thông tin này để sử dụng dịch vụ GIS Cẩm Phả.'**
  String get privacyConsent;

  /// No description provided for @alreadyAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản?'**
  String get alreadyAccount;

  /// No description provided for @passwordMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu nhập lại chưa khớp'**
  String get passwordMismatch;

  /// No description provided for @verificationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra hộp thư'**
  String get verificationTitle;

  /// No description provided for @verificationBody.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết xác minh đã được gửi tới {email}. Xác minh email trước khi đăng nhập.'**
  String verificationBody(String email);

  /// No description provided for @continueAsGuest.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với tư cách khách'**
  String get continueAsGuest;

  /// No description provided for @forgotTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục mật khẩu'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email. Nếu tài khoản tồn tại, hướng dẫn khôi phục sẽ được gửi an toàn.'**
  String get forgotSubtitle;

  /// No description provided for @sendInstructionAction.
  ///
  /// In vi, this message translates to:
  /// **'Gửi hướng dẫn'**
  String get sendInstructionAction;

  /// No description provided for @forgotSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đã được ghi nhận'**
  String get forgotSuccessTitle;

  /// No description provided for @backToLogin.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại đăng nhập'**
  String get backToLogin;

  /// No description provided for @changePasswordTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới cần 8–128 ký tự và khác mật khẩu hiện tại.'**
  String get changePasswordSubtitle;

  /// No description provided for @oldPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại'**
  String get oldPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get newPasswordLabel;

  /// No description provided for @changePasswordAction.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật mật khẩu'**
  String get changePasswordAction;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu đã đổi. Vui lòng đăng nhập lại.'**
  String get changePasswordSuccess;

  /// No description provided for @profileGuestTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá với tư cách khách'**
  String get profileGuestTitle;

  /// No description provided for @profileGuestBody.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để gửi phản ánh, lưu bản vẽ và dùng nội dung theo quyền.'**
  String get profileGuestBody;

  /// No description provided for @profileAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get profileAccount;

  /// No description provided for @profilePreferences.
  ///
  /// In vi, this message translates to:
  /// **'Trải nghiệm ứng dụng'**
  String get profilePreferences;

  /// No description provided for @profileSecurity.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật'**
  String get profileSecurity;

  /// No description provided for @logoutAction.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logoutAction;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất khỏi thiết bị?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Phiên và dữ liệu riêng tư trên thiết bị sẽ được xoá.'**
  String get logoutConfirmBody;

  /// No description provided for @languageLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get languageLabel;

  /// No description provided for @languageVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageEnglish.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @themeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo thiết bị'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get themeDark;

  /// No description provided for @versionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản'**
  String get versionLabel;

  /// No description provided for @mapWelcomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ đô thị Cẩm Phả'**
  String get mapWelcomeTitle;

  /// No description provided for @mapWelcomeBody.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá không gian thành phố trên nền bản đồ tương tác.'**
  String get mapWelcomeBody;

  /// No description provided for @mapLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải nền bản đồ…'**
  String get mapLoading;

  /// No description provided for @mapConfigMissing.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ chưa được cấu hình trên môi trường này.'**
  String get mapConfigMissing;

  /// No description provided for @featureUpcomingTitle.
  ///
  /// In vi, this message translates to:
  /// **'{title} đang được hoàn thiện'**
  String featureUpcomingTitle(String title);

  /// No description provided for @featureUpcomingBody.
  ///
  /// In vi, this message translates to:
  /// **'Nền tảng và điều hướng đã sẵn sàng. Dữ liệu thật sẽ được nối đúng Sprint, không dùng nội dung giả.'**
  String get featureUpcomingBody;

  /// No description provided for @reportsIntro.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi và gửi thông tin hiện trường trên địa bàn thành phố.'**
  String get reportsIntro;

  /// No description provided for @newsIntro.
  ///
  /// In vi, this message translates to:
  /// **'Tin tức chính thống, cập nhật từ hệ thống Cẩm Phả.'**
  String get newsIntro;

  /// No description provided for @documentsIntro.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu văn bản, báo cáo và bản đồ PDF theo quyền truy cập.'**
  String get documentsIntro;

  /// No description provided for @cmsDateUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa rõ ngày'**
  String get cmsDateUnknown;

  /// No description provided for @cmsClearSearch.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tìm kiếm'**
  String get cmsClearSearch;

  /// No description provided for @cmsStaleData.
  ///
  /// In vi, this message translates to:
  /// **'Đang hiển thị dữ liệu đã tải; chưa thể làm mới.'**
  String get cmsStaleData;

  /// No description provided for @cmsNoSearchResult.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy kết quả'**
  String get cmsNoSearchResult;

  /// No description provided for @cmsTryAnotherSearch.
  ///
  /// In vi, this message translates to:
  /// **'Thử từ khoá ngắn hơn hoặc nội dung khác.'**
  String get cmsTryAnotherSearch;

  /// No description provided for @cmsLoadMoreRetry.
  ///
  /// In vi, this message translates to:
  /// **'Tải trang tiếp theo'**
  String get cmsLoadMoreRetry;

  /// No description provided for @newsOfficialSource.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn tin chính thức Cẩm Phả'**
  String get newsOfficialSource;

  /// No description provided for @newsSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm theo tiêu đề tin tức'**
  String get newsSearchHint;

  /// No description provided for @newsOfficialBadge.
  ///
  /// In vi, this message translates to:
  /// **'TIN CHÍNH THỐNG'**
  String get newsOfficialBadge;

  /// No description provided for @newsReadMore.
  ///
  /// In vi, this message translates to:
  /// **'Đọc chi tiết'**
  String get newsReadMore;

  /// No description provided for @newsEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tin tức'**
  String get newsEmptyTitle;

  /// No description provided for @newsEmptyBody.
  ///
  /// In vi, this message translates to:
  /// **'Tin công khai sẽ xuất hiện tại đây khi được phát hành.'**
  String get newsEmptyBody;

  /// No description provided for @newsDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết tin tức'**
  String get newsDetailTitle;

  /// No description provided for @newsContentEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bài viết chưa có nội dung chi tiết.'**
  String get newsContentEmpty;

  /// No description provided for @cmsShare.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get cmsShare;

  /// No description provided for @commentsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bình luận cộng đồng'**
  String get commentsTitle;

  /// No description provided for @commentsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bình luận được duyệt.'**
  String get commentsEmpty;

  /// No description provided for @commentWriteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi ý kiến'**
  String get commentWriteTitle;

  /// No description provided for @commentHint.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung 1–2000 ký tự'**
  String get commentHint;

  /// No description provided for @commentLoginBody.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để gửi ý kiến. Bạn sẽ quay lại bài viết này sau đăng nhập.'**
  String get commentLoginBody;

  /// No description provided for @commentSend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi bình luận'**
  String get commentSend;

  /// No description provided for @commentInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Bình luận cần 1–2000 ký tự và không chứa thẻ HTML.'**
  String get commentInvalid;

  /// No description provided for @commentPending.
  ///
  /// In vi, this message translates to:
  /// **'Bình luận đã gửi và đang chờ duyệt.'**
  String get commentPending;

  /// No description provided for @commentSent.
  ///
  /// In vi, this message translates to:
  /// **'Bình luận đã được gửi.'**
  String get commentSent;

  /// No description provided for @documentsVerifiedSource.
  ///
  /// In vi, this message translates to:
  /// **'Kho dữ liệu đã xác minh'**
  String get documentsVerifiedSource;

  /// No description provided for @documentsSegment.
  ///
  /// In vi, this message translates to:
  /// **'Văn bản'**
  String get documentsSegment;

  /// No description provided for @pdfMapsSegment.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ PDF'**
  String get pdfMapsSegment;

  /// No description provided for @documentsSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm tiêu đề hoặc mã văn bản'**
  String get documentsSearchHint;

  /// No description provided for @pdfSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm tiêu đề bản đồ PDF'**
  String get pdfSearchHint;

  /// No description provided for @documentsEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có văn bản'**
  String get documentsEmptyTitle;

  /// No description provided for @documentsEmptyBody.
  ///
  /// In vi, this message translates to:
  /// **'Văn bản phù hợp quyền truy cập sẽ xuất hiện tại đây.'**
  String get documentsEmptyBody;

  /// No description provided for @pdfEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bản đồ PDF'**
  String get pdfEmptyTitle;

  /// No description provided for @pdfEmptyBody.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ PDF công khai sẽ xuất hiện tại đây.'**
  String get pdfEmptyBody;

  /// No description provided for @documentDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết văn bản'**
  String get documentDetailTitle;

  /// No description provided for @pdfDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết bản đồ PDF'**
  String get pdfDetailTitle;

  /// No description provided for @cmsDescription.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả'**
  String get cmsDescription;

  /// No description provided for @documentCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã văn bản'**
  String get documentCodeLabel;

  /// No description provided for @issuingAgencyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Cơ quan ban hành'**
  String get issuingAgencyLabel;

  /// No description provided for @issuedDateLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngày ban hành'**
  String get issuedDateLabel;

  /// No description provided for @scaleLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ'**
  String get scaleLabel;

  /// No description provided for @mapYearLabel.
  ///
  /// In vi, this message translates to:
  /// **'Năm bản đồ'**
  String get mapYearLabel;

  /// No description provided for @preparingAgencyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị thành lập'**
  String get preparingAgencyLabel;

  /// No description provided for @cmsOpenFile.
  ///
  /// In vi, this message translates to:
  /// **'Mở bằng ứng dụng trên thiết bị'**
  String get cmsOpenFile;

  /// No description provided for @cmsShareFile.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ liên kết tạm thời'**
  String get cmsShareFile;

  /// No description provided for @cmsSecureLinkNotice.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết bảo mật chỉ được tạo khi thao tác và tự hết hạn.'**
  String get cmsSecureLinkNotice;

  /// No description provided for @cmsNoFileViewer.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không có ứng dụng phù hợp để mở tệp.'**
  String get cmsNoFileViewer;

  /// No description provided for @cmsVisibilityAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get cmsVisibilityAll;

  /// No description provided for @cmsVisibilityPublic.
  ///
  /// In vi, this message translates to:
  /// **'Công khai'**
  String get cmsVisibilityPublic;

  /// No description provided for @cmsVisibilityInternal.
  ///
  /// In vi, this message translates to:
  /// **'Nội bộ'**
  String get cmsVisibilityInternal;

  /// No description provided for @cmsInternalBadge.
  ///
  /// In vi, this message translates to:
  /// **'Nội bộ'**
  String get cmsInternalBadge;

  /// No description provided for @cmsInternalAccessDeniedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Văn bản nội bộ'**
  String get cmsInternalAccessDeniedTitle;

  /// No description provided for @cmsInternalAccessDeniedBody.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung này chỉ dành cho cán bộ được phân quyền. Vui lòng liên hệ quản trị viên nếu cần hỗ trợ.'**
  String get cmsInternalAccessDeniedBody;

  /// No description provided for @mapLayersTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lớp dữ liệu bản đồ'**
  String get mapLayersTitle;

  /// No description provided for @mapActiveLayers.
  ///
  /// In vi, this message translates to:
  /// **'{count} lớp đang hiển thị'**
  String mapActiveLayers(int count);

  /// No description provided for @mapDisableAll.
  ///
  /// In vi, this message translates to:
  /// **'Tắt tất cả'**
  String get mapDisableAll;

  /// No description provided for @mapLayerSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm lớp dữ liệu'**
  String get mapLayerSearchHint;

  /// No description provided for @mapCatalogStale.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng catalog đã tải; chưa thể làm mới.'**
  String get mapCatalogStale;

  /// No description provided for @mapNoLayersFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy lớp phù hợp'**
  String get mapNoLayersFound;

  /// No description provided for @mapBasemapTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ nền'**
  String get mapBasemapTitle;

  /// No description provided for @mapBasemapEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bản đồ nền từ hệ thống.'**
  String get mapBasemapEmpty;

  /// No description provided for @mapLegendAction.
  ///
  /// In vi, this message translates to:
  /// **'Xem chú giải'**
  String get mapLegendAction;

  /// No description provided for @mapLegendEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Lớp này chưa cấu hình chú giải.'**
  String get mapLegendEmpty;

  /// No description provided for @mapSearchTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm trên bản đồ'**
  String get mapSearchTitle;

  /// No description provided for @mapSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm địa danh hoặc đối tượng'**
  String get mapSearchHint;

  /// No description provided for @mapSearchPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Nhập ít nhất 2 ký tự để tìm trong các lớp được phép.'**
  String get mapSearchPrompt;

  /// No description provided for @mapSearchEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy đối tượng phù hợp.'**
  String get mapSearchEmpty;

  /// No description provided for @mapFeatureTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đối tượng'**
  String get mapFeatureTitle;

  /// No description provided for @mapFeatureId.
  ///
  /// In vi, this message translates to:
  /// **'Mã đối tượng'**
  String get mapFeatureId;

  /// No description provided for @mapAttributesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thuộc tính'**
  String get mapAttributesTitle;

  /// No description provided for @mapAttributesEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có thuộc tính được phép hiển thị.'**
  String get mapAttributesEmpty;

  /// No description provided for @mapGeometryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hình học'**
  String get mapGeometryTitle;

  /// No description provided for @mapGeometryPoints.
  ///
  /// In vi, this message translates to:
  /// **'{count} điểm tọa độ'**
  String mapGeometryPoints(int count);

  /// No description provided for @mapLayerRenderError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hiển thị lớp {name}.'**
  String mapLayerRenderError(String name);

  /// No description provided for @mapTileError.
  ///
  /// In vi, this message translates to:
  /// **'Một lớp bản đồ chưa tải được'**
  String get mapTileError;

  /// No description provided for @mapRecenter.
  ///
  /// In vi, this message translates to:
  /// **'Về trung tâm Cẩm Phả'**
  String get mapRecenter;

  /// No description provided for @mapGpsAction.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí của tôi'**
  String get mapGpsAction;

  /// No description provided for @mapLayersCount.
  ///
  /// In vi, this message translates to:
  /// **'Lớp dữ liệu ({count})'**
  String mapLayersCount(int count);

  /// No description provided for @mapInfoAction.
  ///
  /// In vi, this message translates to:
  /// **'Tra cứu đối tượng'**
  String get mapInfoAction;

  /// No description provided for @mapTapInfoHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm trực tiếp vào đối tượng đang hiển thị để mở thông tin.'**
  String get mapTapInfoHint;

  /// No description provided for @fieldToolsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Công cụ hiện trường'**
  String get fieldToolsTitle;

  /// No description provided for @fieldToolsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Định vị, đo đạc và phân tích GIS'**
  String get fieldToolsSubtitle;

  /// No description provided for @locationWeatherTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí & thời tiết'**
  String get locationWeatherTitle;

  /// No description provided for @locationPrimer.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ lấy vị trí khi bạn bấm tiếp tục. Ứng dụng không theo dõi nền.'**
  String get locationPrimer;

  /// No description provided for @locationStart.
  ///
  /// In vi, this message translates to:
  /// **'Xác định vị trí'**
  String get locationStart;

  /// No description provided for @locationServiceOff.
  ///
  /// In vi, this message translates to:
  /// **'Dịch vụ vị trí đang tắt.'**
  String get locationServiceOff;

  /// No description provided for @locationDenied.
  ///
  /// In vi, this message translates to:
  /// **'Chưa được cấp quyền vị trí.'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In vi, this message translates to:
  /// **'Quyền vị trí đã bị chặn. Mở cài đặt để cấp lại.'**
  String get locationDeniedForever;

  /// No description provided for @locationOpenSettings.
  ///
  /// In vi, this message translates to:
  /// **'Mở cài đặt'**
  String get locationOpenSettings;

  /// No description provided for @locationOutsideBounds.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí nằm ngoài phạm vi Cẩm Phả hỗ trợ.'**
  String get locationOutsideBounds;

  /// No description provided for @locationAccuracy.
  ///
  /// In vi, this message translates to:
  /// **'Độ chính xác ±{meters} m'**
  String locationAccuracy(String meters);

  /// No description provided for @locationAccuracyLow.
  ///
  /// In vi, this message translates to:
  /// **'Độ chính xác thấp · sai số ±{meters} m'**
  String locationAccuracyLow(String meters);

  /// No description provided for @locationAccuracyUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông tin độ chính xác.'**
  String get locationAccuracyUnavailable;

  /// No description provided for @weatherUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể lấy thời tiết lúc này.'**
  String get weatherUnavailable;

  /// No description provided for @weatherTemperature.
  ///
  /// In vi, this message translates to:
  /// **'Nhiệt độ'**
  String get weatherTemperature;

  /// No description provided for @weatherWind.
  ///
  /// In vi, this message translates to:
  /// **'Gió'**
  String get weatherWind;

  /// No description provided for @weatherObserved.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật'**
  String get weatherObserved;

  /// No description provided for @nearbyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đối tượng gần vị trí'**
  String get nearbyTitle;

  /// No description provided for @nearbyEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có đối tượng trong bán kính hiện tại.'**
  String get nearbyEmpty;

  /// No description provided for @nearbyDistance.
  ///
  /// In vi, this message translates to:
  /// **'Cách {meters} m'**
  String nearbyDistance(String meters);

  /// No description provided for @measureTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đo đạc'**
  String get measureTitle;

  /// No description provided for @measureDistance.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng cách'**
  String get measureDistance;

  /// No description provided for @measureArea.
  ///
  /// In vi, this message translates to:
  /// **'Diện tích'**
  String get measureArea;

  /// No description provided for @measureTapHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm bản đồ để thêm điểm đo'**
  String get measureTapHint;

  /// No description provided for @measurePointCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} điểm'**
  String measurePointCount(int count);

  /// No description provided for @measureUndo.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác'**
  String get measureUndo;

  /// No description provided for @measureRedo.
  ///
  /// In vi, this message translates to:
  /// **'Làm lại'**
  String get measureRedo;

  /// No description provided for @measureComplete.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đo'**
  String get measureComplete;

  /// No description provided for @measureOfficial.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống xác nhận'**
  String get measureOfficial;

  /// No description provided for @measureLengthResult.
  ///
  /// In vi, this message translates to:
  /// **'{value} m'**
  String measureLengthResult(String value);

  /// No description provided for @measureAreaResult.
  ///
  /// In vi, this message translates to:
  /// **'{value} m²'**
  String measureAreaResult(String value);

  /// No description provided for @routeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tìm đường'**
  String get routeTitle;

  /// No description provided for @routeSelectHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm bản đồ lần lượt để chọn điểm đầu và điểm cuối. Tuyến được tính bằng Mapbox.'**
  String get routeSelectHint;

  /// No description provided for @routeStart.
  ///
  /// In vi, this message translates to:
  /// **'Điểm đầu'**
  String get routeStart;

  /// No description provided for @routeEnd.
  ///
  /// In vi, this message translates to:
  /// **'Điểm cuối'**
  String get routeEnd;

  /// No description provided for @routeUseGps.
  ///
  /// In vi, this message translates to:
  /// **'Dùng vị trí hiện tại'**
  String get routeUseGps;

  /// No description provided for @routeSwap.
  ///
  /// In vi, this message translates to:
  /// **'Đổi điểm đầu/cuối'**
  String get routeSwap;

  /// No description provided for @routeFind.
  ///
  /// In vi, this message translates to:
  /// **'Tìm tuyến'**
  String get routeFind;

  /// No description provided for @routeSourceMapbox.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn định tuyến: Mapbox'**
  String get routeSourceMapbox;

  /// No description provided for @routeDistance.
  ///
  /// In vi, this message translates to:
  /// **'Chiều dài {value} m'**
  String routeDistance(String value);

  /// No description provided for @fieldToolSheetDragHint.
  ///
  /// In vi, this message translates to:
  /// **'Kéo lên để xem thêm, kéo xuống để xem bản đồ'**
  String get fieldToolSheetDragHint;

  /// No description provided for @routeInstructionFallback.
  ///
  /// In vi, this message translates to:
  /// **'Tuyến đường đã sẵn sàng.'**
  String get routeInstructionFallback;

  /// No description provided for @fieldToolCancel.
  ///
  /// In vi, this message translates to:
  /// **'Thoát công cụ'**
  String get fieldToolCancel;

  /// No description provided for @reportsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phản ánh hiện trường'**
  String get reportsTitle;

  /// No description provided for @reportsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi thay đổi đô thị từ cộng đồng Cẩm Phả'**
  String get reportsSubtitle;

  /// No description provided for @reportCreate.
  ///
  /// In vi, this message translates to:
  /// **'Gửi phản ánh'**
  String get reportCreate;

  /// No description provided for @myReports.
  ///
  /// In vi, this message translates to:
  /// **'Phản ánh của tôi'**
  String get myReports;

  /// No description provided for @reportListView.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách'**
  String get reportListView;

  /// No description provided for @reportMapView.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ'**
  String get reportMapView;

  /// No description provided for @reportStale.
  ///
  /// In vi, this message translates to:
  /// **'Đang hiển thị dữ liệu gần nhất. Kéo xuống để thử lại.'**
  String get reportStale;

  /// No description provided for @reportStatusAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get reportStatusAll;

  /// No description provided for @reportStatusPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ tiếp nhận'**
  String get reportStatusPending;

  /// No description provided for @reportStatusReview.
  ///
  /// In vi, this message translates to:
  /// **'Đang xem xét'**
  String get reportStatusReview;

  /// No description provided for @reportStatusApproved.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác minh'**
  String get reportStatusApproved;

  /// No description provided for @reportStatusRejected.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get reportStatusRejected;

  /// No description provided for @reportStatusResolved.
  ///
  /// In vi, this message translates to:
  /// **'Đã xử lý'**
  String get reportStatusResolved;

  /// No description provided for @reportPublicEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có phản ánh công khai.'**
  String get reportPublicEmpty;

  /// No description provided for @reportFilteredEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có phản ánh phù hợp bộ lọc.'**
  String get reportFilteredEmpty;

  /// No description provided for @reportDaysAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày trước'**
  String reportDaysAgo(int count);

  /// No description provided for @reportHoursAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count} giờ trước'**
  String reportHoursAgo(int count);

  /// No description provided for @reportMinutesAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count} phút trước'**
  String reportMinutesAgo(int count);

  /// No description provided for @reportEvidenceStep.
  ///
  /// In vi, this message translates to:
  /// **'Minh chứng'**
  String get reportEvidenceStep;

  /// No description provided for @reportLocationStep.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí'**
  String get reportLocationStep;

  /// No description provided for @reportDescriptionStep.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get reportDescriptionStep;

  /// No description provided for @reportEvidenceHint.
  ///
  /// In vi, this message translates to:
  /// **'Thêm 1–5 ảnh PNG hoặc WebP'**
  String get reportEvidenceHint;

  /// No description provided for @reportCamera.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get reportCamera;

  /// No description provided for @reportGallery.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh'**
  String get reportGallery;

  /// No description provided for @reportLocationHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm bản đồ để đặt hoặc điều chỉnh ghim trong phạm vi Cẩm Phả'**
  String get reportLocationHint;

  /// No description provided for @reportDescriptionHint.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả hiện trạng từ 10 đến 2000 ký tự'**
  String get reportDescriptionHint;

  /// No description provided for @reportTruthConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Tôi xác nhận thông tin và minh chứng là đúng sự thật.'**
  String get reportTruthConfirm;

  /// No description provided for @reportNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get reportNext;

  /// No description provided for @reportBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get reportBack;

  /// No description provided for @reportSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Gửi phản ánh'**
  String get reportSubmit;

  /// No description provided for @reportUploadPresign.
  ///
  /// In vi, this message translates to:
  /// **'Chuẩn bị tải lên'**
  String get reportUploadPresign;

  /// No description provided for @reportUploadUploading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải ảnh'**
  String get reportUploadUploading;

  /// No description provided for @reportUploadCommit.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra an toàn'**
  String get reportUploadCommit;

  /// No description provided for @reportUploadReady.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đã sẵn sàng'**
  String get reportUploadReady;

  /// No description provided for @reportDraftRestored.
  ///
  /// In vi, this message translates to:
  /// **'Đã khôi phục phản ánh chưa gửi'**
  String get reportDraftRestored;

  /// No description provided for @reportDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa phản ánh'**
  String get reportDelete;

  /// No description provided for @reportDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa phản ánh này? Thao tác không thể hoàn tác.'**
  String get reportDeleteConfirm;

  /// No description provided for @reportHistory.
  ///
  /// In vi, this message translates to:
  /// **'Tiến trình xử lý'**
  String get reportHistory;

  /// No description provided for @reportPhotos.
  ///
  /// In vi, this message translates to:
  /// **'Minh chứng hình ảnh'**
  String get reportPhotos;

  /// No description provided for @reportReviewReason.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi xử lý'**
  String get reportReviewReason;

  /// No description provided for @reportNearby30Days.
  ///
  /// In vi, this message translates to:
  /// **'Gần tôi · 30 ngày'**
  String get reportNearby30Days;

  /// No description provided for @featureEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa đối tượng'**
  String get featureEditTitle;

  /// No description provided for @featureEditForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản không có quyền chỉnh sửa dữ liệu gốc.'**
  String get featureEditForbidden;

  /// No description provided for @featureEditUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Đối tượng hoặc phiên bản chưa hỗ trợ chỉnh sửa.'**
  String get featureEditUnavailable;

  /// No description provided for @featureInvalidValue.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị không đúng kiểu hoặc vượt giới hạn.'**
  String get featureInvalidValue;

  /// No description provided for @featureUnsavedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thay đổi chưa lưu?'**
  String get featureUnsavedTitle;

  /// No description provided for @featureUnsavedBody.
  ///
  /// In vi, this message translates to:
  /// **'Thuộc tính hoặc hình học đã thay đổi sẽ bị mất.'**
  String get featureUnsavedBody;

  /// No description provided for @featureDiscard.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thay đổi'**
  String get featureDiscard;

  /// No description provided for @featureVertices.
  ///
  /// In vi, this message translates to:
  /// **'đỉnh'**
  String get featureVertices;

  /// No description provided for @featureVersion.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản'**
  String get featureVersion;

  /// No description provided for @featureCurrent.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tại'**
  String get featureCurrent;

  /// No description provided for @featureSaveNow.
  ///
  /// In vi, this message translates to:
  /// **'Lưu lên máy chủ'**
  String get featureSaveNow;

  /// No description provided for @featureSaveOffline.
  ///
  /// In vi, this message translates to:
  /// **'Lưu vào hàng đợi offline'**
  String get featureSaveOffline;

  /// No description provided for @featureHistoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử đối tượng'**
  String get featureHistoryTitle;

  /// No description provided for @featureHistoryEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử phiên bản.'**
  String get featureHistoryEmpty;

  /// No description provided for @featureGeometryChanged.
  ///
  /// In vi, this message translates to:
  /// **'Hình học được cập nhật'**
  String get featureGeometryChanged;

  /// No description provided for @featureActionUpdate.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật'**
  String get featureActionUpdate;

  /// No description provided for @featureActionRestore.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục'**
  String get featureActionRestore;

  /// No description provided for @featureActionChanged.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi'**
  String get featureActionChanged;

  /// No description provided for @featureRestoreTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục phiên bản'**
  String get featureRestoreTitle;

  /// No description provided for @featureRestoreCreatesVersion.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục phiên bản {version} sẽ tạo một phiên bản mới; không ghi đè lịch sử.'**
  String featureRestoreCreatesVersion(int version);

  /// No description provided for @featureRestoreAction.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục'**
  String get featureRestoreAction;

  /// No description provided for @featureRestoreSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo phiên bản khôi phục mới.'**
  String get featureRestoreSuccess;

  /// No description provided for @featureSyncTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi offline'**
  String get featureSyncTitle;

  /// No description provided for @featureSyncNow.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ ngay'**
  String get featureSyncNow;

  /// No description provided for @featureSyncEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có thay đổi offline.'**
  String get featureSyncEmpty;

  /// No description provided for @featurePending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ đồng bộ'**
  String get featurePending;

  /// No description provided for @featureConflicts.
  ///
  /// In vi, this message translates to:
  /// **'Xung đột'**
  String get featureConflicts;

  /// No description provided for @featureRejected.
  ///
  /// In vi, this message translates to:
  /// **'Bị từ chối'**
  String get featureRejected;

  /// No description provided for @featureServerVersion.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản máy chủ'**
  String get featureServerVersion;

  /// No description provided for @featureUndo.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tác đỉnh cuối'**
  String get featureUndo;

  /// No description provided for @featureConflictTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đối tượng đã thay đổi'**
  String get featureConflictTitle;

  /// No description provided for @featureConflictBody.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản máy chủ mới hơn. Không thể ghi đè. Tải bản máy chủ hoặc giữ thay đổi này trong hàng đợi offline.'**
  String get featureConflictBody;

  /// No description provided for @featureReloadServer.
  ///
  /// In vi, this message translates to:
  /// **'Tải bản máy chủ'**
  String get featureReloadServer;

  /// No description provided for @reportNearbyFilterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phản ánh gần vị trí hiện tại'**
  String get reportNearbyFilterTitle;

  /// No description provided for @reportNearbyDateRange.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng thời gian'**
  String get reportNearbyDateRange;

  /// No description provided for @reportNearbyRadius.
  ///
  /// In vi, this message translates to:
  /// **'Bán kính: {meters} m'**
  String reportNearbyRadius(int meters);

  /// No description provided for @reportNearbyApply.
  ///
  /// In vi, this message translates to:
  /// **'Dùng vị trí hiện tại'**
  String get reportNearbyApply;

  /// No description provided for @featureChangedBy.
  ///
  /// In vi, this message translates to:
  /// **'Người thay đổi'**
  String get featureChangedBy;

  /// No description provided for @brandTagline.
  ///
  /// In vi, this message translates to:
  /// **'Đô thị trong tầm tay'**
  String get brandTagline;

  /// No description provided for @showPassword.
  ///
  /// In vi, this message translates to:
  /// **'Hiện mật khẩu'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn mật khẩu'**
  String get hidePassword;

  /// No description provided for @emailRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email chưa đúng định dạng'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu cần ít nhất 8 ký tự'**
  String get passwordMinLength;

  /// No description provided for @passwordMaxLength.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu tối đa 128 ký tự'**
  String get passwordMaxLength;

  /// No description provided for @passwordMustDiffer.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới phải khác mật khẩu hiện tại'**
  String get passwordMustDiffer;

  /// No description provided for @fullNameMinLength.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên cần ít nhất 2 ký tự'**
  String get fullNameMinLength;

  /// No description provided for @fullNameMaxLength.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên tối đa 255 ký tự'**
  String get fullNameMaxLength;

  /// No description provided for @privacyConsentRequired.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đồng ý trước khi đăng ký'**
  String get privacyConsentRequired;

  /// No description provided for @mapActiveTool.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng: {name}'**
  String mapActiveTool(String name);

  /// No description provided for @mapLayerOpacity.
  ///
  /// In vi, this message translates to:
  /// **'Độ hiển thị {percent}%'**
  String mapLayerOpacity(int percent);

  /// No description provided for @measureDistanceRequired.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ít nhất 2 điểm để xác nhận khoảng cách.'**
  String get measureDistanceRequired;

  /// No description provided for @measureAreaRequired.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ít nhất 3 điểm để xác nhận diện tích.'**
  String get measureAreaRequired;

  /// No description provided for @routeStartRequired.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm đầu trên bản đồ.'**
  String get routeStartRequired;

  /// No description provided for @routeEndRequired.
  ///
  /// In vi, this message translates to:
  /// **'Chọn điểm cuối trên bản đồ.'**
  String get routeEndRequired;

  /// No description provided for @routeEstimatedMinutes.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian dự kiến: {minutes} phút'**
  String routeEstimatedMinutes(int minutes);

  /// No description provided for @routeMinutesShort.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String routeMinutesShort(int minutes);

  /// No description provided for @draftPoint.
  ///
  /// In vi, this message translates to:
  /// **'Điểm'**
  String get draftPoint;

  /// No description provided for @draftLine.
  ///
  /// In vi, this message translates to:
  /// **'Đường'**
  String get draftLine;

  /// No description provided for @draftPolygon.
  ///
  /// In vi, this message translates to:
  /// **'Vùng'**
  String get draftPolygon;

  /// No description provided for @reportStepProgress.
  ///
  /// In vi, this message translates to:
  /// **'Bước {current}/{total} · {title}'**
  String reportStepProgress(int current, int total, String title);

  /// No description provided for @reportDraftAutosaved.
  ///
  /// In vi, this message translates to:
  /// **'Bản nháp được tự động lưu trên thiết bị.'**
  String get reportDraftAutosaved;

  /// No description provided for @reportEvidenceRequired.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ít nhất 1 ảnh để tiếp tục.'**
  String get reportEvidenceRequired;

  /// No description provided for @reportLocationRequired.
  ///
  /// In vi, this message translates to:
  /// **'Chọn vị trí trong phạm vi Cẩm Phả để tiếp tục.'**
  String get reportLocationRequired;

  /// No description provided for @reportDescriptionRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mô tả có ít nhất 10 ký tự.'**
  String get reportDescriptionRequired;

  /// No description provided for @reportTruthRequired.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận thông tin là đúng sự thật trước khi gửi.'**
  String get reportTruthRequired;

  /// No description provided for @reportCameraPrimerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép dùng máy ảnh?'**
  String get reportCameraPrimerTitle;

  /// No description provided for @reportCameraPrimerBody.
  ///
  /// In vi, this message translates to:
  /// **'Máy ảnh chỉ mở khi bạn tiếp tục để chụp minh chứng. Ứng dụng không chụp hoặc ghi hình nền.'**
  String get reportCameraPrimerBody;

  /// No description provided for @reportCameraPermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Chưa được cấp quyền máy ảnh. Mở cài đặt để cấp lại.'**
  String get reportCameraPermissionDenied;

  /// No description provided for @reportPhotoLimit.
  ///
  /// In vi, this message translates to:
  /// **'Đã đủ 5 ảnh minh chứng.'**
  String get reportPhotoLimit;

  /// No description provided for @reportPhotoPosition.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh {current} trên {total}'**
  String reportPhotoPosition(int current, int total);

  /// No description provided for @locationLocating.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác định vị trí…'**
  String get locationLocating;

  /// No description provided for @featureNoChanges.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi ít nhất một thuộc tính hoặc tọa độ trước khi lưu.'**
  String get featureNoChanges;

  /// No description provided for @featureLongitude.
  ///
  /// In vi, this message translates to:
  /// **'Kinh độ'**
  String get featureLongitude;

  /// No description provided for @featureLatitude.
  ///
  /// In vi, this message translates to:
  /// **'Vĩ độ'**
  String get featureLatitude;

  /// No description provided for @featureCoordinateOutOfBounds.
  ///
  /// In vi, this message translates to:
  /// **'Tọa độ phải nằm trong phạm vi Cẩm Phả.'**
  String get featureCoordinateOutOfBounds;

  /// No description provided for @featureDiscardOfflineTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa thay đổi offline?'**
  String get featureDiscardOfflineTitle;

  /// No description provided for @featureDiscardOfflineBody.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi chưa đồng bộ sẽ bị xóa khỏi thiết bị và không thể khôi phục.'**
  String get featureDiscardOfflineBody;

  /// No description provided for @featureSyncDiscardAction.
  ///
  /// In vi, this message translates to:
  /// **'Xóa thay đổi'**
  String get featureSyncDiscardAction;

  /// No description provided for @featureSyncing.
  ///
  /// In vi, this message translates to:
  /// **'Đang đồng bộ'**
  String get featureSyncing;

  /// No description provided for @featureSyncRejectedReason.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi này không thể đồng bộ. Kiểm tra dữ liệu hoặc xóa khỏi hàng đợi.'**
  String get featureSyncRejectedReason;

  /// No description provided for @reportDiscardDraftTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bản nháp phản ánh?'**
  String get reportDiscardDraftTitle;

  /// No description provided for @reportDiscardDraftBody.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh, vị trí và nội dung chưa gửi sẽ bị xóa khỏi thiết bị và không thể khôi phục.'**
  String get reportDiscardDraftBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
