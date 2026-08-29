# campha_moblie

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Build APK demo ARM64 release

Sau mỗi lần sửa mã, chạy tại thư mục gốc dự án:

```powershell
flutter build apk --flavor prod --release --target-platform android-arm64 --split-per-abi -t lib/main.dart --dart-define-from-file=.env --dart-define=ENABLE_TEST_LOGIN=true
```

`.env` phải có `TEST_ACCOUNT_PASSWORD`. APK tạo tại
`build/app/outputs/flutter-apk/app-arm64-v8a-prod-release.apk`.

> Không phát hành APK demo công khai vì mật khẩu kiểm thử được nhúng vào binary.
