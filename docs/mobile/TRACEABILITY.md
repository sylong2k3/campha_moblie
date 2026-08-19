# M01–M22 Traceability Matrix

| Screen | Route/owner | Sprint | Primary API/state | Permission | Minimum verification |
|---|---|---:|---|---|---|
| M01 Splash | `/splash` | 1 | TokenStorage, `/auth/me` | public/session | bootstrap widget + token cases |
| M02 Login | `/auth/login` | 1 | login, Google optional | guest | form widget + token contract |
| M03 Register | `/auth/register` | 1 | register/verify branch | guest | validation + response branches |
| M04 Shell | shell roots | 1 | session/theme/locale | public | indexed navigation widget |
| M05 Map | `/map` | 3 | styles/catalog/MVT | `map.view` | emulator renderer + error states |
| M06 Layers | sheet owner M05 | 3 | layers/legend/basemaps | map permissions | repository + sheet widget |
| M07 Feature | feature route/sheet | 3/4 | detail/nearby | attributes/locate | allowlist + sheet states |
| M08 Search | `/map/search` | 3 | feature search | search_feature | debounce/cancel + route result |
| M09 Location/weather | map sheet | 4 | geolocator/weather | locate/weather | permission matrix + API contract |
| M10 Measure | map mode | 4 | `/mobile/measure` | map.measure | geometry unit + mode widget |
| M11 Route | map mode/sheet | 4 | routes/shortest | map.route | body/409/422 + overlay |
| M12 Drafts | `/map/drafts` | 4 | draft CRUD | map.draw | payload/page/409 + draw mode |
| M13 Editor | feature edit route | 6 | feature PATCH | exact TNMT/update | role + conflict + geometry |
| M14 History | feature history route | 6 | history/restore | exact TNMT/update | timeline/restore conflict |
| M15 Reports | `/reports` | 5 | public/nearby | public | list/map filter + date contract |
| M16 New report | `/reports/new` | 5 | storage + create | field_report.create | stepper/upload/double submit |
| M17 Mine/detail | mine/detail routes | 5 | mine/detail/delete | authenticated/owner | URL expiry + optimistic delete |
| M18 News | `/news` | 2 | news list/search | public | paged envelope + list widget |
| M19 News detail | `/news/:id` | 2 | detail/comments | public/comment | sanitize + auth return |
| M20 Docs/PDF | `/documents` | 2 | documents/pdf lists | server filtered | role/cache/page widget |
| M21 File detail | detail routes | 2 | detail/download URLs | read/download | expiry/open fallback |
| M22 Profile/sync | `/profile` children | 1/6 | me/preferences/push/queue | public/session | guest/auth/queue/logout |

## Coverage Rules

- Story cannot be Done if its screen lacks routed access, API/state owner and minimum verification.
- Shared endpoint belongs to first vertical slice using it; no standalone repository-only Done claim.
- A screen may span Sprints only when the first increment is usable; M22 profile foundation precedes queue.
- Backend Blocked evidence satisfies transparency, not product acceptance.
