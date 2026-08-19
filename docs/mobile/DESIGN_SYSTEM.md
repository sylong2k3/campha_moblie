# Design System — Civic GIS Premium

## Design Intent

**Tin cậy như hạ tầng công, rõ như thiết bị hiện trường, sống động vừa đủ.**
Hướng hình ảnh `Civic Coastal`: forest sâu tạo độ tin cậy, coastal jade gợi địa phương ven biển,
clay làm điểm nhấn tác nghiệp. Bản đồ/dữ liệu là hero; chrome nhẹ, không dùng dashboard cards
dày đặc hoặc glass blur làm giảm đọc GIS.

## Color Tokens

### Brand

| Token | Light | Dark | Use |
|---|---|---|---|
| `brand.forest` | `#174D43` | `#91D3BF` | primary actions, active map control |
| `brand.forest.deep` | `#0C352F` | `#081F1B` | brand gradient, dark foreground |
| `brand.forest.bright` | `#2F7465` | `#245E52` | brand gradient, secondary emphasis |
| `brand.moss` | `#456B60` | `#A9D0C2` | secondary emphasis |
| `brand.coastal` | `#32788A` | semantic tone | information/location context |
| `brand.clay` | `#C66F3D` | `#F0B183` | geometry/tool highlight, not generic error |
| `brand.ink` | `#12211D` | `#EAF3EF` | primary text |

### Surfaces

| Token | Light | Dark |
|---|---|---|
| `surface.canvas` | `#F5F7F6` | `#0B1512` |
| `surface.primary` | `#FFFFFF` | `#13231E` |
| `surface.subtle` | `#EAF0ED` | `#1D302A` |
| `surface.overlay` | white 97% | dark surface 97% |
| `border.subtle` | `#DCE5E1` | `#334B43` |
| `text.primary` | `#12211D` | `#EAF3EF` |
| `text.muted` | `#52635D` | `#B5C8C0` |

### Gradient policy

- `brand`: forest deep → forest → forest bright; splash, short hero, identity và special context only.
- `ambient`: pale forest → neutral surface → pale clay; auth identity background only.
- Profile/page background, card dữ liệu, CTA, status, navigation và form dùng màu đặc.
- Không animated gradient, glass blur, rainbow gradient hoặc gradient phủ tile/layer bản đồ.
- Text trên brand gradient dùng white với contrast tối thiểu 4.5:1 ở mọi color stop.

### Semantic

| Token | Color | Icon + label required |
|---|---|---|
| `status.info` | `#35758A` | info circle |
| `status.warning` | `#D39A3D` | warning triangle |
| `status.error` | `#B64D47` | error outline |
| `status.success` | `#36745B` | check circle |
| `status.pending` | `#697973` | schedule/sync |

No status communicates by color alone. On-map geometry colors get halo/outline against both basemap styles.

## Typography — Be Vietnam Pro

| Token | Size / line | Weight | Use |
|---|---:|---:|---|
| `display.small` | 32 / 40 | 700 | rare onboarding/splash |
| `headline.medium` | 28 / 36 | 700 | major page title tablet |
| `headline.small` | 24 / 30 | 700 | major page title phone |
| `title.large` | 20 / 26 | 700 | sheet/detail title |
| `title.medium` | 16 / 22 | 600 | card/section |
| `body.large` | 16 / 23 | 400 | readable content/forms |
| `body.medium` | 14 / 20 | 400 | lists/metadata |
| `label.large` | 14 / 20 | 600 | button/control |
| `label.medium` | 12 / 17 | 600 | chip/map microcopy |
| `label.small` | 11 / 15 | 500 | scale/time; never key action |

Support text scale 200%; titles wrap, controls grow vertically, no fixed text-height cards.

## Spatial Tokens

```text
space.1 = 4    space.2 = 8    space.3 = 12
space.4 = 16   space.5 = 20   space.6 = 24
space.8 = 32   space.10 = 40  space.12 = 48
```

- Phone screen padding 16; tablet 24–32.
- Section gap 24; related item gap 8–12.
- Minimum control/touch 48×48dp; map icon buttons 48, compact visual glyph 22–24.
- List row minimum 64; key two-line row 72–80.

## Shape and Elevation

| Token | Value | Use |
|---|---:|---|
| `radius.s` | 8 | small chip/thumbnail |
| `radius.m` | 12 | controls/input |
| `radius.l` | 16 | cards/FAB |
| `radius.xl` | 20 | phone bottom sheet |
| `radius.pill` | 999 | search/status only |
| `elevation.rest` | 0 + 1px border | default card |
| `elevation.float` | 2–3 | map controls/FAB |
| `elevation.modal` | 6 | dialog/sheet separation |

Avoid shadow stacks. On map, opaque surface + thin border beats blur-heavy glass.

## Motion

| Motion | Duration | Curve |
|---|---:|---|
| state/color | 160ms | standard easing |
| sheet/FAB/tool dock | 220ms | easeOutCubic |
| route/page | 240ms | platform transition |
| map camera | 450–700ms | renderer camera easing |
| skeleton shimmer | avoid by default | use low-motion pulse |

Reduced-motion: zero nonessential transitions; retain instant state change and progress semantics.
No infinite decorative animation.

## Layout Grid

- Phone: 4-column conceptual grid, 16 gutter.
- Tablet ≥600dp: 8 columns; reading max width 720.
- Wide ≥840dp: NavigationRail and optional map side panel 360–420.
- Map always extends edge-to-edge behind safe controls; sheet content obeys safe area.
- Forms use one column phone; two-column only for short related fields at wide widths.

