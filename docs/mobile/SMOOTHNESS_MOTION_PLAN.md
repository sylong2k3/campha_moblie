# Kế hoạch tối ưu độ mượt & chuẩn hoá hiệu ứng — Mobile GIS Cẩm Phả

**Ngày lập:** 2026-08-14
**Phạm vi duyệt:** toàn bộ `lib/` (99 file Dart, ~23.7k dòng), `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`
**Công cụ:** đọc source thủ công + `flutter analyze --no-pub` (Flutter 3.41.6 / Dart 3.11.4)
**Trạng thái analyze:** sạch — 3 issue không liên quan hiệu năng (2 `unnecessary_import`, 1 `experimental_member_use` cho `MapboxMapsOptions.setLanguage`)

> Baseline đã có từ `PERFORMANCE_SECURITY_AUDIT.md` (2026-08-11, emulator Android 17): navigation soak 236 frames, p50/p90/p95/p99 = 5/15/16/18 ms, **modern jank 16.10%**, cold start median 1,735 ms.
> Tài liệu này giải thích *tại sao* jank còn 16.10% và đề ra lộ trình đóng nó, đồng thời hiện thực hoá bảng Motion đã ghi trong `DESIGN_SYSTEM.md` nhưng **chưa từng tồn tại trong code**.

---

## 1. Kết luận nhanh

Ứng dụng có kiến trúc tốt (feature-first, Riverpod thủ công, `AutomaticKeepAliveClientMixin` đúng chỗ, `cacheWidth/cacheHeight` đã dùng, `CancelToken` đã dùng, debounce search đã có). Vấn đề **không nằm ở lint hay ở thuật toán**, mà ở ba nhóm:

| Nhóm | Bản chất | Số phát hiện |
|---|---|---:|
| **A. Bão state → platform channel** | Một cử chỉ người dùng sinh ~60 state update/giây, mỗi update kéo theo N lời gọi bất đồng bộ sang native Mapbox | 2 |
| **B. Lãng phí build/layout** | Tính toán và cấp phát lặp trong `build()`, list không lazy, không có `RepaintBoundary` nào trong toàn app | 11 |
| **C. Hiệu ứng thiếu hoặc không chuẩn** | Bảng Motion trong DESIGN_SYSTEM chưa được code hoá; 0 `Hero`, 0 haptics, 0 `pageTransitionsTheme`, reduced-motion chỉ áp dụng 2/99 file | 11 |

Nhóm A là nguyên nhân chính của jank cảm nhận được. Nhóm C là lý do app "chạy được nhưng không sang".

---

## 2. Phát hiện chi tiết

### P0 — Jank người dùng thấy được

#### P0-1. Kéo slider độ mờ layer → bão platform-channel

Chuỗi sự kiện mỗi frame kéo slider:

```
Slider.onChanged                      layer_catalog_sheet.dart:292
  → controller.setLayerOpacity        map_controller.dart:127   (state mới, copyWith + clone Map)
    → ref.watch(mapCatalogProvider)   layer_catalog_sheet.dart:31   → rebuild TOÀN BỘ sheet
    → ref.listen(mapCatalogProvider)  map_home_screen.dart:754
      → _syncCatalog → _syncMap       map_home_screen.dart:269-291
        → for (layer in state.layers):
            await map.style.styleLayerExists(...)   ← 1 round-trip native / layer
            await _setOpacity(...)                  ← 1 round-trip native / layer
```

Với N layer trong catalog, **mỗi frame kéo slider = 2N lời gọi native tuần tự (`await` nối tiếp)**. Đồng thời `layer_catalog_sheet.dart:137` dùng `ListView(children: [...])` — không lazy — nên toàn bộ category + toàn bộ `SwitchListTile` + `Slider` được dựng lại mỗi frame.

#### P0-2. Mỗi GPS fix khi dẫn đường → `jsonEncode` toàn bộ hình học tuyến

