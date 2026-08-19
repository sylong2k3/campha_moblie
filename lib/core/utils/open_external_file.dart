import 'package:url_launcher/url_launcher.dart';

/// Mở URL tệp bằng ứng dụng hệ thống (trình đọc PDF/trình duyệt sẵn có).
///
/// Trả `true` nếu hệ điều hành nhận mở được, `false` nếu không (không có app
/// xử lý). Không tự hiện SnackBar để bên gọi tự quyết định thông báo lỗi phù
/// hợp ngữ cảnh.
Future<bool> openExternalFile(String url) {
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
