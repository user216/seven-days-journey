# Changelog — 7 Days Journey

All notable changes to the game are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/).

## [0.7.1] — 2026-03-22

### Fixed
- **Hair overlapping faces** — restructured SVG layer order in all 16 climb sprites: hair back volume now renders before head skin, hair crown/sides render after head but before face features; side volumes clipped above eye line
- **Male hero dress appearance** — replaced single wide trapezoid (read as skirt) with two distinct pant leg polygons with visible gap, inseam lines, and per-leg hems in all 8 male SVGs

## [0.7.0] — 2026-03-22

### Added
- **Dead-zone camera** — camera stays still while hero is within center 30% of viewport, smoothly lerps to follow when hero exits the dead zone; camera is standalone node (not child of hero)
- **AudioManager autoload** — music crossfade (two AudioStreamPlayer nodes), hierarchical SFX key resolution (`"complete+day"` falls back to `"complete"`), pitch jitter (0.93–1.07), volume control (±10% steps)
- **SceneTransition upgrade** — lifecycle signals (`transition_started`, `scene_swapped`, `transition_finished`), scene history stack with `go_back()`, pattern dissolve transition, shockwave effect
- **6 new shaders**: `screen_flash`, `dissolve`, `diamond_wipe`, `pattern_dissolve`, `shockwave`, `background_blur`, `sprite_outline`
- **Haptic gating** — `GameState.vibrate(ms)` method checks `haptic_enabled` flag; all 9 `Input.vibrate_handheld()` calls across 6 files replaced
- **Pause menu settings** — volume ±10% buttons, SFX toggle, haptic toggle with save/load
- **Hero dialogue system** — mode select, visual novel scene, RPG companion garden walk, branching dialogue, API sync (scaffolding)

### Changed
- `SaveManager` bumped to v5 — persists `sfx_enabled` and `haptic_enabled`
- `ThemeManager` expanded with day-specific dress color palette
- `hero_tint.gdshader` rewritten with cleaner HSL-based skin/hair/clothing detection
- Camera changed from hero-child to standalone with manual dead-zone smoothing
- 354 E2E tests (was 288)

## [0.5.9] — 2026-03-21

### Added
- **HOPA framework** — scene scaffolding, `hopa_data.gd` with level format, 4 discovery shaders (`hopa_object_highlight`, `hopa_discovery_burst`, `hopa_scene_depth`), `placeholder_factory.gd` for procedural test art
- **HOPA state** in `GameState` — `hopa_progress`, `hopa_inventory`, `hopa_current_level` with save/load
- Test data: `test_hopa_level.json` for level format validation

## [0.5.8] — 2026-03-21

### Added
- **Stats page** — layer 38 CanvasLayer with XP breakdown + achievements grid, accessed via "..." button in HUD
- **Character customization** — 6 female hairstyles (braided, ponytail, short) + 3 male (buzz, spiky, swept), skin/hair color presets
- **Hero tint shader** (`hero_tint.gdshader`) — GPU-based recoloring for skin/hair/clothes
- **Hairstyle hero SVGs** — 12 new climb sprites (6 styles × idle/jump variants)

### Changed
- `GameState` tracks `hero_skin_idx`, `hero_hair_idx`, `hero_hair_style_idx`
- `SaveManager` persists customization choices

## [0.5.7] — 2026-03-21

### Added
- **Animated main menu** — procedural sky gradient, drifting clouds, parallax mountains/trees, sun with glow, leaf + golden sparkle GPUParticles2D, entrance slide+spring animations
- `main_menu_draw.gd` — extracted `_draw()` rendering (mountains, trees, clouds, sun) from main menu script

### Changed
- Main menu scene rebuilt: added ParallaxBackground, particle nodes, animated layout
- Menu buttons use spring entrance animation on ready

## [0.5.6] — 2026-03-21

### Added
- **Circle iris wipe** scene transition (`iris_wipe.gdshader`) — `change_scene_iris()` in SceneTransition autoload
- **App icon upgrade** — hero character on mountain peak with golden glow aura (replaced stick figure)
- `icon_foreground.svg` redrawn with full character detail

