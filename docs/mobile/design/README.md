# Visual Directions — Sprint 0

Các sheet dùng để chốt hierarchy, mật độ và visual language; không phải screenshot app chạy,
không phải mock-data acceptance. Production UI phải dùng API/state/accessibility thật.

## Direction A — Map-first App Shell

![App shell direction](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/app_shell_direction.png)

**Adopt:** edge-to-edge map, prominent search, compact right control rail, low-profile layer/tool actions,
five clear destinations, forest chrome and neutral surface.

**Validate in code:** exact safe-area spacing, Vietnamese text at 200%, Mapbox attribution,
selected navigation indicator, satellite contrast and 48dp controls.

## Direction B — GIS Tool Workspace

![Map workspace direction](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/map_workspace_direction.png)

**Adopt:** explicit active mode, clay geometry with halos, context bar, result-first sheet,
server-confirmed value distinct from live preview, grouped undo/redo/clear/finish/cancel.

**Refine:** five actions may need two rows or icon toolbar on narrow devices; “Hủy” must not look like
success. Sheet must leave enough map for vertex editing and avoid attribution.

## Direction C — Field Report Stepper

![Field report direction](file:///C:/Users/SunSun/Documents/DuAN_20226/campha/campha_moblie/docs/mobile/design/field_report_direction.png)

**Adopt:** visible three-stage progress, evidence continuity, accuracy status, adjustable mini-map,
geometry choice, privacy copy and sticky draft/continue actions.

**Validate:** real upload lifecycle, offline draft distinction, keyboard/text scale, location permission states,
image source/legal privacy. Evidence images shown here are concept art only; never enter acceptance build.

## Shared Review Decisions

- Civic GIS palette and Be Vietnam Pro hierarchy accepted.
- Data/map dominates; cards used for task focus, not dashboard decoration.
- Thin borders + controlled elevation; no glass blur/heavy gradient.
- Forest = action/navigation; clay = active geometry/emphasis; semantic red reserved for errors.
- Every icon-only map action needs tooltip/semantics; status includes icon + text.
- Dark mode must restyle chrome and geometry halos, not merely invert basemap.

## Production Ceiling

Do not create custom components solely to match these images. Use Material 3 first, then add minimum
behavior/style needed by Screen Spec. Actual screenshots and recordings come from emulator each Sprint.
