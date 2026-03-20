# Changelog — 7 Days Journey

All notable changes to the game are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/).

## [0.5.0] — 2026-03-20

### Added
- Vignette shader overlay — darkened screen edges for cinematic depth
- Platform glow shader — soft radial emission on active platforms
- Ambient glow shader — reusable soft radial light effect
- Completion sparkle burst — gold particle explosion when finishing activity
- Screen shake on activity completion (decaying camera offset)
- Hero squash & stretch — landing bounce, jump stretch, idle bob
- Pause menu accessible from HUD pause button (was missing in vertical mode)
- Wavy vine bridges with alternating leaf pairs
- Wider platforms (280px), taller platform texture (40px)
- More parallax nature: 18 trees, 22 bushes, 14 flowers, 10 clouds

### Changed
- Climb hero SVGs completely redrawn — 4x more detail (face, clothing, accessories match side hero quality)
- Platform SVG upgraded — stone cracks, moss highlights, embedded pebbles, tiny flowers, rounded edges, drop shadow
- Hero 50% larger (scale 1.8 vs 1.2) with higher-res viewBox (80×150 vs 64×120)
- More/denser particles: 30 leaves, 25 fireflies (was 20/15)
- Move speed increased (600 vs 500)

### Fixed
- Movement blocked by sky ColorRect absorbing touch events (added mouse_filter=IGNORE)
- Settings menu inaccessible — pause menu now added to vertical level with HUD button connection

## [0.4.0] — 2026-03-20

### Added
- Smooth sky gradient shader — replaces 20 flat color bands with GPU-rendered gradient + twinkling stars at night
- Falling leaf particles — gentle ambient drift with fade-in/out and color aging (green to brown)
- Night fireflies — warm yellow-green glowing particles, visible only after dark
- Parallax background — 3 depth layers (far: clouds, mid: trees, near: bushes/flowers) with independent scroll rates
- Textured platforms — SVG sprite with moss patches, highlights, and shadows replaces flat rectangles
- Wavy vine bridges with leaf dots between completed platforms
- Fade-to-black scene transitions on all screen changes
- `SceneTransition` autoload — `change_scene()` and `reload_scene()` with configurable duration
- Separate `build.sh` and `install.sh` scripts
- Game moved to standalone git repo (submodule `seven_days_game/`)

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
