# Screen Spec — M01–M22

## Global Contract

All screens use Vietnamese first, vi/en localization keys, light/dark themes, 48dp targets,
200% text support and semantic labels. API-backed screens retain content during refresh.
Applicable states: loading, refreshing, data, empty, error/retry, offline/stale, forbidden,
submitting, success, conflict. Do not render a state that cannot occur for that screen.

Analytics/event names below must contain route/action/result only; never email, phone, token,
free text, precise coordinates, photo name/content or raw feature attributes.

---

## M01 — Splash and Bootstrap

- **Route:** `/splash`; outside shell.
- **Hierarchy:** subtle contour background → civic GIS mark → “Mobile GIS Cẩm Phả” → compact progress → version.
- **Flow:** env/Firebase ready → token read → `/auth/me` → password gate or safe return route → `/map` guest on no/invalid session.
- **States:** initializing; config error + retry; offline cached session; offline guest fallback.
- **API/state:** `TokenStorage`, `GET /auth/me`, theme/locale preference. No news/docs request.
- **A11y:** progress announces concise phase once, no looping spoken updates.
- **Event:** `bootstrap_completed(result: guest|session|offline|config_error)`.
- **Acceptance:** no blank frame/dead-end; access token error clears both tokens/private cache; map first frame not blocked by CMS.

## M02 — Login

- **Route:** `/auth/login?returnTo=`; outside shell.
- **Hierarchy:** close/back → compact welcome mark/title → email/password → forgot → primary login → optional Google if configured → register.
- **Actions:** login; toggle password; forgot; Google; register; cancel.
- **States:** idle; inline invalid; submitting; credential/account/email verification/password-change/rate/network errors; success.
- **API:** `POST /auth/login`; tokens via `TokenStorage`; fetch/derive user session; preserve safe `returnTo`.
- **Validation:** normalized email; password required; never persist/log password; lock submit while pending.
- **A11y:** fields expose labels/errors; show-password announces state; banner focused on submit failure.
- **Event:** `login_submitted(method)` and result code only.
- **Acceptance:** 401 copy does not enumerate account; success returns exactly once; cancel restores origin.

## M03 — Citizen Registration

- **Route:** `/auth/register?returnTo=`.
- **Hierarchy:** app bar → identity section (name/email/phone optional) → security section → privacy consent → create account.
- **Actions:** register; password toggles; terms/privacy; return login.
- **States:** idle; field invalid; email used; submitting; verify-email success; authenticated success; server/rate/network error.
- **API:** `POST /auth/register`; branch on `requiresVerification`; optional phone.
- **Validation:** name 2–255; valid email; password 8–128; confirmation equal; phone server-compatible; consent required client-side.
- **A11y:** grouped headings; password requirements readable; not color-only.
- **Acceptance:** guest only; no assumption token exists after register; returnTo survives verification.

## M04 — Main Shell

- **Route:** shell roots `/map`, `/reports`, `/news`, `/documents`, `/profile`.
- **Hierarchy:** branch body + Material 3 NavigationBar/Rail.
- **Behavior:** IndexedStack preserves camera/scroll; re-tap list tab scrolls top; map re-tap keeps camera.
- **States:** normal; offline banner; profile badge for pending sync/push issue; shell-level session expiration.
- **Role:** public for all; tab content server-filtered.
- **A11y:** tab selected state/count announced; rail order equals bottom order.
- **Acceptance:** no placeholder; no cross-tab state loss; logout resets private branch stacks.

## M05 — Map Explorer

- **Route:** `/map`; shell tab 0.
- **Hierarchy:** edge-to-edge renderer; top search/profile; offline banner; right controls; scale/attribution; layer + tool actions above nav.
- **Actions:** search, query tap, profile/login, compass, GPS, weather, layers, measure, route, draw.
- **States:** style loading/error; map loaded; tile 401/403/5xx; offline/cache; low GPS accuracy; active tool mode.
- **API:** layers/basemaps; Mapbox styles; MVT; optional auth exact-host header.
- **Role:** guest public layer; server permission decides private catalog/actions.
- **A11y:** non-map alternatives for selected feature/result; controls named; attribution visible.
- **Event:** map screen/renderer result and tool selected; no coordinate.
- **Acceptance:** Cẩm Phả camera/bounds; pan/pinch/rotate; overlays do not rebuild whole map; tab preserves camera.

