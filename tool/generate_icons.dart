import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoFile = File('assets/images/logo.png');
  if (!logoFile.existsSync()) {
    stderr.writeln('Error: assets/images/logo.png not found');
    exit(1);
  }

  final rawLogo = img.decodePng(logoFile.readAsBytesSync());
  if (rawLogo == null) {
    stderr.writeln('Error: Failed to decode logo.png');
    exit(1);
  }

  print('Loaded logo: ${rawLogo.width}x${rawLogo.height}');

  final iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final iosTargets = <String, int>{
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  final androidTargets = <String, int>{
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };

  final webTargets = <String, int>{
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
  };

  // 1. Generate iOS icons (White background, RGB opaque)
  for (final entry in iosTargets.entries) {
    _generateOpaqueIcon(rawLogo, '$iosDir/${entry.key}', entry.value);
  }

  // 2. Generate Android icons (White background, RGB opaque)
  for (final entry in androidTargets.entries) {
    _generateOpaqueIcon(rawLogo, entry.key, entry.value);
  }

  // 3. Generate Web app icons (White background, RGB opaque)
  for (final entry in webTargets.entries) {
    _generateOpaqueIcon(rawLogo, entry.key, entry.value);
  }

  // 4. Generate Web favicon (16x16 with transparency)
  _generateTransparentIcon(rawLogo, 'web/favicon.png', 16);

  print('All icons generated successfully!');
}

void _generateOpaqueIcon(img.Image rawLogo, String path, int size) {
  final canvas = img.Image(width: size, height: size, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

  final resized = img.copyResize(
    rawLogo,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );

  img.compositeImage(canvas, resized);

  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(canvas));
  print('Generated $path (${size}x$size, opaque)');
}

void _generateTransparentIcon(img.Image rawLogo, String path, int size) {
  final resized = img.copyResize(
    rawLogo,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(resized));
  print('Generated $path (${size}x$size, transparent)');
}
