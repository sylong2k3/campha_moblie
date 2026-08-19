# Android Release Handoff — Mobile GIS Cẩm Phả

## Trạng thái hiện tại

- Dev Android chạy từ `lib/main.dart`; Release Closure 2026-08-11 build dev debug PASS.
- `dart format`, `flutter analyze`, 63/63 mobile tests và Android debug/profile audit PASS; xem [RELEASE_CLOSURE.md](./RELEASE_CLOSURE.md).
- Release/profile chỉ nhận config từ `--dart-define` hoặc `--dart-define-from-file`; không đọc `.env`.
- Main/staging/prod chặn cleartext; chỉ flavor `dev` cho HTTP local.
- Release build fail-fast khi thiếu production signing.
- Firebase, production signing, official endpoints và owner acceptance chưa được cung cấp.
- Production RC **Not Done**; dev evidence không thay authenticated/device/iOS/owner gates.

## Input bắt buộc từ Ops/PO

Tạo file ignored `config/prod.json` từ `config/prod.example.json`:

- `API_BASE_URL`: HTTPS `/api/v1` chính thức.
- `GEOSERVER_URL`: HTTPS bắt buộc — mọi lớp raster/WMS gọi trực tiếp GeoServer, thiếu giá trị này sẽ fail-fast khi validate release.
- `WS_NOTIFICATIONS_URL`: WSS hoặc bỏ trống nếu chưa dùng.
- `MAPBOX_TOKEN`: public `pk.*`, giới hạn application/package và URL theo chính sách Mapbox.
- `GOOGLE_CLIENT_ID`: public OAuth client ID nếu native Google flow được bật.
- Timeout/accuracy trong giới hạn validator.

Không đặt password, JWT, refresh token, service-account JSON hoặc private API key trong file này.

## Production signing

Tạo `android/key.properties` đã bị ignore:

```properties
storePassword=<runtime secret>
keyPassword=<runtime secret>
keyAlias=<production alias>
storeFile=<path relative to android directory or approved absolute path>
```

Keystore và mật khẩu đi qua secure CI secret store. Không commit, gửi chat hoặc đưa vào evidence. Thiếu/incomplete signing phải dừng build; không dùng debug key.

## Firebase flavor resources

Ops cung cấp đúng app/package:

- Android prod: `google-services.json` qua secure delivery.
- iOS prod: `GoogleService-Info.plist` qua secure delivery.
- Bật Gradle plugins sau khi resource/project đã xác nhận.
- Xác minh FCM register/unregister/deep link và Crashlytics không chứa PII.

## Build Android RC

```powershell
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build appbundle --flavor prod -t lib/main.dart --release --dart-define-from-file=config/prod.json
```

Output mong đợi:

```text
build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

Kiểm tra Play signing certificate/app ID/versionCode trước upload. Không dùng local `.env` làm release input.

## Acceptance matrix bắt buộc

- Guest + citizen + UBND + Sở Xây dựng + Sở TNMT + system admin bằng account/fixture thật.
- Android emulator và ít nhất một thiết bị vật lý tầm trung.
- iOS 14+ trên macOS CI/simulator/device.
- Cold/warm start, background/resume, rotation, vi/en, light/dark/system, large text, TalkBack.
- Map sustained pan/zoom, long lists, five report images, PDF lifecycle, offline queue/conflict.
- FCM/Crashlytics sau khi native configs có mặt.

## Release stop / rollback

Dừng RC nếu:

- Release config không phải HTTPS/WSS hoặc production signing thiếu.
- P0/P1 chưa có waiver rõ tên owner.
- Token/password/phone/photo/exact GPS xuất hiện trong log/evidence.
- Auth/TNMT conflict UAT, physical Android, Firebase hoặc iOS còn Blocked mà không có PO/Ops waiver.

Ops phải ghi backend version, migration status, rollback command/contact và Mapbox terms/cost/token-restriction acceptance trong release ticket ngoài repository.