`_startRoutePositionTracking` (`map_home_screen.dart:142`) đăng ký stream với `distanceFilter: 5`. Mỗi vị trí mới:

```
updateRoutePosition                   field_tools_controller.dart:403  (state mới)
  → ref.listen(fieldToolsProvider)    map_home_screen.dart:757   (KHÔNG có guard so sánh)
    → _syncFieldOverlay               map_home_screen.dart:473
      → state.route!.geometry.toJson()  + jsonEncode(...)        map_home_screen.dart:499, 522
      → map.style.setStyleSourceProperty(...)
  → ref.watch(fieldToolsProvider)     route_sheet.dart:25   → rebuild toàn sheet
```

Hình học tuyến **không đổi** giữa các GPS fix — chỉ `location`/`activeRouteStepIndex` đổi. Toàn bộ serialize + đẩy sang native là lãng phí thuần trên UI isolate, đúng lúc người dùng đang di chuyển và cần app mượt nhất.

#### P0-3. `Future.microtask(loadMore)` đặt trong `itemBuilder`

- `field_reports_screen.dart:323`
- `my_reports_screen.dart:95`

`itemBuilder` của sentinel item chạy lại mỗi lần sliver layout lại (scroll, resize, keyboard, rebuild cha) → xếp hàng `loadMore` lặp. `PagedController.loadMore` có guard `if (state.loading || state.appending)` nên không nhân đôi request, nhưng vẫn tạo microtask rác mỗi frame và là mô hình sai (side-effect trong build). So sánh: `news_screen.dart:38` và `documents_screen.dart:120` đã làm đúng bằng `ScrollController` listener.

#### P0-4. `_viewportForReports()` chạy trong `build()`

`field_reports_screen.dart:1172` — quét min/max toạ độ toàn bộ danh sách báo cáo **mỗi lần build** `_ReportMap`, dù kết quả chỉ cần khi `items` đổi (đã có `_fittedReportSignature` để phát hiện điều đó). Thêm nữa `_reportSignature` (`:1101`) nối chuỗi toàn bộ danh sách — cấp phát O(n) chuỗi mỗi lần gọi.

#### P0-5. `ref.watch` cả state ở màn hình bản đồ

`map_home_screen.dart:752` watch nguyên `MapCatalogState`, nhưng `build()` chỉ dùng đúng `catalog.activeCount` và `catalog.loading`. Mọi thay đổi opacity/layers/error đều rebuild cả `Stack` chứa `MapWidget` + toàn bộ overlay. Toàn app chỉ có **6 file** dùng `.select()`, trong khi có ~20 chỗ `ref.watch` nguyên state.

---

### P1 — Lãng phí build/layout