### Changed
- Scene transitions default to fade-to-black; iris wipe available as opt-in alternative
- `icon_192.png`, `icon_background_432.png`, `icon_foreground_432.png` regenerated

## [0.5.5] — 2026-03-21

### Added
- **Spring animations** on UI popups:
  - Activity popup: slide-up from bottom with spring overshoot on show, fade-out on close
  - Day summary: scale-in from center with spring + confetti particle burst
  - Achievement toast: slide-in from right with spring
  - Level up: scale-in with spring + glow pulse

### Changed
- All shared UI scenes updated with AnimationPlayer or tween-based spring animations
- Day summary confetti: GPUParticles2D burst (30 gold/green particles) on completion

## [0.5.4] — 2026-03-20

### Added
- **Improved mini-interactions** — drag_food (plate targets, success feedback), drink_water (glass fill animation, splash), flip_cards (card flip with reveal), hold_candle (flame flicker, glow radius)
- Gender select transition uses iris wipe

### Changed
- Mini-interaction scenes enlarged and polished for mobile readability
- E2E test suite expanded (288+ lines)

## [0.5.3] — 2026-03-20

### Added
- **Hero SVG rewrite** — all 4 climb sprites (idle/jump × female/male) completely redrawn:
  - ViewBox 80×150 → 120×200, SVG gradients, feDropShadow, 5-layer eyes, rim light
- **Ghost trail** — 3 semi-transparent sprite copies trail behind hero during jump
- **Landing dust** — GPUParticles2D burst (12 earthy-tone particles) on hero landing
- **Rotation tilt** — hero leans ±11° toward movement direction during arc jump
- **Sun/moon** — celestial bodies drawn via ProceduralDrawing methods
- **Cloud drift** — parallax clouds drift rightward at 8px/s

### Changed
- Hero `BASE_SCALE` 1.8 → 1.2 (new larger SVG viewBox)
- Particle textures: `PlaceholderTexture2D` → procedural `ImageTexture` with soft alpha falloff
- Hero jump: straight-line → quadratic bezier arc (120px elevation)
- HUD PauseBtn: `⏸` (24px) → `⚙` (32px, 80px min width); `"⚙ Настройки"` heading in pause menu
- Build script: APK filename includes version + unix timestamp

## [0.5.1] — 2026-03-20

### Added
- **E2E test suite** — 164 tests across 10 suites in `tests/test_e2e.gd`
- **Unified test runner** — `test.sh` runs unit + E2E, reports pass/fail per suite
- **397 total tests** (233 unit + 164 E2E)

### Fixed
- Broken mountain code in `vertical_level.gd` (non-static `get_class()` call)
- `ParallaxBackground.z_index` → `.layer` (extends CanvasLayer, not Node2D)
- XP test assertion (completing 'wk' at 04:30 earns both achievements)

## [0.3.0] — 2026-03-20

### Added
- Centralized font scaling via `ThemeManager.font_size()` — 40% base increase on all text
- User-adjustable text size in pause menu (80% / 100% / 120% / 150%)
- Text size preference persisted in save file
- Live UI re-rendering on scale change (Labels, Buttons, draw_string)
- Base font size overrides for 35 Label/Button nodes across 8 scenes
- Test suite (`tests/test_runner.gd`) — 7 suites, 80+ assertions

### Fixed
- Movement blocked after time window passes — removed "missed" state, past activities now return "available_late" (tappable with clock indicator)

## [0.2.0] — 2026-03-19

### Added
- Vertical-only game mode (portrait lock, vertical climb level)
- Time-blocking system — activities unlock at scheduled card times
- Done button on activity stations
- Gender selection screen (male/female character)
- Custom app icon (adaptive icon with foreground/background layers)
- Garden path game concept with 16 stations

## [0.1.0] — 2026-03-18

### Added
- Initial game prototype
- Main menu, pause menu, day summary screens
- 7-day practicum structure with 16 activity slots per day
- Activity popup with emoji, title, description
- XP/level system (10 levels, reaction-based scoring)
- Save/load game state via ConfigFile
- Developer mode toggle in pause menu
- HUD with clock, day counter, level display
