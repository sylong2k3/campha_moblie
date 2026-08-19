# Sprint 06 — TNMT Feature Edit, History & Offline Sync

## Sprint Goal

Cho phép đúng vai trò Sở TNMT sửa thuộc tính/hình học theo allowlist, xem/khôi phục lịch sử phiên bản và đồng bộ thay đổi offline mà không ghi đè xung đột.

## Phạm vi hoàn thành

### M13 — TNMT Feature Editor

- Route `/map/feature/:layerId/:featureId/edit` có auth return và exact role/permission guard.
- Backend catalog trả `canEdit` và `editableFields` đã lọc ID/system/routing columns chỉ cho TNMT hợp lệ.
- Mobile chỉ dựng form từ exact allowlist; không đoán từ display attributes.
- Mobile feature detail dùng endpoint version-aware và nhận authoritative snapshot/version cho TNMT.
- Thuộc tính giữ giá trị hiện tại, track dirty theo field, hỗ trợ submit `null` khi xóa.
- Point/LineString/Polygon editor có vertex count, validity, undo và Cẩm Phả bounds validation.
- PATCH gửi exact `baseVersion`; không force overwrite.
- Back xác nhận unsaved changes.
- 409 giữ local input, cho reload server hoặc enqueue offline; recursive submit bug đã loại.

### M14 — History & Restore

- Route `/map/feature/:layerId/:featureId/history`.
- Timeline newest-first: version/action/time/actor/current badge/changed values.
- Geometry summary có type và recursive coordinate count kèm semantics.
- Restore giải thích tạo phiên bản mới và gửi current `baseVersion`.
- Conflict/error invalidates history; không silent retry.

### Offline Sync

- SQLite schema v2, owner-partitioned queue và durable UUID v4 client/change IDs.
- States: `pending`, `syncing`, `conflict`, `rejected`.
- Startup recovery đưa abandoned `syncing` về `pending`.
- Exact batch payload tới `POST /mobile/sync`.
- Applied/conflicts/rejected xử lý riêng; server snapshot lưu cho conflict review.
- Chỉ `NetworkException` dùng bounded exponential backoff.
- Auth/permission/validation batch failure đưa rows về pending reviewable, không tăng transport attempt.
- Mọi transition scope theo owner; stale session không sửa queue user khác.
- Logout/change-password purge queue và client identity trong transaction.

## Backend Contract

Backend được bổ sung tối thiểu:

- Catalog query chọn per-role `role_can_edit`.
- Catalog serializer trả sanitized `canEdit/editableFields`.
- TNMT mobile feature detail trả authoritative editable snapshot và current version.
- Guest/non-TNMT không nhận editable allowlist/capability.

Backend vẫn là final authority cho role, permission, layer, allowlist, geometry và version conflict.

Final regression hardening:

- Geometry-only editable layer giữ `canEdit=true` dù `editableFields=[]`.
- Clear boolean attribute gửi `null`, không đổi im lặng thành `false`.
- Direct editor route chờ catalog load trước khi kết luận forbidden.

## Verification

### Mobile

```text
dart format lib test: PASS
flutter analyze: No issues found
flutter test: 29/29 passed
```

Tests khóa:

- Strict history/version/snapshot parsing.
- Exact offline sync payload và malformed layer ID rejection.
- Applied/conflict/rejected buckets.
- Catalog edit capability/allowlist and current version parsing.
- Safe edit/history/queue route returns.

### Backend targeted

```text
Jest: 3 suites, 14/14 passed
Prettier: PASS
ESLint targeted files: PASS
```

Covered catalog sanitization, guest hiding, TNMT snapshot/version detail and edit service contract.

## Definition of Done

| Hạng mục | Trạng thái | Bằng chứng/Ghi chú |
|---|---|---|
| Exact backend capability/allowlist contract | Done | Backend code + targeted tests |
| Current feature version contract | Done | TNMT mobile detail code + test |
| M13 editor code | Done | Mobile gate clean |
| M14 history/restore code | Done | Mobile gate clean |
| Durable owner-scoped offline queue/sync | Done | Mobile gate clean |
| Guest Android `lib/main.dart` proof | Done | Dev APK build/install/launch + guest screenshot/XML |
| Authenticated TNMT end-to-end | Blocked | Thiếu TNMT runtime credential và editable/versioned fixture |
| iOS runtime | Blocked | Windows host; cần macOS |

Android evidence:

- `docs/mobile/design/sprint6_guest_home.png`
- `docs/mobile/design/sprint6_guest_home.xml`
- Guest semantics không chứa edit/history/offline sync actions.

## Blocked — không mock

1. Không có TNMT runtime password credential.
2. Không có production-like editable/versioned feature fixture được cấp cho account.
3. Firebase native resources vẫn thiếu; không ảnh hưởng M13/M14 nhưng chặn push acceptance.
4. iOS cần macOS CI/simulator/device.

## Sprint Review

Code và backend contract hiện không còn đoán allowlist/version. Không claim authenticated E2E Done khi chưa có credential/fixture. Sprint 7 nhận phần runtime hardening, accessibility, profiling, security/privacy và RC gates.
