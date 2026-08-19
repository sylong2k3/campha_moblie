# Source Audit — Sprint 0

Ngày audit: 2026-08-10. Phạm vi: source Flutter hiện tại đối chiếu route, validator,
controller/service/backend live. Nhãn: **GIỮ**, **SỬA**, **THIẾU UI**, **XÓA**.

## Executive Summary

| Nhãn | Kết luận |
|---|---|
| GIỮ | Core config, Dio singleton, secure token abstraction, retry/log redaction, theme/locale persistence, location/push shells |
| SỬA | Mọi repository nghiệp vụ hiện có ít nhất một contract/ownership/parsing issue |
| THIẾU UI | Không feature nào có `presentation/`; router chỉ có splash rỗng + placeholder |
| XÓA | `HomePlaceholderScreen`; duplicate token storage/header logic; stale comments/role assumptions |

`flutter analyze` sạch không chứng minh runtime contract đúng. Không sửa hàng loạt trong Sprint 0;
mỗi nhóm được sửa cùng vertical slice ở Sprint sở hữu feature.

## App / Router / Theme

| File/area | Nhãn | Finding | Sprint owner |
|---|---|---|---|
| `main.dart` | GIỮ/SỬA NHỎ | Env + Firebase init song song, release validation tốt. Sprint 1 phải bootstrap session trước navigation; Mapbox token chỉ init khi map cần. | 1/3 |
| `app_router.dart` | THIẾU UI | Initial `/`, chỉ splash + placeholder; không auth guard, shell, deep link, `returnTo`. | 1 |
| `route_names.dart` | SỬA | Chưa có route M01–M22. | 1+ |
| `splash_screen.dart` | THIẾU UI | Scaffold rỗng. | 1 |
| `home_placeholder_screen.dart` | XÓA | Không được tồn tại trong product flow. | 1 |
| `app_colors.dart` | GIỮ | Palette khớp civic GIS direction; có semantic status. | 0 |
| `app_theme.dart` | GIỮ/SỬA | M3 + Be Vietnam Pro tốt; cần token spacing/radius/motion, 48dp icon controls, selected nav state. | 1 |
| theme/locale controllers | GIỮ | Persistence đã có; theme hiện thiếu `system` choice. | 1/7 |
| ARB | SỬA | Role key/code cũ; thiếu toàn bộ product copy/states. | mỗi Sprint |

## Core

| Area | Nhãn | Finding |
|---|---|---|
| `ApiConfig` | GIỮ | Dart define ưu tiên dotenv; HTTPS/WSS release guard đúng. `.env` asset là public client config, không được chứa secret. |
| `ApiEndpoints` | SỬA | Comment stale; thiếu basemap, search, legend, weather, public/mine/detail report, storage, sessions helpers. |
| `dioProvider` + interceptors | GIỮ | Singleton, language, auth, idempotent retry, redacted logging. Cần integration test refresh concurrency. |
| `TokenStorage` | GIỮ | Nguồn token chuẩn. Cần session notifier để router/map biết rotation/logout. |
| `ApiResponse<T>` | GIỮ/SỬA | Envelope đúng; list repositories chưa dùng. Pagination casts nên chịu numeric string nếu backend thay driver. |
| Error model/mapper | SỬA | Chưa có first-class 409 conflict và 422 semantic validation; UI cần error codes. |
| `AppDatabase` | GIỮ SHELL | Schema rỗng là đúng trước Sprint 6; chưa tạo bảng “cho sau này”. |
| `LocationHelper` | GIỮ/AUDIT | Reuse cho primer → permission states; không xin background location. |
| `PushService` | GIỮ SHELL | Firebase optional an toàn; registration/deep link chưa nối API/session. |
| Pending media store/utils | GIỮ | Chỉ nối khi report vertical slice. |

## Auth

| Finding | Nhãn | Correct contract/action |
|---|---|---|
| `AuthRepository` tự tạo `FlutterSecureStorage` | XÓA | Inject `TokenStorage` duy nhất. |
| Repository tự gắn Authorization | XÓA | Dio `AuthInterceptor` sở hữu header. |
| `catch (_)` ở getMe/logout | SỬA | Map `AppException`; logout local-clear vẫn phải có technical result không PII. |
| Login/register parse user từ root `data` | SỬA | User nằm trong `data.user`; tokens ở root `data`. |
| Register luôn trả `UserModel` | SỬA | Có nhánh `{user, requiresVerification:true}` không token. |
| Register thiếu phone optional | SỬA | Body `{email,password,fullName,phone?}`. |
| Logout không gửi refresh token | SỬA | Body `{refreshToken?}`; Authorization do interceptor. |
| User model integer/case assumptions | SỬA | Backend IDs có thể string từ pg; fields snake_case; role `{code,name,permissions}`. |
| Auth presentation/session state | THIẾU UI | M01–M03, change password, verify state, returnTo. |

## CMS

