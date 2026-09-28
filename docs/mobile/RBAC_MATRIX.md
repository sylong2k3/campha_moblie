# RBAC Matrix — Mobile GIS Cẩm Phả

## Source of Truth

1. JWT identifies actor; `/auth/me` supplies role and permission payload.
2. Active `system_admin` has all client capability flags, even if permission entries are missing/false. Other roles still use the permission payload; inactive users have no capability flags.
3. Backend middleware/service remains final authority. Client capabilities do not alter tokens, roles, payloads or server authorization.
4. Matrix below is a UX baseline, not an authorization replacement.

Role codes: `guest`, `citizen`, `ubnd_tp`, `so_tnmt`, `so_xd`, `system_admin`.

## Mobile Capability Matrix

Legend: ✓ available; — unavailable; P = permission payload decides; A = active admin client capability, subject to server authorization; Public = server-filtered public data.

| Capability / permission | guest | citizen | ubnd_tp | so_tnmt | so_xd | system_admin |
|---|---:|---:|---:|---:|---:|---:|
| Register `auth.register` | ✓ | — | — | — | — | — |
| Login `auth.login` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Own profile | — | P | P | P | P | A |
| Map/layer `map.view` | Public | P | P | P | P | A |
| Feature info `map.view_attributes` | Public | P | P | P | P | A |
| Search `map.search_feature` | Public | P | P | P | P | A |
| Legend `map.view_legend` | Public | P | P | P | P | A |
| GPS `map.locate` | ✓ | P | P | P | P | A |
| Measure `map.measure` | ✓ | P | P | P | P | A |
| Route `map.route` | ✓ | P | P | P | P | A |
| Weather `weather.read` | ✓ | P | P | P | P | A |
| Draw preview | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Save draft `map.draw` | — | P | P | P | P | A |
| Edit base feature `map_feature.update` | — | — | — | **P** | — | A + editable layer |
| Feature history/restore | — | — | — | **P** | — | A |
| News public `news.read_public` | ✓ | P | P | P | P | A |
| News comment `news.comment` | — | P | P | P | P | A |
| Public documents/PDF | ✓ | P | P | P | P | A |
| Internal documents `documents.read_internal` | — | — | P | P | P | A |
| Document/PDF download | — | P by content | P | P | P | A |
| Public reports | Public | Public | Public | Public | Public | Public |
| Create report `field_report.create` | — | P | P | P | P | A |
| Report measurement `field_report.measure` | — | P | P | P | P | A |
| Own reports (view/delete own) | — | ✓ | ✓ | ✓ | ✓ | ✓ |
| Admin reports `field_report.read` | — | — | P | P | P | A |
| Review report `field_report.approve` + read | — | — | P | P | P | A |
| Report analytics `field_report.stats` + read | — | — | P | P | P | A |
| New-report notifications `field_report.notify` | — | — | P (server) | P (server) | P (server) | A (server) |
| Offline feature sync | — | — | — | P | — | A |

### Admin client scope (2026-09-28)

- Shared `UserModel.canEditMapFeatures` gates edit/history routes, detail actions, edit form and offline-sync menu.
- Admin can use existing functions and the report management tab; user/role/log management remains outside mobile scope.
- Layer `canEdit`, editable-field allowlist, geometry validation, `baseVersion`, restore confirmation and offline queue ownership remain enforced.
- Backend is not in this workspace and was not changed. Live read-only QA on 2026-09-28: all five sample roles logged in successfully; admin catalog returned 174 layers with `canEdit=false`, TNMT catalog returned 80 layers (22 editable). Admin edit UI therefore remains unavailable for current live layers until backend grants layer access. No live feature writes/restores were attempted.

### Field report management (2026-09-28)

- Active, authenticated `ubnd_tp`, `so_tnmt`, `so_xd`, `system_admin` with read capability default to **Quản lý phản ánh**. Public scope remains available separately, including GPS nearby search.
- Admin list/detail use `/api/v1/admin/field-reports`; public/nearby use `/api/v1/field-reports`. Public parsing only accepts `approved`/`resolved` and discards sender/reviewer/history fields.
- Admin detail displays sender name/email/ID, review reason, reviewer ID, timestamp and server audit history. No reviewer name is invented when API only supplies ID.
- Main map automatically fetches every list page (100 reports/request), deduplicates IDs and updates markers once per completed batch. Status/scope changes and refresh repeat the full load; list mode keeps manual pagination. No map load-more button. Failed pages expose incomplete-load feedback; access changes cancel remaining pages. GPS nearby remains a separate filtered API query.
- Backend status is `under_review`, not `reviewing`. Allowed transitions: `pending` to `under_review`/`approved`/`rejected`; `under_review` to `approved`/`rejected`; `approved` to `resolved`. Rejected/resolved reports are terminal.
- Review sends `{status, reason?, expectedUpdatedAt}`. Rejection requires reason; supplied reasons contain 5–1000 characters. `review_reason` is response data, not the PATCH input key. Conflict 409 requires reload before resubmission; typed reason is retained.
- Clusters require stats + read client capabilities; request includes `from`, `to`, `radiusMeters` (10–500), `minReporters` (2–20). Results are capped at 200 clusters, not a global report total.
- Access/account changes cancel pending requests and clear private list/detail/cluster state. Admin 401/403 clears private data, without public fallback or automatic review retry.
- Existing push registration remains in use; server chooses recipients. Report pushes refresh initialized management lists; report links open admin detail for permitted managers. No second WebSocket connection or polling loop added.
- Adjacent backend source was inspected read-only to verify these contracts; no backend edits or live report review writes performed. Own reports/create/upload flows remain available.