## M06 — Layer Catalog

- **Owner:** modal bottom sheet from M05.
- **Hierarchy:** handle/header/active count → search → category accordions → layer rows → basemap section → disable-all.
- **Layer row:** geometry icon, localized name, visible switch, info/legend, active opacity.
- **States:** loading skeleton; categorized data; empty search; catalog error; layer tile loading/error; forbidden item never leaks.
- **API:** `GET /web-map/layers`, legend, basemaps.
- **Behavior:** local visibility optimistic; source failure communicates and rolls back according to prior valid state.
- **A11y:** switch includes layer name/state; opacity numeric value; accordion expansion announced.
- **Acceptance:** active count accurate; state retained during session; no hard-coded backend layer list.

## M07 — Feature Info / Nearby

- **Route:** shareable `/map/feature/:layerId/:featureId`; quick view sheet from map.
- **Hierarchy:** layer/title/short ID → allowed attribute table → geometry summary → nearby/route/share → TNMT edit/history.
- **States:** skeleton; data; missing; forbidden; stale version; nearby loading/empty/error.
- **API:** mobile feature detail, layer nearby.
- **Security:** show only serialized/allowlisted fields; sanitize values; no internal table/column disclosure.
- **A11y:** label/value semantics; geometry has text summary; actions ordered.
- **Acceptance:** selected geometry remains visible; direct link restores map context; TNMT actions use exact role+permission.

## M08 — Map Search

- **Route:** `/map/search`.
- **Hierarchy:** autofocus search/clear → recent local searches → grouped live results.
- **Result:** geometry icon, primary field, layer, optional approximate distance.
- **States:** idle/recent; debounce loading; grouped data; no result; query invalid; API/offline error.
- **API:** `/web-map/features/search`; q 2–100, optional layer/bbox, limit ≤50.
- **Behavior:** debounce 350–500ms, cancel stale request; tap closes search, moves camera and opens M07.
- **Privacy:** recent query local and clearable; never include token/location in event.
- **Acceptance:** latest query wins; keyboard/back behavior stable; safe highlights without raw HTML.

## M09 — Location and Weather

- **Owner:** compact sheet from GPS/weather controls.
- **Hierarchy:** rounded coordinate → accuracy icon/value → timestamp → weather values → nearby/start-point actions.
- **States:** primer; permission denied/permanent; locating; low accuracy; location data; weather loading/data/unavailable; offline.
- **API/platform:** geolocator; weather lon/lat; nearby optional.
- **Validation:** Cẩm Phả bounds before API; weather absent remains unavailable, never fabricated.
- **A11y:** accuracy includes label, not color; open settings action explicit.
- **Acceptance:** permission asked at use time; no background location; displayed coordinate rounded.

## M10 — Measure Mode

- **Owner:** map contextual mode.
- **Hierarchy:** mode bar distance/area → map vertices/crosshair → result card → undo/redo/clear/complete/cancel.
- **States:** zero/valid/invalid points; live preview; server submitting; official result; validation/API/offline error.
- **API:** `POST /mobile/measure` with LineString or closed Polygon.
- **Validation:** line ≥2; polygon ring ≥4 including closure; max server limits; all points in bounds.
- **Visual:** clay geometry with casing/halo; official result marked “Hệ thống xác nhận”.
- **A11y:** point count/action availability/results announced; alternative list of vertices not required in MVP, but result text required.
- **Acceptance:** undo/redo deterministic; close segment visible; cancel restores prior map state.

## M11 — Route

