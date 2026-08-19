# Báo cáo tổng quan ứng dụng — Mobile GIS Cẩm Phả (`campha_moblie`)

**Ngày lập:** 2026-08-18
**Phạm vi:** toàn bộ source mobile trong `campha_moblie`, tài liệu `docs/mobile`, cấu hình build Android/iOS.

---

## 1. Giới thiệu

`campha_moblie` là ứng dụng **MobileGIS** phục vụ quản lý bản đồ và tác nghiệp hiện trường của
thành phố Cẩm Phả. Sản phẩm theo định hướng **map-first**: mở app là thấy bản đồ, không ép đăng
nhập sớm, và mọi thao tác nâng cao được mở dần theo quyền do server cấp.

Đối tượng sử dụng gồm 6 vai trò: `guest`, `citizen`, `ubnd_tp`, `so_tnmt`, `so_xd`, `system_admin`.

**Giá trị cốt lõi**
- Người dân và cơ quan đọc **cùng một nguồn dữ liệu không gian**.
- Thu thập bằng chứng hiện trường (GPS, ảnh, hình học) kể cả khi mạng gián đoạn.
- Sửa dữ liệu gốc an toàn: có optimistic concurrency, lịch sử phiên bản và khôi phục.

---

## 2. Công nghệ và kiến trúc

| Hạng mục | Lựa chọn |
|---|---|
| Framework | Flutter, Dart SDK `^3.11.4` |
| State / DI | `flutter_riverpod` 2.6 (provider viết tay, **không** code-gen) |
| Điều hướng | `go_router` 14.6 với `StatefulShellRoute.indexedStack` |
| Network | `dio` 5.7 + 3 interceptor (auth, idempotent-retry, logging) |
| Bản đồ | `mapbox_maps_flutter` 2.28 (vector MVT + raster tile theo ticket) |
| Lưu trữ | `sqflite`, `shared_preferences`, `flutter_secure_storage` |
| Nền tảng phụ trợ | Firebase Core / Crashlytics / Messaging, local notifications |
| Khác | `geolocator`, `image_picker`, `share_plus`, `url_launcher`, `intl` |

**Kiến trúc:** feature-first, mỗi feature chia 3 lớp `data / domain / presentation`; hạ tầng dùng
chung nằm ở `lib/core` (error, network, storage, permissions, push, paginated, location, utils) và
`lib/app` (router, theme, locale).

**Quy mô mã nguồn:** 99 file Dart, ~23.700 dòng (bao gồm ~4.400 dòng l10n sinh tự động).

```
lib/
├── app/        router · theme · locale
├── core/       network · storage · error · permissions · push · paginated
├── features/   auth · map · cms · field_reports · feature_edit · routing · tools · profile · offline_sync
└── l10n/       vi (mặc định) + en
```

---

## 3. Chức năng chính

### 3.1 Xác thực & phiên
Đăng ký, đăng nhập (kể cả Google mobile / OAuth exchange), quên mật khẩu, đổi mật khẩu bắt buộc
(`mustChangePassword`), xác minh email, refresh token. Token nằm trong secure storage; khi đăng
xuất, toàn bộ draft, media chờ, GPS, hàng đợi offline và state màn hình được purge.

### 3.2 Bản đồ (trung tâm sản phẩm)
- Danh mục lớp, chọn basemap, chú giải (legend), tìm kiếm feature, xem chi tiết thuộc tính.
- Tile vector MVT `/mobile/layers/{id}/tiles/{z}/{x}/{y}.mvt`; lớp không công khai phải xin
  **tile-ticket** trước khi lấy raster tile.
- Định vị GPS, đo đạc (`/mobile/measure`), tìm đường ngắn nhất (`/mobile/routes/shortest`),
  thời tiết tại vị trí.

### 3.3 Chỉnh sửa feature (riêng `so_tnmt`)
Sửa thuộc tính/hình học feature gốc, xem **lịch sử phiên bản**, **restore** về phiên bản cũ, và
màn hình **đồng bộ thay đổi offline** với hàng đợi cục bộ (`offline_edit_queue`). Route được chặn
hai lớp: theo `roleCode` và theo permission `map_feature.update`.

### 3.4 Phản ánh hiện trường
Tạo phản ánh kèm mô tả, vị trí GPS, ảnh, xác nhận trung thực; xem phản ánh công khai, phản ánh
gần vị trí, và "phản ánh của tôi". Draft được lưu bền, có generation guard chống hồi sinh dữ liệu
sau khi đăng xuất.

### 3.5 Nội dung (CMS)
Tin tức + bình luận, tài liệu, bản đồ PDF. Tệp tải qua **signed URL chỉ lấy khi người dùng bấm**,
không cache/persist, tự refresh tối đa một lần khi grant sắp hết hạn.

