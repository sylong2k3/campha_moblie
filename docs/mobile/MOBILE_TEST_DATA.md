# Dữ liệu kiểm thử mobile

Tài liệu này bổ sung [UAT_CHECKLIST.md](UAT_CHECKLIST.md). Dữ liệu mang prefix `MOBACC`, do backend tạo qua HTTP API thật; mobile không dùng mock.

## 1. Chuẩn bị

1. Chạy backend và các dịch vụ cần dùng.
2. Seed dữ liệu:

```powershell
$env:API_BASE_URL='http://127.0.0.1:3006'
$env:API_TEST_PASSWORD='<mật khẩu test nhận qua kênh nội bộ>'
npm --prefix '..\server-campha' run seed:mobile-test
npm --prefix '..\server-campha' run acceptance:verify
```

3. Mở [`mobile-api-fixtures.json`](../../../server-campha/docs/api/mobile-api-fixtures.json) để xem ID thật và trạng thái module.
4. Thiết bị/emulator phải gọi được backend. Với thiết bị thật, dùng IP LAN của máy chạy backend, không dùng `127.0.0.1`.
5. Không chạy `reset-and-seed.js`; lệnh đó xóa DB.

## 2. Tài khoản test

| Vai trò           | Email                   | Dùng để test                                        |
| ----------------- | ----------------------- | --------------------------------------------------- |
| Quản trị hệ thống | `admin@campha.gov.vn`   | Login, profile, phân quyền âm với feature edit      |
| UBND thành phố    | `ubnd@campha.gov.vn`    | Nội dung nội bộ, duyệt phản ánh qua API/admin       |
| Sở TNMT           | `tnmt@campha.gov.vn`    | Bản đồ, sửa feature, history, restore, offline sync |
| Sở Xây dựng       | `xaydung@campha.gov.vn` | Nội dung nội bộ, phân quyền âm với feature edit     |
| Công dân          | `citizen@campha.gov.vn` | Bình luận, phản ánh, draft, công cụ bản đồ          |

Mật khẩu không ghi trong file này. Dùng cùng secret đã cấp cho `API_TEST_PASSWORD`.

## 3. Dữ liệu có sẵn

### Tin tức và bình luận

- Từ khóa: `MOBACC`.
- 22 tin public: `MOBACC Tin kiểm thử mobile 01` đến `22`.
- Page size mobile: 20; kéo cuối trang 1 phải tải thêm 2 tin trang 2.
- Tin chính: `MOBACC Tin kiểm thử mobile 01`.
- Trên tin chính có:
  - `MOBACC Bình luận đã duyệt trên mobile`: public nhìn thấy.
  - `MOBACC Bình luận chờ duyệt trên mobile`: public không thấy.
  - `MOBACC Bình luận đã từ chối trên mobile`: public không thấy.

### Văn bản và bản đồ PDF

| Nhãn                             | Mức hiển thị | Kết quả                                         |
| -------------------------------- | ------------ | ----------------------------------------------- |
| `MOBACC Văn bản công khai`       | public       | Khách và mọi role nhìn thấy, tải PDF được       |
| `MOBACC Văn bản nội bộ`          | internal     | Chỉ role có `documents.read_internal` nhìn thấy |
| `MOBACC Bản đồ PDF Cẩm Phả 2024` | public       | Mở/tải PDF thật                                 |
| `MOBACC Bản đồ PDF Cẩm Phả 2025` | public       | Mở/tải PDF thật                                 |
| `MOBACC Bản đồ PDF Cẩm Phả 2026` | public       | Mở/tải PDF thật                                 |

### Phản ánh hiện trường

Đăng nhập `citizen`, mở **Phản ánh** rồi bấm icon **Phản ánh của tôi**.

| Nhãn chứa trong mô tả               | Trạng thái     | Ảnh | Hình học đo |
| ----------------------------------- | -------------- | --: | ----------- |
| `MOBACC ổ gà đang chờ tiếp nhận`    | `pending`      |   0 | Point       |
| `MOBACC ngập cục bộ đang xem xét`   | `under_review` |   1 | LineString  |
| `MOBACC rác thải đã xác minh`       | `approved`     |   3 | Polygon     |
| `MOBACC phản ánh trùng đã từ chối`  | `rejected`     |   2 | Không có    |
| `MOBACC vỉa hè hư hỏng đã xác minh` | `approved`     |   4 | Không có    |
| `MOBACC nắp cống đã xử lý`          | `resolved`     |   5 | LineString  |

