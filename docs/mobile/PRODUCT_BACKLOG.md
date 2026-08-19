# Product Backlog — Mobile GIS Cẩm Phả

## Backlog Policy

- Priority: P0 release-critical, P1 core value, P2 enhancement.
- Estimate: Fibonacci story points; re-estimate only during refinement with evidence.
- Story cannot enter Sprint unless Definition of Ready passes.
- `Blocked` is not `Done`; mock does not satisfy live acceptance.

## Definition of Ready

- Persona/value and Given/When/Then acceptance criteria clear.
- Route/UI states and API method/path/body/response audited.
- Permission, dependency, privacy and error behavior known.
- Story small enough for one Sprint; design direction accepted.

## Definition of Done

- Accessible routed UI; no dead control/placeholder.
- API real or evidenced backend blocker; typed state and error mapping.
- Loading/refresh/empty/error/offline/forbidden/conflict states as applicable.
- Client validation + server enforcement; double-submit protected.
- Unit/widget/contract checks; format/analyze/test clean.
- Emulator/device screenshot or recording; docs/risk/backlog updated.
- No token, PII, exact GPS or media in logs/evidence.

## Sprint 0 — Discovery and Foundation (20 SP)

| ID | Story | SP | Priority | Status | Output |
|---|---|---:|---:|---|---|
| MOB-001 | Audit mobile source: giữ/sửa/thiếu/xóa | 5 | P0 | Done | `SOURCE_AUDIT.md` |
| MOB-002 | Audit Auth/Map/GIS/CMS/Report/Storage contracts + live smoke | 5 | P0 | Done with blocker | `API_CONTRACT_AUDIT.md` |
| MOB-003 | Select renderer and prove basemap/GeoJSON/MVT/auth header | 5 | P0 | Done with blocker | ADR + spike/evidence |
| MOB-004 | Product/screen/navigation/design/RBAC artifacts | 5 | P0 | Done | docs/mobile |

**Sprint 0 acceptance:**

- Given current backend, when each target mobile endpoint is reviewed, then method/input/envelope/auth/error are documented.
- Given Mapbox configuration, when spike runs on Android, then custom basemap and GeoJSON render with timing/error state.
- Given real MVT, when tile request fails, then exact backend blocker is captured; no mock is signed off.
- Given M01–M22, when product review occurs, then hierarchy, state, role and API ownership are traceable.

## Sprint 1 — Auth, Session, Shell and Profile (34 SP)

| ID | Story / screen | SP | Priority | Dependencies |
|---|---|---:|---:|---|
| MOB-101 | Splash/bootstrap session — M01 | 3 | P0 | TokenStorage, `/auth/me` |
| MOB-102 | Login/change-password/errors — M02 | 8 | P0 | auth DTO/error mapping |
| MOB-103 | Citizen registration/verification — M03 | 8 | P0 | register response branches |
| MOB-104 | Shared token lifecycle, refresh mutex, logout, router returnTo | 8 | P0 | auth/session notifier |
| MOB-105 | Indexed shell + guest/auth profile/settings — M04/M22 | 7 | P0 | navigation/RBAC/i18n |

Key acceptance:

- Given valid saved tokens, when cold-starting, then `/me` restores session without duplicate storage.
- Given expired access token, when requests return 401 together, then one refresh rotates both tokens.
- Given guest opens a write deep link, when login succeeds, then route returns to validated `returnTo`.
- Given logout, when complete/offline, then local tokens/private caches/map host header are cleared.

## Sprint 2 — CMS Content (36 SP)

| ID | Story / screen | SP | Priority | Dependencies | Status |
|---|---|---:|---:|---|---|
| MOB-201 | News search/pagination — M18 | 5 | P1 | paged envelope primitive | Done |
| MOB-202 | News detail/share — M19 | 5 | P1 | content sanitizer contract | Done |
| MOB-203 | Comments list/create/auth return — M19 | 8 | P1 | session | Done; authenticated create runtime blocked by credential |
| MOB-204 | Public/internal documents search — M20 | 5 | P1 | permissions | Public Done; internal runtime blocked by permission fixture |
| MOB-205 | Document detail/presigned open/share — M21 | 8 | P1 | system open decision | Done; grant success runtime blocked by permission fixture |
| MOB-206 | PDF map list/detail/download — M20/M21 | 5 | P1 | same download primitive | Done; grant success runtime blocked by permission fixture |

Acceptance implementation complete: `data.items + metadata`, 400 ms cancellable search, stale-content state,
presigned URL requested only on action. Runtime evidence/blockers: `SPRINTS/SPRINT_02.md`.

## Sprint 3 — Map Explorer Core (40 SP)

| ID | Story / screen | SP | Priority | Dependencies |
|---|---|---:|---:|---|
| MOB-301 | Map shell, styles, camera/bounds — M05 | 8 | P0 | ADR-001, Mapbox token |
| MOB-302 | Catalog/group/toggle/opacity/legend/basemap — M06 | 8 | P0 | layer DTO |
| MOB-303 | MVT public/private + exact-host token rotation | 13 | P0 | **backend MVT 200** |
| MOB-304 | Tap/query feature info — M07 | 5 | P1 | configured IDs/fields |
| MOB-305 | Search/group/zoom result — M08 | 6 | P1 | search API |

Acceptance: real `ranhgioi_campha` visible; source-layer equals code; tile 401/403/500 recoverable;
tab switch preserves camera; map attribution and accessibility alternatives remain.

## Sprint 4 — GIS Field Tools (40 SP)

