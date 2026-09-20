# Bảng Tra Cứu Design Tokens (MobileGIS Cẩm Phả)

## 1. Bảng Màu (Color Tokens)

| Token | Mã Màu (HEX) | Mục đích sử dụng |
| :--- | :--- | :--- |
| `AppColors.primary` | `#006B63` | Màu nhận diện chính, nút hành động chính, viền active |
| `AppColors.primaryDeep` | `#073B3A` | Nền header, gradient tối, icon nhấn mạnh |
| `AppColors.coastal` | `#8FD8D2` | Bạc hà ven biển, highlight nhẹ, badge hệ thống |
| `AppColors.clay` | `#D5EFEC` | Nền thẻ nổi bật, container xanh nhạt |
| `AppColors.statusNew` | `#1677A3` | Phản ánh mới, thông báo thủy văn/ngập lụt |
| `AppColors.statusInProgress` | `#D97706` | Đang xử lý, cảnh báo hiện trường |
| `AppColors.statusResolved` | `#087A5B` | Đã xử lý thành công, tiến độ hoàn tất |
| `AppColors.statusError` | `#B42318` | Cảnh báo khẩn cấp, lỗi hệ thống |

---

## 2. Hệ Thống Bo Góc (Border Radius)

| Ký hiệu | Giá trị | Ứng dụng |
| :--- | :--- | :--- |
| `Radius.small` | `6px` | Nhãn phân loại (Tag Badges), status dots |
| `Radius.medium` | `10px - 12px` | Nút bấm (Buttons), Chip, Input fields |
| `Radius.large` | `16px` | Thẻ danh sách (Cards), Banner |
| `Radius.xlarge` | `24px` | Modal Bottom Sheet, Dialog container |

---

## 3. Hệ Thống Bóng Đổ (Elevation & Shadows)

- **Thẻ thường (Subtle card)**:
  `BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.03), blurRadius: 6, offset: Offset(0, 2))`
- **Thẻ nổi bật / Chưa đọc (Active / Glowing card)**:
  `BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.08), blurRadius: 10, offset: Offset(0, 2))`
- **Banner lớn (Elevated Banner)**:
  `BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.10), blurRadius: 16, offset: Offset(0, 4))`