| # | Vị trí | Vấn đề |
|---|---|---|
| P1-1 | 15 chỗ dùng `ListView(children:)`, 0 chỗ dùng `ListView.builder` | List không lazy. Nặng nhất: `layer_catalog_sheet.dart:137` (toàn catalog), `create_field_report_screen.dart:476` (danh sách ảnh), `feature_detail_screen.dart:89`, `map_search_screen.dart:179` |
| P1-2 | Toàn bộ `lib/` | **0 `RepaintBoundary`, 0 `cacheExtent`, 0 `itemExtent`/`prototypeItem`**. Overlay bản đồ và `MapWidget` nằm chung `Stack` không có ranh giới repaint |
| P1-3 | `field_reports_screen.dart:32` | `_effectiveItems` chạy `.where().toList()` mỗi build |
| P1-4 | `documents_screen.dart:141,149` + `:201,209` | `_filterByVisibility` + `state.copyWith(items:)` cấp phát list & state mới mỗi build |
| P1-5 | `documents_screen.dart:94` | `IndexedStack` dựng cả `_DocumentList` lẫn `_PdfMapList` ngay lần vào đầu → **2 request mạng** khi chỉ cần 1 (cả hai provider đều `Future.microtask(loadFirstPage)` trong `build()`) |
| P1-6 | `cms_widgets.dart:56` | `_changed` gọi `setState(() {})` rỗng mỗi ký tự gõ — thừa, vì `AppSearchField` (`app_search_field.dart:30`) đã tự `ValueListenableBuilder` trên controller |
| P1-7 | `cms_widgets.dart:13` | `cmsDate` khởi tạo `DateFormat.yMMMd(...)` mới cho **mỗi card, mỗi build** |
| P1-8 | `field_reports_screen.dart:355-382` | `_ReportsHero` dựng lại toàn bộ `Column`/`DecoratedBox`/`Text` trong `LayoutBuilder` **mỗi frame cuộn** (FlexibleSpaceBar co giãn liên tục), rồi bọc `Opacity` — kích hoạt `saveLayer` khi 0 < opacity < 1 |
| P1-9 | `map_home_screen.dart:413-427` | `_removeLayer` luôn thử cả cặp vector **và** raster → 4 lời gọi native + 2 exception nuốt, dù layer chỉ thuộc một loại (`layer.isRaster` đã biết trước) |
| P1-10 | `map_home_screen.dart:121-132` | `_refreshPrivateRasterLayers` mỗi 5 phút **xoá rồi thêm lại** source/layer → tile private nháy trắng định kỳ. Nên cập nhật `tiles` url tại chỗ, hoặc chỉ refresh khi vé sắp hết hạn |
| P1-11 | `field_reports_screen.dart:1209` | `_relative(DateTime, dynamic l10n)` — tham số `dynamic` gây dynamic dispatch mỗi card và mất type-safety |

---

### P2 — Hiệu ứng thiếu hoặc không chuẩn

| # | Hiện trạng | Chuẩn cần đạt |
|---|---|---|
| P2-1 | Bảng Motion trong `DESIGN_SYSTEM.md:101-112` **chưa có trong code**. Duration rải rác literal: 160 / 180 / 220 / 240 / 320 ms ở 6 file | Một class token `AppMotion` là nguồn duy nhất |
| P2-2 | `MediaQuery.disableAnimationsOf` chỉ dùng ở **2/99 file** (`login_screen.dart:77`, `create_field_report_screen.dart` ×4) | DESIGN_SYSTEM:111 yêu cầu "zero nonessential transitions" khi reduced-motion — phải áp dụng nhất quán, tốt nhất là gói trong token |
| P2-3 | **0 widget `Hero`** trong toàn app | Card báo cáo → sheet chi tiết, card tin tức → trang chi tiết: shared-element |
| P2-4 | Không cấu hình `pageTransitionsTheme`; `AndroidManifest.xml` thiếu `android:enableOnBackInvokedCallback="true"` | Bật predictive back Android 14+ (`PredictiveBackPageTransitionsBuilder`) |
| P2-5 | `map_home_screen.dart:783` — `if (!toolActive)` bật/tắt toàn bộ khối search + map controls **tức thì** | Fade + slide 220ms easeOutCubic (`DESIGN_SYSTEM:106` "tool dock") |
| P2-6 | `map_home_screen.dart:927` — spinner giữa màn hình xuất hiện/biến mất đột ngột, không nền mờ | `AnimatedSwitcher` + scrim nhẹ |
| P2-7 | Chuyển loading ↔ empty ↔ error ↔ list nhảy cóc ở mọi màn danh sách (`news_screen.dart:90`, `documents_screen.dart:270`, `field_reports_screen.dart:280-337`, `my_reports_screen.dart:62-150`) | `AnimatedSwitcher` 240ms bao quanh nhánh trạng thái |
| P2-8 | `CmsLoadingList` (`cms_widgets.dart:126`) là thanh xám **tĩnh hoàn toàn** | DESIGN_SYSTEM:109 yêu cầu "low-motion pulse" — pulse opacity 0.55↔1.0, không shimmer gradient |
| P2-9 | `documents_screen.dart:94` `IndexedStack` đổi segment không hiệu ứng | Fade 160ms |
| P2-10 | `main.dart:83` `themeAnimationDuration: Duration.zero` | Đây có thể là chủ ý (tránh crossfade tốn kém với `MapWidget` platform view). **Cần xác nhận với PO** trước khi đổi — xem mục Rủi ro |
| P2-11 | **0 `HapticFeedback`**, **0 `SystemUiOverlayStyle`** | Haptic cho toggle layer / chụp ảnh / gửi báo cáo. Status bar cần `light` icon khi `SliverAppBar` xanh của màn báo cáo pin lên (`field_reports_screen.dart:197`) |