| ID | Story / screen | SP | Priority | Dependencies |
|---|---|---:|---:|---|
| MOB-401 | GPS primer/permission/accuracy — M09 | 5 | P1 | geolocator |
| MOB-402 | Live weather at location — M09 | 3 | P1 | weather API |
| MOB-403 | Nearby features — M07/M09 | 5 | P1 | active layer/location |
| MOB-404 | Measure line/polygon — M10 | 8 | P1 | geometry validation |
| MOB-405 | pgRouting start/end/route — M11 | 8 | P1 | ready line network fixture |
| MOB-406 | Draw/save/list/delete drafts — M12 | 11 | P1 | auth + optimistic timestamp |

Acceptance: mode ownership prevents gesture collisions; undo/redo/clear/cancel; official values from backend;
route requests cancel on endpoint changes; guest draw survives auth transition while process lives.

## Sprint 5 — Field Reports (36 SP)

| ID | Story / screen | SP | Priority | Dependencies |
|---|---|---:|---:|---|
| MOB-501 | Public list/map/nearby time range — M15 | 5 | P1 | report serializers |
| MOB-502 | 3-step report form — M16 | 13 | P0 | image source + GPS + local form |
| MOB-503 | Presign/direct upload/commit/retry | 8 | P0 | storage service availability |
| MOB-504 | Mine/detail/history/delete — M17 | 5 | P1 | session/optimistic lock |
| MOB-505 | Push register/unregister/deep link | 5 | P1 | Firebase config/session |

Acceptance: 1–5 PNG/WebP evidence, description 10–2000, bounds validation, upload stages visible,
double tap creates once, unsent form survives network loss, push opens correct authorized report.

Review: M15–M17 code, exact storage contracts, local persistence and Android public path Done;
authenticated upload/mine/detail/delete Blocked bởi credential; push delivery Blocked bởi Firebase native resources.

## Sprint 6 — TNMT Edit and Offline Sync (40 SP)

| ID | Story / screen | SP | Priority | Dependencies |
|---|---|---:|---:|---|
| MOB-601 | Allowed attribute editor — M13 | 8 | P0 | TNMT fixture/allowlist |
| MOB-602 | Geometry vertex editor/client validity — M13 | 8 | P0 | Mapbox overlay interactions |
| MOB-603 | History/preview/restore — M14 | 5 | P1 | version response |
| MOB-604 | Sqflite queue + UUID client/change | 8 | P0 | schema migration/tests |
| MOB-605 | Sync applied/conflict/rejected compare | 11 | P0 | offline API + fixtures |

Acceptance: only exact TNMT permission exposes edit; `baseVersion`; 409 preserves local/server;
no force overwrite; retry bounded; same clientChangeId never duplicates an applied change.

Review: exact backend capability/allowlist/version contract, editor/history/offline queue and Android guest proof Done;
authenticated TNMT conflict/restore/sync runtime Blocked bởi credential và editable/versioned fixture.

## Sprint 7 — Hardening and Release Candidate (30 SP)

| ID | Story | SP | Priority | Status |
|---|---|---:|---:|---|
| MOB-701 | Accessibility, vi/en, light/dark/system audit | 5 | P0 | Code Done; TalkBack/200% physical runtime open |
| MOB-702 | Map/list/image memory and frame profiling | 5 | P0 | Code hardening Done; physical profiling Blocked |
| MOB-703 | Security/privacy/permission copy review | 5 | P0 | Code audit Done; owner/runtime review open |
| MOB-704 | Regression/API acceptance/device matrix | 8 | P0 | 61 mobile + 14 backend tests and Android guest Done; role/device matrix Blocked |
| MOB-705 | Crash-free smoke/release config/handoff | 7 | P0 | Guest smoke/config/handoff Done; Firebase/signing/iOS Blocked |
| MOB-706 | Release Closure: session privacy, error/retry, CMS grant, first-error focus | — | P0 | Code/automated gates Done; authenticated/device UAT Blocked |

Acceptance: local `.env` not used by release/profile; HTTPS/WSS guard; zero raw error/log payload;
Android guest evidence attached. Release Closure 2026-08-11: format/analyze clean, 63/63 tests, Android debug/profile performance-security audit PASS.
Final production RC sign-off Not Done until named blockers are fixed or explicitly waived.

## Cross-cutting Enablers

| ID | Item | Schedule trigger |
|---|---|---|
| EN-01 | First-class 409/422 errors and server code preservation | Sprint 1 before first form |
| EN-02 | Typed paged envelope helper | Sprint 2 first list |
| EN-03 | Geometry validators/bounds/closure | Sprint 4 first tool |
| EN-04 | Safe technical telemetry/redaction | Extend only with each feature |
| EN-05 | Cache migration harness | Sprint 6 only |

## Current Blockers

| Blocker | Affects | Owner/exit |
|---|---|---|
| MVT 500: missing `source_fid` | MOB-003 live MVT; MOB-303 | Backend GIS metadata/table fixed; protobuf 200 |
| No runtime acceptance password | Authenticated smoke across Sprints | PO supplies secret runtime or manual login |
| Routing fixture only Point in handoff | MOB-405/route admin | Backend line network fixture ready |
| Firebase flavor resources/signing/prod HTTPS config unavailable | Push/crash and production packaging | Ops securely supplies Android/iOS config, endpoints and signing |
| Physical Android/TalkBack/performance soak unavailable | Accessibility/performance release gate | QA runs representative device matrix and attaches evidence |
| Mapbox terms/cost not release-reviewed | MOB-301/RC | PO/legal/ops acceptance before release |
| iOS toolchain unavailable on Windows | iOS runtime UAT | macOS CI/device step before RC |
