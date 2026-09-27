# BÁO CÁO CHỨC NĂNG ỨNG DỤNG MOBILE GIS CẨM PHẢ

**Ngày lập:** 23/09/2026  
**Phạm vi:** các màn hình, luồng xử lý hiện có trong mã nguồn ứng dụng Flutter.  
**Mục đích:** giới thiệu chức năng cho người sử dụng, đối chiếu yêu cầu và hỗ trợ nghiệm thu; không thay thế biên bản kiểm thử.

## 1. Tổng quan

Mobile GIS Cẩm Phả là ứng dụng bản đồ trên Android/iOS, kết hợp dữ liệu địa lý với phản ánh hiện trường, tin tức và tài liệu. Khách có thể vào bản đồ mà không đăng nhập; tác vụ cá nhân hoặc chuyên môn đòi hỏi tài khoản và quyền do máy chủ cấp.

Ứng dụng gồm **năm mục chính**: **Bản đồ**, **Hiện trường**, **Tin tức**, **Tài liệu**, **Cá nhân**. Trên điện thoại, người dùng đổi mục bằng thanh điều hướng dưới; trên màn hình rộng dùng thanh bên. Dữ liệu trực tuyến phụ thuộc dịch vụ máy chủ, lớp đã công bố và quyền của tài khoản.

| Nhóm người dùng | Nhu cầu được hỗ trợ |
|---|---|
| Khách | Khám phá bản đồ, tin tức, tài liệu và danh sách phản ánh được công khai. |
| Người dân có tài khoản | Gửi phản ánh kèm ảnh/vị trí, theo dõi phản ánh của mình, bình luận tin, quản lý thông báo. |
| Cán bộ/cơ quan | Xem dữ liệu theo quyền; cán bộ đủ quyền có thể chỉnh sửa đối tượng bản đồ. |

Các mã vai trò ứng dụng nhận diện: `guest`, `citizen`, `ubnd_tp`, `so_tnmt`, `so_xd`, `system_admin`. Vai trò là điều kiện giao diện, **không tự cấp quyền**: máy chủ quyết định dữ liệu và thao tác cuối cùng.

## 2. Chức năng theo mục

### 2.1. Bản đồ: tra cứu dữ liệu địa lý

**Hiển thị và quản lý lớp.** Mở ứng dụng, người dùng thấy bản đồ, chọn kiểu nền và mở danh mục lớp. Danh mục hỗ trợ tìm lớp theo tên/danh mục, bật/tắt từng lớp hoặc tất cả, chỉnh độ mờ và xem chú giải. Ứng dụng hiển thị lớp vector hoặc raster từ dịch vụ bản đồ; lớp hạn chế chỉ tải khi được cấp quyền.

**Khám phá đối tượng.** Chạm đối tượng để lấy thuộc tính; lớp raster sử dụng truy vấn thông tin từ dịch vụ bản đồ. Có màn hình chi tiết đối tượng và hành động chia sẻ. Công cụ tìm kiếm tra cứu trên các lớp đang bật; chọn kết quả sẽ đưa bản đồ đến vị trí phù hợp. Kết quả phụ thuộc lớp được chọn và dữ liệu sẵn có trên máy chủ.

**Định vị và công cụ.** Người dùng có thể đưa bản đồ đến vị trí thiết bị; xem thông tin vị trí/thời tiết khi dịch vụ trả dữ liệu; đo khoảng cách, diện tích và hoàn tác/làm lại điểm đo. Công cụ tìm tuyến nhận hai điểm, yêu cầu tuyến từ dịch vụ và có giao diện theo dõi khi di chuyển bằng GPS. Các thao tác dùng vị trí cần thiết bị bật GPS và cấp quyền truy cập.

**Dữ liệu chuyên đề:**