---

## 3. Lộ trình thực thi

Thứ tự cố ý: đo trước → sửa nguyên nhân gốc → chuẩn hoá token → dọn lãng phí → thêm hiệu ứng → đo lại. Không thêm hiệu ứng trước khi đóng P0, vì hiệu ứng trên nền jank chỉ làm jank rõ hơn.

### Phase 0 — Đo baseline (0.5 ngày)

Không sửa code. Mục tiêu: có số liệu để chứng minh từng phase có tác dụng.

1. `flutter run --profile --flavor dev` trên **thiết bị Android vật lý tầm trung** (audit trước mới chỉ có emulator — đây là gate còn treo trong `PERFORMANCE_SECURITY_AUDIT.md:148`).
2. Ghi timeline DevTools cho 5 kịch bản, lưu vào `docs/mobile/evidence/`:
   - `S1` kéo slider opacity 5 giây với ≥3 layer bật
   - `S2` chạy dẫn đường 60 giây (route tracking bật)
   - `S3` cuộn danh sách báo cáo 100 item
   - `S4` chuyển tab 5 lần
   - `S5` pan/zoom bản đồ 20 giây
3. Bật `Performance Overlay` + `debugProfileBuildsEnabled` để đếm rebuild thừa.
4. Ghi lại: janky frame %, p50/p90/p99, số lần build của `MapHomeScreen` và `LayerCatalogSheet`.

**Deliverable:** `docs/mobile/evidence/motion_baseline_2026-08-xx.json` + bảng số trong file này.

---

### Phase 1 — Đóng P0 (2–3 ngày) — ưu tiên cao nhất

| Task | File | Nội dung |
|---|---|---|
| 1.1 | `layer_catalog_sheet.dart` | Tách `Slider` thành `StatefulWidget` giữ giá trị cục bộ; `onChanged` chỉ cập nhật local state (UI mượt 60fps), `onChangeEnd` mới gọi `controller.setLayerOpacity`. Nếu cần preview realtime thì throttle 100ms |
| 1.2 | `map_home_screen.dart:269` | `_syncMap` bỏ `styleLayerExists` trong vòng lặp — đã có `_renderedLayerIds` là nguồn sự thật. Chỉ gọi `styleLayerExists` khi khôi phục sau style reload |
| 1.3 | `map_home_screen.dart:247` | `_syncCatalog` thêm early-return: nếu `previous` và `next` giống nhau ở `activeLayerIds` + `opacityByLayer` + `selectedBasemapCode` thì không làm gì |
| 1.4 | `map_home_screen.dart:757` | `ref.listen(fieldToolsProvider)` chỉ gọi `_syncFieldOverlay` khi **hình học thực sự đổi**. Thêm getter `overlaySignature` vào `FieldToolsState` (mode + vertices.length + routeStart/End + identityHashCode của route) và so sánh trước khi encode |
| 1.5 | `map_home_screen.dart:473` | Cache chuỗi GeoJSON đã encode; bỏ qua nếu bằng lần trước |
| 1.6 | `route_sheet.dart:25` | Đổi sang `ref.watch(fieldToolsProvider.select(...))` cho đúng các field sheet dùng, để GPS fix không rebuild cả sheet |
| 1.7 | `field_reports_screen.dart:323`, `my_reports_screen.dart:95` | Bỏ `Future.microtask` trong `itemBuilder`; chuyển sang `ScrollController` listener theo đúng mẫu `news_screen.dart:38` |
| 1.8 | `field_reports_screen.dart:1164` | Chuyển `_viewportForReports()` và `_reportSignature` ra khỏi `build()`; tính trong `didUpdateWidget` và cache vào field |
| 1.9 | `map_home_screen.dart:752` | `ref.watch(mapCatalogProvider.select((s) => (s.activeCount, s.loading)))` |

