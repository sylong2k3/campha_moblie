import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../error/app_exception.dart';

const pendingMediaMaxBytes = 5 * 1024 * 1024;

/// Copy media khỏi cache của picker trước khi enqueue để OS không dọn mất file.
class PendingMediaStore {
  const PendingMediaStore();

  Future<String> persist(String sourcePath, {String folder = 'uploads'}) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const ValidationException('Không tìm thấy tệp ảnh đã chọn.');
    }
    if (await source.length() > pendingMediaMaxBytes) {
      throw const PayloadTooLargeException(
        'Mỗi ảnh phải nhỏ hơn hoặc bằng 5 MB.',
      );
    }

    final root = await getApplicationSupportDirectory();
    final directory = Directory(path.join(root.path, 'pending_media', folder));
    await directory.create(recursive: true);
    final extension = path.extension(source.path);
    final target = path.join(
      directory.path,
      '${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    return (await source.copy(target)).path;
  }

  Future<void> delete(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    try {
      await file.delete();
    } on FileSystemException {
      // File có thể đã bị OS dọn; queue vẫn phải xóa được.
    }
  }

  Future<void> deleteAll(Iterable<String> paths) async {
    for (final filePath in paths) {
      await delete(filePath);
    }
  }
}

final pendingMediaStoreProvider = Provider<PendingMediaStore>(
  (ref) => const PendingMediaStore(),
  name: 'pendingMediaStoreProvider',
);