### 3.6 Khác
Hồ sơ cá nhân, đa ngôn ngữ vi/en, theme sáng/tối, push notification (đăng ký/hủy device token).

---

## 4. Phân quyền

Nguyên tắc: **JWT xác định actor, `/auth/me.role.permissions` quyết định khả năng**; backend là
thẩm quyền cuối; permission thiếu/không rõ ⇒ **mặc định từ chối** với hành động ghi hoặc nhạy cảm.
Ma trận đầy đủ 30 capability × 6 role nằm ở `docs/mobile/RBAC_MATRIX.md`.

Điểm đáng lưu ý: `system_admin` **không** mặc định được duyệt phản ánh hay sửa feature — chỉ khi
server thực sự cấp quyền.

---

## 5. Chất lượng và bảo mật

### Đã đạt (chốt ngày 2026-08-11)
| Cổng kiểm | Kết quả |
|---|---|
| `dart format` | PASS — 0 thay đổi |
| `flutter analyze` | PASS — không có issue |
| `flutter test` | PASS — 63/63 |
| Android debug split-per-abi | arm32 87.5 MiB · arm64 114.0 MiB · x86_64 102.2 MiB |
| Staging profile build | 111.92 MiB, có SHA-256 |
| Quét bí mật trong artifact | PASS — không có `.env`, seed key, Bearer literal |

**Hardening đã làm:** gỡ credential fallback và `.env` đóng gói; chặn URL scheme lạ do server trả
về (chỉ HTTPS ở profile/release); Firebase khởi tạo lười, ra khỏi critical path first-frame; bundle
font Be Vietnam Pro cục bộ và gỡ Material Symbols (~16 MiB nén); retry chỉ áp dụng cho GET
transient tối đa 1 lần, POST/PATCH/multipart không retry; typed error mapping phủ 400/401/403/404/
409/413/422/429/500/502/503 kèm `Retry-After`.

**Hiệu năng đo trên emulator:** cold start median 1.735 s (baseline 2.270 s); điều hướng
p50/p90/p95/p99 = 5/15/16/18 ms.

### Rủi ro và hạn chế còn mở
1. **Chưa đạt Production RC.** Quyết định chính thức là *code closure PASS, production RC NOT DONE*.
2. **UAT theo vai trò bị chặn** — thiếu credential/fixture thật cho môi trường release.
3. **UAT riêng tư A→B chưa chạy** — cần hai tài khoản thật để kiểm rò rỉ state sau logout/login.
4. **Firebase Android/iOS chưa có resource theo flavor** và chưa có evidence trên máy thật.
5. **HTTPS production + signing** chưa có; chưa có AAB đã ký.
6. **Đo hiệu năng mới ở emulator**; 2/5 lần cold start còn skip frame — gate máy thật vẫn mở.
7. **Kích thước gói lớn** (arm64 debug 114 MiB) do native lib Mapbox; bắt buộc `--split-per-abi`.
8. **Độ phủ test lệch về model/logic** — màn hình lớn nhất (`map_home_screen.dart` 1.322 dòng,
   `field_reports_screen.dart` 1.229 dòng) chưa có widget test tương xứng.
9. `README.md` vẫn là template mặc định của Flutter.

---

## 6. Khuyến nghị

**Ưu tiên cao (chặn phát hành)**
- Ops cấp endpoint production, signing material, Firebase resource theo flavor → dựng AAB đã ký.
- PO/QA cấp bộ tài khoản 5 vai trò để chạy role UAT và kịch bản riêng tư A→B.
- Chạy lại đo cold start/navigation trên máy Android tầm trung thật, đóng gate hiệu năng.

**Ưu tiên trung bình**
- Bổ sung widget/integration test cho màn hình bản đồ và luồng tạo phản ánh.
- Tách nhỏ hai màn hình >1.000 dòng thành widget con để dễ test và bảo trì.
- Viết lại `README.md`: cách chạy, biến môi trường, lệnh build split-per-abi.

**Ưu tiên thấp**
- Rà lại kích thước gói sau khi bật R8 (giữ rule `Signature` cho Gson/local notifications).
- Tự động hóa các cổng kiểm (format/analyze/test/scan bí mật) trong CI.

---

## 7. Kết luận

Ứng dụng đã hoàn chỉnh về mặt sản phẩm và mã nguồn: đủ luồng cho cả 6 vai trò, kiến trúc rõ ràng,
tài liệu Scrum/traceability đầy đủ, và đã qua một đợt hardening bảo mật – hiệu năng nghiêm túc với
63/63 test xanh. Phần còn thiếu **không nằm ở code** mà ở hạ tầng phát hành: credential UAT, tài
nguyên Firebase, endpoint HTTPS và vật liệu ký. Khi Ops và PO/QA cung cấp đủ các mục này, sản phẩm
có thể chuyển sang Release Candidate mà không cần thay đổi kiến trúc.
