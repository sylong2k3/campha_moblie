# Prompt triển khai Mobile GIS Cẩm Phả theo Agile Scrum

Sao chép toàn bộ nội dung từ **BẮT ĐẦU PROMPT** đến **KẾT THÚC PROMPT** và gửi cho AI coding agent triển khai dự án.

---

# BẮT ĐẦU PROMPT

## 1. Vai trò

Bạn là nhóm phát triển sản phẩm Mobile GIS cấp senior, làm việc theo Agile Scrum. Bạn đồng thời đảm nhiệm:

- Product Analyst: phân tích yêu cầu và viết Acceptance Criteria.
- Scrum Master: quản lý Sprint Goal, Sprint Backlog, impediment và Sprint Review.
- UX/UI Designer: thiết kế luồng, màn hình, trạng thái và khả năng tiếp cận.
- Flutter Engineer: triển khai ứng dụng Android/iOS.
- GIS Engineer: MVT, WMS, GeoJSON, GPS, đo đạc, pgRouting và biên tập geometry.
- QA Engineer: unit, widget, integration, API contract và UAT.
- Security Reviewer: JWT, RBAC, secure storage, PII, tải file và quyền vị trí/camera.

Mục tiêu: hoàn thiện ứng dụng **Mobile GIS thành phố Cẩm Phả** bằng Flutter, kết nối đúng với Backend `server-campha`, có giao diện hoàn chỉnh, chạy được trên thiết bị thật, không dừng ở model/repository hoặc placeholder.

Ngôn ngữ giao diện chính: **Tiếng Việt**. Hỗ trợ thêm tiếng Anh bằng cơ chế localization hiện có.

---

## 2. Repository và nguồn sự thật

### Mobile Flutter

```text
C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie
```

### Backend Node.js/PostgreSQL/PostGIS

```text
C:/Users/SunSun/Documents/DuAN_20226/campha/server-campha
```

### File phải đọc trước khi thiết kế hoặc sửa code

```text
campha_moblie/pubspec.yaml
campha_moblie/lib/main.dart
campha_moblie/lib/app/router/app_router.dart
campha_moblie/lib/app/router/route_names.dart
campha_moblie/lib/app/theme/app_colors.dart
campha_moblie/lib/app/theme/app_theme.dart
campha_moblie/lib/core/network/api_config.dart
campha_moblie/lib/core/network/api_endpoints.dart
campha_moblie/lib/core/network/dio_client.dart
campha_moblie/lib/core/storage/token_storage.dart
campha_moblie/lib/core/permissions/user_role.dart
server-campha/src/routes/index.js
server-campha/src/routes/auth.routes.js
server-campha/src/routes/web-map.routes.js
server-campha/src/routes/mobile-gis.routes.js
server-campha/src/routes/field-report.routes.js
server-campha/src/routes/cms.routes.js
server-campha/src/validators/auth.validator.js
server-campha/src/validators/web-map.validator.js
server-campha/src/validators/mobile-gis.validator.js
server-campha/src/validators/field-report.validator.js
server-campha/src/validators/cms.validator.js
server-campha/docs/MA_TRAN_PHAN_QUYEN.csv
```

Backend route, validator, controller, serializer và test hiện hành là nguồn sự thật. Không suy đoán payload chỉ từ tên endpoint.

---

## 3. Công nghệ bắt buộc

Tận dụng stack đã cài:

- Flutter và Dart.
- Material 3.
- `flutter_riverpod`, provider viết tay; không dùng code generation.
- `go_router` cho navigation và deep link.
- `dio` singleton từ `dioProvider`.
- `flutter_secure_storage` thông qua `TokenStorage`; không tạo kho token thứ hai.
- `sqflite` cho hàng đợi offline.
- `geolocator` cho GPS.
- Firebase Messaging, Crashlytics và local notifications theo cấu hình hiện có.
- `intl` và Flutter localization.
- Typography `Be Vietnam Pro` qua `google_fonts`.

Không thêm package khi SDK hoặc dependency hiện có giải quyết được. Nếu phải thêm map renderer, image picker/camera, connectivity hoặc PDF viewer:

1. Chứng minh chức năng chưa có trong stack hiện tại.
2. Kiểm tra phiên bản tương thích với Flutter/Dart hiện tại.
3. Ghi ADR ngắn nêu lý do chọn.
4. Chỉ thêm dependency tối thiểu.

### Map renderer spike bắt buộc trong Sprint 0

So sánh trước khi chọn:

- `mapbox_maps_flutter`: phù hợp cấu hình `MAPBOX_TOKEN` và `MAPBOX_STYLE_*` hiện có.
- `flutter_map` + renderer MVT phù hợp: ưu tiên nếu cần tự gắn Authorization header, kiểm soát cache/offline hoặc không có Mapbox token.

Tiêu chí quyết định:

- Render MVT từ `/api/v1/mobile/layers/:layerId/tiles/:z/:x/:y.mvt`.
- Truyền JWT cho layer riêng tư.
- Hiển thị GeoJSON overlay cho route, đo đạc, draft và feature edit.
- Dark mode.
- Hiệu năng pan/zoom trên Android tầm trung.
- Offline cache theo phạm vi cho phép.
- Chi phí và điều khoản giấy phép.

Không gọi Mapbox Directions làm nguồn tìm đường chính. Tuyến đường nghiệp vụ phải dùng Backend `POST /api/v1/mobile/routes/shortest` để giữ một nguồn dữ liệu pgRouting thống nhất.

---

## 4. Nguyên tắc không thương lượng

1. Không tạo endpoint giả.
2. Không dùng mock data trong bản build nghiệm thu.
3. Không hard-code token, mật khẩu, API URL hoặc Mapbox token.
4. Không log JWT, refresh token, ảnh, số điện thoại hoặc dữ liệu vị trí chính xác.
5. Server là nơi quyết định quyền cuối cùng; UI role gate chỉ giúp UX.
6. Không gọi một feature “hoàn thành” nếu mới có model/repository nhưng chưa có:
   - Màn hình truy cập được qua router.
   - State loading/empty/error/offline.
   - Tương tác API thật.
   - Test phù hợp.
   - Bằng chứng chạy trên emulator hoặc thiết bị.
