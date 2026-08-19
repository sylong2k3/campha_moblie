# Sprint 07 — Hardening & Release Candidate

## Sprint Goal

Đóng feature scope; harden accessibility, privacy/security, performance và release configuration. Chứng minh Android từ `lib/main.dart`; không dùng Chrome, không mock credential/fixtures.

## Phạm vi hoàn thành

### MOB-701 — Accessibility, vi/en, theme

- Icon-only controls audit; report composer close control có tooltip.
- Material controls dùng padded 48dp tap targets.
- Report step transition và progress animation tắt khi system `disableAnimations`.
- Existing vi/en và light/dark/system giữ nguyên.
- Map/feature/history/report status tiếp tục có text alternative, không dựa màu đơn độc.

### MOB-702 — Performance hardening

- Persistent MapWidget/lazy paging architecture giữ nguyên.
- Local evidence thumbnails decode theo 52dp × device pixel ratio.
- Private report remote photo decode theo rendered viewport × 220dp, tránh full-resolution cache không cần thiết.
- Physical mid-range Android profiling và authenticated five-image/PDF soak vẫn Blocked.
- Emulator từng báo startup frame skip; không claim target-device performance pass.

### MOB-703 — Security/privacy

- HTTP log chỉ method, sanitized path, status, duration, Dio error type.
- Không log query/header/body/response/error payload; test khóa query/token stripping.
- Push/location/crash fallback dùng fixed debug codes, không interpolate exception/stack.
- Raw `error.toString()` bị loại khỏi report/editor/history/sync UI; unknown object thành localized generic message.
- Release/profile không load `.env`; chỉ dart-define/CI.
- HTTPS/WSS/local-host/public-client validation có tests.
- Dev HTTP vẫn chỉ ở Android flavor `dev`; no background location permission.

### MOB-704 — Regression/API/device

- Mobile full gate sạch, 32/32 tests.
- Backend targeted 3 suites, 14/14 tests; Prettier/ESLint sạch.
- Geometry-only editable layer fix: `canEdit` dựa exact TNMT permission + `role_can_edit`, độc lập attribute allowlist.
- Boolean field clear gửi `null`; direct editor route chờ catalog trước forbidden.
- Nearby picker giới hạn 365 ngày lịch để end-of-day không vượt backend max 366 ngày.
- Android dev APK build/install/launch thành công từ `lib/main.dart`.
- Guest semantics xác nhận five-tab shell và không expose TNMT actions.
- Logcat filtered smoke không thấy FATAL/ANR/[CRASH]/query token-phone marker.

### MOB-705 — Release config/handoff

- Release build không fallback debug signing.
- Missing production signing dừng đúng thông báo.
- Release handoff mô tả ignored dart-define file, signing/Firebase/CI/device/iOS gates.
- Production AAB chưa build vì thiếu official signing/config; đúng trạng thái Blocked.

## Verification

### Mobile

```text
dart format lib test: PASS
flutter analyze: No issues found
flutter test: 32/32 passed
flutter build apk --flavor dev -t lib/main.dart --debug: PASS
```

### Backend targeted

```text
Jest: 3 suites passed
Tests: 14/14 passed
Prettier: PASS
ESLint targeted: PASS
```

### Release signing guard

```text
flutter build appbundle --flavor prod ...
FAIL (expected): Release build yêu cầu android/key.properties và production keystore hợp lệ.
```

### Android evidence

- `docs/mobile/design/sprint7_guest.png`
- `docs/mobile/design/sprint7_guest.xml`
- Package: `vn.gov.campha.mobilegis.dev`.
- `adb reverse tcp:3006 tcp:3006`, install, force-stop và launch đều thành công.

## Definition of Done

| Hạng mục | Trạng thái | Bằng chứng/Ghi chú |
|---|---|---|
| Security/privacy code audit | Done | Redacted logs + safe UI errors + tests |
| Release config guard | Done | dotenv disabled release/profile; HTTPS/WSS tests |
| Accessibility code hardening | Done | 48dp targets, tooltip, reduced motion |
| Image/list/map code hardening | Done | bounded decode + persistent/lazy architecture |
| Full mobile regression | Done | Analyze clean; 32/32 |
| Backend Sprint 6 regression | Done | 14/14 + lint/format |
| Android guest `lib/main.dart` | Done | APK install/launch + screenshot/XML |
| Production signed AAB | Blocked | Thiếu official URLs/token restrictions/signing material |
| Full role UAT | Blocked | Thiếu runtime password/TNMT/internal fixtures |
| Firebase delivery/Crashlytics | Blocked | Thiếu native flavor resources |
| Physical Android performance/accessibility | Blocked | Không có representative device |
| iOS RC | Blocked | Windows host; cần macOS CI/device |
| Final RC sign-off | Not Done | High-impact blockers chưa có owner waiver |

## Sprint Review

Sprint 1–7 code/public Android lộ trình đã hoàn tất theo scope có thể chứng minh. Build hiện không được gọi “production RC” vì signing, credential/role fixtures, Firebase, physical Android và iOS gates chưa đạt. Không mock hoặc hạ gate.