**Acceptance Phase 1:** chạy lại S1 và S2. Kỳ vọng: S1 janky frame về < 3%; S2 không còn spike `jsonEncode` trên timeline.

---

### Phase 2 — Code hoá token motion (1 ngày)

Tạo `lib/app/theme/app_motion.dart` — hiện thực đúng bảng `DESIGN_SYSTEM.md:101-112`, không phát minh giá trị mới:

```dart
/// Token chuyển động. Nguồn duy nhất — khớp bảng Motion trong DESIGN_SYSTEM.md.
/// Mọi Duration/Curve trong UI phải lấy từ đây, không viết literal tại chỗ dùng.
class AppMotion {
  const AppMotion._();

  static const state    = Duration(milliseconds: 160); // state/color
  static const surface  = Duration(milliseconds: 220); // sheet/FAB/tool dock
  static const page     = Duration(milliseconds: 240); // route/page
  static const cameraMs = 450;                         // map camera (Mapbox nhận int ms)
  static const cameraFarMs = 700;

  static const stateCurve   = Curves.easeOut;
  static const surfaceCurve = Curves.easeOutCubic;

  /// Trả Duration.zero khi hệ điều hành bật reduced-motion.
  /// DESIGN_SYSTEM.md:111 — "zero nonessential transitions".
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
```

Sau đó thay thế toàn bộ literal:

- `field_reports_screen.dart:533` (160) → `AppMotion.of(context, AppMotion.state)`
- `field_reports_screen.dart:621` (180) → `AppMotion.state` *(chuẩn hoá 180 → 160)*
- `field_reports_screen.dart:670` (320) → `AppMotion.page` *(chuẩn hoá 320 → 240)*
- `create_field_report_screen.dart:266,280` (180) → `AppMotion.state`
- `create_field_report_screen.dart:332` (240) → `AppMotion.page`
- `create_field_report_screen.dart:426` (220) → `AppMotion.surface`
- `login_screen.dart:79` (180) → `AppMotion.state`
- `map_home_screen.dart:605` (900) → `AppMotion.cameraFarMs` *(900 ngoài dải 450–700 tài liệu quy định)*
- `map_home_screen.dart:741` (700), `field_reports_screen.dart:1159` (450) → token camera

**Task kèm theo:**
- Bật predictive back: thêm `android:enableOnBackInvokedCallback="true"` vào `<application>` trong `AndroidManifest.xml`, và `pageTransitionsTheme` với `PredictiveBackPageTransitionsBuilder` cho Android trong `app_theme.dart`.
- Thêm test: `test/app_motion_test.dart` khẳng định `AppMotion.of` trả `Duration.zero` khi `disableAnimations: true` (đặt cạnh `app_theme_test.dart` đã có).

---

### Phase 3 — Dọn lãng phí build (2 ngày)

