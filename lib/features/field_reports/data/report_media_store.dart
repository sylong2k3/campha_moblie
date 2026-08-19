import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ReportMediaStore {
  static const maxInputBytes = 30 * 1024 * 1024;
  static const maxOutputBytes = 10 * 1024 * 1024;
  static const maxDimension = 2400;

  Future<String> importAsPng(String sourcePath) async {
    final source = File(sourcePath);
    final inputBytes = await source.length();
    if (inputBytes <= 0 || inputBytes > maxInputBytes) {
      throw ArgumentError('Invalid source image size');
    }
    final decoded = await img.decodeImageFile(sourcePath);
    if (decoded == null) throw ArgumentError('Unsupported image data');
    final resized =
        decoded.width > maxDimension || decoded.height > maxDimension
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxDimension : null,
            height: decoded.height > decoded.width ? maxDimension : null,
            interpolation: img.Interpolation.average,
          )
        : decoded;
    final output = img.encodePng(resized, level: 6);
    if (output.length > maxOutputBytes) {
      throw ArgumentError('Converted image exceeds 10 MB');
    }
    final root = await getApplicationSupportDirectory();
    final directory = Directory(path.join(root.path, 'field_report_drafts'));
    await directory.create(recursive: true);
    final target = File(
      path.join(directory.path, '${DateTime.now().microsecondsSinceEpoch}.png'),
    );
    await target.writeAsBytes(output, flush: true);
    return target.path;
  }

  Future<void> delete(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Local cleanup best effort; never lose server-side report after success.
    }
  }
}
