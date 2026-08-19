# Sprint 3 — Map Explorer Core Review

## Goal

Hoàn thiện M05–M08 trên app production `lib/main.dart`: catalog/layer/legend/basemap,
real MVT, search, identify và feature detail. Không dùng GeoJSON/mock thay MVT; không Chrome UAT.

## Delivered

- Exact catalog DTO: BIGINT-safe string ID, camelCase web-map serializer, legend/zoom/public fields.
- Repository dùng singleton Dio/interceptor; không manual bearer; search Dio cancellation.
- Edge-to-edge Mapbox workspace giữ renderer/camera trong indexed shell.
- MVT thật: dynamic source per layer, `sourceLayer = layer.code`, point/line/polygon style.
- Mapbox Authorization chỉ đặt cho exact API host, cập nhật sau save/refresh và clear khi logout.
- Permission-filtered catalog reset ngay khi logout/account switch.
- Layer catalog: category, search, switch, active count, opacity, disable all, live legend.
- Basemap catalog: live OSM XYZ raster từ `/web-map/basemaps`, attribution giữ nguyên.
- Search: 400 ms debounce, 2–100 ký tự, latest-query-wins, grouped live results.
- Identify: modern per-layer `TapInteraction` đọc `feature_id`, mở live backend detail.
- Feature detail: allowlisted attributes, textual geometry summary, native share.
- Safe routes: `/map/search`, `/map/feature/:layerId/:featureId`.
- vi/en đầy đủ; loading/empty/stale/error/retry states.

## Verification

### Automated

```text
dart format lib test: PASS
flutter analyze: No issues found
flutter test: 15/15 passed
```

Contract/security checks khóa:

- BIGINT-safe layer/feature IDs.
- Exact camelCase layer and snake_case basemap serializers.
- GeoJSON Point search location validation.
- Feature ID/geometry validation.
- Safe map feature deep links; external/path traversal rejected.

### Live API smoke

```json
{
  "layers": 1,
  "basemaps": 1,
  "legendStatus": 200,
  "searchStatus": 200,
  "featureStatus": 200,
  "mvt": {
    "tile": "11/1634/901",
    "status": 200,
    "contentType": "application/vnd.mapbox-vector-tile",
    "bytes": 5339
  }
}
```

Historical `column "source_fid" does not exist` blocker: re-tested and cleared.

### Android runtime

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3006 tcp:3006
flutter run --flavor dev -d emulator-5554 -t lib/main.dart --no-resident
```

Result:

- `app-dev-debug.apk` built, installed, launched from `lib/main.dart`.
- OSM basemap and live administrative boundary MVT visible.
- Live catalog showed one active layer, opacity, legend control and OSM selector.
- Live search executed and returned truthful empty state for current fixture/query.
- Tap on rendered MVT opened feature ID `1` from backend.
- Detail displayed allowlisted `NAME_2`, `TYPE_2`, `NAME_1`, `NAME_0`, `ISO`.
- Geometry alternative displayed `MultiLineString · 3924 điểm tọa độ`.

Evidence:

- `design/sprint3_map_final_android.png`
- `design/sprint3_layers_android.png`
- `design/sprint3_search_android.png`
- `design/sprint3_identify_android.png`

## Definition of Done

| Item | Status | Evidence / blocker |
|---|---|---|
| Catalog/category/visibility/opacity | Done | Android live catalog |
| Legend and basemap | Done | Live API + Android controls/OSM |
| Real MVT rendering | Done | Non-empty protobuf + Android overlay |
| Search/group/camera code | Done | Cancellable live API + Android search |
| Search result camera move | Blocked | Current live `searchFields` fixture returns 0 results; no mock used |
| Tap identify/feature detail | Done | Android live MVT ID 1/detail |
| Exact-host Authorization/session partition | Done | Token lifecycle test + identity reset; runtime private fixture unavailable |
| Private layer/session header rotation runtime | Blocked | Authenticated permission fixture unavailable |
| Android production entrypoint | Done | APK build/install/launch |
| iOS runtime | Not Done | Windows environment; macOS gate remains |

## Sprint Decision

Sprint 3 public implementation and Android acceptance: **Done**.
Search camera path is implemented but live positive result remains backend-fixture blocker.
Private layer runtime and iOS remain named gates, not replaced by mock.
Proceed Sprint 4 discovery: GIS Field Tools.