7. Không để `HomePlaceholderScreen` trong luồng sản phẩm cuối.
8. Không dùng nút chết, màn rỗng hoặc placeholder.
9. Không nuốt lỗi bằng `catch (_)`. Chuyển lỗi sang `AppException`, thông báo thân thiện và log kỹ thuật không chứa bí mật.
10. Không nhân đôi Token Storage. `AuthRepository`, `AuthInterceptor` và router guard phải dùng cùng `TokenStorage`.
11. Không sửa backend để che lỗi mobile nếu API hiện hành đã đúng hợp đồng.
12. Tất cả form phải validate phía client, nhưng không thay thế validation server.
13. Tất cả thao tác ghi phải chống double-submit; dùng idempotency nếu Backend hỗ trợ.
14. Tất cả danh sách phải có pagination/infinite scroll đúng API.
15. Tất cả màn hình phải hỗ trợ light/dark theme và tiếng Việt/Anh.

### Contract audit bắt buộc cho code hiện có

Kiểm tra và sửa trước khi xây UI. Một số điểm có nguy cơ đang sai hợp đồng:

- Draft Backend nhận `title`, `properties`, `geometry`; không tự gửi `geometryType` hoặc `attributes` nếu validator không nhận.
- Routing Backend nhận `layerId`, `start`, `end`, `snapRadiusMeters`, `maxDistanceMeters`.
- Feature update/restore dùng `baseVersion`, không tự đổi thành `expectedVersion`.
- Offline sync cần `clientId` UUID và từng change cần `clientChangeId` UUID.
- Field report create nhận `description`, `longitude`, `latitude`, `measuredGeometry`, `photoIds`.
- Push token nhận `token`, `platform`.
- Nearby report bắt buộc có `longitude`, `latitude`, `radiusMeters`, `from`, `to`.
- Xóa draft/report cần optimistic-lock query theo validator hiện hành.
- CMS list response có thể là envelope phân trang; không ép `data` thành `List` trước khi đọc serializer/controller.
- Auth phải lưu access/refresh token qua `TokenStorage`, để `AuthInterceptor` đọc được ngay.

Đối chiếu toàn bộ route + validator + controller + response serializer trước khi chốt DTO.

---

## 5. Product Goal

Người dùng có thể mở Mobile GIS Cẩm Phả để:

1. Xem, bật/tắt, phóng to/thu nhỏ và truy vấn lớp bản đồ.
2. Xác định vị trí GPS và xem thời tiết tại vị trí.
3. Tìm đường ngắn nhất giữa hai điểm.
4. Đo chiều dài/diện tích.
5. Vẽ điểm, đường, vùng và quản lý bản nháp.
6. Cán bộ Sở TNMT sửa thuộc tính/geometry, xem lịch sử và khôi phục phiên bản.
7. Gửi phản ánh hiện trường kèm ảnh, GPS, thời gian và geometry đo tương đối.
8. Đăng nhập; khách đăng ký tài khoản người dân.
9. Đọc, tìm kiếm và bình luận tin tức.
10. Đọc/tìm kiếm/tải văn bản, báo cáo và bản đồ PDF theo quyền.
11. Làm việc gián đoạn mạng và đồng bộ an toàn khi có mạng lại.
12. Nhận push notification theo quyền và trạng thái phản ánh.

---

## 6. Vai trò và quyền

Dùng đúng role code Backend, không dùng tên role cũ:

- `guest`: khách chưa đăng nhập.
- `citizen`: người dân.
- `ubnd_tp`: UBND.
- `so_tnmt`: Sở TNMT.
- `so_xd`: Sở Xây dựng.
- `system_admin`: quản trị hệ thống.

Quyền chính theo `MA_TRAN_PHAN_QUYEN.csv`:

| Chức năng | guest | citizen | ubnd_tp | so_tnmt | so_xd | system_admin |
|---|---:|---:|---:|---:|---:|---:|
| Xem bản đồ, GPS, đo, route, weather | Có | Có | Có | Có | Có | Có |
| Vẽ/lưu draft | Không | Có | Có | Có | Có | Có |
| Sửa feature gốc | Không | Không | Không | Có | Không | Theo server |
| Gửi phản ánh | Không | Có | Có | Có | Có | Theo server |
| Đọc/tìm tin công khai | Có | Có | Có | Có | Có | Có |
| Bình luận tin | Không | Có | Có | Có | Có | Có |
| Đăng ký | Có | Không | Không | Không | Không | Không |
| Văn bản công khai | Có | Có | Có | Có | Có | Có |
| Văn bản nội bộ | Không | Không | Có | Có | Có | Có |

Nếu quyền thật trả từ `/auth/me` khác bảng trên, server và permission payload hiện hành thắng. Ghi discrepancy vào API Contract Audit.

---

## 7. Quy trình Agile Scrum

### Nhịp Sprint

- Sprint dài 2 tuần.
- Daily Scrum: cập nhật Done / Next / Blocker ngắn gọn.
- Backlog Refinement: giữa Sprint.
- Sprint Review: demo vertical slice chạy thật.
- Sprint Retrospective: giữ, bỏ, thử trong Sprint sau.

### Scrum artifacts phải duy trì

Tạo trong `campha_moblie/docs/mobile/`:

```text
PRODUCT_VISION.md
PRODUCT_BACKLOG.md
RELEASE_PLAN.md
SCREEN_SPEC.md
API_CONTRACT_AUDIT.md
RBAC_MATRIX.md
DECISION_LOG.md
RISK_REGISTER.md
SPRINTS/SPRINT_00.md
SPRINTS/SPRINT_01.md
...
UAT_CHECKLIST.md
```

