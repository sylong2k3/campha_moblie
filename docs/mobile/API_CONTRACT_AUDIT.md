# API Contract Audit — Sprint 0

Audit date: 2026-08-10. Sources, theo thứ tự ưu tiên:
route → validator → controller/service/repository → live response tại `127.0.0.1:3006`.
Backend code hiện hành thắng tài liệu handoff cũ.

## Conventions

### Base and auth

- Base: `/api/v1`.
- `optionalAuth`: public request chạy guest; JWT hợp lệ mở thêm permission-scoped data.
- `verifyToken + enforcePasswordChange`: JWT bắt buộc; account có temporary password bị chặn.
- Request ghi phải chống double-submit phía UI; idempotency chỉ dùng khi server hỗ trợ route đó.

### Success envelope

```json
{"message":"...","status":200,"data":{},"metadata":{}}
```

Paged lists:

```json
{
  "data":{"items":[]},
  "metadata":{"page":1,"limit":20,"total":0,"totalPages":0}
}
```

### Error envelope

```json
{"success":false,"message":"...","errors":["ERROR_CODE"]}
```

Client must preserve status and `errors`: 400 validation, 401 session, 403 permission,
404 missing, 409 optimistic conflict, 413 size, 422 semantic/spatial, 429 rate, 5xx service.
Never show/log backend stack in app; server development currently exposes stack on some 500 responses.

## Auth

| Method/path | Auth | Input | Key output/status |
|---|---|---|---|
| `POST /auth/register` | Public | `email`, `password` 8–128, `fullName` 2–255, optional `phone` | `user`, `requiresVerification`; tokens only when verification disabled |
| `POST /auth/login` | Public | `email`, `password` | `user`, `accessToken`, `refreshToken`; 401 message must not enumerate user |
| `POST /auth/refresh` | Public | `refreshToken` | rotated `accessToken`, `refreshToken` |
| `POST /auth/logout` | Bearer | optional `refreshToken` | logout result; client always clears local session |
| `GET /auth/me` | Bearer | — | sanitized user |
| `PATCH /auth/me` | Bearer multipart | optional `fullName`, `phone`, `avatarUrl`, `expectedUpdatedAt`, optional avatar file | sanitized user; possible 409 |
| `POST /auth/change-password` | Bearer | `oldPassword`, new distinct `newPassword` 8–128 | success; token behavior verify service during Sprint 1 |
| `POST /auth/set-password` | Bearer | `newPassword` 8–128 | Google/no-password account flow |
| `POST /auth/forgot-password` | Public/rate limited | `email` | enumeration-safe result |
| `POST /auth/reset-password` | Public/rate limited | `token`, `newPassword` | reset result |
| `POST /auth/verify-email` | Public | `token` | verification/auth result per service |
| `POST /auth/resend-verification` | Public/rate limited | `email` | enumeration-safe result |
| `POST /auth/google/mobile` | Public | `idToken` | user + token pair |

Sanitized user shape:

```json
{
  "id":"3",
  "email":"...",
  "full_name":"...",
  "phone":null,
  "avatar_url":null,
  "role":{"code":"citizen","name":"...","permissions":{}},
  "is_active":true,
  "email_verified":true,
  "must_change_password":false,
  "has_password":true
}
```

**Mobile status:** mismatch. Duplicate secure storage, wrong nested user parsing, swallowed errors,
manual Authorization, register result cannot represent verify-email branch.

## Web Map

| Method/path | Auth | Query/params | Response data |
|---|---|---|---|
| `GET /web-map/layers` | Optional | optional `category` max 50 | array of serialized layers |
| `GET /web-map/layers/:layerId/features/:featureId` | Optional | `includeGeometry` bool default false | `{layerId, feature}` |
| `GET /web-map/features/search` | Optional | `q` 2–100; optional `layerId`, CSV `bbox`; `limit` 1–50 | result array grouped client-side by layer |
| `GET /web-map/layers/:layerId/legend` | Optional | positive layer ID | layer/style/zoom/legend object |
| `GET /web-map/basemaps` | Optional | — | basemap array |
| `GET /web-map/terrain` | Optional | — | terrain catalog, permission `map.view_3d` |
| `GET /web-map/terrain/:layerId/url` | Optional | `expireSeconds` 60–900 | presigned result |