| Task | File | Nội dung |
|---|---|---|
| 3.1 | `layer_catalog_sheet.dart:137` | `ListView` → `ListView.builder` theo danh sách category đã phẳng hoá |
| 3.2 | `map_home_screen.dart:762` | Bọc `RepaintBoundary` quanh cụm overlay (search bar + map controls) để chúng không repaint cùng `MapWidget` |
| 3.3 | Các màn danh sách | Thêm `RepaintBoundary` cho card có shadow/border; cân nhắc `cacheExtent` cho list ảnh |
| 3.4 | `field_reports_screen.dart:32` | Ghi nhớ `_effectiveItems` theo `(items, status)` thay vì lọc lại mỗi build |
| 3.5 | `documents_screen.dart` | Ghi nhớ `_filterByVisibility`; bỏ `state.copyWith` mỗi build (truyền `items` riêng cho `_CmsListLayout`) |
| 3.6 | `documents_screen.dart:94` | `IndexedStack` → dựng lazy tab thứ 2 lần đầu người dùng chạm vào, để không bắn 2 request lúc mở màn |
| 3.7 | `cms_widgets.dart:56` | Bỏ `setState(() {})` rỗng |
| 3.8 | `cms_widgets.dart:13` | Cache `DateFormat` theo locale (map `locale → DateFormat`) |
| 3.9 | `field_reports_screen.dart:355` | `_ReportsHero`: dựng phần nội dung **một lần** ngoài `LayoutBuilder`, truyền vào làm `child` để Flutter tái dùng element; cân nhắc `FadeTransition`/alpha màu thay `Opacity` để tránh `saveLayer` |
| 3.10 | `map_home_screen.dart:413` | `_removeLayer` nhận `LayerModel` (hoặc cờ `isRaster`) và chỉ gỡ đúng cặp id của loại đó |
| 3.11 | `map_home_screen.dart:121` | `_refreshPrivateRasterLayers`: cập nhật `tiles` bằng `setStyleSourceProperty` thay vì remove + add, để tile không nháy. Nếu Mapbox không cho, giữ remove+add nhưng chỉ chạy khi vé còn < 3 phút |
| 3.12 | `field_reports_screen.dart:1209` | `_relative(DateTime, AppLocalizations)` — bỏ `dynamic` |

> Lưu ý: `map_home_screen.dart:121` và `map_repository.dart` gắn với luồng tile-ticket cho layer private (xem `MEMORY.md`). Bất kỳ thay đổi nào ở `_addLayer`/`_refreshPrivateRasterLayers` phải giữ nguyên hợp đồng: layer raster **không** `is_public` bắt buộc có `ticket` trước khi dựng `RasterSource`, và vé phải được làm mới trước TTL ~15 phút.

---

### Phase 4 — Hiệu ứng màn hình (2–3 ngày)

| Task | Nội dung | Duration/Curve |
|---|---|---|
| 4.1 | `map_home_screen.dart:783` — bọc khối overlay bằng `AnimatedSwitcher` + `SlideTransition` khi tool panel bật/tắt | `AppMotion.surface` / `easeOutCubic` |
| 4.2 | `map_home_screen.dart:927` — spinner bản đồ vào/ra bằng `AnimatedOpacity` + scrim `surface.withValues(alpha: .35)` | `AppMotion.state` |
| 4.3 | Bọc `AnimatedSwitcher` quanh nhánh loading/empty/error/list ở `news_screen.dart:90`, `documents_screen.dart:270`, `field_reports_screen.dart:280`, `my_reports_screen.dart:62` | `AppMotion.page` |
| 4.4 | `CmsLoadingList` — pulse opacity 0.55↔1.0 lặp, dừng hẳn khi reduced-motion (DESIGN_SYSTEM:109, 112 cấm "infinite decorative animation" — pulse skeleton là chỉ báo tiến trình nên được phép, nhưng **phải** tắt theo reduced-motion) | 900ms `easeInOut` |
| 4.5 | `Hero` cho: card báo cáo (`field_reports_screen.dart:869`) → `_PublicReportSheet`; card tin (`news_screen.dart:140`) → `news_detail_screen.dart`. Dùng tag ổn định `report-${id}` / `news-${id}` | mặc định platform |
| 4.6 | `documents_screen.dart:94` — `AnimatedSwitcher` fade khi đổi segment | `AppMotion.state` |
| 4.7 | FAB `field_reports_screen.dart:179` — ẩn/hiện theo hướng cuộn bằng `AnimatedSlide` | `AppMotion.surface` |
| 4.8 | Haptics: `HapticFeedback.selectionClick()` cho toggle layer + đổi segment; `.mediumImpact()` cho chụp ảnh và gửi báo cáo thành công | — |
| 4.9 | `SystemUiOverlayStyle`: status bar icon sáng khi `SliverAppBar` xanh của màn báo cáo được pin; trả về theo theme ở màn khác | — |
| 4.10 | `splash_screen.dart` — fade-in logo/tiêu đề để splash → map không cắt cảnh cứng | `AppMotion.page` |