### Definition of Ready

Story chỉ được đưa vào Sprint khi:

- Persona và giá trị người dùng rõ.
- Acceptance Criteria viết dạng Given/When/Then.
- Endpoint và payload đã đối chiếu code Backend.
- Thiết kế màn và trạng thái đã chốt.
- Dependency và rủi ro đã xác định.
- Story đủ nhỏ để hoàn thành trong một Sprint.

### Definition of Done

Story chỉ Done khi:

- Code theo kiến trúc hiện có, không duplication.
- Màn hình kết nối router và dùng được.
- Loading, empty, error, retry, offline, permission-denied đầy đủ.
- API thật hoạt động hoặc có bằng chứng Backend blocker.
- Unit/widget test đạt.
- `dart format`, `flutter analyze`, `flutter test` đạt.
- Không lộ secret/PII trong log.
- Accessibility label và touch target đạt.
- Demo trên emulator/thiết bị có ảnh hoặc video.
- Acceptance Criteria đạt và Product Owner duyệt.

### Chu trình thực hiện mỗi Sprint

1. Đọc Sprint Goal và chọn stories theo capacity.
2. Tách story thành task UI, domain, data, test và API verification.
3. Thiết kế wireframe/component states trước code.
4. Làm vertical slice nhỏ nhất chạy xuyên UI → API → state → test.
5. Chạy static analysis và test sau từng slice.
6. Demo luồng thật ở Sprint Review.
7. Ghi bug/blocker; không đổi scope âm thầm.
8. Retro và cập nhật backlog.

---

## 8. Release plan và Product Backlog ưu tiên

### Sprint 0 — Discovery, Contract Audit và UX Foundation — 20 SP

**Sprint Goal:** chốt kiến trúc, hợp đồng API và hệ thống thiết kế trước khi xây feature.

- `MOB-001` Audit code mobile hiện có và phân loại: dùng được / sai contract / thiếu UI / cần xóa. 5 SP.
- `MOB-002` Audit tất cả API Mobile/Auth/CMS/Field Report bằng route + validator + live smoke. 5 SP.
- `MOB-003` Map renderer spike và ADR. 5 SP.
- `MOB-004` Hoàn thiện Screen Spec, navigation map, design tokens và component inventory. 5 SP.

**Exit criteria:** không còn endpoint/payload chưa rõ; map proof-of-concept render được basemap + một MVT layer thật.

### Sprint 1 — Auth, App Shell và Profile — 34 SP

**Sprint Goal:** người dùng vào ứng dụng, đăng nhập/đăng ký và điều hướng theo vai trò.

- `MOB-101` Splash/bootstrap session. 3 SP.
- `MOB-102` Đăng nhập + lỗi credential + khóa tài khoản + password-change flow. 8 SP.
- `MOB-103` Đăng ký citizen + xác nhận email nếu server yêu cầu. 8 SP.
- `MOB-104` Refresh token dùng chung `TokenStorage` + router guard. 8 SP.
- `MOB-105` Main shell 5 tab + profile/settings/theme/language. 7 SP.

**Exit criteria:** cold start phục hồi phiên; logout xóa token; guest/auth deep link đúng; không có placeholder home.

### Sprint 2 — Tin tức, Bình luận, Văn bản và Bản đồ PDF — 36 SP

**Sprint Goal:** cung cấp nội dung CMS hoàn chỉnh trên mobile.

- `MOB-201` Danh sách/tìm kiếm/phân trang tin tức. 5 SP.
- `MOB-202` Chi tiết tin tức, chia sẻ deep link. 5 SP.
- `MOB-203` Danh sách bình luận + gửi bình luận khi đăng nhập. 8 SP.
- `MOB-204` Danh sách/tìm kiếm văn bản công khai/nội bộ theo quyền. 5 SP.
- `MOB-205` Chi tiết văn bản + presigned download + mở/chia sẻ file. 8 SP.
- `MOB-206` Danh sách/chi tiết/tải bản đồ PDF. 5 SP.

**Exit criteria:** guest đọc được nội dung công khai; citizen bình luận; role nội bộ xem đúng nội dung; link hết hạn được xin lại.

### Sprint 3 — Map Explorer Core — 40 SP

**Sprint Goal:** xem bản đồ Cẩm Phả ổn định và truy vấn feature.

- `MOB-301` Map shell, basemap, camera bounds Cẩm Phả. 8 SP.
- `MOB-302` Layer catalog, nhóm layer, bật/tắt, opacity, legend. 8 SP.
- `MOB-303` Render MVT backend + auth cho layer riêng tư. 13 SP.
- `MOB-304` Tap feature → feature info sheet. 5 SP.
- `MOB-305` Search feature theo tên và zoom tới kết quả. 6 SP.

**Exit criteria:** layer `ranhgioi_campha` hiển thị thật; toggle/zoom/tap/search hoạt động; không lag nghiêm trọng.

### Sprint 4 — GPS, Weather, Measure, Route và Draft — 40 SP

**Sprint Goal:** hoàn thiện công cụ GIS hiện trường cho mọi đối tượng được phép.

- `MOB-401` GPS permission + current location + accuracy indicator. 5 SP.
- `MOB-402` Weather tại vị trí. 3 SP.
- `MOB-403` Nearby features. 5 SP.
- `MOB-404` Đo LineString/Polygon qua Backend. 8 SP.
- `MOB-405` Tìm đường pgRouting, chọn điểm đầu/cuối, hiển thị route. 8 SP.
- `MOB-406` Vẽ/lưu/xem/xóa draft Point/LineString/Polygon. 11 SP.

**Exit criteria:** mỗi tool có mode rõ, undo/redo/cancel/save; không xung đột gesture map.

### Sprint 5 — Giám sát hiện trạng — 36 SP

**Sprint Goal:** gửi và theo dõi bằng chứng hiện trường đầy đủ.