Layer serializer:

```json
{
  "id":"1","code":"ranhgioi_campha","nameVi":"...","category":"ranh_gioi",
  "geometryType":"MULTILINESTRING","srid":4326,"geoserverLayer":"campha:...",
  "styleName":null,"minZoom":null,"maxZoom":null,"legend":{},"isPublic":true
}
```

**Mobile status:** catalog parse list works; model field names/defaults and missing metadata are wrong.
Search/legend/basemap methods missing.

## Mobile GIS

Cẩm Phả coordinate boundary: longitude `107..108`, latitude `20.7..21.3`.

| Method/path | Auth | Input | Response/notes |
|---|---|---|---|
| `GET /mobile/layers/:id/tiles/:z/:x/:y.mvt` | Optional | `z` 0–22; URL **must end `.mvt`** | protobuf; empty outside layer zoom |
| `GET /mobile/layers/:id/features/:featureId` | Optional | safe feature ID | `{layerId, feature}` including geometry |
| `GET /mobile/layers/:id/nearby` | Optional | lon/lat; radius 10–2000 default 200; limit 1–100 | array, `feature_id`, configured fields, `distance_m`, point location |
| `GET /mobile/weather/current` | Optional | lon/lat | observedAt/location/temp/wind/description; 503 if upstream unavailable |
| `POST /mobile/measure` | Optional | `{geometry}` LineString/closed Polygon | `{geometry_type,length_m,area_m2}` |
| `POST /mobile/routes/shortest` | Optional | see payload below | route object; 409 network not ready; 422 no/too-long route |
| `POST /mobile/drafts` | Bearer | `{title,properties,geometry}` | draft row |
| `GET /mobile/drafts` | Bearer | page/limit | controller returns paged `data.items` + metadata |
| `GET /mobile/drafts/:id` | Bearer | positive ID | draft row |
| `DELETE /mobile/drafts/:id` | Bearer | required query `expectedUpdatedAt` ISO | `{id}`; 409 stale |
| `PATCH /mobile/layers/:layerId/features/:featureId` | Bearer TNMT permission | `{baseVersion,attributes?,geometry?}` | applied result; 409 conflict |
| `GET .../history` | Bearer TNMT permission | IDs | history array/result from controller |
| `POST .../restore/:version` | Bearer TNMT permission | `{baseVersion}` | new version; 409 conflict |
| `POST /mobile/sync` | Bearer TNMT permission | `{clientId,changes}` UUID v4 | arrays `applied`, `conflicts`, `rejected` |

Route body:

```json
{
  "layerId":1,
  "start":[107.1,21.0],
  "end":[107.2,21.1],
  "snapRadiusMeters":100,
  "maxDistanceMeters":50000
}
```

Route response fields: `layerId`, `topologyVersion`, `distance_m`, `geometry`,
`snapped_start`, `snapped_end`.

Sync change:

```json
{
  "clientChangeId":"uuid-v4",
  "layerId":1,"featureId":"...","baseVersion":1,
  "attributes":{},"geometry":{}
}
```

MVT:

- Tile source URL: `${API_BASE_URL}/mobile/layers/{id}/tiles/{z}/{x}/{y}.mvt`.
- `sourceLayer = layer.code`; proved by backend `ST_AsMVT(mvtgeom, $4, ...)` with `$4=layer.code`.
- Private JWT: Mapbox custom header scoped to exact API host only.
- **Live blocker:** layer 1 returns HTTP 500 `column "source_fid" does not exist`.
  Catalog metadata/id-field mapping and imported table disagree. Mobile must not mask with mock MVT.

**Mobile status:** measure/draft/route/edit/sync DTOs all need correction noted in Source Audit.

## CMS

List query for news/documents/pdf maps: optional `q` 1–100, page ≥1, limit 1–100.

