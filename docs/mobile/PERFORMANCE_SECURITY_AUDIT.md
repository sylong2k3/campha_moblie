# Audit hiệu năng & bảo mật — Mobile GIS Cẩm Phả

**Ngày audit:** 2026-08-11  
**Phạm vi:** Flutter source, Android/iOS config, dependencies, APK debug/profile và Android 17 emulator  
**Kết luận:** **Code gate PASS sau remediation; production RC vẫn NOT DONE**

> Emulator evidence tìm regression lớn nhưng không thay physical mid-range Android, TalkBack, iOS/macOS và authenticated UAT.

## Tóm tắt

| Khu vực | Kết quả | Kết luận |
|---|---|---|
| Format/analyze/tests | PASS | `flutter analyze` clean; full suite 63/63 |
| Embedded credential | Fixed | Seed password gỡ khỏi source; không có fallback; scan không thấy known seed |
| Runtime config | Fixed | `.env` không còn bundled/read runtime; chỉ dùng compile-time dart defines |
| External/storage URLs | Fixed | `file:`, `content:` và custom schemes bị từ chối; profile/release yêu cầu HTTPS |
| Token header | Fixed | Offline sync bỏ manual Bearer; shared auth interceptor là đường duy nhất |
| Android platform | PASS với flavor note | Backup off; staging/profile cleartext off; release shrink/signing fail-fast |
| Startup/profile emulator | Cần theo dõi | Baseline cold profile 2.270 s; 229,859 KiB PSS; 34 skipped frames |
| Navigation soak emulator | Cần physical gate | 236 frames; p50 5 ms, p90 15 ms, p99 18 ms; modern jank 16.10% |
| APK debug size | Giải thích được | Debug JIT + Flutter engine + Mapbox native + Vulkan validation + ABI bundling |
| Dependencies | Có technical debt | Nhiều minor/major update; secure-storage macOS implementation cũ discontinued |

## Remediation đã áp dụng

### Credential và config

- Test role picker chỉ fill email mặc định; password rỗng và focus password field.
- Password test chỉ nhận từ `TEST_ACCOUNT_PASSWORD`; không có hardcoded fallback.
- `.env` gỡ khỏi Flutter assets và app startup.
- `flutter_dotenv` gỡ khỏi dependency graph.
- VS Code vẫn dùng `.env` làm input `--dart-define-from-file`; file không thành app asset.
- Debug APK có truyền secret bằng dart define vẫn chứa secret trong binary, không được phân phối.

### Network và trust boundaries

- CMS download grant chỉ nhận URI có authority và HTTPS; debug local được phép HTTP.
- Report photo/direct-upload grants áp dụng cùng policy.
- `file:`, `content:`, relative URL và custom scheme bị từ chối trước external launch/upload.
- Offline sync bỏ manual Authorization header; singleton Dio + AuthInterceptor sở hữu token/refresh.
- Logger chỉ chạy debug và chỉ log method, safe path, status, duration, error type.

### Startup, fonts và package size

- Firebase optional init chuyển khỏi first-frame critical path.
- Shared initialization future khóa race; push operations vẫn chờ Firebase khi cần.
- Be Vietnam Pro bundle local theo weights 400/500/600/700; bỏ runtime Google Fonts fetch.
- Gỡ `google_fonts`, `flutter_dotenv` và unused `material_symbols_icons`.
- Unused Material Symbols trước đó chiếm khoảng **16.11 MiB compressed**.

## Runtime evidence

Môi trường: Android 17 `sdk_gphone16k_x86_64`, 1344 × 2992, 480 dpi, AVD RAM 2048 MiB, Impeller/OpenGL ES.

### Final startup sau remediation

Năm cold starts liên tiếp trên final profile artifact:

| Run | Cold start | Skipped-frame events |
|---:|---:|---:|
| 1 | 1,735 ms | 0 |
| 2 | 1,809 ms | 0 |
| 3 | 2,170 ms | 58 frames |
| 4 | 1,634 ms | 0 |
| 5 | 1,735 ms | 32 frames |

- Median: **1,735 ms**; min/max: 1,634/2,170 ms.
- 2/5 runs có Choreographer skip event; 3/5 sạch.
- So với baseline 2,270 ms, median giảm khoảng 23.6%; không claim startup jank đã đóng.
- Final memory sample: Java/native heap 16,440/85,592 KiB; PSS/RSS 220,213/369,780 KiB.
- Log context đặt skips quanh Android surface/Mapbox/geolocator class initialization; physical device vẫn là quyết định cuối.

### Navigation/map-tab soak