- `MOB-501` Danh sách/map phản ánh công khai và nearby có time range. 5 SP.
- `MOB-502` Form phản ánh đa bước: ảnh, mô tả, GPS, geometry đo tương đối. 13 SP.
- `MOB-503` Upload ảnh theo storage presign/commit đúng Backend. 8 SP.
- `MOB-504` Phản ánh của tôi, chi tiết và trạng thái xử lý. 5 SP.
- `MOB-505` Push token và notification deep link. 5 SP.

**Exit criteria:** gửi phản ánh thật với ảnh + GPS; mất mạng không mất dữ liệu đang nhập; push mở đúng report.

### Sprint 6 — TNMT Feature Edit và Offline Sync — 40 SP

**Sprint Goal:** cán bộ TNMT chỉnh sửa an toàn và đồng bộ công việc gián đoạn mạng.

- `MOB-601` Role-gated feature attribute editor. 8 SP.
- `MOB-602` Geometry edit với topology/client validation. 8 SP.
- `MOB-603` Lịch sử phiên bản và restore. 5 SP.
- `MOB-604` Local change queue Sqflite + UUID client/change. 8 SP.
- `MOB-605` Sync, conflict compare và lựa chọn xử lý. 11 SP.

**Exit criteria:** chỉ `so_tnmt` thấy edit; server vẫn chặn role khác; conflict không ghi đè im lặng.

### Sprint 7 — Hardening, UAT và Release Candidate — 30 SP

**Sprint Goal:** đạt chất lượng nghiệm thu Android/iOS.

- `MOB-701` Accessibility, localization, dark mode. 5 SP.
- `MOB-702` Performance map/list/image và memory profiling. 5 SP.
- `MOB-703` Security review và privacy permission copy. 5 SP.
- `MOB-704` Full regression + API acceptance + device matrix. 8 SP.
- `MOB-705` Crash-free smoke, release config và handoff. 7 SP.

**Exit criteria:** mọi checklist UAT đạt; không lỗi analyze/test; không placeholder/dead-end; có recording các luồng chính.

---

## 9. User stories và Acceptance Criteria cốt lõi

### US-MAP-01 — Xem và điều khiển lớp bản đồ

**As a** người dùng, **I want** bật/tắt các lớp GIS **so that** xem thông tin phù hợp nhu cầu.

- Given catalog tải thành công, when mở sheet Lớp dữ liệu, then thấy layer theo nhóm, trạng thái visibility và legend.
- When bật `ranhgioi_campha`, then MVT hiển thị đúng camera Cẩm Phả.
- When layer bị từ chối quyền, then không rò tên/metadata riêng tư và hiển thị thông báo phù hợp.
- Visibility và opacity được giữ trong phiên hiện tại.

### US-MAP-02 — Truy vấn đối tượng

- Given một layer đang bật, when chạm feature, then mở bottom sheet tên layer, thuộc tính được phép và hành động liên quan.
- Không hiển thị field không có trong allowlist Backend.
- Sheet có loading skeleton, retry và empty state.

### US-MAP-03 — GPS và Nearby

- Hỏi quyền vị trí đúng lúc, giải thích mục đích trước system dialog.
- Khi cấp quyền, map animate tới vị trí và hiển thị accuracy circle.
- Nếu accuracy vượt ngưỡng, cảnh báo “Độ chính xác thấp”, không giả định GPS chuẩn.
- Nếu từ chối vĩnh viễn, có nút mở Settings.

### US-MAP-04 — Đo đạc

- LineString tối thiểu 2 điểm; Polygon tối thiểu 4 điểm và khép kín trước submit.
- Preview cập nhật trong lúc vẽ; kết quả chính thức lấy từ `/mobile/measure`.
- Hiển thị đơn vị m/km hoặc m²/ha theo độ lớn.
- Undo, redo, clear và cancel không làm mất map state.

### US-MAP-05 — Tìm đường

- Chọn start/end bằng tap map, GPS hoặc search result.
- Gửi đúng `start`, `end`, `layerId` và bounds Cẩm Phả.
- Hiển thị route GeoJSON, tổng chiều dài và trạng thái không tìm thấy đường.
- Đổi start/end không tạo request chồng; hủy request cũ.

### US-DRAFT-01 — Vẽ bản nháp

- Guest được vẽ tạm nhưng khi lưu phải đăng nhập.
- Geometry hợp lệ với validator Backend.
- Save gửi `title`, `properties`, `geometry`.
- Xóa draft gửi đúng optimistic-lock query.

### US-EDIT-01 — Sửa feature gốc

- Chỉ `so_tnmt` nhìn thấy hành động “Chỉnh sửa”.
- Update gửi `baseVersion`; khi conflict 409, hiển thị bản local và server, không tự ghi đè.
- Restore yêu cầu confirm và gửi audit reason nếu Backend hỗ trợ.

### US-REPORT-01 — Gửi phản ánh hiện trường

- Người dùng thêm tối đa 5 ảnh, mô tả 10–2000 ký tự, vị trí trong bounds Cẩm Phả.
- Ảnh phải upload/commit thành công trước create report.
- Payload dùng `description`, `longitude`, `latitude`, `photoIds`, optional `measuredGeometry`.
- Double tap không tạo report trùng.
- Nếu offline, lưu draft local và thông báo rõ chưa gửi.

### US-NEWS-01 — Tin tức

- Guest và mọi role đọc/tìm/phân trang tin công khai.
- Search debounce 350–500 ms; query tối đa 100 ký tự.
- Chi tiết render nội dung an toàn, không chạy script hoặc HTML nguy hiểm.
- Người đã đăng nhập xem/gửi comment; guest bấm bình luận được chuyển login rồi quay lại bài.

### US-DOC-01 — Văn bản, báo cáo

- Guest/citizen thấy public; UBND/TNMT/XD/Admin thấy nội dung được server cấp.
- Search theo tiêu đề/mã số bằng `q`.
- Download URL hết hạn phải được lấy lại, không lưu lâu dài trong DB local.
- File mở bằng viewer phù hợp hoặc ứng dụng hệ thống; báo lỗi rõ nếu không hỗ trợ.

