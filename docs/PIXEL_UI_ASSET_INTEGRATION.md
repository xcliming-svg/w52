# W52 — Rust-red wasteland survival UI asset expansion

Feature branch: `feature/pixel-ui-fantasy-free-assets`. This revision is designed for a **Mars-like wasteland planet** survival game spanning 52 weeks, without changing the scripted scenario, rules or data model.

## Applied UI art (only real free-pack PNGs)

All original PNGs are unmodified and stored under `assets/ui/pixel_fantasy/`. Full source ZIP stays outside the game. Attribution and CC BY 4.0: `assets/ui/pixel_fantasy/ATTRIBUTION.md`.

| Existing W52 UI | Original pack PNGs | Code |
|---|---|---|
| Window and menu buttons | `panel`, `button_*`, `focus` | `ui_style.gd` |
| Audio sliders | `slider`, `slider_fill`, `grabber`, `grabber_hover`, `grabber_disabled` | `ui_style.gd`, `settings_menu.gd` |
| Fullscreen checkbox | `checkbox_on`, `checkbox_off` | `settings_menu.gd` |
| Battle report scrollbar | `scroll`, `scroll_grabber`, `scroll_grabber_hover`, `scroll_grabber_pressed` | `game.gd` |
| Report/recess and divider | `panel_inset`, `divider`, `quest` | `game.gd` |
| Week and supply HUD | `coin`, `progress_bg`, `progress_fill` | `game.gd` |
| 1x/2x selectors | `tab_selected`, `tab_unselected`, `tab_hover` | `game.gd` |
| Dialogue/radio briefing | `portrait`, `nameplate`, `panel` | `game.gd` |
| Node information | `window`, `tooltip` | `game.gd` |
| Survival field manual | `parchment`, `ribbon` | `game.gd` |
| Skill-tree nodes | `skill_slot`, `skill_slot_active`, matching icons | `game.gd` |

Most of these were added after the initial 14 PNGs; selected stock graphics are *recontextualized* as worn terminal decorations. We do **not** portray fire spells, RPG inventory/rarity, health/mana or cooldown data as if those systems exist. Battlefield **units** and cell drawing code remain unchanged. Title branding is also unchanged.

## Visual system and numerical constraints

- Art direction: dark rust / oxidized iron / sandy beige, a small teal equipment glow, not pure medieval fantasy. Text contrast over dark panels stays light; parchment field manual uses dark brown text. No new gameplay strings/glyph ranges.
- Logical canvas **1920×1080, 16:9**; initial 1280×720 physical window. All screen bounds, `TreeClip`, popup/deploy geometry, scrollbar bounds and button dimensions remain unchanged.
- Image source pixels are enlarged **3× by nearest-neighbor**; at the initial physical window each source pixel is **2 display pixels**. 9-slice borders are tiled, not blurred or stretched. Display sizes and pixel endpoints snap to multiples of three logical pixels. Other physical window sizes can render fractional source pixel widths; real browser QA remains necessary.
- The progress strip uses the existing `week` and `phase`. It counts **completed** weeks: `week - 1` before a week's result, `week` after the result. It reaches 52/52 only after the last result. No save changes.
- The G amount remains G; the golden coin is only its icon, not a claim that the economic system uses physical gold.
- Audio sliders and fullscreen state retain their same settings connection; `CheckButton` becomes a `CheckBox` with the same `button_pressed` and `toggled` behavior.
- Headless `tests/w52_ui_smoke.gd` now asserts Godot loads art style boxes, scrollbar, tab, slider, checkbox and button textures while preserving existing 52-week and tree input regression tests.

## Verification and promotion

1. Commit only to the ongoing feature branch; selectively apply only its changes to devel for web preview.
2. Run Godot 4.7.2 import, scene smoke, art style smoke, 52-week state smoke and PC/Web shared Web Export via GitHub Actions. Inspect failing steps and revise in the **same feature branch**, then republish devel.
3. Verify the Pages publisher run completed successfully, then manually inspect at both 1280×720 and 1920×1080 when browser access is available.
4. Never merge into `main` without explicit approval. The local `C:\GPT-Workspace\w52` working tree is separate and has not been synchronized.

## Visual QA checklist (not completed by automated tests)

- Intro/menu panel and button ink contrast; keyboard focus outline
- Sound sliders at 0, 50 and 100 and fullscreen toggle
- HUD progress at week 1 initial, week 1 result and week 52 result
- Briefing names/portrait and Space input, text clipping at 1280×720
- Tooltip against fixed 390×274 popup and its embedded 160×62 deploy button
- Log thumb visible after many entries, scrolling remains functional
- New tab skin does not break mutual-exclusion logic for 1×/2×
- Skill-tree pan, drag threshold and minimum visible node+label invariant
