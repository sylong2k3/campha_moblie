# Sprint 0 — Discovery, Contract Audit and UX Foundation

## Sprint Goal

Chốt kiến trúc renderer, hợp đồng API, RBAC, navigation và hệ thống thiết kế trước khi xây feature;
chứng minh Mapbox basemap/GeoJSON và thử real MVT trên Android.

## Capacity

20 SP, 4 stories. Timebox 2 tuần theo product process; execution evidence được cập nhật liên tục.

## Selected Stories

| Story | SP | Status |
|---|---:|---|
| MOB-001 Source audit | 5 | Done |
| MOB-002 API/RBAC/live audit | 5 | Done with backend blocker |
| MOB-003 Renderer spike + ADR | 5 | In progress |
| MOB-004 Screen/navigation/design artifacts | 5 | In progress |

## Acceptance Criteria

- Given current source, when audited, then each area is classified keep/fix/missing/delete with Sprint owner.
- Given every target endpoint, when route/validator/service/live response are compared, then auth/input/output/error are known.
- Given Mapbox config, when spike runs on Android, then basemap + GeoJSON render and timing/error state is visible.
- Given real MVT request, when backend responds, then tile displays; if not, exact reproducible blocker is recorded.
- Given M01–M22, when reviewed, then route/hierarchy/state/API/role/accessibility and acceptance are defined.

## Technical Tasks

- [x] Baseline Flutter/Dart/analyze/test.
- [x] Public API smoke: map catalog, basemap, CMS, reports, weather.
- [x] Audit mobile repositories/core/router/theme/platform.
- [x] Audit backend route/validator/controller/service/repository.
- [x] Confirm MVT `sourceLayer = layer.code`.
- [x] Select `mapbox_maps_flutter 2.28.0` and add minimum dependency.
- [x] Raise iOS target to 14.
- [x] Add dev-only Android cleartext manifest.
- [x] Create isolated `tool/map_spike/main.dart`.
- [x] Create product/backlog/release/screen/navigation/API/RBAC/decision/risk/UAT/source docs.
- [x] Create three visual direction sheets.
- [x] Run spike trên Android emulator và capture basemap/GeoJSON screenshot bằng ADB.
- [x] Trigger MVT từ spike; capture exact renderer error `HTTP 500 · source_fid`.
- [x] Run final format/analyze/test; all pass.
- [x] Device matrix loại Chrome/web; mobile Android emulator/device + iOS simulator/device only.

## UX Screens / States

- Screen Spec covers M01–M22.
- Visual directions: map-first shell, measure workspace, field-report stepper.
- Design system covers palette/type/spacing/radius/motion/components/map geometry and async/form states.
- Accessibility baseline: AA, 48dp, 200% text, semantics, status icon+label, textual map alternatives.

## API Contracts

- Full matrix: `API_CONTRACT_AUDIT.md`.
- Success: `{message,status,data,metadata?}`; paged lists use `data.items`.
- Auth user nested in `data.user`; one `TokenStorage` required.
- Mobile GIS payload names and optimistic versions verified.
- Field report/storage lifecycle verified.
- MVT URL requires `.mvt`; source-layer uses catalog code.

## Risks / Dependencies

- **Blocker:** live MVT 500 `column "source_fid" does not exist`.
- Acceptance password not stored; authenticated smoke requires runtime secret/manual login.
- Mapbox commercial/offline terms need release review.
- iOS runtime evidence requires macOS environment.
- Routing needs published line/network fixture.

## Verification Plan

```powershell
dart format --set-exit-if-changed lib test tool/map_spike
flutter analyze
flutter test
adb reverse tcp:3006 tcp:3006
flutter run --flavor dev -d emulator-5554 -t tool/map_spike/main.dart
```

Public API `curl.exe` matrix; no credential/token output. Runtime UI evidence uses Android ADB
`screencap`, `uiautomator` and input gestures only; Chrome/web is outside product device matrix.

---

# Daily Notes

## 2026-08-10