### US-AUTH-01 — Đăng nhập/đăng ký

- Login validate email/password; lỗi 401 không tiết lộ tài khoản có tồn tại.
- Register chỉ dành guest, gồm full name, email, phone optional, password và xác nhận password.
- Password ít nhất 8 ký tự theo validator hiện hành.
- Token lưu qua một `TokenStorage`; refresh đồng bộ tránh nhiều request refresh song song.

---

## 10. Information Architecture và navigation

Dùng `StatefulShellRoute.indexedStack` để giữ state các tab.

### Bottom Navigation — 5 tab

1. **Bản đồ** — icon map.
2. **Hiện trường** — icon report/location.
3. **Tin tức** — icon newspaper.
4. **Tài liệu** — icon description.
5. **Cá nhân** — icon person.

### Route map đề xuất

```text
/splash
/auth/login
/auth/register
/auth/forgot-password
/auth/change-password
/map
/map/search
/map/drafts
/map/feature/:layerId/:featureId
/map/feature/:layerId/:featureId/history
/reports
/reports/new
/reports/mine
/reports/:id
/news
/news/:id
/documents
/documents/:id
/pdf-maps/:id
/profile
/profile/offline-queue
/profile/settings
```

Deep link phải giữ `returnTo` để sau đăng nhập quay lại đúng news/report/feature.

---

## 11. Hệ thống thiết kế

### Visual direction

Phong cách: **civic GIS premium**, sạch, tin cậy, map-first, không giống dashboard template chung chung.

Dùng token hiện có:

- Primary forest: `#214E43`.
- Secondary moss: `#4A6B5D`.
- Accent clay: `#C47745`.
- Background light: `#F4F6F5`.
- Surface: `#FFFFFF`.
- Text primary: `#14211D`.
- Error: `#B6534D`.
- Font: Be Vietnam Pro.

### Quy tắc layout

- Grid 4/8dp.
- Padding màn 16dp; section 24dp.
- Touch target tối thiểu 48×48dp.
- Card radius 14–16dp.
- Bottom sheet top radius 20dp.
- Modal full-screen trên thiết bị nhỏ khi bàn phím hoặc map tool cần không gian.
- Không dùng shadow dày; dùng border + elevation nhẹ.
- Animation 160–240ms; tôn trọng reduce motion.
- Dữ liệu GIS luôn nổi hơn trang trí.

### Components dùng chung

- `AppScaffold`.
- `AsyncStateView` cho loading/error/empty/content.
- `AppSearchBar` có debounce và clear.
- `PermissionPrimer`.
- `StatusChip`.
- `MapActionButton`.
- `MapToolDock`.
- `LayerRow`.
- `FeatureAttributeTable`.
- `OfflineBanner`.
- `SyncStatusBadge`.
- `ConfirmActionSheet`.
- `PagedListView`.

Không tạo abstraction nếu chỉ một màn dùng.

---

## 12. Thiết kế chi tiết từng màn hình

### M01 — Splash và Bootstrap

**Route:** `/splash`

**Mục tiêu:** khởi tạo Firebase, env, token/session, locale và theme.

**Thiết kế:**

- Nền gradient rất nhẹ từ forest sang moss.
- Biểu tượng đường đồng mức + ghim vị trí Cẩm Phả, không dùng logo giả.
- Tên “Mobile GIS Cẩm Phả”.
- Progress indicator nhỏ và phiên bản app ở đáy.

**Luồng:**

1. Đọc token từ `TokenStorage`.
2. Nếu có token, gọi `/auth/me`.
3. Hợp lệ: vào `/map`.
4. Không hợp lệ: clear token, vẫn vào `/map` dưới guest; chỉ chuyển login khi thao tác yêu cầu auth.
5. `mustChangePassword`: chuyển màn đổi mật khẩu.

**States:** initializing, offline with cached session, config error, retry.

---

### M02 — Đăng nhập

**Route:** `/auth/login`

**Layout:**

- App bar nút đóng/quay lại.
- Header nhỏ: biểu tượng GIS, “Chào mừng trở lại”.
- Email field.
- Password field có show/hide.
- “Quên mật khẩu?”.
- Primary button “Đăng nhập”.
- Divider và action Google Mobile nếu backend/config đã sẵn sàng.
- Footer “Chưa có tài khoản? Đăng ký”.

**Behavior:**

- Inline validation.
- Disable button khi submit.
- Error banner không làm layout nhảy mạnh.
- Giữ `returnTo`.
- Không ghi password vào log/state persistence.

---

### M03 — Đăng ký người dân

**Route:** `/auth/register`

**Layout:** form từng nhóm, không nhồi một card dài:

- Họ tên.
- Email.
- Số điện thoại optional.
- Mật khẩu.
- Xác nhận mật khẩu.
- Checkbox đồng ý điều khoản/chính sách dữ liệu vị trí.
- Button “Tạo tài khoản”.

**States:** validating, submitting, email-already-used, success/verify-email.

---

### M04 — Main Shell

**Route gốc:** shell chứa 5 tab.

**Thiết kế:**

- Material 3 NavigationBar.
- Badge chấm nhỏ ở Cá nhân khi có offline changes/push issue.
- Tab giữ scroll/map camera khi chuyển tab.
- Guest vẫn dùng nội dung công khai; hành động ghi mở auth sheet.

---

### M05 — Map Explorer

**Route:** `/map`

**Layout map-first:**

- Map full màn hình phía sau.
- Safe-area top:
  - Search pill “Tìm địa điểm hoặc đối tượng”.
  - Avatar/profile nhỏ hoặc login action.
- Cụm nút phải:
  - Compass/reset north.
  - GPS.
  - Zoom +/− nếu thiết bị cần.
  - Weather.
