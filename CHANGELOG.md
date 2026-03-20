# Changelog — 7 Days Journey

All notable changes to the game are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/).

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