- **Owner:** map sheet + result overlay.
- **Hierarchy:** start/end selectors + swap → network layer → find route → length/start/end result + clear.
- **States:** incomplete; selecting point; submitting; route data; network-not-ready 409; no-route/too-long 422; offline/error.
- **API:** `POST /mobile/routes/shortest` with `start`, `end`, layer and bounded radii.
- **Behavior:** GPS/search/map/feature input; changing endpoints cancels old request; pgRouting only.
- **A11y:** start/end labels, swap meaning, route length textual.
- **Acceptance:** GeoJSON visible; snapped endpoints distinguish requested points; no Mapbox Directions fallback.

## M12 — Draw and Drafts

- **Routes:** draw mode owner M05; list `/map/drafts`.
- **Draw hierarchy:** type Point/Line/Polygon → vertex controls → title/properties form → save.
- **List hierarchy:** search → geometry/title/updated → zoom/edit/delete.
- **States:** guest preview; auth return; saving; list loading/empty/error; delete confirmation/submitting/conflict 409.
- **API:** create/list/detail/delete drafts; envelope and optimistic timestamp.
- **Validation:** title 1–200 no HTML; ≤30 properties/16KB/depth 4; geometry bounds/closure.
- **Acceptance:** payload exactly `title/properties/geometry`; guest geometry retained across in-process login; conflict never hides item silently.

## M13 — TNMT Feature Editor

- **Route:** `/map/feature/:layerId/:featureId/edit`.
- **Hierarchy:** step 1 attributes from allowlist → step 2 geometry → version footer/cancel/save.
- **States:** guard; loading; invalid; dirty; submitting; success; 409 compare; 403; stale/offline.
- **API:** PATCH feature with `baseVersion`, attributes and/or geometry.
- **Guard:** role `so_tnmt` + `permissions.map_feature.update`; server still final.
- **Security:** never edit ID/system geometry columns not allowed; no force overwrite.
- **A11y:** map geometry edits also expose count/validity and undo actions.
- **Acceptance:** back confirms unsaved; conflict preserves local and server choices (reload or local draft).

## M14 — Feature History and Restore

- **Route:** `/map/feature/:layerId/:featureId/history`.
- **Hierarchy:** current version → version timeline (actor/time/action/changed fields) → preview → restore confirm.
- **States:** loading/empty/data/error/forbidden; preview loading; restore submitting/success/conflict.
- **API:** history and restore `baseVersion`.
- **A11y:** timeline reads newest-first with current badge; map preview has attribute summary.
- **Acceptance:** restore explains it creates new version; uses latest base; conflict reloads history, no silent retry.

## M15 — Field Report List/Map

- **Route:** `/reports`; shell tab 1.
- **Hierarchy:** title → list/map segment → status/date/near filters → report cards/markers → create FAB.
- **Card:** real thumbnail if available; status icon/label; distance if GPS; relative time; two-line description.
- **States:** loading skeleton; empty public; filtered empty; data; pagination; error; offline cached; map errors.
- **API:** public list; nearby with required from/to; optional auth.
- **Role:** guest reads public; create auth/permission gate.
- **A11y:** list is equivalent to map markers; filter state announced.
- **Acceptance:** map/list share filters; no fabricated thumbnails; time range always supplied for nearby.

## M16 — Create Field Report

- **Route:** `/reports/new`.
- **Hierarchy:** 3-step progress.
  1. Evidence: capture/select, 1–5 thumbnails, remove/retry.
  2. Location: GPS accuracy, adjustable pin, optional geometry.
  3. Description 10–2000, truth confirmation, summary.
- **Submit stages:** presign → direct upload → commit each → create report.
- **States:** local draft; permission denied; media invalid; upload progress/failure; offline unsent; creating; success.
- **API:** storage lifecycle then report body.
- **Privacy:** no upload before explicit submit unless draft copy states it; preserve only required local path; no EXIF/log disclosure.
- **A11y:** step labels/status; thumbnail progress/remove names; error focuses failed item.
- **Acceptance:** double-submit locked; only committed IDs sent as `photoIds`; failure retains form/media paths.

## M17 — My Reports and Detail