Kết quả:

- **Phản ánh của tôi** thấy đủ 6 bản ghi, đủ 5 trạng thái, đủ số ảnh 0–5.
- Detail thấy ảnh thật và lịch sử trạng thái.
- Danh sách/map public chỉ thấy `approved` và `resolved`.
- Nearby quanh `107.31, 21.01`, bán kính 500 m thấy hai phản ánh public.

### Draft và công cụ bản đồ

Đăng nhập `citizen`, mở **Bản đồ** → **Công cụ**:

- `MOBACC Điểm khảo sát mobile`: Point.
- `MOBACC Tuyến khảo sát mobile`: LineString.
- `MOBACC Vùng khảo sát mobile`: Polygon.
- **Bản nháp của tôi** phải hiện đủ ba bản ghi.
- Thử đo khoảng cách bằng LineString và diện tích bằng Polygon; kết quả phải lớn hơn 0.
- Thử thời tiết tại `107.31, 21.01` nếu module `mobileWeather` là `ready`.
- Thử chỉ đường từ `107.31, 21.01` đến `107.325, 21.02` với ô tô, đi bộ, xe đạp nếu module `routing` là `ready`.

### Bản đồ và feature edit

Đọc ID/layer code từ manifest; không dùng ID trong tài liệu.

- Point layer: `mobacc_mobile_points`.
  - Catalog thấy layer khi module `map` là `ready`.
  - Search/feature detail/nearby quanh `107.3, 21.0` hoạt động.
- Editable layer: `mobacc_editable_roads`.
  - Chỉ `so_tnmt` thấy quyền sửa khi module `featureEditing` là `ready`.
  - Detail hiển thị version hiện tại.
  - History có baseline, update, restore và sync update.
  - `citizen`, `system_admin`, `ubnd_tp`, `so_xd` không được sửa.

## 4. Checklist toàn bộ chức năng

### Auth và hồ sơ

- [ ] Login đúng với cả 5 tài khoản.
- [ ] Login sai hiển thị lỗi, không vào app.
- [ ] Profile hiển thị đúng tên/email/role.
- [ ] Đổi ngôn ngữ Việt/Anh; mở lại app vẫn giữ lựa chọn.
- [ ] Đổi theme sáng/tối/hệ thống; mở lại app vẫn giữ lựa chọn.
- [ ] Logout xóa session và đưa về màn hình phù hợp.
- [ ] Refresh token diễn ra không làm mất phiên khi access token hết hạn.
- [ ] Back/foreground app không lộ dữ liệu người dùng cũ sau logout.

### Đăng ký và mật khẩu — manual

- [ ] Đăng ký bằng email dùng một lần chưa tồn tại.
- [ ] Nếu `REQUIRE_EMAIL_VERIFICATION=true`, app hiển thị nhánh chờ xác minh; mở link email thật rồi login.
- [ ] Quên mật khẩu luôn trả thông báo chung cho email có/không tồn tại.
- [ ] Mở email reset, đặt mật khẩu mới, token cũ không dùng lại được.
- [ ] Đổi mật khẩu bằng tài khoản dùng một lần; login bằng mật khẩu mới thành công.

Không đổi mật khẩu của 5 tài khoản nền. Nếu buộc phải test bằng tài khoản nền, phải đổi lại secret ban đầu ngay sau case.

### CMS

- [ ] Khách xem danh sách, tìm `MOBACC`, kéo tải trang 2.
- [ ] Mở chi tiết tin và refresh.
- [ ] Citizen gửi bình luận mới; bình luận chưa xuất hiện public trước khi duyệt.
- [ ] Public chỉ thấy bình luận approved đã seed.
- [ ] Văn bản public mở/tải PDF thành công.
- [ ] Citizen/khách không thấy văn bản internal.
- [ ] Quản trị hệ thống/TNMT/UBND/Sở Xây dựng thấy văn bản internal nếu role có quyền.
- [ ] Ba bản đồ PDF mở/tải thành công.
- [ ] Mất mạng khi tải file hiển thị lỗi và retry được; grant hết hạn được lấy lại.