---

### Phase 5 — Xác minh & chốt (1 ngày)

1. `flutter analyze` phải sạch như trước (baseline: 3 issue đã biết).
2. `flutter test` — toàn bộ suite phải xanh. Chú ý `test/layer_catalog_sheet_test.dart` sẽ cần cập nhật vì task 1.1 đổi hành vi slider.
3. Chạy lại **đúng 5 kịch bản S1–S5** của Phase 0 trên **cùng thiết bị vật lý**, cùng flavor profile.
4. Kiểm tra reduced-motion: bật "Remove animations" trong Android Accessibility, duyệt lại toàn app — không được còn transition trang trí nào.
5. Kiểm tra TalkBack: `Hero` mới không được phá thứ tự đọc; `liveRegion` hiện có phải giữ nguyên.
6. Cập nhật `PERFORMANCE_SECURITY_AUDIT.md` với số liệu physical-device (đóng luôn residual risk #4 đang treo).

**Ngưỡng chấp nhận đề xuất:**

| Chỉ số | Baseline emulator | Mục tiêu physical |
|---|---:|---:|
| Modern janky frames (navigation soak) | 16.10% | < 5% |
| p99 frame time | 18 ms | ≤ 16 ms |
| Janky frames khi kéo slider opacity (S1) | chưa đo | < 3% |
| Request mạng khi mở màn Văn bản | 2 | 1 |

---

## 4. Rủi ro & điểm cần quyết định

1. **`themeAnimationDuration: Duration.zero` (`main.dart:83`)** — tôi *không* đề xuất đổi trong plan này. Crossfade theme trên màn hình có `MapWidget` (platform view) dễ gây artifact nặng hơn lợi ích. Cần PO xác nhận đây là chủ ý trước khi động vào.
2. **Slider opacity chuyển sang `onChangeEnd` (task 1.1)** làm mất preview realtime trên bản đồ. Nếu PO cho rằng preview realtime là yêu cầu nghiệp vụ, dùng phương án throttle 100ms thay vì commit-on-release — vẫn giảm ~85% số lời gọi native.
3. **Tile-ticket** — task 3.11 chạm vào code auth cho layer private. Phải test với layer `is_public=false` thật, không chỉ layer public.
4. **`Hero` + `go_router` `StatefulShellRoute`** — shared element qua ranh giới branch có thể không hoạt động như mong đợi. Task 4.5 chỉ áp dụng trong cùng branch (report→sheet, news→news detail), không bắc cầu giữa các tab.
5. **Baseline hiện tại là emulator.** Mọi con số "cải thiện x%" chỉ có giá trị khi Phase 0 và Phase 5 chạy trên cùng một thiết bị vật lý.

---

## 5. Ước lượng

| Phase | Ngày công | Rủi ro |
|---|---:|---|
| 0 — Đo baseline | 0.5 | Thấp |
| 1 — Đóng P0 | 2–3 | **Trung bình** (chạm map sync + route tracking) |
| 2 — Token motion | 1 | Thấp |
| 3 — Dọn lãng phí build | 2 | Trung bình (task 3.11 chạm tile-ticket) |
| 4 — Hiệu ứng màn hình | 2–3 | Thấp |
| 5 — Xác minh | 1 | Thấp — nhưng cần thiết bị vật lý |
| **Tổng** | **8.5–10.5** | |

Phase 1 và Phase 2 độc lập nhau, có thể chạy song song hai người. Phase 4 phụ thuộc Phase 2 (cần token).
