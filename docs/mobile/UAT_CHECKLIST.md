# UAT Checklist — Mobile GIS Cẩm Phả

Use real acceptance backend and runtime secrets. Record Pass / Fail / Blocked / N/A with evidence.
Do not capture password, token, phone, raw GPS, private feature properties or report photos containing PII.

## Environment and Device

- [x] Dev build identifies package `vn.gov.campha.mobilegis.dev`.
- [x] Dev HTTP works only in Android dev flavor.
- [x] Staging/prod release validator rejects local HTTP and invalid WSS.
- [x] Android emulator build/install/launch smoke passes from `lib/main.dart`.
- [ ] Representative mid-range physical Android passes core flows.
- [ ] iOS simulator/physical device on iOS 14+ passes via macOS environment.
- [x] Cold start and Home/background → warm resume keep the guest map usable. — Android dev 2026-08-11; rotation and authenticated critical state remain open.
- [x] Dark/light/system and vi/en persist after restart. — `en/light` survived force-stop/relaunch; persisted prefs confirmed and restored to `vi/system`.

## Guest

- [x] Opens `/map` after bootstrap without forced login. — Android dev guest map semantics, 2026-08-11.
- [x] Sees only public layer catalog and real basemap. — live `ranhgioi_campha` + OSM catalog HTTP 200; Android shows one layer.
- [ ] Pan/zoom/rotate, legend, feature info, GPS, weather, measure and route per server policy. — legend/search/weather APIs, Android GPS permission matrix, measurement và route 409 UI đã đạt; full gesture audit và positive routing còn mở.
- [x] Reads/searches/pages public news. — Sprint 2 tests + 2026-08-11 live Android cards/API 200.
- [x] Reads public document/PDF metadata. — Sprint 2 + 2026-08-11 live Android/API 200.
- [x] Reads public field reports. — Sprint 5 + 2026-08-11 API 200 and Android explicit empty-state evidence.
- [x] Draft/report/comment/download write action opens login with correct returnTo. — safe route tests include report new/mine/detail.
- [x] Cancel login returns original CMS screen via safe returnTo.
- [ ] Private layer/content metadata never appears after another user logs out. — state isolation code + provider/list/detail identity guards đạt; authenticated account-switch runtime fixture vẫn thiếu.

## Citizen

- [ ] Registers with valid data; verify-email branch handled when enabled.
- [ ] Duplicate email and invalid input show safe inline/error banner copy.
- [ ] Login success stores tokens in one `TokenStorage`. — local seed citizen/UBND/SXD/TNMT/admin đều login HTTP 200 và role mapping đúng; acceptance environment/token lifecycle runtime vẫn mở.
- [ ] Cold start restores `/me`; expired token performs single refresh.
- [ ] Creates/lists/deletes map draft with correct optimistic timestamp.
- [ ] Posts comment once; rate/error states preserve text appropriately.
- [ ] Creates field report with 1–5 valid images, location and description. — code/tests clean; runtime auth credential blocked.
- [x] Upload stages presign/upload/commit/create are distinguishable in implementation.
- [x] Network loss preserves unsent report draft/media paths via app-support PNG + SharedPreferences.
- [ ] Sees mine/detail/status history and only allowed delete. — runtime auth credential blocked.
- [ ] Push token registers as `{token, platform}` and deep link opens allowed report. — code wired; Firebase native config blocked.
- [x] Logout unregisters/clears session and private cache locally even offline. — best-effort push/server logout không chặn token clear; owner queue/client ID, report draft/media/GPS, field tools, CMS list/detail và map/report state đều purge/reset; authenticated runtime credential vẫn cần cho end-to-end server unregister.

## UBND / Sở Xây dựng

- [ ] Server-granted internal documents appear; public and internal labels clear.
- [ ] Unauthorized documents/layers remain absent/forbidden after deep link.
- [ ] Report create/review actions match runtime permission and explicit backend role rules.
- [ ] No TNMT base-feature edit action appears.
- [ ] 403 after permission change refreshes session capability and explains denial.

## Sở TNMT