- **Kịch bản ngập úng:** xem kịch bản đã kích hoạt, thông tin mưa/triều; chọn kịch bản có lớp để hiển thị trên bản đồ.
- **Ngập lụt và thủy văn:** chọn kỳ quan trắc, xem thông tin tóm tắt và bật lớp ngập, ảnh hưởng, tiêu thoát nước hoặc kiểm tra chất lượng khi đã có dữ liệu.
- **Phân loại đối tượng:** chọn kỳ công bố, bật lớp, xem chú giải, chỉnh độ mờ; xem tổng diện tích và độ che phủ rừng nếu API cung cấp.

Các mục này **hiển thị dữ liệu/kết quả do máy chủ công bố**; điện thoại không tự mô phỏng ngập hay tạo dự báo và kỳ phân loại.

### 2.2. Hiện trường: phản ánh sự việc

**Tra cứu công khai.** Người dùng xem phản ánh dạng danh sách hoặc bản đồ; lọc theo trạng thái, thời gian, hoặc dùng “gần tôi” với vị trí GPS và bán kính theo giao diện từ 10 đến 500 m. Xem chi tiết phản ánh thuộc luồng yêu cầu đăng nhập; nội dung cụ thể phụ thuộc dữ liệu và quyền từ máy chủ.

**Gửi phản ánh.** Người đã đăng nhập thực hiện ba bước:

1. Thêm bằng chứng: chụp ảnh hoặc chọn từ thư viện, từ **một đến năm ảnh**.
2. Lấy tọa độ GPS để xác định địa điểm sự việc.
3. Viết mô tả **10–2.000 ký tự**, xác nhận tính trung thực rồi gửi.

Ứng dụng lưu bản nháp chưa gửi trên thiết bị để tiếp tục khi thao tác bị gián đoạn. Khi gửi, ảnh được tải lên máy chủ trước khi tạo phản ánh; giao diện thể hiện tiến độ tải. **Nháp không phải phản ánh đã nộp:** gửi ảnh và nội dung vẫn cần mạng và máy chủ hoạt động. Dữ liệu nháp của phiên cũ được dọn khi đăng xuất.

**Phản ánh của tôi.** Người dùng xem phản ánh đã gửi, lọc theo trạng thái, mở chi tiết để xem mô tả, ảnh, vị trí và lịch sử xử lý; có thao tác xóa với bước xác nhận. Máy chủ quyết định quyền xóa. Không thấy giao diện duyệt phản ánh dành cho quản trị trên ứng dụng mobile.

### 2.3. Tin tức: đọc và bình luận

Người dùng tìm tin theo từ khóa, xem danh sách phân trang, đọc chi tiết và chia sẻ nội dung qua hệ thống của thiết bị. Có thể đọc bình luận; người đã đăng nhập được gửi bình luận. Bình luận có thể chờ duyệt, nên không mặc định xuất hiện công khai ngay sau khi gửi. Nội dung và trạng thái duyệt do hệ thống phía máy chủ quản lý.

### 2.4. Tài liệu: văn bản và bản đồ PDF

Mục Tài liệu cho phép chuyển giữa **văn bản** và **bản đồ PDF**, tìm kiếm, xem danh sách phân trang và mở thông tin chi tiết như tên, mô tả, metadata và tệp đính kèm. Khách/người dân xem nội dung công khai; tài liệu nội bộ chỉ dành cho vai trò cán bộ được cấp quyền.

Để **mở tệp** hoặc **chia sẻ liên kết tệp**, người dùng phải đăng nhập. Ứng dụng xin URL truy cập có thời hạn khi người dùng bấm thao tác, rồi mở bằng ứng dụng ngoài hoặc chia sẻ URL qua thiết bị. **Không có trình xem PDF nhúng** và không cam kết lưu sẵn để đọc ngoại tuyến.

### 2.5. Cá nhân: tài khoản và tùy chọn

