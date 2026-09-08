# 📱 GIS CẨM PHẢ - MOBILE APPLICATION

Ứng dụng MobileGIS phục vụ quản lý bản đồ, tra cứu thông tin quy hoạch và phản ánh hiện trường thành phố Cẩm Phả.

---

## 🛠️ THÔNG TIN CẤU HÌNH VÀ CI/CD

- **Package Name (Bundle ID):** `vn.gov.campha.camphaMoblie`
- **Framework:** Flutter (Dart)
- **Hệ điều hành hỗ trợ:** iOS & Android

---

## 🚀 HƯỚNG DẪN BUILD VÀ ĐẨY APP LÊN TESTFLIGHT & APP STORE (IOS)

### 📋 Bước 1: Chuẩn bị & Cập nhật phiên bản (`pubspec.yaml`)
Mỗi lần upload bản mới lên TestFlight hoặc App Store, **bắt buộc phải tăng Build Number** (số sau dấu `+`).

Mở file `pubspec.yaml` và cập nhật:
```yaml
version: 1.0.0+3  # Tăng số build number (+1, +2, +3...) cho mỗi lần upload mới
```

---

### 💻 Bước 2: Biên dịch bản Release iOS bằng Terminal
Mở Terminal tại thư mục gốc của dự án và chạy các lệnh sau:
```bash
flutter clean
flutter pub get
flutter build ios --release --no-codesign
```

---

### 🛠️ Bước 3: Cấu hình Signing & Đóng gói Archive trong Xcode
1. Mở dự án trong Xcode bằng lệnh:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. **Kiểm tra Signing:**
   - Ở cột trái Xcode chọn **Runner** (biểu tượng màu xanh) $\rightarrow$ chọn tab **Signing & Capabilities**.
   - Tích chọn **`Automatically manage signing`**.
   - Chọn đúng **`Team`** tài khoản Apple Developer của bạn.
   - Kiểm tra **Bundle Identifier:** `vn.gov.campha.camphaMoblie`.
3. **Đóng gói Archive:**
   - Ở thanh công cụ phía trên Xcode, đổi thiết bị sang **`Any iOS Device (arm64)`**.
   - Trên thanh menu Mac, chọn **`Product`** $\rightarrow$ **`Archive`**.
   - Đợi Xcode đóng gói xong, cửa sổ **Organizer** sẽ tự động hiển thị.

---

### 📤 Bước 4: Upload lên App Store Connect / TestFlight
1. Trong cửa sổ **Organizer**, chọn bản Archive vừa tạo $\rightarrow$ Bấm nút màu xanh **`Distribute App`**.
2. Chọn **`TestFlight & App Store`** $\rightarrow$ Bấm **`Distribute`**.
3. Chọn **`Upload`** $\rightarrow$ Giữ tùy chọn mặc định $\rightarrow$ Chọn **`Automatically manage signing`** $\rightarrow$ Bấm **`Upload`**.
4. Đợi Xcode báo **`App successfully uploaded`**.

---

### 📲 Bước 5: Mời người thử nghiệm (TestFlight) & Đẩy lên App Store

Truy cập [appstoreconnect.apple.com](https://appstoreconnect.apple.com) $\rightarrow$ chọn **Apps** $\rightarrow$ chọn **`campha_moblie`** $\rightarrow$ chọn tab **`TestFlight`**:

1. **Xác minh mã hóa (Bắt buộc):**
   - Nếu bản build hiển thị chữ màu vàng *Missing Export Compliance*, bấm vào bản build chọn **Provide Export Compliance Information** $\rightarrow$ chọn **`No`** $\rightarrow$ Bấm **Save**.
2. **Gửi cho người dùng Test:**
   - **Nội bộ (Internal Testing):** Thêm email thành viên trong team vào mục *Internal Testing* $\rightarrow$ Tải app được ngay qua ứng dụng **TestFlight** trên iPhone mà **không cần duyệt**.
   - **Bên ngoài (External Testing):** Tạo nhóm *External Group* hoặc dùng *Public Link* gửi qua Zalo/Email cho đối tác/khách hàng.
3. **Phát hành chính thức lên App Store:**
   - Sang tab **App Store** $\rightarrow$ Chọn bản build đã upload $\rightarrow$ Điền thông tin mô tả, ảnh chụp màn hình (6.7-inch & 5.5-inch), tài khoản demo $\rightarrow$ Bấm **Submit for Review** (Apple duyệt trong 24-48h).

---

## ❓ CÁC LỖI THƯỜNG GẶP VÀ CÁCH KHẮC PHỤC THỰC TẾ

| Tên lỗi | Nguyên nhân | Cách khắc phục |
| :--- | :--- | :--- |
| **Màn hình trắng xóa khi mở app** | Thiếu URL mặc định cho `GEOSERVER_URL` làm hàm `validateForRelease()` trong `lib/main.dart` tung ra ngoại lệ `StateError` trước khi `runApp()` chạy. | Đã bổ sung URL fallback chuẩn trong `lib/core/network/api_config.dart`. Đảm bảo mọi cấu hình API bắt buộc đều có giá trị mặc định. |
| **`errSecInternalComponent`** | Móc khóa (Keychain) trên máy Mac bị khóa khiến công cụ `codesign` không thể truy cập Certificate. | Chạy lệnh Terminal: `security unlock-keychain login.keychain` (gõ mật khẩu Mac, **tắt bộ gõ tiếng Việt** khi nhập). |
| **`ITMS-90683: Missing purpose string`** | Apple từ chối do thiếu câu lý do xin quyền GPS khi sử dụng thư viện bản đồ/vị trí. | Khai báo đủ 3 key `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription` trong `ios/Runner/Info.plist`. |
| **`No builds available` trên TestFlight** | Chưa trả lời câu hỏi mã hóa xuất khẩu làm bản build bị ẩn khỏi danh sách gán nhóm test. | Nhấp trực tiếp vào bản build trong TestFlight $\rightarrow$ Hoàn thành mục **Export Compliance** (chọn *No*) rồi quay lại gán nhóm. |
| **`Upload Symbols Failed` (Warning)** | Cảnh báo thiếu file dSYM của thư viện đồ họa Mapbox. | **Bỏ qua.** Đây là cảnh báo không ảnh hưởng tới việc cài đặt hay phê duyệt ứng dụng. |

---

## 🤖 HƯỚNG DẪN BUILD DEMO APK (ANDROID)

Sau mỗi lần sửa mã, chạy tại thư mục gốc dự án:

```powershell
flutter build apk --flavor prod --release --target-platform android-arm64 --split-per-abi -t lib/main.dart --dart-define-from-file=.env --dart-define=ENABLE_TEST_LOGIN=true
```

APK xuất ra tại: `build/app/outputs/flutter-apk/app-arm64-v8a-prod-release.apk`.