| Method/path | Auth | Input | Response |
|---|---|---|---|
| `GET /cms/news` | Optional | paged search | `data.items`, `metadata` |
| `GET /cms/news/:id` | Optional | positive ID | public news detail |
| `GET /cms/news/:id/comments` | Optional | page/limit, optional status accepted only as validator defines | paged comments |
| `POST /cms/news/:id/comments` | Bearer | `{content}` plain 1–2000 | comment |
| `GET /cms/documents` | Optional | paged search | permission-filtered `items` |
| `GET /cms/documents/:id` | Optional | positive ID | metadata detail |
| `GET /cms/documents/:id/download-url` | Bearer | `expireSeconds` 60–900 default 300 | short-lived URL |
| `GET /cms/pdf-maps` | Optional | paged search | `items` |
| `GET /cms/pdf-maps/:id` | Optional | ID | map metadata detail |
| `GET /cms/pdf-maps/:id/download-url` | Bearer | expiry 60–900 | short-lived URL |

Live list fields include snake_case dates and metadata, e.g. news `published_at`, document
`document_code`, PDF `scale_label`, `map_year`, `preparing_agency`.

**Mobile status:** list envelope wrong; no comments/PDF/full detail flows; manual token dependency must go.

## Field Reports and Devices

| Method/path | Auth | Input | Response/notes |
|---|---|---|---|
| `GET /field-reports/public` | Optional | optional status; page/limit | paged public items |
| `GET /field-reports/nearby` | Optional | lon/lat, radius 10–500, required ISO `from < to`, max 366 days | nearby items |
| `GET /field-reports/mine` | Bearer + create permission | status/page/limit | paged own items |
| `POST /field-reports` | Bearer + create permission | see body | report; max 10/hour |
| `GET /field-reports/:id` | Bearer | ID | report + presigned photos + history |
| `DELETE /field-reports/:id` | Bearer | required `expectedUpdatedAt` query | soft-delete + media cleanup semantics |
| `PUT /devices/push-token` | Bearer | `{token,platform}` | registered device |
| `DELETE /devices/push-token` | Bearer | body `{token}` | disabled device |

Create report:

```json
{
  "description":"10–2000 chars, no HTML",
  "longitude":107.31,
  "latitude":21.01,
  "measuredGeometry":{"type":"Polygon","coordinates":[]},
  "photoIds":[1,2]
}
```

Max 5 unique photo IDs. Geometry serialized size/depth/bounds limited server-side.

**Mobile status:** payload/query/push field mismatches; list shape/model needs serializer audit.

## Storage Upload Lifecycle

All routes Bearer + enforce password change.

1. `POST /storage/uploads/presign`

```json
{
  "category":"field-photos",
  "originalName":"evidence.webp",
  "contentType":"image/webp",
  "expireSeconds":900
}
```

Categories: `layers`, `raster`, `documents`, `field-photos`. Expiry 60–3600.

2. Direct upload to returned presigned URL using required headers/content type.
3. `POST /storage/uploads/:id/commit` — backend validates object/signature/ownership.
4. Use committed object IDs as field report `photoIds`.
5. `GET /storage/objects/:id/download-url?expireSeconds=...` only on demand.

**Mobile status:** missing repository and upload state machine. Camera/image dependency is Sprint 5 decision.

## Live Smoke Evidence

| Endpoint | Result | Evidence summary |
|---|---:|---|
| `GET /web-map/layers` | 200 | 1 public layer `ranhgioi_campha` |
| `GET /web-map/basemaps` | 200 | OSM catalog |
| `GET /cms/news?page=1&limit=2` | 200 | `data.items`, total 7 |
| `GET /cms/documents?page=1&limit=2` | 200 | real document metadata |
| `GET /cms/pdf-maps?page=1&limit=2` | 200 | real PDF metadata |
| `GET /field-reports/public?page=1&limit=2` | 200 | empty `data.items`, valid metadata |
| `GET /mobile/weather/current?...` | 200 | live weather response |
| `GET /mobile/layers/1/tiles/12/3268/1803.mvt` | **500** | missing `source_fid` column |

Authenticated smoke pending runtime `API_TEST_PASSWORD` or manual demo login. Fixture accounts exist
for `citizen`, `ubnd_tp`, `so_tnmt`, `so_xd`, `system_admin`; no credential stored in repo.

## Exit Assessment

- Endpoint/path/payload ambiguity: resolved for target mobile routes.
- Mobile repository correctness: documented, not fixed in bulk during Sprint 0.
- Public backend availability: confirmed except MVT.
- Sprint 3 entry blocker: backend MVT must return protobuf 200 for real Cẩm Phả tile.
