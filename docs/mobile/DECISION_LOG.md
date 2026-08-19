# Decision Log — Mobile GIS Cẩm Phả

## ADR-001 — Renderer: Mapbox Maps Flutter 2.28.0

- **Status:** Accepted — 2026-08-10.
- **Context:** app cần Mapbox custom style, MVT backend, GeoJSON overlays, dark mode,
  pan/zoom native, private tile JWT và offline capability.
- **Decision:** dùng trực tiếp `mapbox_maps_flutter 2.28.0`; không tạo renderer interface.
- **Why not `flutter_map + vector_map_tiles`:** stable packages đang lệch major dependency;
  beta phù hợp version mới chưa đủ an toàn production.
- **Consequences:** iOS baseline 14; phải rà Mapbox terms/MAU trước release;
  Mapbox basemap không đồng nghĩa được cache tùy ý.
- **Evidence:** isolated spike ở `tool/map_spike/main.dart`.

## ADR-002 — Private MVT Authorization

- **Status:** Accepted.
- **Decision:** gọi `mapboxMap.httpService.setCustomHeadersForHost(apiHost, headers)`.
- Exact host lấy từ `Uri.parse(ApiConfig.baseUrl).host`.
- Cấu hình trước khi thêm private `VectorSource`.
- Token refresh cập nhật host; logout truyền `{}` để clear.
- **Rejected:** deprecated/global custom header vì có thể gửi JWT tới style/sprite/glyph/Mapbox host.

## ADR-003 — MVT Contract

- **Status:** Accepted, backend blocker open.
- URL: `/mobile/layers/{layerId}/tiles/{z}/{x}/{y}.mvt`.
- `sourceLayer = layer.code`; backend SQL gọi `ST_AsMVT(..., layer.code, ...)`.
- Bounds client: `[107, 20.7, 108, 21.3]`.
- Layer style chọn theo `geometryType` tại runtime; không hard-code một geometry cho catalog.
- **Blocker:** live layer 1 trả 500 `column "source_fid" does not exist`.

## ADR-004 — Navigation

- **Status:** Proposed for Sprint 1 implementation.
- `StatefulShellRoute.indexedStack` giữ camera/scroll cho 5 tab:
  Map · Field · News · Documents · Profile.
- Guest-first: public route không redirect login.
- Action ghi giữ `returnTo`, mở auth, rồi quay lại flow ban đầu.
- Splash là bootstrap route duy nhất; router guard đọc cùng auth/session state.

## ADR-005 — Token Ownership

- **Status:** Accepted; source fix deferred to Sprint 1 vertical auth slice.
- `TokenStorage` là kho duy nhất; repository không tạo `FlutterSecureStorage` thứ hai.
- Dio singleton tự gắn Authorization; repository không tự đọc/gắn token.
- Refresh dùng mutex hiện có; auth session/router/map header cùng nhận token rotation.
- Logout cố unregister push + server logout, luôn clear local token/cache nhạy cảm.

## ADR-006 — Environment and Cleartext

- **Status:** Accepted.
- Runtime config order: `--dart-define` → `.env` asset → fallback.
- `.env` hiện chỉ cho local/development; không chứa JWT/server secret.
- Android `dev` manifest cho HTTP; main/staging/prod tiếp tục `usesCleartextTraffic=false`.
- Emulator dùng `adb reverse tcp:3006 tcp:3006`, `10.0.2.2`, hoặc LAN host;
  `localhost` không tự trỏ máy phát triển nếu không reverse.
- Release validation tiếp tục bắt HTTPS/WSS và cấm local host.

## ADR-007 — Offline Ceiling

- **Status:** Accepted.
- Không làm full offline GIS trong MVP.
- Sprint 6 chỉ thêm cache metadata gần nhất, report draft/media path, queued draft/feature edits,
  UUID identity, retry/backoff và explicit conflict.
- Map tile offline chỉ refinement sau license/capacity review.
- Không thêm connectivity package trước story cần network stream thật;
  network errors từ Dio đủ cho UI retry sớm hơn.

## ADR-008 — Document/PDF Opening

- **Status:** Deferred to Sprint 2 refinement.
- Trước tiên dùng presigned URL + `url_launcher`/system app đã cài.
- Chỉ thêm native PDF viewer khi acceptance yêu cầu in-app rendering và system handoff không đủ.

## ADR-009 — Visual System

- **Status:** Accepted direction; component coding deferred by Sprint.
- Material 3 + Be Vietnam Pro + civic GIS palette.
- Token-first; component chỉ được tạo khi ít nhất hai flow dùng hoặc là shared app primitive.
- No gradient decoration over map data; gradient chỉ dùng splash/brand moments nhẹ.
- Every async screen: loading, refreshing, empty, error/retry, offline, forbidden as applicable.