- [ ] Real editable layer exposes edit/history only when permission true. — code/backend contract verified; TNMT runtime fixture blocked.
- [x] Attribute allowlist excludes ID/system/internal fields. — backend sanitizer + tests.
- [x] Geometry edits validate bounds/type/closure and support undo/cancel. — implementation + analyze/tests.
- [ ] PATCH sends `baseVersion`; successful edit produces next version. — exact contract tested; authenticated runtime blocked.
- [ ] Concurrent edit returns 409 and shows local/server choices without overwrite. — code path fixed; runtime fixture blocked.
- [x] History timeline/geometry summary expose actor/time/action/changed fields in implementation.
- [ ] Restore confirms consequence, sends current `baseVersion`, creates new version. — exact code; runtime fixture blocked.
- [x] Offline change has UUID v4 client ID/change ID.
- [x] Sync persists applied/conflicts/rejected separately with network-only bounded retry.
- [x] Non-TNMT direct request remains rejected by server. — backend service tests.

## System Admin

- [ ] Mobile exposes only product-supported capabilities from runtime permission.
- [ ] Report approval remains hidden/forbidden where service excludes admin.
- [ ] Base feature edit remains hidden where service requires exact TNMT.
- [ ] Unknown/missing permission defaults denied for write actions.

## Map and GIS

- [ ] Custom Mapbox light/dark styles load using public token config. — app uses live OSM catalog; custom Mapbox style acceptance remains open.
- [x] Camera starts within Cẩm Phả bounds. — Android guest map bootstrap centers Cẩm Phả.
- [x] Real MVT `ranhgioi_campha` returns 200 and displays with `sourceLayer=code`. — z12/3269/1803 returns 1856 B `application/vnd.mapbox-vector-tile`; Android reports one active layer.
- [ ] Private MVT Authorization goes only to API host; cleared on logout. — exact-host header + token-clear/catalog reset code đạt; authenticated runtime resource inspection vẫn mở.
- [ ] Tile 401/403/500 has actionable non-blocking state.
- [x] Tab switch preserves camera and active layer state. — 67,500 sampled map pixels unchanged; layer/OSM stayed checked and 50% opacity persisted across tabs.
- [x] Search latest query wins and result zoom/query works. — cancel/query-identity guard plus Android `ranh` → `cam pha`; final result opened feature id `1` detail (`MultiLineString`, 3924 points).
- [x] GPS primer/system permission/permanent denial/settings paths work. — APK Android emulator xác nhận disclosure trước native prompt; Huỷ không request; deny hiện Thử lại; deny lần hai hiện Mở cài đặt; service-off mở `LocationSettingsActivity`; deniedForever mở `com.android.settings`; cleanup trả permission chưa cấp và location service bật. Thiết bị thật được theo dõi riêng ở Environment.
- [x] Low accuracy is labeled, not shown as precise. — threshold dùng `GPS_ACCURACY_THRESHOLD_M=10`; widget regressions 100 m/5 m đạt; APK coarse-only hiển thị “Độ chính xác thấp · sai số ±2000.0 m” và giữ cảnh báo ngoài Cẩm Phả.
- [x] Measure official `length_m/area_m2` formats m/km/m²/ha correctly. — Android backend result `6.74 km` and `1524.65 ha`; unit regression covers m/km/m²/ha thresholds; undo/redo/disabled CTA states passed.
- [ ] Route uses pgRouting backend, shows snapped endpoints and handles 409/422. — Android selected both endpoints and rendered localized `409 ROUTING_NETWORK_NOT_READY`; positive route/snapped endpoints and 422 remain blocked by missing routing topology fixture.
- [x] Tool gestures do not collide; back/cancel preserves previous map state. — measure/route taps worked sequentially; cancel kept all 176,400 sampled pixels identical, retained active layer, and identify opened feature detail afterward.
- [x] Scale and attribution remain visible. — Android map semantics retain Mapbox attribution after cold/warm launch.

## CMS / Files

- [x] List pagination reads `data.items` and `metadata`; append keeps old data.
- [x] Search max length/debounce/cancellation validated in implementation + tests/analyze.
- [x] CMS content sanitized; legacy HTML normalized as text; no JavaScript/WebView.
- [x] Presigned URL fetched only on user action.
- [ ] Expired URL is refreshed once then actionable error. — pure regression đạt: fresh=1 request, near-expiry=2, expired lần hai dừng tại 2; external viewer không báo downstream 401/403 và authenticated runtime fixture vẫn blocked.
- [x] Unsupported file/system viewer missing has graceful fallback.
- [x] No presigned URL persisted past useful lifetime.

## Error and Recovery