## Component Inventory

Build only when owning Sprint needs it.

| Component | Anatomy | Required states |
|---|---|---|
| `AppSearchField` | search/input/clear/loading | idle, focus, typing, loading, clear |
| `AppInlineNotice` | semantic icon/copy/optional action | info, warning, error, success, live region |
| `AppStateMessage` | icon/title/body/one recovery action | empty, error, forbidden, success |
| `PermissionPrimer` | purpose, privacy note, allow/not-now | initial, denied, permanently denied |
| `OfflineBanner` | status icon, concise copy, retry/detail | offline, syncing, failed, restored |
| `SyncStatusBadge` | count/status | pending, syncing, conflict, failed |
| `PagedListView` | items, footer loader/retry | first load, append, append error, end |
| `ConfirmActionSheet` | action consequence + cancel/confirm | destructive, double-submit disabled |
| `MapActionButton` | 48dp surface, icon, tooltip/semantics | default, pressed, active, disabled, error dot |
| `MapToolDock` | measure/route/draw | collapsed, expanded, active mode |
| `LayerRow` | geometry icon/name/switch/info/opacity | off, loading, on, tile error, forbidden |
| `FeatureAttributeTable` | label/value/copy/expand | loading, empty, sanitized values |
| `EvidenceThumbnail` | actual image/progress/retry/remove | local, upload, committed, failed |

Implemented rules:

- `AppInlineNotice` stacks action below copy at width `<360dp` or text scale `>1.3`.
- Search clear cancels feature debounce and sends empty query immediately.
- One screen state exposes at most one recovery action.
- Native camera/location permission request always follows an in-app purpose primer.
- `deniedForever` opens App Settings; location service disabled opens Location Settings.
- Destructive report draft/offline change/history actions require confirmation; write buttons lock while submitting.

## Map Chrome

### Z-order

1. Basemap.
2. Data MVT/raster layers.
3. Selection/route/measurement/draft GeoJSON.
4. Accuracy circle/user puck.
5. Scale/attribution.
6. Tool controls/search/banner.
7. Bottom sheet/navigation.

### Controls

- Top search pill max width 560; avatar/login trailing.
- Right rail: compass, GPS, optional zoom, weather; 8dp gaps.
- Bottom actions stay above NavigationBar and sheet extent.
- Active tool uses forest context bar and clay geometry; no ambiguous gesture mode.
- Attribution never hidden; controls avoid system gesture inset.

### Geometry styles

| Geometry | Normal | Selected/edit |
|---|---|---|
| Point | forest 10px + white halo | clay 12px + pulse once |
| Line | forest 2–3px | clay 4–5px + dark halo |
| Polygon | forest 20% fill + 2px outline | clay 22% + 4px outline |
| Route | deep teal 5px + white/ink casing | start/end distinct icon + text |
| Accuracy | info 10% fill + dashed/soft edge | warning label when over threshold |

## Screen State Standard

Every API-backed screen spec explicitly selects applicable states:

- `initial`: no request yet.
- `loading`: skeleton preserving layout; map uses neutral cover/progress.
- `refreshing`: retain data, small progress.
- `data`: content.
- `empty`: domain-specific message + next valid action.
- `error`: plain language + retry/detail only if safe.
- `offline`: cached content + stale indicator, no fake success.
- `forbidden`: permission reason + route back; no hidden blank screen.
- `disabled`: explain missing prerequisite.
- `submitting`: lock primary action, progress stage.
- `success`: confirmation + next action, not toast-only for critical writes.
- `conflict`: preserve local input and compare/reload choices.

## Forms

- Persistent labels; hint is example, never label replacement.
- Inline validation after blur/submit; summary banner for server-wide failure.
- Keyboard action sequence and autofocus only when expected.
- Required/optional copy explicit; counters near long text.
- Submit disabled only for active request or clearly invalid required data; disabled reason accessible.
- Never persist password; avoid location/phone in logs and analytics.

## Content and Voice

- Vietnamese primary: concise, respectful, action-oriented.
- Error pattern: **what happened + what user can do**.
- Use “Phản ánh”, “Lớp dữ liệu”, “Bản vẽ nháp”; avoid raw backend terms.
- Show coordinates only when useful, rounded for display; preserve full precision only in API payload.
- Do not show stack traces/error codes as primary copy; code may appear in expandable support detail.

## Accessibility Checklist

- WCAG AA contrast; check overlay controls against light and satellite styles.
- Semantics name, role, value/state for icon buttons, switches, map mode and upload progress.
- Tooltip for icon-only actions.
- Focus order follows visual order; sheet traps focus correctly.
- 200% text keeps primary CTA reachable.
- Status = icon + text, never color alone.
- Images have evidence/content description or decorative exclusion.
- Map alternatives: selected feature attributes and route length available as text.
- Haptic only on add vertex, successful commit or destructive confirmation; setting-respectful.

## Implementation Guardrails

1. Add spacing/radius/motion tokens only when production Sprint starts; Sprint 0 documents them.
2. No screen-specific hex values; map style factory may translate semantic tokens to renderer integer colors.
3. Use native Material widgets before custom draw.
4. No common component with one use unless accessibility/behavior complexity earns it.
5. Snapshot visual sheets are direction, not mock acceptance data.
