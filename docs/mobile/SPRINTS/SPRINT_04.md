# Sprint 4 — GIS Field Tools Review

## Goal

Hoàn thiện M09–M12 trên app production `lib/main.dart`: foreground location,
weather/nearby, đo đạc chính thức, pgRouting và private drafts. Không background location,
không Mapbox Directions fallback, không mock che backend/auth blocker, không Chrome UAT.

## Delivered

- Strict domain contracts: bounded coordinate, GeoJSON Point/LineString/Polygon,
  weather, nearby, measurement, route, draft/page; BIGINT-safe string IDs.
- Repositories dùng global Dio/interceptors; không manual bearer.
- M09 foreground-only permission primer và state: service off, denied, denied forever,
  app/location settings, rounded coordinate, accuracy, outside bounds.
- Live `/mobile/weather/current` và permission-filtered nearby list mở feature detail.
- M10 persistent map controls: distance/area, map-wide `TapInteraction.onMap`, vertices,
  undo/redo, dynamic point/line/polygon GeoJSON, official server result.
- M11 start/end map input, GPS start, swap, cancellable exact pgRouting request,
  requested/snapped route display. `409 ROUTING_NETWORK_NOT_READY` hiện rõ; không fallback.
- M12 map draw Point/Line/Polygon; title validation; guest login handoff giữ geometry trong
  tiến trình; exact create payload; owner-partitioned list; delete với `expectedUpdatedAt`.
- Draft load/create/delete chống stale account switch; delete conflict không xóa item local.
- Safe `/map/drafts` route/`returnTo`; vi/en đầy đủ.
- Server 409 `errors` được giữ trong `ConflictException` để phân biệt named conflicts.

## Verification

### Automated

```text
dart format lib test: PASS
flutter analyze: No issues found
flutter test: 21/21 passed
```

Contract/security checks khóa:

- Cẩm Phả coordinate bounds và closed Polygon ring.
- Exact live weather/nearby/measure fixtures.
- Exact paged draft envelope và BIGINT-safe ID.
- Exact snake_case pgRouting result; malformed geometry rejected.
- `/map/drafts` safe return; external/traversal/auth-loop rejected.

### Live API smoke

```json
{
  "weather": 200,
  "nearby": {"status": 200, "feature_id": "1", "distance_m": "0.11"},
  "measureLine": {"status": 200, "length_m": "1518.68"},
  "measureArea": {"status": 200, "area_m2": "575473.69"},
  "route": {"status": 409, "errors": ["ROUTING_NETWORK_NOT_READY"]},
  "draftsGuest": 401
}
```

### Android runtime

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3006 tcp:3006
flutter run --flavor dev -d emulator-5554 -t lib/main.dart --no-resident
```

Result:

- `app-dev-debug.apk` built, installed, launched from `lib/main.dart`.
- Production Mapbox workspace retained; field-tools launcher and persistent measure workspace captured.
- Android process/activity remained resumed with no Flutter/FATAL runtime exception during capture.
- Foreground location uses existing FINE/COARSE permissions only.
- No background permission/service was introduced.

## Definition of Done

| Item | Status | Evidence / blocker |
|---|---|---|
| Foreground location permission/service states | Done | Android implementation + platform manifest audit |
| Live weather | Done | HTTP 200 exact serializer |
| Nearby positive feature | Done | HTTP 200, feature ID `1`, distance `0.11` |
| Distance/area drawing and official result | Done | Live 1518.68 m / 575473.69 m² |
| Dynamic map tool overlays | Done | Map-wide interaction + GeoJSON layers |
| Exact pgRouting flow/no fallback | Done | Exact request/UI/error branch |
| Positive route rendering runtime | Blocked | Backend `409 ROUTING_NETWORK_NOT_READY` |
| Guest draft auth handoff | Done | Safe local return, in-process geometry retained |
| Authenticated draft CRUD runtime | Blocked | No safe runtime password credential supplied |
| Optimistic delete conflict preservation | Done | Required timestamp + no local deletion on error |
| Android production entrypoint | Done | APK build/install/launch |
| iOS runtime | Not Done | Windows environment; macOS gate remains |

## Sprint Decision

Sprint 4 public implementation and Android production-entrypoint acceptance: **Done**.
Positive routing and authenticated draft runtime remain named backend/credential blockers;
no fallback or mock used. Proceed Sprint 5: Field Reports.