- Góc trái dưới: scale bar, attribution.
- Phía trên bottom nav:
  - FAB “Lớp dữ liệu”.
  - Tool dock mở Measure / Route / Draw.
- Offline banner nằm dưới search bar, không che map controls.

**Gestures:** pan, pinch zoom, rotate; single tap query; long press dùng theo tool mode.

**States:** map loading, style error, tile 401/403, no network with cache, low GPS accuracy.

---

### M06 — Layer Catalog Bottom Sheet

**Mở từ:** M05.

**Layout:**

- Drag handle.
- Header “Lớp dữ liệu” + count active.
- Search layer.
- Group accordion theo category.
- Mỗi row: icon geometry, tên, visibility switch, info, opacity khi active.
- Section “Bản đồ nền”.
- Link “Chú giải” mở legend.
- Nút “Tắt tất cả” chỉ khi có layer active.

**Behavior:** optimistic UI chỉ cho visibility local; tile error phải trả switch về trạng thái phù hợp.

---

### M07 — Feature Info Bottom Sheet

**Mở từ:** tap feature.

**Layout:**

- Tên layer + feature ID ngắn.
- Các thuộc tính dạng label/value, ưu tiên field thân thiện.
- Coordinate/geometry summary collapsible.
- Actions: “Tìm gần đây”, “Dẫn đường tới đây”, “Chia sẻ vị trí”.
- `so_tnmt`: thêm “Chỉnh sửa” và “Lịch sử”.

**States:** skeleton, no feature, forbidden, stale version.

---

### M08 — Tìm kiếm bản đồ

**Route:** `/map/search`

**Layout:**

- Search field autofocus.
- Recent searches local.
- Kết quả nhóm theo layer.
- Mỗi item: icon type, primary name, layer name, distance nếu có GPS.

**Action:** tap → đóng search, animate map tới geometry/bbox, mở Feature Info.

---

### M09 — Vị trí và Thời tiết

**Mở từ:** GPS/weather button.

**Thiết kế:** compact bottom sheet:

- Tọa độ làm tròn hợp lý.
- GPS accuracy và timestamp.
- Nhiệt độ, mưa, gió nếu API trả.
- “Tìm đối tượng trong 200m”.
- “Dùng làm điểm bắt đầu”.

Không hiển thị dữ liệu weather giả nếu provider lỗi.

---

### M10 — Chế độ Đo đạc

**Mở từ:** Tool Dock → Đo đạc.

**Overlay:**

- Top contextual bar “Đo khoảng cách” / “Đo diện tích”.
- Map crosshair hoặc tap-to-add vertices.
- Vertex markers rõ, line/polygon accent clay.
- Bottom result card: số điểm, preview, kết quả server.
- Actions: Undo, Redo, Xóa, Hoàn tất, Hủy.

Tự khép Polygon khi hoàn tất, nhưng phải cho user thấy segment đóng.

---

### M11 — Tìm đường

**Mở từ:** Tool Dock → Tìm đường.

**Bottom sheet:**

- Điểm đầu: “Vị trí của tôi”, tap map hoặc search.
- Điểm cuối: tap map, feature hoặc search.
- Swap button.
- Chọn mạng đường/layer nếu API cần `layerId`.
- Button “Tìm đường”.

**Kết quả:**

- Route line rõ tương phản.
- Card tổng chiều dài, start/end, “Xóa tuyến”.
- No route state đề nghị tăng snap radius trong giới hạn cho phép.

---

### M12 — Vẽ và Quản lý Draft

**Route danh sách:** `/map/drafts`

**Draw mode:**

- Chọn Point / Line / Polygon.
- Vertex toolbar giống Measure.
- Sau hoàn tất mở form: tiêu đề, thuộc tính key/value tối đa theo server.
- Guest: cho preview nhưng khi Save mở login, sau login phục hồi geometry.

**Danh sách Draft:**

- Search local/server.
- Geometry icon, title, updated time.
- Actions: zoom to, edit, delete.
- Delete confirm + optimistic-lock.

---

### M13 — Feature Editor dành cho TNMT

**Route:** `/map/feature/:layerId/:featureId/edit`

**Guard:** chỉ `so_tnmt`; server vẫn kiểm quyền.

**Thiết kế hai bước:**

1. Thuộc tính: form sinh từ field metadata/allowlist; không cho sửa ID/geom nội bộ.
2. Geometry: kéo vertex, thêm/xóa vertex, undo/redo, preview validity.

**Footer:** version hiện tại, “Hủy”, “Lưu thay đổi”.

**Conflict 409:** mở compare sheet, hiển thị server/local; lựa chọn tải bản server hoặc giữ local thành draft. Không có “force overwrite” nếu Backend không hỗ trợ.

---

### M14 — Lịch sử và Restore Feature

**Route:** `/map/feature/:layerId/:featureId/history`

**Layout:** timeline phiên bản, người sửa, thời gian, field changed.

- Tap version xem preview thuộc tính/geometry.
- “Khôi phục phiên bản này” mở confirmation nêu rõ tạo version mới.
- Restore gửi `baseVersion` mới nhất.

---

### M15 — Danh sách/Map phản ánh hiện trường

**Route:** `/reports`

**Layout:**

- Header “Hiện trường”.
- Segmented control: Danh sách / Bản đồ.
- Filters: status, khoảng thời gian, gần tôi.
- Cards: thumbnail thật, trạng thái, khoảng cách, thời gian, mô tả 2 dòng.
- FAB “Gửi phản ánh”.

Guest xem public; action gửi yêu cầu đăng nhập.

---

### M16 — Tạo phản ánh hiện trường

**Route:** `/reports/new`

**Thiết kế stepper 3 bước:**

1. **Bằng chứng**
   - Chụp ảnh/chọn ảnh, tối đa 5.
   - Preview, xóa, retry upload.
   - Strip EXIF nhạy cảm nếu yêu cầu privacy; không giảm chất lượng quá mức.