- [x] Offline/timeout, 400, 401, 403, 404, 409, 413, 422, 429 and 5xx mapped. — table-driven regression kiểm typed exception, status, errors, PasswordChangeRequired, Retry-After/RateLimit-Reset và unknown-payload privacy fallback.
- [x] UI raw exception/stack rendering removed from audited feature paths; standard mapper hides unknown payloads.
- [x] Retry does not duplicate non-idempotent writes. — adapter regression: GET retry tối đa 1; POST/PATCH/multipart gặp 503 chỉ 1 request; GET 429 không retry.
- [x] Button locks during report submit; upload/create state cannot double-submit.
- [x] Empty public/filtered/error states differ in report implementation and Android semantics.
- [x] Refresh keeps prior report content and labels stale state.
- [x] Process restart preserves unsent report metadata and durable media paths within documented ceiling.
- [x] Backend blocker is labeled Blocked, never replaced by mock acceptance.

## Accessibility

- [x] Icon-only controls audited with tooltip/semantics; report close label added.
- [x] Material controls use padded 48dp tap targets.
- [x] Text and controls meet WCAG AA in light/dark and over tested map style. — token contrast regression plus Android light/dark emulator audit; physical device remains release blocker.
- [x] 200% text preserves primary actions and no important clipping on tested Android guest flow. — runtime 320dp/200% trên map, reports, news, documents, profile; semantics giữ đủ 5 tab/search/filter/CTA; tools sheet đã sửa thành scrollable; log không có `RenderFlex`, `BoxConstraints` hoặc exception. Broader physical/TalkBack audit remains open.
- [ ] Screen-reader focus order follows visual/task order. — automated login/report visual-order focus regressions đạt; TalkBack runtime pass pending.
- [x] Status includes icon + text; color is not sole meaning in implemented status flows.
- [x] Form error links/focus identify field and correction. — login focus/scroll email rồi password; report focus/scroll description rồi truth checkbox; widget regressions đạt.
- [x] Map-selected feature/tool result has textual alternative in details/sheets.
- [x] Report step transitions honor system reduced-motion setting.

## Privacy and Security

- [x] Access/refresh token ownership remains Keychain/Keystore via `TokenStorage`.
- [x] HTTP/push/location/crash fallback logs are metadata/fixed-code only; no payload/query/exception stack.
- [x] `.env` contains public client config only; no password/JWT/private key.
- [x] Release/profile skip dotenv and require CI/dart-define HTTPS/WSS validation.
- [x] Location/camera/notification requested at point of use; runtime copy review remains open.
- [x] No background location permission.
- [x] Report images not uploaded before explicit informed Submit action.
- [x] Logout clears sensitive local user data and map host header. — owner queue/client identity purge + catalog reset wired.
- [x] Deep-link returnTo rejects external/unknown/auth-loop paths, including numeric report IDs only.

## Performance and Stability

- [ ] Map first meaningful frame measured; not blocked by CMS calls. — emulator startup showed first-frame skips; profiling open.
- [ ] Pan/zoom has no severe sustained jank on target Android. — physical mid-range device blocked.
- [x] Layer toggle/feature sheet keeps persistent MapWidget.
- [x] Long lists use pagination/lazy loading; report images decode at bounded display size.
- [ ] Five report images/PDF open-close show no unbounded memory growth. — authenticated/device run blocked.
- [x] Search cancels stale requests.
- [ ] Background/resume and repeated tab changes remain crash-free. — extended device soak open.

## Release Sign-off

- [x] `dart format --output=none --set-exit-if-changed lib test`: 114 files, 0 changes after Release Closure pass.
- [x] `flutter analyze`: no issues after Release Closure pass.
- [x] `flutter test`: 63/63 passed; includes session/draft cleanup, HTTP matrix, GET-only retry, bounded presigned refresh, unsafe URL rejection and login/report focus regressions.
- [x] `flutter build apk --flavor dev -t lib/main.dart --debug`: built `build/app/outputs/flutter-apk/app-dev-debug.apk`.
- [x] API acceptance matrix attached for public guest/read scope. — `API_ACCEPTANCE_MATRIX.md`; authenticated/private/write/error-injection matrix remains open.
- [ ] Android and iOS recordings attached. — Android screenshots/XML attached; no interaction recording in this run and iOS blocked on macOS.
- [ ] Open P0/P1 defects = 0 or named PO waiver.
- [ ] High-impact risks closed/accepted by owner.
- [ ] Mapbox terms/cost/token restrictions accepted.
- [ ] Product Owner signs Done/Not Done without “100%” claim when blocked.
