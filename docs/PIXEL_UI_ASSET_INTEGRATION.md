# W52 — Pixel UI Fantasy Free selected visual assets

Status: implementation committed to `feature/pixel-ui-fantasy-free-assets`; static review complete, Godot runtime/web rendering **not yet verified**.

## Scope

- Keep the approved 1920×1080 / 16:9 design and 1280×720 initial window.
- Keep existing text sizes, bundled Korean font, battle flow, tree positions, dragging, focus, hit testing, save schema and battlefield grid cells.
- Replace **HUD panel borders**, **node popup/dialogue borders**, and **skill-tree node drawings** with a limited selection of Pixel UI Fantasy Free PNGs.
- Do not apply the free pack's Theme globally; its 10px Quill font does not cover Korean and its content margins differ from W52's layout.
- Do not modify main/devel or run local gameplay QA without an explicit request.

## Art mappings

Source: `pixel-ui-fantasy-free/addons/pixel_ui_fantasy/` in the user-provided ZIP.

| New resource | Original source |
|---|---|
| `assets/ui/pixel_fantasy/frame.png` | `themes/parchment/panel.png` |
| `slot.png` | `themes/parchment/skill_slot.png` |
| `slot_active.png` | `themes/parchment/skill_slot_active.png` |
| `gem.png`, `scroll.png`, `shield.png`, `arrow_right.png`, `chest.png`, `sword.png`, `lock.png` | matching `icons/*.png` |

Drumming/air units have no honest equivalent icon in this free pack. Their legacy glyph remains until specific art is approved. Locked nodes show the lock icon. Author and CC BY 4.0 attribution are in `assets/ui/pixel_fantasy/ATTRIBUTION.md`.

## Pixel geometry

Original border image 24×24px and skill frame images 20×20px; icons 16×16px.

- Nearest-neighbor upscale **3× once at scene setup**, and use local `CanvasItem.TEXTURE_FILTER_NEAREST`; no project-wide image filter or resolution changes.
- At 1920×1080, artwork source pixels occupy 3 logical px. At the default 1280×720 window, that corresponds to 2 output px. Other window sizes can introduce unequal physical pixel widths under aspect-preserving canvas scaling; that needs visual QA.
- Draw 9-slice frame corners/edges with `StyleBoxTexture`; border margin **18 logical px** for the 6px source panel edge, **9 logical px** for the 3px skill-slot edge. Use `AXIS_STRETCH_MODE_TILE`, not stretched borders.
- Round art rectangle endpoints and icon origins to the nearest **3 logical px**. This changes visuals only; interaction geometry is not snapped.
- Skill slot outer size: **75×75** normal, **84×84** selected/hovered = exactly **1.12×**. Icons remain 48×48. Visibility bounds conservatively include the snap tolerance. Labels stay at their previous layout positions.
- Keep HUD/popup/dialogue dark fills; only their borders are replaced. Battlefield 46×46 cell drawing and its color-coded strokes are left unchanged.

## Static design audit

| Requirement | Code evidence | Status |
|---|---|---|
| 1920×1080, 16:9 and default 1280×720 | `project.godot` is untouched | MATCH |
| Tree selection and drag threshold | `_node_at`, `_start_pan`, `_finish_pan`, `_clamp_pan` unchanged | MATCH |
| At least one full node + label while dragging | `_node_visual_rect` conservatively includes 3px snap | MATCH (static) |
| Pixel art quality | nearest scaling, integer frame sizes, 9-slice tiled margins | MATCH (static) |
| Popup/deploy alignment | `POPUP_SIZE`, `POPUP_BUTTON_OFFSET`, `_popup_rect` unchanged | MATCH |
| Battlefield grid, save format and game phases | unaffected drawing/logic | MATCH |
| Bundled Korean typeface | `main.gd` and `FONT` unchanged | MATCH |
| PC/Web shared UI | all changes in `scripts/game.gd` | MATCH (static) |
| 실제 Godot 화면, 1280×720 가독성, Web Export | runtime/CI unexecuted on feature branch | NOT VERIFIED |

If a future visual QA finds edge clipping, color contrast, or font overlap, correct only the relevant frame geometry/art code and repeat the checks. Do not assume static review is equivalent to a successful game launch.