2. **Vị trí và phạm vi**
   - GPS current location + accuracy.
   - Mini map cho điều chỉnh pin.
   - Optional đo Point/Line/Polygon tương đối.
3. **Mô tả và xác nhận**
   - Mô tả 10–2000 ký tự.
   - Summary ảnh, GPS, measured geometry.
   - Checkbox xác nhận thông tin trung thực.

**Submit:** upload/commit ảnh → nhận `photoIds` → create report. Progress phải phân biệt đang tải ảnh và đang gửi phản ánh.

---

### M17 — Phản ánh của tôi và Chi tiết

**Routes:** `/reports/mine`, `/reports/:id`

**Detail:**

- Status timeline.
- Ảnh carousel.
- Map location + measured geometry.
- Description.
- Created/updated time.
- Review reason nếu có.
- Delete chỉ khi Backend cho phép và gửi optimistic-lock query.

---

### M18 — Danh sách Tin tức

**Route:** `/news`

**Layout:**

- Header “Tin tức Cẩm Phả”.
- Search bar sticky.
- Featured card đầu nếu CMS có nội dung thật; không tự bịa featured.
- List card: ảnh thật hoặc category illustration đã được cung cấp, title, summary, publish time.
- Pull-to-refresh + infinite scroll.

**States:** skeleton cards, empty search, error/retry, offline cache indicator.

---

### M19 — Chi tiết Tin tức và Bình luận

**Route:** `/news/:id`

**Layout:**

- Title, metadata, cover.
- Nội dung readable, max width hợp lý trên tablet.
- Share action.
- Section Bình luận có pagination.
- Composer cố định gần cuối nội dung; guest thấy “Đăng nhập để bình luận”.

**Security:** render plain text/HTML sanitized đúng contract; không bật arbitrary WebView JS.

---

### M20 — Văn bản, Báo cáo và Bản đồ PDF

**Route:** `/documents`

**Layout:**

- Segmented tabs: “Văn bản & báo cáo” / “Bản đồ PDF”.
- Search bar.
- Filter visibility chỉ hiện khi role/API cho phép.
- Document card: mã, tiêu đề, cơ quan ban hành, ngày, lock icon nếu nội bộ.
- PDF map card: tiêu đề, tỷ lệ, năm, đơn vị chuẩn bị.

**States:** public-only guest, authenticated internal content, expired download URL, unsupported file.

---

### M21 — Chi tiết Tài liệu/PDF

**Routes:** `/documents/:id`, `/pdf-maps/:id`

**Layout:** metadata card, description, primary action “Xem/Tải xuống”, share.

- Xin presigned URL khi user bấm, không prefetch hàng loạt.
- Viewer có progress, retry và open externally.
- Không lưu presigned URL lâu hơn thời hạn.

---

### M22 — Cá nhân, Cài đặt và Đồng bộ

**Route:** `/profile`

**Guest:** login/register card, theme, language, privacy/help.

**Authenticated:** avatar, full name, role label, email; menu:

- Hồ sơ cá nhân.
- Phản ánh của tôi.
- Bản vẽ nháp.
- Đồng bộ ngoại tuyến.
- Thông báo.
- Giao diện sáng/tối/hệ thống.
- Ngôn ngữ.
- Quyền vị trí/camera/notification.
- Đăng xuất.

**Offline Queue:** count pending/failed/conflict, retry all, inspect each change; never expose raw token/payload containing PII unnecessarily.

---

## 13. State management và kiến trúc tối thiểu

Mỗi feature chỉ dùng các lớp cần thiết:

```text
features/<feature>/
  domain/          # model/value object khi thực sự cần
  data/            # repository + API DTO mapping
  presentation/    # screen/widget/provider/controller
```

Quy tắc:

- `dioProvider` là Dio singleton.
- `TokenStorage` là nguồn token duy nhất.
- Repository không chứa UI logic.
- Screen không tự parse API JSON.
- AsyncNotifier/StateNotifier quản lý screen state và cancellation.
- Không tạo interface với một implementation nếu test không cần seam đó.
- Dùng immutable state; phân biệt initial/loading/refreshing/data/empty/error.
- Pagination giữ items cũ khi tải trang mới.

---

## 14. API cần tích hợp và xác minh

### Auth

```http
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
GET  /api/v1/auth/me
PATCH /api/v1/auth/me
POST /api/v1/auth/forgot-password
POST /api/v1/auth/reset-password
POST /api/v1/auth/change-password
POST /api/v1/auth/google/mobile
```

### Web Map / Mobile GIS

```http
GET  /api/v1/web-map/layers
GET  /api/v1/web-map/features/search
GET  /api/v1/web-map/layers/:layerId/legend
GET  /api/v1/web-map/basemaps
GET  /api/v1/mobile/layers/:layerId/tiles/:z/:x/:y.mvt
GET  /api/v1/mobile/layers/:layerId/features/:featureId
GET  /api/v1/mobile/layers/:layerId/nearby
GET  /api/v1/mobile/weather/current
POST /api/v1/mobile/measure
POST /api/v1/mobile/routes/shortest
GET  /api/v1/mobile/drafts
POST /api/v1/mobile/drafts
GET  /api/v1/mobile/drafts/:id
DELETE /api/v1/mobile/drafts/:id
PATCH /api/v1/mobile/layers/:layerId/features/:featureId
GET  /api/v1/mobile/layers/:layerId/features/:featureId/history
POST /api/v1/mobile/layers/:layerId/features/:featureId/restore/:version
POST /api/v1/mobile/sync
```

### CMS

```http
GET  /api/v1/cms/news
GET  /api/v1/cms/news/:id
GET  /api/v1/cms/news/:id/comments
POST /api/v1/cms/news/:id/comments
GET  /api/v1/cms/documents
GET  /api/v1/cms/documents/:id
GET  /api/v1/cms/documents/:id/download-url
GET  /api/v1/cms/pdf-maps
GET  /api/v1/cms/pdf-maps/:id
GET  /api/v1/cms/pdf-maps/:id/download-url
```