Khách có thể chọn đăng nhập hoặc đăng ký. Đăng ký nhập thông tin tài khoản, chấp thuận điều khoản; nếu máy chủ yêu cầu xác minh email, ứng dụng hiển thị hướng dẫn. Đăng nhập sử dụng email/mật khẩu. Có luồng quên mật khẩu, đổi mật khẩu, đăng xuất và tiếp tục với tư cách khách; nếu tài khoản bắt buộc đổi mật khẩu, ứng dụng điều hướng đến bước đó trước khi đi tiếp.

Trang Cá nhân của người đăng nhập hiển thị tên, email, vai trò; dẫn tới **Thông báo** và **Phản ánh của tôi**. Mọi người có thể chọn ngôn ngữ Việt/Anh, giao diện sáng/tối/theo hệ thống và xem phiên bản. Giao diện hiện tại **không có biểu mẫu sửa hồ sơ** và **không có nút đăng nhập Google** dù có mã liên quan ở tầng dữ liệu.

### 2.6. Thông báo

Người đăng nhập xem danh sách và số lượng chưa đọc, đánh dấu một hoặc tất cả đã đọc, xóa thông báo và mở phản ánh liên quan. Tích hợp thông báo đẩy Firebase chỉ hoạt động khi bản cài đặt có tài nguyên cấu hình phù hợp. Không đồng nhất danh sách thông báo trong ứng dụng với việc đã xác nhận nhận push trên thiết bị thật.

## 3. Chỉnh sửa dữ liệu GIS cho cán bộ

Luồng này giới hạn cho tài khoản vai trò **`so_tnmt`** có quyền **`map_feature.update`**, trên lớp cho phép sửa. Từ chi tiết đối tượng, cán bộ sửa thuộc tính hoặc hình học theo biểu mẫu, xem lịch sử phiên bản và khôi phục phiên bản khi quyền/API cho phép. Lưu dữ liệu có kiểm tra phiên bản để phát hiện khi đối tượng trên máy chủ đã đổi.

Thay đổi GIS chưa gửi có thể nằm trong hàng đợi SQLite trên thiết bị. Màn hình đồng bộ hiển thị số mục đang chờ, xung đột, bị từ chối; cán bộ **bấm đồng bộ thủ công** khi có mạng, xem trạng thái và có thể loại bỏ mục chờ sau xác nhận. Đây là khả năng lưu *thay đổi chỉnh sửa* ngoại tuyến, **không phải bản đồ ngoại tuyến hoàn chỉnh** hoặc tự động đồng bộ mọi thao tác. Máy chủ kiểm tra quyền và phiên bản trước khi ghi.

## 4. Luồng sử dụng điển hình

| Tình huống | Các bước | Kết quả/điều kiện |
|---|---|---|
| Khảo sát vị trí | Bản đồ → chọn lớp/nền → tìm đối tượng hoặc dùng GPS → xem thuộc tính. | Kết quả theo lớp bật, dữ liệu và quyền; GPS cần cấp quyền. |
| Theo dõi ngập | Bản đồ → chuyên đề → chọn kỳ/kịch bản → xem lớp và chú giải. | Cần dữ liệu đã công bố; không chạy mô hình tại máy. |
| Gửi phản ánh | Đăng nhập → Hiện trường → tạo mới → ảnh → GPS → mô tả/xác nhận → gửi. | Cần mạng để nộp; nháp chỉ lưu cục bộ. |
| Mở tài liệu | Tài liệu → tìm/chọn PDF → xem thông tin → đăng nhập → mở/chia sẻ. | URL có thời hạn; mở bằng ứng dụng ngoài. |
| Chỉnh sửa GIS | Cán bộ đủ quyền → chọn đối tượng/lớp → sửa → lưu → xem hàng đợi và đồng bộ. | Cần kết nối, quyền và phiên bản hợp lệ để ghi lên máy chủ. |

## 5. Kiến trúc và điều kiện vận hành

