# Changelog — 7 Days Journey

All notable changes to the game are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/).

## [0.7.18] — 2026-03-23

### Fixed
- **AudioStreamWAV LOOP_FORWARD crash (SIGSEGV in AudioTrack)** — removed native `loop_mode = LOOP_FORWARD` from all procedural audio streams (ambient drone, 3 music tracks); native AudioTrack thread was accessing GC-managed PackedByteArray buffer at loop boundary, causing ARM MTE `SEGV_ACCERR` on Infinix X6853 (exactly at 4.0s ambient drone loop point); now loops via GDScript `finished` signal (main thread, no cross-thread buffer access)
- Added `finished` signal to both music players (was only on player A) for proper crossfade loop handling

### Added
- v0.7.16: Visible diagnostic toggle switches on main menu (Audio, Shaders, Rendering) — replaces hidden triple-tap; flags persisted to `user://diag_flags.txt`
- v0.7.16: Android logcat capture in CrashLogger — on restart after crash, captures last 500 logcat lines with native crash stacktrace filtering

## [0.7.14] — 2026-03-23

### Changed
- **Switched renderer from Vulkan Mobile to GL Compatibility (OpenGL ES 3.0)** — Mali-G57 MC2 (Vulkan 1.1.177) still crashes after 4-5 seconds of steady-state rendering despite all Vulkan-specific mitigations (staggered shader warmup, CPUParticles2D, lazy screen-texture shaders, no warmup rect cleanup, throttled draw calls); 2D game does not use any Vulkan-specific rendering features; OpenGL ES 3.0 is universally supported on target devices and eliminates all Vulkan driver compatibility issues
- Updated `config/features` from `Mobile` to `GL Compatibility`

## [0.7.13] — 2026-03-23

### Fixed
- **Shader warmup cleanup crash** — warmup rects (14 invisible 1px nodes) are no longer freed; on Mali Vulkan, freeing shader material resources while the GPU command buffer still references them causes deferred native crash
- Heartbeat breadcrumbs now fire every 1 second (was 3s) for precise crash timing

## [0.7.12] — 2026-03-23

### Fixed
- **SceneTransition shockwave early-load crash** — lazy-load `shockwave.gdshader` (uses `hint_screen_texture`) on first `shockwave()` call instead of at boot; having the material in the scene tree at startup corrupts Mali's internal screen texture binding
- **DrawLayer Vulkan command buffer pressure** — throttled `queue_redraw()` from 60fps to ~20fps; reduced sun glow rings from 5 to 3; cuts Vulkan draw calls by 66%
- Added 1-second heartbeat breadcrumbs during MainMenu rendering for crash timing diagnosis

## [0.7.11] — 2026-03-23

### Fixed
- **Mali-G57 crash (GPUParticles2D)** — replaced all 14 GPUParticles2D instances with CPUParticles2D across 10 files; GPUParticles2D uses Vulkan compute shaders that crash Mali-G57 MC2 with Vulkan 1.1.177 driver after particle buffer cycles (~10-12s); CPUParticles2D is visually identical, no compute shaders

### Changed
- All particle systems now use CPUParticles2D (leaf, sparkle, confetti, dust, firefly, ambient, discovery burst)

## [0.7.10] — 2026-03-23

### Added
- **CrashLogger breadcrumb trail** — `CrashLogger.breadcrumb("label")` writes timestamped markers to `user://breadcrumbs.txt`; each autoload and key startup step writes a breadcrumb; on crash, the trail shows exactly which step was executing when the native crash happened
- Breadcrumbs in all 9 autoloads + MainMenu (15 total markers across initialization sequence)

## [0.7.9] — 2026-03-23

### Fixed
- **Mali shader warmup crash** — staggered shader compilation from 16-at-once to 4 per frame; excluded `background_blur` and `shockwave` shaders (use `hint_screen_texture` which doesn't exist before first frame renders)
- **hopa_object_highlight shader** — replaced 169-fetch dynamic loop (13×13) with 8 fixed directional samples; dynamic loops with texture fetches in non-uniform control flow crash Mali Vulkan drivers
- **sprite_outline shader** — moved all texture fetches to unconditional code path; texture sampling inside branching causes undefined behavior on Mali tile-based renderers
- **VERSION file not exported** — added `VERSION` to `include_filter` in export_presets.cfg (was showing "App version: ?" in crash reports)

## [0.7.8] — 2026-03-23

### Added
- **CrashLogger autoload** — NewPipe-style crash recovery: session state tracking, post-crash dialog with device diagnostics (GPU, model, VRAM, renderer), engine log capture, email report with clipboard backup
- **Send logs button** in main menu — "Отправить логи" button calling `CrashLogger.send_logs_via_email()`

### Fixed
- **ObjectDB/RID leak warnings in tests** — added `await process_frame` before `quit()` in test_runner.gd and test_e2e.gd so `queue_free()` calls complete before exit
- **AudioStreamWAV leak in headless mode** — skip audio playback in headless mode (`_headless` flag) while keeping sound generation for E2E tests
- **crash_logger.gd parse error** — fixed Variant type inference with explicit `Vector2` type annotation
- **godogen_scene.gd parse error** — fixed "Cannot infer type of instance" with explicit `PackedScene`/`Node` types
- **top_down_level.gd script error** — changed `TimeSystem.game_time_minutes` (non-existent property) to `TimeSystem.get_real_minutes()`

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