## Runtime Gating Rules

### Read actions

- Guest calls optional-auth endpoints; server only returns public/accessibly serialized resources.
- Never display private layer name/metadata learned from stale cache after logout.
- Authenticated cached screen revalidates on permission/user change.

### Write actions

- Capability-gated buttons use active admin access or the explicit non-admin permission and feature-specific role condition.
- Forbidden GIS deep links return to map; the edit form also checks capability and layer editability.
- Server 403 is surfaced as an error; no token refresh or automatic write retry bypasses it.
- Guest write action opens auth flow with `returnTo` and preserves safe draft input.

### Dangerous map edit

All must hold:

```text
session authenticated, required password change completed
user.is_active == true
role == system_admin OR (role == so_tnmt AND permissions.map_feature.update == true)
layer.canEdit == true (API-provided)
current baseVersion and geometry present
only layer.editableFields may be edited
```

Mobile cannot infer layer editability from role alone. Conflict 409 never enables force overwrite.

## Discrepancies / Decisions

| Area | Static matrix | Backend audit (reverified only where stated) | Mobile decision |
|---|---|---|---|
| Field report create | CSV line A.2-11 says citizen only; B-2 says citizen/UBND/TNMT/XD | Service uses `permissions.field_report.create` | Existing authenticated create flow includes admin; server may deny |
| Report approve | Older CSV excludes admin | Current adjacent source reverified: `ubnd_tp`, `so_tnmt`, `so_xd`, `system_admin` plus approve permission | Permission-scoped management list/detail/review/clusters now available; server remains final authority |
| Feature edit | TNMT only; admin excluded | Service explicitly requires `actor.role === so_tnmt` + permission | Active admin and explicitly permitted TNMT pass client gate; backend must separately authorize admin |
| Map public actions | Matrix allows guest | `optionalAuth`; `requirePermission` skips when actor absent | Guest UX enabled; response remains server-filtered |
| Draft save | Guest denied | Auth middleware required | Guest can draw temporary, auth required on Save |
| Document download | Public metadata readable, download endpoints require token | Bearer required for all download-url routes | Guest reads detail, login on download, then returnTo |

## Role Labels

| Code | Vietnamese | Short |
|---|---|---|
| `guest` | Khách | Khách |
| `citizen` | Người dân | Người dân |
| `ubnd_tp` | Cán bộ UBND thành phố | UBND TP |
| `so_tnmt` | Cán bộ Sở Tài nguyên và Môi trường | Sở TNMT |
| `so_xd` | Cán bộ Sở Xây dựng | Sở XD |
| `system_admin` | Quản trị viên hệ thống | Quản trị |

Mobile enum/ARB uses current `so_tnmt` and `ubnd_tp` codes; unknown role codes map to guest.

## RBAC Test Minimum

1. `UserRole.fromApiValue` covers all five backend roles + unknown → guest.
2. Guest cannot reach write endpoint from UI, but public read paths work.
3. Active admin has client capabilities with missing/false permissions; serialized role/payload stays unchanged.
4. Inactive admin, unknown role and citizen cannot gain GIS edit access; TNMT still needs explicit update permission.
5. Admin passes edit/history/offline guards; guest login and forced password-change redirects remain intact.
6. Read-only layers, missing versions, field allowlists and server 403 remain enforced; writes are not retried automatically.
7. Logout clears private cached catalog and exact-host Mapbox Authorization header.
8. Four manager roles use admin list/detail, never public fallback; citizen/unknown role cannot access private reports.
9. Logout/permission loss and delayed success/error responses cannot repopulate PII.
10. Review validates transitions/reason, prevents duplicate submission and handles 403/409 without write retry.

Admin regression: `flutter test test/admin_permissions_test.dart`.
Report regression: `flutter test test/field_report_admin_test.dart test/field_report_admin_widget_test.dart test/field_report_status_colors_test.dart`.