| Finding | Nhãn | Correct contract/action |
|---|---|---|
| News/doc list ép `data` thành List | SỬA | Parse `data.items`, pagination từ `metadata`. |
| CMS phụ thuộc `AuthRepository` để lấy token | XÓA | Optional auth interceptor tự làm. |
| Document download trả null khi guest | SỬA | Endpoint bắt auth; UI auth gate, repository ném typed unauthorized. |
| Models thiếu content/metadata fields | SỬA | DTO theo public detail serializers/live response. |
| Comments, PDF map, detail/download methods | THIẾU | Sprint 2. |
| `presentation/` | THIẾU UI | News/document/PDF list/detail/comments/search/pagination states. |

## Map

| Finding | Nhãn | Correct contract/action |
|---|---|---|
| `LayerModel` đọc snake_case cho fields backend trả camelCase | SỬA | Parse `geometryType`, `geoserverLayer`, `isPublic`; thêm `styleName/minZoom/maxZoom/legend`. Không mong `storageKind/tableName` từ public serializer. |
| `MapRepository` tự gắn token | XÓA | Dio/Mapbox exact-host header. |
| Catalog parser | GIỮ/SỬA | `data` là List, đúng; cần category query/cache/error mapping. |
| Feature model ID | SỬA | Backend feature row dùng configured ID/`feature_id`; không mặc định `properties.id` duy nhất. |
| Nearby `radiusMeters=500` | SỬA | Server max 2000, default 200; expose limit 1–100. |
| Search/legend/basemaps | THIẾU | Routes thật đã có. |
| Renderer/UI | THIẾU UI | Sprint 3; spike riêng Sprint 0. |
| MVT backend live | BLOCKED | Layer metadata chọn `source_fid` không tồn tại; endpoint 500. |

## GIS Tools / Routing / Draft

| Finding | Nhãn | Correct contract/action |
|---|---|---|
| Measurement expects `value/unit/type` | SỬA | Parse `geometry_type`, `length_m`, `area_m2`; unit format ở client. |
| Draft list ép List | SỬA | `data.items`; pagination metadata. |
| Draft create gửi `geometryType/attributes` | SỬA | `{title, properties, geometry}`. |
| Draft delete thiếu version | SỬA | Query `expectedUpdatedAt` ISO required. |
| Route gửi `startCoordinates/endCoordinates` | SỬA | `{layerId,start,end,snapRadiusMeters,maxDistanceMeters}`. |
| Route response | SỬA | `distance_m`, `geometry`, `snapped_start`, `snapped_end`, `topologyVersion`. |
| Draw/measure/route state UI | THIẾU UI | Mode/cancellation/undo/redo/validation. |

## Field Reports / Storage / Push

| Finding | Nhãn | Correct contract/action |
|---|---|---|
| Report model có `title` không thuộc create contract | SỬA | Model theo repository serializers: description/location/status/reference/timestamps. |
| Create gửi `title/photoFileIds` | SỬA | `{description,longitude,latitude,measuredGeometry?,photoIds}`. |
| Nearby thiếu time range | SỬA | `from`, `to` required; radius 10–500, max 366 days. |
| Nearby parse shape | SỬA | Xác minh serializer; không ép List trước envelope check. |
| Push gửi `pushToken` | SỬA | `{token, platform}`. Delete cũng gửi body `{token}`. |
| Upload lifecycle | THIẾU | `POST /storage/uploads/presign` → direct PUT → `POST /uploads/:id/commit` → report `photoIds`; category `field-photos`, PNG/WebP rule từ service. |
| Report UI/offline form | THIẾU UI | Stepper, progress stages, local media paths, privacy/error states. |

## Feature Edit / Offline Sync

| Finding | Nhãn | Correct contract/action |
|---|---|---|
| Update/restore gửi `expectedVersion` | SỬA | `baseVersion`. |
| History ép `data` List | VERIFY/SỬA | Đối chiếu controller response; model snake_case/geometry/change metadata. |
| 409 không typed | SỬA | Preserve error code `FEATURE_VERSION_CONFLICT`; compare UX. |
| Sync body thiếu `clientId` | SỬA | UUID v4 client ID. |
| Change identity chưa enforced | SỬA | Mỗi item có unique UUID v4 `clientChangeId`. |
| `SyncResult.applied` là int | SỬA | Backend trả arrays `applied/conflicts/rejected`. |
| Local queue | THIẾU | Sqflite schema/migration/state machine Sprint 6, không sớm hơn. |

## Deletion List

1. `lib/app/router/home_placeholder_screen.dart` sau khi Sprint 1 shell hoạt động.
2. Duplicate `FlutterSecureStorage`, token key và manual Authorization trong repositories.
3. Stale comments nói backend chỉ có auth/core.
4. Role values `so_nnmt`, `ubnd_tinh` và related localization names.
5. Mock/default data có thể bị hiểu là live content trong acceptance build.

## Safe Sequencing

1. Sprint 1: token ownership → auth DTO/session → router/shell → role/i18n → tests.
2. Sprint 2: reusable paged envelope → CMS repositories → screens.
3. Sprint 3: layer DTO/catalog → Mapbox source/header → map UI.
4. Sprint 4+: tools/report/edit/offline theo từng vertical slice; không bulk-refactor trước UI owner.
