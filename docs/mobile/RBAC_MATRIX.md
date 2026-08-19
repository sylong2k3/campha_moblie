# RBAC Matrix — Mobile GIS Cẩm Phả

## Source of Truth

1. JWT identifies actor; `/auth/me.role.permissions` decides current capabilities.
2. Backend middleware/service remains final authority.
3. Matrix below is UX baseline from `MA_TRAN_PHAN_QUYEN.csv`, not authorization replacement.
4. Unknown/missing permission defaults denied for write/sensitive actions.

Role codes: `guest`, `citizen`, `ubnd_tp`, `so_tnmt`, `so_xd`, `system_admin`.

## Mobile Capability Matrix

Legend: ✓ available; — unavailable; P = permission payload decides; Public = server-filtered public data.

| Capability / permission | guest | citizen | ubnd_tp | so_tnmt | so_xd | system_admin |
|---|---:|---:|---:|---:|---:|---:|
| Register `auth.register` | ✓ | — | — | — | — | — |
| Login `auth.login` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Own profile | — | P | P | P | P | P |
| Map/layer `map.view` | Public | P | P | P | P | P |
| Feature info `map.view_attributes` | Public | P | P | P | P | P |
| Search `map.search_feature` | Public | P | P | P | P | P |
| Legend `map.view_legend` | Public | P | P | P | P | P |
| GPS `map.locate` | ✓ | P | P | P | P | P |
| Measure `map.measure` | ✓ | P | P | P | P | P |
| Route `map.route` | ✓ | P | P | P | P | P |
| Weather `weather.read` | ✓ | P | P | P | P | P |
| Draw preview | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Save draft `map.draw` | — | P | P | P | P | P |
| Edit base feature `map_feature.update` | — | — | — | **P** | — | —/P only if server grants |
| Feature history/restore | — | — | — | **P** | — | —/P only if server grants |
| News public `news.read_public` | ✓ | P | P | P | P | P |
| News comment `news.comment` | — | P | P | P | P | P |
| Public documents/PDF | ✓ | P | P | P | P | P |
| Internal documents `documents.read_internal` | — | — | P | P | P | P |
| Document/PDF download | — | P by content | P | P | P | P |
| Public reports | Public | Public | Public | Public | Public | Public |
| Create report `field_report.create` | — | P | P | P | P | — unless server grants |
| Report measurement `field_report.measure` | — | P | P | P | P | — unless server grants |
| Review report `field_report.approve` | — | — | P | P | P | **— in service** |
| Report analytics `field_report.stats` | — | — | P | P | P | P if granted |
| Offline feature sync | — | — | — | P | — | —/P only if server grants |

## Runtime Gating Rules

### Read actions

- Guest calls optional-auth endpoints; server only returns public/accessibly serialized resources.
- Never display private layer name/metadata learned from stale cache after logout.
- Authenticated cached screen revalidates on permission/user change.

### Write actions

- Button appears only when permission is `true` and role-specific service condition is met.
- Deep link to forbidden screen renders forbidden state, not hidden blank page.
- Server 403 always overrides visible UI; refresh `/auth/me` then explain action unavailable.
- Guest write action opens auth flow with `returnTo` and preserves safe draft input.

### Dangerous map edit

All must hold:

```text
role == so_tnmt
permissions.map_feature.update == true
layer.role_can_edit == true (server-side)
current baseVersion present
```

Mobile cannot infer `role_can_edit` from role alone. Conflict 409 never enables force overwrite.

## Discrepancies / Decisions

| Area | Static matrix | Current backend implementation | Mobile decision |
|---|---|---|---|
| Field report create | CSV line A.2-11 says citizen only; B-2 says citizen/UBND/TNMT/XD | Service uses `permissions.field_report.create` | Use runtime permission; log fixture differences |
| Report approve | CSV excludes admin | Service allows only roles `ubnd_tp`, `so_tnmt`, `so_xd` plus permission | Explicit role + permission gate; admin hidden |
| Feature edit | TNMT only; admin excluded | Service explicitly requires `actor.role === so_tnmt` + permission | Only TNMT UI, even generic admin capability assumption says otherwise |
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

Existing mobile enum/ARB uses stale `so_nnmt`, `ubnd_tinh`; replace in Sprint 1 with tests.

## RBAC Test Minimum

1. `UserRole.fromApiValue` covers all five backend roles + unknown → guest.
2. Guest cannot reach write endpoint from UI, but public read paths work.
3. Permission false hides action and direct deep link shows forbidden.
4. 403 after stale permission triggers revalidation, no automatic retry write.
5. Only TNMT sees edit/history; backend rejects all other roles.
6. Logout clears private cached catalog and exact-host Mapbox Authorization header.
