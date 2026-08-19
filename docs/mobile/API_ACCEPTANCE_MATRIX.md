# API Acceptance Matrix — Android Dev Guest

**Run:** 2026-08-11 10:51–12:12 ICT  
**Backend:** `http://127.0.0.1:3006/api/v1`  
**Android transport:** `adb reverse tcp:3006 tcp:3006`  
**Package:** `vn.gov.campha.mobilegis.dev`

> [!IMPORTANT]
> Bảng này chỉ xác nhận API public/guest và công cụ không ghi dữ liệu. Không suy rộng sang auth,
> write, private layer, role fixture hoặc production HTTPS.

## Public API Results

| Capability | Method/path | Result | Evidence |
|---|---|---:|---|
| Layer catalog | `GET /web-map/layers` | 200, 388 B | Public `ranhgioi_campha`, id `1` |
| Basemap catalog | `GET /web-map/basemaps` | 200, 287 B | OSM Standard catalog |
| Layer legend | `GET /web-map/layers/1/legend` | 200, 218 B | API/UI hợp lệ; backend trả trạng thái chưa cấu hình legend |
| Feature search | `GET /web-map/features/search?q=Cẩm Phả` | 200, 275 B | Android chọn `Cẩm Phả`, mở feature id `1` |
| MVT boundary | `GET /mobile/layers/1/tiles/12/3269/1803.mvt` | 200, 1856 B | `application/vnd.mapbox-vector-tile` |
| Weather | `GET /mobile/weather/current?latitude=21.01&longitude=107.32` | 200, 248 B | Current-weather envelope |
| Nearby feature | `GET /mobile/layers/1/nearby?...` | 200 | Feature id `1`, distance `1245.26 m` |
| Measure line | `POST /mobile/measure` | 200 | `LINESTRING`, `length_m=1177.73` |
| Measure polygon | `POST /mobile/measure` | 200 | `POLYGON`, `area_m2=1150834.32` |
| Shortest route | `POST /mobile/routes/shortest` | 409 | Expected blocker: `ROUTING_NETWORK_NOT_READY` |
| News | `GET /cms/news` | 200, 2635 B | Live cards rendered on Android |
| Documents | `GET /cms/documents` | 200, 3410 B | Live metadata rendered on Android |
| PDF maps | `GET /cms/pdf-maps` | 200, 3361 B | Public PDF-map catalog |
| Public reports | `GET /field-reports/public` | 200, 157 B | Android rendered explicit empty state |

Machine-readable output:

- [api_public_2026-08-11.json](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/evidence/api_public_2026-08-11.json)
- [api_tools_2026-08-11.json](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/evidence/api_tools_2026-08-11.json)

## Android Runtime Evidence

| Flow | Result | Evidence |
|---|---|---|
| Guest bootstrap to map | Pass | `MapWidget`, search, one active layer, attribution |
| News live load | Pass | Four live cards visible after network load |
| Documents live load | Pass | Document metadata and file sizes visible |
| Public reports load | Pass | Explicit “Chưa có phản ánh công khai” state |
| Home/background → warm resume | Pass | Map tab restored; no crash/ANR/overflow |
| Locale/theme restart persistence | Pass | `en/light` survived force-stop/relaunch; prefs confirmed |
| Search → map focus → feature detail | Pass | `cam pha` returned feature id `1`; detail exposed attributes and 3924-point `MultiLineString` |
| Layer state across tabs | Pass | Active layer and OSM remained checked; changed opacity `90% → 50%` remained `50%` after tab return |
| Measure distance + history | Pass | Two points; undo/redo toggled CTA correctly; official result `6.74 km` |
| Measure area | Pass | Mode reset to zero; three points; official result `1524.65 ha` |
| Shortest route | Blocked as expected | Both endpoints selected; localized `409 ROUTING_NETWORK_NOT_READY`; no fallback route |
| Tool cancel + identify | Pass | 176,400 sampled pixels unchanged; active layer retained; boundary tap opened feature detail |
| Final APK measure smoke | Pass | 21 semantics nodes; zero-point CTA/undo disabled; zero render errors |
| Restore test defaults | Pass | Persisted values returned to `vi/system`; layer opacity returned to `90%` |

Runtime files:

- [uat_news_live.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_news_live.xml)
- [uat_documents_live.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_documents_live.xml)
- [uat_reports_live.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_reports_live.xml)
- [uat_map_warm_resume.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_map_warm_resume.xml)
- [uat_preferences_restart.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_preferences_restart.xml)
- [uat_search_campha.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_search_campha.xml)
- [uat_search_selected.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_search_selected.xml)
- [uat_legend.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_legend.xml)
- [uat_layer_valid_after_tabs.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_layer_valid_after_tabs.xml)
- [uat_measure_distance_result.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_measure_distance_result.xml)
- [uat_measure_area_result.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_measure_area_result.xml)
- [uat_route_network_not_ready.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_route_network_not_ready.xml)
- [uat_tool_cancel_camera_before.png](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_tool_cancel_camera_before.png)
- [uat_tool_cancel_camera_after.png](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_tool_cancel_camera_after.png)
- [uat_identify_after_tool.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_identify_after_tool.xml)
- [uat_final_measure_smoke.xml](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/uat_final_measure_smoke.xml)

## Not Accepted By This Run

- Citizen registration/login/token refresh/write flows.
- Private MVT authorization and logout purge.
- TNMT/internal/admin role behavior.
- GPS permission variants, real sensor accuracy and authenticated draft draw/persist flows.
- Positive pgRouting result, snapped endpoints and 422; current public layer returns `409 ROUTING_NETWORK_NOT_READY`.
- Presigned download refresh and upload/report media flow.
- Physical Android performance, TalkBack and iOS.
- Error-injection matrix for 400/401/403/404/409/413/422/429/5xx.
