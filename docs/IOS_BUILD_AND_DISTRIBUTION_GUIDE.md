# HƯỚNG DẪN TỔNG QUÁT BUILD VÀ PHÁT HÀNH ỨNG DỤNG FLUTTER IOS
*(Dùng chung cho tất cả các dự án Flutter)*

---

## 📋 I. ĐIỀU KIỆN BAN ĐẦU (PREREQUISITES)

### 1. Tài khoản & Đăng ký trên Apple Developer
- **Tài khoản Apple Developer Program** (Gói doanh nghiệp/cá nhân $99/năm).
- **Bundle Identifier (Bundle ID):** Đã đăng ký tại [developer.apple.com](https://developer.apple.com) dạng `com.domain.appname` (ví dụ: `com.example.myapp`).
- **App Record:** Đã tạo bản ghi App mới trên [appstoreconnect.apple.com](https://appstoreconnect.apple.com) liên kết với Bundle ID tương ứng.

### 2. Capabilities (Tính năng đặc biệt) trên Apple Developer
Trước khi đóng gói, cần tích chọn các quyền tương ứng với thư viện app sử dụng tại mục App ID trên Apple Developer Portal:
- **Push Notifications:** Bắt buộc nếu app sử dụng thông báo đẩy (Firebase Messaging, OneSignal...).
- **Sign In with Apple:** Nếu app có chức năng đăng nhập bằng Apple.
- **Associated Domains:** Nếu app dùng Deep Link / Universal Link.

### 3. Khai báo Quyền riêng tư (`ios/Runner/Info.plist`)
Mọi quyền truy cập thiết bị mà ứng dụng (hoặc thư viện bên thứ 3) sử dụng **bắt buộc phải có câu lý do rõ ràng**:
- **Vị trí (GPS):** `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription`.
- **Máy ảnh:** `NSCameraUsageDescription`.
- **Thư viện ảnh:** `NSPhotoLibraryUsageDescription`.
- **Microphone / Bluetooth...:** Khai báo thêm nếu app có sử dụng.

---

## 🔢 II. QUY TẮC PHIÊN BẢN VÀ BUILD NUMBER (`pubspec.yaml`)

Trong file `pubspec.yaml`:
```yaml
version: 1.0.0+1
```
- **Version Name (`1.0.0`):** Phiên bản ứng dụng hiển thị cho người dùng.
- **Build Number (`+1`):** Số lần đóng gói bản build.

> ⚠️ **QUY TẮC BẮT BUỘC:** Mỗi lần Upload bản mới lên TestFlight hoặc App Store, **bắt buộc phải tăng Build Number** (`+1` $\rightarrow$ `+2` $\rightarrow$ `+3`...). Apple sẽ từ chối nếu bạn Upload bản build trùng Build Number cũ.

---

## 🛠️ III. QUY TRÌNH BUILD VÀ ĐÓNG GÓI ARCHIVE

### Bước 1: Build Release bằng Terminal
Mở Terminal tại thư mục gốc của dự án Flutter:
```bash
flutter clean
flutter pub get
flutter build ios --release --no-codesign
```

### Bước 2: Cấu hình Signing trong Xcode
1. Mở workspace iOS bằng Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Chọn target **Runner** $\rightarrow$ Tab **Signing & Capabilities**:
   - Tích chọn **`Automatically manage signing`**.
   - Chọn đúng **`Team`** của bạn.
   - Kiểm tra **Bundle Identifier** trùng khớp với App ID trên Apple.

### Bước 3: Đóng gói Archive
1. Thanh công cụ trên cùng của Xcode $\rightarrow$ Chọn thiết bị đích: **`Any iOS Device (arm64)`**.
2. Thanh menu chính trên Mac $\rightarrow$ Chọn **`Product`** $\rightarrow$ **`Archive`**.
3. Khi đóng gói hoàn tất, cửa sổ **Organizer** sẽ tự động hiển thị bản Archive.

---

## 📤 IV. UPLOAD VÀ THỬ NGHIỆM TRÊN TESTFLIGHT

### Bước 1: Upload ứng dụng lên App Store Connect
1. Cửa sổ **Organizer** $\rightarrow$ Chọn bản Archive mới nhất.
2. Bấm nút màu xanh **`Distribute App`** $\rightarrow$ Chọn **`TestFlight & App Store`** $\rightarrow$ Bấm **`Distribute`**.
3. Chọn **`Upload`** $\rightarrow$ Chọn **`Automatically manage signing`** $\rightarrow$ Bấm **`Upload`**.
4. Đợi đến khi xuất hiện thông báo **App successfully uploaded**.

### Bước 2: Mời người thử nghiệm trên TestFlight
1. Truy cập [appstoreconnect.apple.com](https://appstoreconnect.apple.com) $\rightarrow$ **Apps** $\rightarrow$ Chọn App của bạn $\rightarrow$ Tab **`TestFlight`**.
2. Đợi bản build xử lý từ trạng thái *Processing* sang sẵn sàng.
3. Bấm vào bản build $\rightarrow$ Trả lời **Export Compliance** (Mã hóa: thường chọn *None of the algorithms mentioned above*).
4. **Thêm Tester:**
   - **Internal Testing (Nội bộ):** Thêm email thành viên trong team $\rightarrow$ Cài app ngay qua ứng dụng TestFlight.
   - **External Testing (Bên ngoài):** Tạo nhóm công khai hoặc tạo **Public Link** gửi cho đối tác/khách hàng qua Zalo/Email.

---

## 🚀 V. NỘP PHÁT HÀNH CHÍNH THỨC TRÊN APP STORE (PRODUCTION)

Khi bản build thử nghiệm đã ổn định và sẵn sàng phát hành toàn cầu:

### 1. Chuẩn bị hồ sơ trên App Store Connect (Tab App Store)
- **Thông tin ứng dụng (App Information):**
  - **Tên app (Title):** Dưới 30 ký tự.
  - **Phụ đề (Subtitle):** Dưới 30 ký tự.
  - **Category:** Thể loại chính của ứng dụng.
  - **Privacy Policy URL:** Đường dẫn web chứa chính sách bảo mật.
- **Hình ảnh màn hình (Screenshots):**
  - Tối thiểu 3–5 ảnh giao diện sắc nét chụp ở màn hình **6.7-inch** (iPhone Pro Max) và **5.5-inch** (iPhone 8 Plus).
- **Mô tả & Từ khóa:**
  - **Description:** Mô tả chi tiết tính năng app.
  - **Keywords:** Từ khóa tìm kiếm (ngăn cách bởi dấu phẩy).
- **Thông tin dành cho Đội duyệt Apple (App Review Information):**
  - **Tài khoản Demo:** Cung cấp tài khoản test + mật khẩu sống để nhân viên Apple đăng nhập kiểm tra app.
  - **Thông tin liên hệ:** Tên, Email, Số điện thoại hỗ trợ kỹ thuật.

### 2. Gửi kiểm duyệt (Submit for Review)
1. Tại trang **App Store**, cuộn xuống mục **Build**.
2. Bấm chọn bản build ổn định từ TestFlight (ví dụ `1.0.0 (2)`).
3. Bấm **`Save`** $\rightarrow$ Bấm nút **`Submit for Review`** (Gửi duyệt).
4. **Thời gian duyệt:** Apple thường duyệt trong vòng **24 - 48 giờ**.

---

## ❓ VI. XỬ LÝ NGÀY MỘT CÁC LỖI THƯỜNG GẶP (TROUBLESHOOTING)

| Tên lỗi / Cảnh báo | Nguyên nhân | Cách khắc phục nhanh |
| :--- | :--- | :--- |
| `errSecInternalComponent` | macOS Keychain (Móc khóa) bị khóa hoặc chưa cấp quyền cho `codesign`. | Chạy Terminal: `security unlock-keychain login.keychain` (nhập mật khẩu mở máy). Chú ý tắt bộ gõ tiếng Việt khi nhập. |
| `Could not resolve package dependencies` | Xcode lưu cache cũ của Swift Package Manager. | Trên Xcode chọn: Menu `File` $\rightarrow$ `Packages` $\rightarrow$ `Reset Package Caches`, sau đó chọn `Product` $\rightarrow$ `Clean Build Folder`. |
| `ITMS-90683: Missing purpose string` | Thiếu câu giải thích quyền riêng tư trong `Info.plist`. | Bổ sung đầy đủ các key mô tả quyền tương ứng trong `Info.plist` và **tăng Build Number (+1)** trước khi Upload lại. |
| `Upload Symbols Failed (Warning)` | Thiếu dSYM cho thư viện bên thứ 3. | **Bỏ qua.** Đây là cảnh báo không ảnh hưởng đến việc cài app hay duyệt trên App Store. |