- **Routes:** `/reports/mine`, `/reports/:id`.
- **Hierarchy:** mine status/paged list; detail status timeline → image carousel → map/geometry → description → timestamps/review reason → allowed delete.
- **States:** loading/empty/data/error/offline/forbidden; photo URL expired/retry; delete confirm/submitting/conflict.
- **API:** mine/detail/delete; detail includes short-lived photo URLs/history.
- **Security:** server decides ownership/reviewer access; screenshots/privacy caution for PII.
- **Acceptance:** URL expiry requests detail/new URL, not stored permanently; optimistic delete timestamp required.

## M18 — News List

- **Route:** `/news`; shell tab 2.
- **Hierarchy:** title → sticky search → first item emphasis only when content truly exists → paged cards.
- **Card:** real cover if contract provides; otherwise designed category treatment, title/summary/publish time.
- **States:** skeleton; data; empty search; first/append error; refreshing; offline stale.
- **API:** paged news query; q ≤100.
- **A11y:** cards semantic buttons; image alt/decorative; dates localized.
- **Acceptance:** cancellable debounce; retain old items during append; no invented “featured” flag.

## M19 — News Detail and Comments

- **Route:** `/news/:id`.
- **Hierarchy:** title/meta/cover → readable sanitized content → share → paged comments → composer/auth CTA.
- **States:** detail loading/missing/error/offline; comments loading/empty/page error; submit invalid/loading/success/rate/error.
- **API:** news detail/comments; post `{content}`.
- **Security:** plain/sanitized HTML only, no arbitrary JS WebView; comment 1–2000 no HTML.
- **Acceptance:** guest login returns to article/composer; submit once; new comment reflects server status.

## M20 — Documents and PDF Maps

- **Route:** `/documents`; shell tab 3.
- **Hierarchy:** title → segment documents/PDF → search → server-allowed filters → paged cards.
- **Card:** document code/title/agency/date/lock; PDF title/scale/year/preparing agency.
- **States:** public guest; authenticated expanded data; loading/empty/error/offline/page append.
- **API:** documents/PDF lists with `data.items + metadata`.
- **Security:** lock label is informative only; never reveal internal item returned only from stale other-user cache.
- **Acceptance:** q title/code; branch scroll retained; logout purges internal cached items.

## M21 — Document/PDF Detail

- **Routes:** `/documents/:id`, `/pdf-maps/:id`.
- **Hierarchy:** metadata card → description → view/download primary → share/open external.
- **States:** loading/missing/forbidden/offline metadata; requesting URL; opening; expired retry; unsupported/error.
- **API:** detail and authenticated download-url, expiry 60–900.
- **Behavior:** request URL only on action; default system viewer via installed `url_launcher`; in-app viewer only if later required.
- **A11y:** file type/size/action consequence read; progress announced.
- **Acceptance:** no long-term URL storage; guest auth returnTo; graceful unsupported file.

## M22 — Profile, Settings and Sync

- **Route:** `/profile`; children edit/settings/offline/notifications.
- **Guest hierarchy:** login/register callout → theme/language → privacy/help/version.
- **Authenticated hierarchy:** avatar/name/role/email → profile, mine reports, drafts, offline queue, notifications, appearance/language/permissions → logout.
- **States:** user loading/error/offline cached; queue pending/syncing/conflict/failed; logout submitting.
- **API/state:** `/auth/me`, profile patch, push unregister, token clear; queue from Sprint 6.
- **Security:** queue summary hides raw PII payload; changing user/logout purges private cache.
- **A11y:** role/status textual; theme group radio semantics; logout confirmation.
- **Acceptance:** theme light/dark/system and vi/en persist; permission rows reflect platform state; logout works offline locally.

## Screen-to-Sprint Trace

| Sprint | Screens |
|---|---|
| 1 | M01–M04, M22 foundation |
| 2 | M18–M21 |
| 3 | M05–M08 |
| 4 | M09–M12 |
| 5 | M15–M17 |
| 6 | M13–M14, M22 offline queue |
| 7 | Cross-screen hardening |