### Phản ánh

- [ ] Danh sách và map public chỉ có approved/resolved.
- [ ] Nearby có dữ liệu trong 500 m.
- [ ] **Phản ánh của tôi** có 6 bản ghi, lọc đúng cả 5 trạng thái, photo count phủ 0–5.
- [ ] Detail hiện ảnh, tọa độ, measured geometry, review reason và history.
- [ ] Tạo mới không ảnh.
- [ ] Tạo mới 1–5 ảnh từ camera/thư viện.
- [ ] Chặn ảnh thứ 6.
- [ ] Từ chối camera/GPS permission không làm crash; app hướng dẫn cấp quyền.
- [ ] Mô tả dưới 10 ký tự bị chặn.
- [ ] Xóa phản ánh đang `pending` rồi refresh không còn dữ liệu.
- [ ] Push notification chỉ test khi module `push` là `ready` và có Firebase token thật.

### Bản đồ

- [ ] Catalog, basemap, terrain tải được.
- [ ] Bật/tắt layer, zoom/pan, recenter.
- [ ] Search feature và mở detail.
- [ ] Nearby theo vị trí thiết bị.
- [ ] MVT tải khi point layer `ready`.
- [ ] Weather hiển thị observed time; upstream lỗi hiển thị trạng thái retry.
- [ ] Đo khoảng cách và diện tích.
- [ ] Route ô tô/đi bộ/xe đạp; geometry, khoảng cách, thời gian và steps hợp lệ.
- [ ] Tạo/list/detail/xóa draft Point, LineString, Polygon.
- [ ] Draft của citizen không đọc được bằng role khác.

### TNMT feature edit và offline

Đăng nhập `tnmt@campha.gov.vn`:

- [ ] Mở editable layer, sửa field `name`, lưu thành version mới.
- [ ] Mở history, xem geometry/attributes trước-sau.
- [ ] Restore một version cũ tạo version mới, không sửa lịch sử cũ.
- [ ] Tắt mạng, sửa và lưu; màn hình **Thay đổi ngoại tuyến** có item `pending`.
- [ ] Bật mạng, **Đồng bộ ngay**; item thành công biến khỏi pending.
- [ ] Conflict: client A lưu offline; client B/server sửa cùng feature; client A bật mạng sync và thấy `conflict`.
- [ ] Rejected: sau khi lưu offline, thu hồi `can_edit` hoặc nhắm feature đã xóa; sync hiển thị `rejected`.
- [ ] Retry transport error tối đa theo UI; conflict/rejected không tự ghi đè server.

Backend manifest chỉ chứng minh API có receipt `applied`/`conflict`/`rejected`. Queue hiển thị trên app nằm trong SQLite thiết bị, nên phải tạo bằng thao tác offline trên chính thiết bị.

### Thiết bị, accessibility và lỗi

- [ ] Android và iOS thật hoặc simulator tương ứng.
- [ ] Font scale 200%, không cắt nút/text quan trọng.
- [ ] TalkBack/VoiceOver đọc nhãn nút, tab, trường nhập.
- [ ] Portrait/landscape và màn hình nhỏ không overflow.
- [ ] Offline từ khi khởi động, mất mạng giữa request, mạng chậm và reconnect.
- [ ] App background/resume trong lúc upload/download/sync.
- [ ] Download grant hết hạn và access token hết hạn được phục hồi đúng.
- [ ] Server 401/403/404/409/422/429/503 hiển thị thông báo hành động được, không crash.
- [ ] Không log access token, refresh token, API key, presigned URL hoặc mật khẩu.

## 5. Đọc kết quả module

Trong manifest:

- `ready`: chạy case ngay.
- `conditional`: sửa blocker dịch vụ trước; không coi là pass.
- `manual`: chỉ tạo được trên thiết bị.

Các module thường phụ thuộc ngoài: raster, GIS import/GeoServer, Mapbox routing, OpenWeather, Firebase push, SMTP.
