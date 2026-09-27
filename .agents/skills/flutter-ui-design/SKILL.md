---
name: flutter-ui-design
description: >-
  Hướng dẫn và quy chuẩn thiết kế UI/UX chuyên sâu cho ứng dụng Flutter MobileGIS Cẩm Phả.
  Sử dụng skill này khi người dùng yêu cầu thiết kế mới (design), làm đẹp, tinh chỉnh bố cục,
  tạo component, chuẩn hoá thẻ hiển thị (Card, ListTile), Modal Sheet, Banner hoặc cải tiến trải nghiệm thị giác.
---

# Flutter UI/UX Design System & Guidelines (MobileGIS Cẩm Phả)

Bộ tiêu chuẩn thiết kế giao diện di động hiện đại, sang trọng và chuẩn công thái học cho MobileGIS Cẩm Phả. Mọi màn hình, widget hay component giao diện cần tuân thủ các nguyên tắc cốt lõi trong hướng dẫn này.

---

## 1. Nguyên Tắc Cốt Lõi (Design Principles)

1. **Thẩm Mỹ Cao Cấp & Bản Sắc Thương Hiệu (Premium & Identity)**:
   - Tông màu chủ đạo là xanh ngọc bích / biển than Cẩm Phả (`AppColors.primary: #006B63`, `primaryDeep: #073B3A`), điểm xuyết bạc hà bờ biển (`coastal: #8FD8D2`, `clay: #D5EFEC`).
   - Sử dụng gradient nhẹ nhàng cho banner, header và các vùng tương tác nổi bật (`AppColors.brandGradient`, `AppColors.ambientGradient`).
   - Tránh dùng màu cộc cằn đơn điệu (pure red, green, blue). Luôn sử dụng bảng màu đã tinh chỉnh có độ bão hoà hài hoà.

2. **Phân Cấp Thị Giác Rõ Ràng (Visual Hierarchy & Typography)**:
   - **Tiêu đề**: `titleMedium` / `titleLarge`, `fontWeight: FontWeight.w700` hoặc `w600`, `height: 1.25 - 1.3`.
   - **Nội dung phụ / mô tả**: `bodyMedium` / `bodySmall`, màu `onSurfaceVariant`, `height: 1.4 - 1.5`, giới hạn dòng bằng `maxLines` và `overflow: TextOverflow.ellipsis` nếu trong thẻ thu gọn.
   - **Nhãn phân loại (Tag Badge)**: `labelSmall` in hoa hoặc viết hoa đầu chữ, nền màu nhạt (`containerColor`), chữ màu đậm đồng điệu (`primaryColor`), có icon mini (`12-14px`).

3. **Hệ Thống Khoảng Cách & Bo Góc (Spacing & Border Radius)**:
   - Lưới khoảng cách chuẩn 8pt: `4, 8, 12, 16, 20, 24, 32`.
   - Bo góc hiện đại:
     - Thẻ Card / Container chính: `R16` (16px).
     - Nút bấm (Button) / Input field: `R10 - R12`.
     - Tag Badge / Chip: `R6 - R8`.
     - Bottom Sheet: `R24` góc trên (`BorderRadius.vertical(top: Radius.circular(24))`).

4. **Độ Nổi & Hiệu Ứng Chiều Sâu (Elevation & Depth)**:
   - Không dùng bóng đổ đen thô cứng. Dùng bóng đổ mềm màu `primary.withValues(alpha: 0.06 - 0.10)` hoặc `shadow.withValues(alpha: 0.03 - 0.05)`, độ mờ `blurRadius: 8 - 14`, độ lệch `offset: Offset(0, 2 - 4)`.
   - Đường viền mỏng (`1 - 1.2px`) bán trong suốt (`withValues(alpha: 0.45 - 0.6)`) giúp thẻ tách biệt rõ nét trên nền sáng lẫn tối (Dark Mode).