| Metric | Evidence |
|---|---:|
| Frames | 236 |
| Android janky / legacy janky | 38 (16.10%) / 3 (1.27%) |
| p50 / p90 / p95 / p99 | 5 / 15 / 16 / 18 ms |
| Total PSS / RSS sau navigation | 248,660 / 394,260 KiB |

- Percentiles ổn tới p95; modern jank metric vẫn cao và cần physical-device xác minh.
- PSS tăng khoảng 18.4 MiB sau map/tab navigation, phù hợp map keep-alive nhưng cần soak dài.
- Không thấy FATAL EXCEPTION, RenderFlex, known credential hoặc Bearer JWT trong filtered log.
- Image import 30 MiB vẫn decode/resize/PNG encode trên main isolate. Chưa có authenticated five-image evidence; chỉ chuyển `Isolate.run` khi physical trace chứng minh jank.

## Vì sao APK debug nặng

Debug giữ JIT/debug runtime và không tối ưu như release:

| Thành phần arm64 debug | Compressed size |
|---|---:|
| Flutter engine `libflutter.so` | 35.44 MiB |
| Dart `kernel_blob.bin` | 27.06 MiB |
| Vulkan validation layer | 14.55 MiB |
| Mapbox Maps / Common native | 12.77 / 6.57 MiB |
| Dex | 10.21 MiB tổng |
| Flutter isolate snapshot | 4.01 MiB |

Universal debug gom arm32 + arm64 + x86_64, khiến native bytes lặp. Đây là nguyên nhân chính, không phải ảnh app.

| Artifact | Size | Dùng cho |
|---|---:|---|
| Universal dev debug | 217.13 MiB | Không nên chia sẻ; gom 3 ABI |
| arm64 dev debug split | 114.01 MiB | Android phone/tablet hiện đại |
| arm32 dev debug split | 87.50 MiB | Thiết bị ARM cũ |
| x86_64 dev debug split | 102.19 MiB | Emulator hiện tại |
| arm64-only default debug | 150.36 MiB | Một Flutter target nhưng plugin packaging vẫn lớn hơn split |
| staging x86_64 profile | 111.92 MiB | Profiling emulator; không phải distribution artifact |

Tạo APK test theo ABI:

```powershell
flutter build apk --flavor dev -t lib/main.dart --debug --split-per-abi --dart-define-from-file=.env
```

Cài Android ARM64: `build/app/outputs/flutter-apk/app-arm64-v8a-dev-debug.apk`.

Production dùng AAB để Play phân phối đúng ABI/resources:

```powershell
flutter build appbundle --flavor prod -t lib/main.dart --release --dart-define-from-file=config/prod.json
```

## Artifact security inspection

Final staging profile:

- Size 111.92 MiB; SHA-256 `7AF8644F85CFFC331C3D9E538B676D898508CD1BEF9395F56DE8B3CE8CC97CB2`.
- `.env` asset: 0; dead Material Symbols: 0 MiB; bundled Be Vietnam Pro OFL license: 1.
- Known seed password/private-key header/literal Bearer JWT: 0 findings.
- `allowBackup=false`; `usesCleartextTraffic=false`.
- Dev flavor duy nhất giữ cleartext cho backend local.

## Platform/dependency review

- Android không có background location, broad storage hoặc `QUERY_ALL_PACKAGES`; release signing fail-fast, minify/shrink bật.
- iOS không thấy arbitrary ATS load exception; purpose strings đủ; runtime vẫn cần macOS.
- 12 direct dependencies sau minor/patch và 14 constraints sau resolvable versions tại audit time.
- `flutter_secure_storage` 9.x kéo macOS implementation discontinued; cần upgrade riêng với token-store regressions.
- Không nâng major mù trong audit.

## Residual risks / release gates

1. Rotate backend seed password; từng tồn tại trong source/fixtures/Postman/APK cũ.
2. Delete/invalidate pre-remediation APK; không phân phối debug artifact có test password define.
3. Report draft giữ exact GPS/description/photo paths trong plaintext SharedPreferences; backup off/logout cleanup chỉ giảm risk.
4. Physical Android: cold/warm start, map pan/zoom, layer toggles, five-image flow, memory soak, TalkBack.
5. macOS/iOS, Firebase resources, production signing/HTTPS và authenticated A→B UAT còn blocking.
6. Restrict public Mapbox token theo app/package policy; PO/Ops/Legal acceptance còn mở.
7. Media deletion dùng restored local paths; containment guard nên thêm nếu preference tampering là hostile boundary.

## Release decision

**Source + automated Android audit: PASS.**  
**Production RC: NOT DONE.** Physical Android, iOS/macOS, Firebase, signing/config, credential rotation và authenticated UAT vẫn bắt buộc.
