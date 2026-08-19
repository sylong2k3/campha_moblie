# Release Closure — Mobile GIS Cẩm Phả

**Ngày chốt:** 2026-08-11  
**Phạm vi:** source mobile hiện tại, automated regression, Android debug/profile audit  
**Quyết định:** **Code closure PASS; production RC NOT DONE**

## Kết quả

| Gate | Kết quả | Evidence |
|---|---|---|
| Dart format | PASS | `dart format --output=none --set-exit-if-changed lib tool test`; 0 changes |
| Static analysis | PASS | `flutter analyze`; no issues |
| Full mobile tests | PASS | `flutter test`; 63/63 passed |
| Android debug split | PASS | arm32 87.50 MiB; arm64 114.01 MiB; x86_64 102.19 MiB |
| Android staging profile | PASS | 111.92 MiB; SHA-256 `7AF8644F85CFFC331C3D9E538B676D898508CD1BEF9395F56DE8B3CE8CC97CB2` |
| Artifact security | PASS | no `.env`, known seed/private-key/Bearer literal; backup/cleartext off for staging |
| Emulator profile | OBSERVED | 5-run cold median 1.735 s, range 1.634–2.170 s; 2/5 runs had skip events; PSS sample 220,213 KiB |

## Hạng mục đã chốt trong code

### Session và privacy

- Token clear idempotent theo lifecycle; secure delete vẫn chạy mỗi lần.
- Push unregister và server logout best effort; local token/data cleanup luôn chạy.
- Owner queue/client identity, report draft/media/GPS, field tools, report/CMS/map retained state được purge/reset độc lập.
- Draft restore có generation guard, không hồi sinh GPS/photo/description sau logout.
- List/detail/search retained state reload hoặc clear khi session identity đổi.

### Error và retry

- Typed mapping bao phủ offline/timeout, 400, 401, 403, 404, 409, 413, 422, 429, 500, 502, 503.
- Validation errors, password-change code, Retry-After/RateLimit-Reset được giữ đúng contract.
- Payload message không phải string không đi ra UI.
- Retry chỉ áp dụng GET transient, tối đa một lần.
- POST, PATCH, multipart và GET 429 không retry.

### CMS signed URL

- URL chỉ lấy khi user action; không persist/cache.
- Grant gần hết hạn được refresh tối đa một lần.
- Grant thứ hai vẫn hết hạn trả safe actionable error, không loop.
- Account đổi trong lúc lấy grant không mở/chia sẻ URL của owner cũ.
- External viewer không cung cấp downstream HTTP status; không tuyên bố đã runtime-test 401/403.

### Form accessibility

- Login focus/scroll theo visual order: email, rồi password.
- Debug role picker fill email; password rỗng/focused mặc định, optional từ `TEST_ACCOUNT_PASSWORD`.
- Report focus/scroll: description, rồi truth confirmation.
- Final submit còn bấm được để chạy validation; invalid state không gọi repository.
- Widget regressions kiểm cả bốn control.

### Audit hiệu năng và bảo mật

- Gỡ credential fallback, bundled `.env`, runtime dotenv và manual offline-sync Bearer header.
- Server-provided external/storage URLs bị giới hạn HTTP debug-local hoặc HTTPS profile/release; custom schemes bị chặn.
- Firebase optional init rời first-frame critical path, dùng shared future chống race.
- Be Vietnam Pro bundle local; gỡ unused Material Symbols (~16.11 MiB compressed) và runtime font fetch.
- Emulator 5-run cold median 1.735 s so với baseline 2.270 s; 2/5 runs vẫn có startup skip event nên physical gate còn mở.
- Navigation profile: p50/p90/p95/p99 = 5/15/16/18 ms; physical-device gate vẫn mở.

## Automated evidence mới

- Token duplicate-clear/delete regression.
- Persisted report draft privacy cleanup regression.
- HTTP status/transport/privacy matrix.
- GET retry call-count và write/multipart no-retry regression.
- Presigned grant 1-call/2-call/bounded-failure regressions.
- Login/report first-invalid focus regressions.
- External/download/upload URL unsafe-scheme regressions.
- Debug role picker no-password fallback regression.

## External gates còn chặn production RC

| Gate | Trạng thái | Exit condition |
|---|---|---|
| Authenticated role UAT | Blocked | Local seed 5/5 role login 200 và mapping đúng; PO/QA vẫn phải cung cấp acceptance credential/fixture cho môi trường release |
| A→B private-state runtime UAT | Blocked | Hai account thật; kiểm private layer/CMS/report/GPS sau logout/login |
| Firebase Android/iOS | Blocked | Ops cung cấp flavor resources và device evidence |
| Production HTTPS/signing | Blocked | Ops cung cấp endpoints, signing material và signed AAB evidence |
| Physical Android/TalkBack/performance soak | Blocked | Emulator profile có evidence; QA vẫn chạy representative mid-range device, map + five-image soak |
| Credential rotation | Blocked | Backend/QA rotate seed password từng xuất hiện trong source/artifact cũ |
| iOS build/UAT | Blocked | macOS CI/simulator/physical device evidence |
| Positive pgRouting | Blocked | Backend GIS cung cấp line topology fixture ready |
| Mapbox owner acceptance | Open | PO/Ops/Legal phê duyệt terms/cost/token restrictions |
| PO/Ops release decision | Open | Named sign-off hoặc waiver cho mọi high-impact risk |

> [!WARNING]
> Android dev debug APK và automated PASS không phải production artifact approval. Không gắn nhãn production RC cho đến khi mọi gate trên có evidence hoặc named waiver.

## Tài liệu liên quan

- [PERFORMANCE_SECURITY_AUDIT.md](./PERFORMANCE_SECURITY_AUDIT.md)
- [UAT_CHECKLIST.md](./UAT_CHECKLIST.md)
- [PRODUCT_BACKLOG.md](./PRODUCT_BACKLOG.md)
- [RISK_REGISTER.md](./RISK_REGISTER.md)
- [RELEASE_HANDOFF.md](./RELEASE_HANDOFF.md)