- **Done:** baseline, source/backend audit, public live smoke, renderer comparison and approval.
- **Next:** create artifacts, spike, emulator evidence.
- **Blocker:** MVT metadata/table mismatch; authenticated secret absent.

## 2026-08-10 — Execution

- **Done:** dependency/platform config, isolated Mapbox spike, product/API/design/navigation/RBAC docs,
  three high-fidelity visual direction sheets.
- **Next:** format/analyze, launch spike, capture screenshot/video and finalize Review.
- **Blocker:** real MVT remains backend 500; iOS cannot run on Windows.

---

# Sprint 0 Review

## Done

- Mobile source classified; no large feature refactor performed prematurely.
- Backend contract ambiguity removed for target mobile routes.
- Public backend live data confirmed for catalog, basemap, news, documents, PDF maps, reports and weather.
- Mapbox 2.28.0 ADR accepted; iOS 14 and dev-only cleartext configured.
- JWT design is exact-host scoped; global headers rejected.
- M01–M22 screen/navigation/design/RBAC/product/release/UAT documents created.
- Visual design directions created for shell, GIS tools and field reports.

## Not Done

- Real MVT cannot satisfy 200/render acceptance while backend chooses missing `source_fid`.
- Authenticated role smoke pending runtime credential.
- iOS runtime smoke pending macOS toolchain.
- Mapbox custom basemap, GeoJSON overlay and pan/zoom are verified on Android emulator.

## Demo Evidence

- `docs/mobile/design/app_shell_direction.png` — concept only.
- `docs/mobile/design/map_workspace_direction.png` — concept only.
- `docs/mobile/design/field_report_direction.png` — concept only.
- `docs/mobile/design/map_spike_android.png` — Android emulator, custom basemap + clay GeoJSON + exact MVT 500.
- `docs/mobile/design/map_spike_gesture.png` — Android emulator after ADB pan/zoom gesture.

Chrome/web was not used and is not an acceptance target.

## Test Results

```text
flutter analyze: No issues found! (19.5s)
flutter test: 1/1 passed
```

Test hiện tại chỉ là bootstrap widget test `App boots and shows the home placeholder`;
không được dùng làm acceptance cho M01–M22. Mapbox spike riêng đã `dart analyze` sạch.

## API Evidence

| API | Result |
|---|---|
| Layers/basemaps | 200 |
| News/documents/PDF maps | 200, real paged data |
| Public reports | 200, valid empty list |
| Weather | 200, live data |
| MVT layer 1 | 500, missing `source_fid` |

## Known Issues

See `RISK_REGISTER.md`; R-01, R-02, R-07, R-08 and R-21 remain open.

## Product Owner Decisions

- [x] Mapbox 2.28.0 accepted.
- [x] iOS target 14 accepted.
- [x] HTTP local only Android dev accepted.
- [x] Acceptance credential only runtime/manual, never repository.
- [ ] Choose visual direction adjustments after reviewing three sheets.
- [ ] Assign backend owner/date for MVT fix.
- [ ] Confirm Mapbox terms/cost before Sprint 3 entry.

## Retrospective

### Keep

- Read live route/validator/service before changing DTO.
- Vertical slice gates and truthful blocker evidence.
- Token/security decision before map UI implementation.

### Stop

- Treating analyze-clean repositories as contract-correct.
- Manual Authorization or feature-specific secure storage.
- Calling concept images/emulator mocks acceptance evidence.

### Try

- Start Sprint 1 with smallest auth token/session slice and runnable contract checks.
- Re-run MVT smoke immediately after backend metadata fix.
- Capture each screen’s failure state alongside happy path.

## Proposed Next Sprint

Sprint 1 only after Sprint 0 Review approval. Sequence:

1. Typed auth/session result + one TokenStorage.
2. `/me`, refresh/logout lifecycle and first-class conflict/errors.
3. Splash/bootstrap/router returnTo.
4. Login/register/change-password.
5. Indexed 5-tab shell/profile/settings; delete `HomePlaceholderScreen`.
6. Contract/unit/widget tests and Android recording.