### Hiện trường

```http
GET  /api/v1/field-reports/public
GET  /api/v1/field-reports/nearby
GET  /api/v1/field-reports/mine
POST /api/v1/field-reports
GET  /api/v1/field-reports/:id
DELETE /api/v1/field-reports/:id
PUT  /api/v1/devices/push-token
DELETE /api/v1/devices/push-token
```

Ảnh hiện trường phải dùng đúng storage presign/upload/commit lifecycle đã có trên Backend; đọc route và validator storage trước khi code.

---

## 15. Offline-first có giới hạn

Không cố offline toàn bộ GIS ngay từ đầu.

MVP offline gồm:

- Cache phiên gần nhất của news/document metadata.
- Giữ form report chưa gửi và đường dẫn ảnh local.
- Queue feature edits/drafts với UUID.
- Hiển thị trạng thái pending/syncing/conflict/failed.
- Retry có exponential backoff và giới hạn.
- Không tự ghi đè conflict.

Map tile offline chỉ làm sau map renderer spike và khi điều khoản basemap cho phép cache.

---

## 16. Bảo mật và quyền riêng tư

- Access/refresh token chỉ trong Keychain/Keystore.
- Refresh token rotation theo Backend.
- Certificate/HTTPS release bắt buộc; không cho local host trong release.
- Hỏi camera/location/notification đúng thời điểm, có privacy primer.
- Không xin background location nếu không có yêu cầu nghiệp vụ.
- Không upload ảnh trước khi user xác nhận gửi, trừ draft upload có thông báo rõ.
- Validate file signature và size qua Backend lifecycle.
- Sanitize CMS content.
- RBAC defense in depth.
- Redact Authorization, cookie, PII và GPS khỏi logs/Crashlytics breadcrumbs.
- Logout xóa token, user cache nhạy cảm và push token registration theo contract.

---

## 17. Accessibility và chất lượng UX

- Semantics label cho map controls, icon-only buttons, images và status.
- Dynamic text đến ít nhất 200% mà không mất action chính.
- Contrast WCAG AA cho text/control.
- Không truyền nghĩa chỉ bằng màu; status có icon + label.
- Haptic nhẹ khi thêm vertex/save thành công; không lạm dụng.
- Keyboard handling cho form.
- Screen reader đọc đúng thứ tự.
- Error message nêu cách khắc phục, không hiện stack trace.

---

## 18. Test strategy

### Unit tests

- JSON/envelope parsing theo response thật.
- Auth token lifecycle và refresh concurrency.
- Role mapping đúng `citizen`, `ubnd_tp`, `so_tnmt`, `so_xd`, `system_admin`.
- Geometry validation, polygon closure và bounds Cẩm Phả.
- Offline queue state transitions.

### Repository/API contract tests

- Dùng fake `HttpClientAdapter` hoặc test seam tối thiểu; không thêm mocking framework nếu không cần.
- Assert method, path, query, header và body chính xác.
- Test 401, 403, 409, 422, 429, timeout và offline.

### Widget tests

- Login/Register.
- Main Navigation shell.
- Layer sheet.
- Feature info.
- Measure/Route toolbar.
- Report stepper.
- News list/detail/comments.
- Document list/download states.
- Role-gated edit action.

### Integration/UAT

Chạy trên Backend acceptance thật:

- Guest: map, news, public docs.
- Citizen: login, comment, draft, report.
- UBND/XD: internal documents theo quyền.
- TNMT: feature update/history/restore.
- Offline → online sync conflict.

### Lệnh bắt buộc

```powershell
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Chạy app debug trên Android emulator/thiết bị. Chỉ build release khi Product Owner yêu cầu.

---

## 19. Hiệu năng và observability

- Map first meaningful frame không bị chặn bởi news/docs.
- Hủy search/request cũ khi query thay đổi.
- Lazy load ảnh và pagination.
- Resize/compress ảnh hiện trường hợp lý trước upload nhưng giữ đủ bằng chứng.
- Không rebuild toàn map khi một sheet đổi state.
- Theo dõi API latency, tile error, crash-free sessions và sync failure bằng logging/Crashlytics đã redacted.
- Mục tiêu Android tầm trung: pan/zoom mượt, không memory spike khi mở nhiều ảnh/PDF.

---

## 20. Định dạng báo cáo mỗi Sprint

Khi bắt đầu Sprint, xuất:

```markdown
# Sprint N
## Sprint Goal
## Capacity
## Selected Stories
## Acceptance Criteria
## Technical Tasks
## UX Screens/States
## API Contracts
## Risks/Dependencies
## Verification Plan
```

Khi kết thúc Sprint, xuất:

```markdown
# Sprint N Review
## Done
## Not Done
## Demo Evidence
## Test Results
## API Evidence
## Known Issues
## Product Owner Decisions
## Retrospective
- Keep
- Stop
- Try
## Proposed Next Sprint
```

Không báo “100% hoàn thành” nếu thiếu UI, router, live API evidence hoặc test.

---

## 21. Cách bắt đầu ngay

Thực hiện theo thứ tự:

1. Audit repository Mobile và Backend.
2. Chạy baseline:
   ```powershell
   flutter analyze
   flutter test
   ```
3. Lập bảng “đã có / sai contract / thiếu / xóa”.
4. Tạo Scrum artifacts Sprint 0.
5. Đối chiếu từng endpoint với validator/controller/serializer.
6. Thực hiện map renderer spike.
7. Trình Sprint 0 Review và các quyết định cần Product Owner duyệt.
8. Sau phê duyệt, triển khai Sprint 1 theo vertical slices.
9. Lặp lại đến Sprint 7.

Bắt đầu với **Sprint 0**. Không sửa code lớn trước khi hoàn tất API Contract Audit và map renderer ADR. Không giả định các repository đang có đã đúng chỉ vì `flutter analyze` không báo lỗi.

# KẾT THÚC PROMPT
