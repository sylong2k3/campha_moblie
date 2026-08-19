/// Định dạng dung lượng file (bytes) sang chuỗi ngắn gọn.
String formatFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '--';
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}