Ứng dụng viết bằng **Flutter/Dart**, dùng **Mapbox** hiển thị bản đồ, **GeoServer/API GIS** cung cấp lớp và truy vấn không gian, **REST API** phục vụ tài khoản, phản ánh và nội dung. GoRouter đảm nhiệm điều hướng, Riverpod quản lý trạng thái. Token phiên lưu trong vùng lưu trữ bảo mật; nháp phản ánh và hàng đợi sửa GIS được lưu cục bộ theo mục đích riêng. Firebase Messaging/Crashlytics là tích hợp có điều kiện cấu hình.

Để sử dụng đầy đủ cần API và dịch vụ bản đồ hoạt động, dữ liệu/lớp đã công bố, tài khoản và quyền phù hợp, kết nối mạng; GPS/ảnh cần quyền thiết bị. Mở PDF cần ứng dụng ngoài có thể xử lý liên kết tệp. Endpoint và dịch vụ môi trường phát hành cần được kiểm tra riêng.

> **Giới hạn xác nhận:** Báo cáo dựa trên mã/giao diện, không chứng nhận vận hành trên thiết bị thật hoặc production. [Hồ sơ chốt phát hành 11/08/2026](./mobile/RELEASE_CLOSURE.md) ghi “code closure PASS; production RC NOT DONE”; kiểm thử ở đó là bằng chứng lịch sử, **không phải lần kiểm thử mới ngày lập báo cáo**. Tài khoản mẫu/chế độ thử nghiệm không tính là chức năng cho người dùng cuối; cần tắt trước khi phát hành chính thức.

## 6. Nguồn đối chiếu chính

- Điều hướng: [app_router.dart](../lib/app/router/app_router.dart), [main_shell.dart](../lib/app/router/main_shell.dart).
- Bản đồ: [map_home_screen.dart](../lib/features/map/presentation/map_home_screen.dart), [layer_catalog_sheet.dart](../lib/features/map/presentation/layer_catalog_sheet.dart), [map_search_screen.dart](../lib/features/map/presentation/map_search_screen.dart), [flood_scenario_sheet.dart](../lib/features/map/presentation/flood_scenario_sheet.dart), [flood_hydrology_sheet.dart](../lib/features/map/presentation/flood_hydrology_sheet.dart), [forest_classification_sheet.dart](../lib/features/map/presentation/forest_classification_sheet.dart), [measure_sheet.dart](../lib/features/tools/presentation/measure_sheet.dart), [route_sheet.dart](../lib/features/routing/presentation/route_sheet.dart).
- Phản ánh: [field_reports_screen.dart](../lib/features/field_reports/presentation/field_reports_screen.dart), [create_field_report_screen.dart](../lib/features/field_reports/presentation/create_field_report_screen.dart), [report_composer_controller.dart](../lib/features/field_reports/domain/report_composer_controller.dart), [my_reports_screen.dart](../lib/features/field_reports/presentation/my_reports_screen.dart).
- Nội dung: [news_screen.dart](../lib/features/cms/presentation/news_screen.dart), [news_detail_screen.dart](../lib/features/cms/presentation/news_detail_screen.dart), [documents_screen.dart](../lib/features/cms/presentation/documents_screen.dart), [cms_file_detail_screen.dart](../lib/features/cms/presentation/cms_file_detail_screen.dart).
- Tài khoản/thông báo: [login_screen.dart](../lib/features/auth/presentation/login_screen.dart), [register_screen.dart](../lib/features/auth/presentation/register_screen.dart), [profile_screen.dart](../lib/features/profile/presentation/profile_screen.dart), [notifications_screen.dart](../lib/features/notifications/presentation/notifications_screen.dart), [push_service.dart](../lib/core/push/push_service.dart).
- Chỉnh sửa GIS: [feature_edit_screen.dart](../lib/features/feature_edit/presentation/feature_edit_screen.dart), [feature_sync_screen.dart](../lib/features/feature_edit/presentation/feature_sync_screen.dart), [feature_history_screen.dart](../lib/features/feature_edit/presentation/feature_history_screen.dart), [user_role.dart](../lib/core/permissions/user_role.dart).