5. **Thiết Kế Co Giãn Linh Hoạt & Trợ Năng (Responsive & Accessibility)**:
   - **Tuyệt đối tránh `Row` cứng** chứa nhiều phần tử văn bản dài hoặc nút bấm cố định, tránh lỗi RenderFlex Overflow khi người dùng bật cỡ chữ to (`TextScaler > 1.5`) hoặc màn hình hẹp (`width <= 320px`).
   - Sử dụng `Wrap(spacing: 8, runSpacing: 6, ...)` cho hàng tag/chip/metadata.
   - Bọc văn bản có thể co giãn bằng `Expanded` hoặc `Flexible` kết hợp `overflow: TextOverflow.ellipsis`.

6. **Tương Tác Chạm & Phản Hồi (Micro-interactions & Touch States)**:
   - Mọi phần tử bấm được phải có `InkWell` hoặc `IconButton` với `borderRadius` đồng bộ với viền ngoài.
   - Thêm biểu tượng mũi tên định hướng (`Icons.arrow_forward_ios_rounded`, size `11-13px`) cho các mục có thể mở chi tiết.
   - Trạng thái chưa đọc (Unread): Chấm tròn phát sáng (glowing dot) + viền nổi bật.

---

## 2. Quy Chuẩn Thành Phần Mẫu (Component Standards)

### A. Thẻ Danh Sách Đa Năng (Modern Card / ListTile)
```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  decoration: BoxDecoration(
    color: isUnread
        ? (isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white)
        : (isDark ? theme.colorScheme.surfaceContainer : theme.colorScheme.surfaceContainerLowest),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: isUnread
          ? theme.colorScheme.primary.withValues(alpha: 0.45)
          : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
      width: isUnread ? 1.4 : 1,
    ),
    boxShadow: [
      BoxShadow(
        color: isUnread
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.shadow.withValues(alpha: 0.03),
        blurRadius: isUnread ? 10 : 6,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: ...
      ),
    ),
  ),
)
```

### B. Nhãn Phân Loại (Category Badge)
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
  decoration: BoxDecoration(
    color: tagBgColor,
    borderRadius: BorderRadius.circular(6),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(tagIcon, size: 12.5, color: tagTextColor),
      const SizedBox(width: 4.5),
      Text(
        tagLabel,
        style: TextStyle(
          color: tagTextColor,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          letterSpacing: 0.3,
        ),
      ),
    ],
  ),
)
```

### C. Banner Giới Thiệu / Kêu Gọi Hành Động (CTA Banner)
- Sử dụng gradient thương hiệu `LinearGradient` chuyển nhẹ từ góc trên trái sang góc dưới phải.
- Bo tròn `R16`, viền mỏng màu thương hiệu bán trong suốt `primary.withValues(alpha: 0.35)`.
- Nút CTA dạng `FilledButton.icon` hoặc `FilledButton.tonal` bo tròn `R10`.

### D. Modal Bottom Sheet Chi Tiết
- Sử dụng `showModalBottomSheet` với `isScrollControlled: true`, `useSafeArea: true`, `showDragHandle: true`.
- Góc bo trên: `Radius.circular(24)`.
- Cho phép bôi đen/sao chép nội dung bằng `SelectableText`.
- Nút đóng to rõ ràng, bo góc `R12`, màu nền `surfaceContainerHighest`.

---

## 3. Quy Trình Kiểm Thử & Đảm Bảo Chất Lượng Giao Diện

Trước khi hoàn thành bất kỳ tác vụ thiết kế nào:
1. **Kiểm tra phân tích cú pháp**: Chạy `flutter analyze` đảm bảo 0 cảnh báo.
2. **Kiểm tra Unit/Widget Test**: Chạy `flutter test` đảm bảo các test case liên quan vẫn pass 100%.
3. **Kiểm tra Trợ năng & Không gian chật hẹp**:
   - Thử nghiệm trên màn hình hẹp (320px width).
   - Thử nghiệm với tỷ lệ phóng to chữ `TextScaler.linear(2)`.
   - Đảm bảo không xảy ra `RenderFlex overflowed by ... pixels`.
4. **Hỗ trợ đầy đủ Cả Light Mode và Dark Mode**: Sử dụng `theme.colorScheme` hoặc kiểm tra `theme.brightness == Brightness.dark` để màu sắc luôn tương phản chuẩn WCAG AA.
