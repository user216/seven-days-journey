extends Node
## Mutable game state — XP, levels, energy, achievements, streaks.

# ── Signals ───────────────────────────────────────────────────────

signal activity_completed(day: int, slot_id: String)
signal xp_gained(amount: int, source: String)
signal level_up(new_level: int, level_name: String)
signal achievement_earned(achievement: Dictionary)
signal energy_changed(new_value: float)
signal day_completed(day: int)
signal streak_updated(current_streak: int, best_streak: int)
signal ui_scale_changed(new_scale: float)
signal hero_appearance_changed
signal hopa_level_completed(scene_id: String, stats: Dictionary)

# ── State ─────────────────────────────────────────────────────────

var current_day: int = 1
var current_mode: String = "vertical"  # vertical (focused mode)
var gender: String = "female"  # "female" or "male"
var developer_mode: bool = false  # disables time-blocking
var ui_scale: float = 1.0  # user-adjustable text/icon scale
var hero_skin_idx: int = 0  # index into SKIN_PRESETS
var hero_hair_idx: int = 0  # index into HAIR_PRESETS
var hero_hair_style_idx: int = 0  # index into HAIR_STYLE_PRESETS_F/M
var completed_activities: Dictionary = {}  # {day_num: [slot_ids]}
var streak_current: int = 0
var streak_best: int = 0
var achievements_earned: Array[String] = []
var energy: float = 1.0
var water_glasses: int = 0
var breathing_sessions: int = 0
var breathing_minutes: int = 0
var game_started: bool = false
var game_finished: bool = false
var haptic_enabled: bool = true

# ── HOPA state ───────────────────────────────────────────────────

var hopa_progress: Dictionary = {}       # {scene_id: {completed, time_seconds, objects_found, hints_used}}
var hopa_inventory: Array[String] = []   # key item IDs collected across levels
var hopa_current_level: String = ""      # set before transitioning to HOPA scene

# ── Dialogue state ───────────────────────────────────────────────

signal dialogue_node_completed(day: int, slot_id: String)

var dialogue_mode: String = ""           # "visual_novel", "rpg_companion", "godogen"
var dialogue_progress: Dictionary = {}   # {day_num: [completed_slot_ids]}
var dialogue_choices: Dictionary = {}    # {dialogue_key: chosen_option_key}

# ── Initialization ────────────────────────────────────────────────

func reset() -> void:
	current_day = 1
	completed_activities = {}
	streak_current = 0
	streak_best = 0
	achievements_earned = []
	energy = 1.0
	water_glasses = 0
	breathing_sessions = 0
	breathing_minutes = 0
	game_started = false
	game_finished = false
	hopa_progress = {}
	hopa_inventory = []
	hopa_current_level = ""
	dialogue_mode = ""
	dialogue_progress = {}
	dialogue_choices = {}
	# gender, ui_scale preserved across resets, developer_mode reset
	developer_mode = false
	_invalidate_xp()
	for d in range(1, 8):
		completed_activities[d] = []


func _ready() -> void:
	CrashLogger.breadcrumb("GameState._ready")
	reset()


# ── Activity completion ──────────────────────────────────────────

func complete_activity(day: int, slot_id: String) -> void:
	if day not in completed_activities:
		completed_activities[day] = []
	if slot_id in completed_activities[day]:
		return

	completed_activities[day].append(slot_id)
	_invalidate_xp()
	activity_completed.emit(day, slot_id)

	# Award XP
	xp_gained.emit(GameData.XP_PER_REACTION, "reaction")

	# Check for day completion
	if get_daily_score(day) >= GameData.TOTAL_CARDS_PER_DAY:
		day_completed.emit(day)
		_update_streak(day)

	_check_achievements(day, slot_id)

	# Check level up
	var old_level := _get_level_before_last()
	var xp_data := get_cached_xp()
	_prev_level = xp_data.level
	if xp_data.level > old_level:
		level_up.emit(xp_data.level, xp_data.level_name)


func miss_activity(_day: int, _slot_id: String) -> void:
	var drain := 1.0 / float(GameData.TOTAL_CARDS_PER_DAY)
	energy = maxf(0.0, energy - drain)
	energy_changed.emit(energy)


# ── Score / XP ────────────────────────────────────────────────────

func get_daily_score(day: int) -> int:
	return len(completed_activities.get(day, []))


func get_weekly_score() -> int:
	var total := 0
	for day in completed_activities:
		total += len(completed_activities[day])
	return total


func get_perfect_days() -> int:
	var count := 0
	for day in completed_activities:
		if len(completed_activities[day]) >= GameData.TOTAL_CARDS_PER_DAY:
			count += 1
	return count


func calculate_xp() -> Dictionary:
	var total_reactions := get_weekly_score()
	var xp := (
		total_reactions * GameData.XP_PER_REACTION
		+ streak_current * GameData.XP_PER_STREAK_DAY
		+ streak_best * GameData.XP_PER_BEST_STREAK_DAY
		+ len(achievements_earned) * GameData.XP_PER_ACHIEVEMENT
		+ get_perfect_days() * GameData.XP_PER_PERFECT_DAY
	)

	var level := 1
	var level_xp := 0
	var level_name := "Новичок"
	var next_level_xp := 50

	for i in range(len(GameData.LEVEL_THRESHOLDS)):
		var t: Dictionary = GameData.LEVEL_THRESHOLDS[i]
		if xp >= t.xp:
			level = t.level
			level_xp = t.xp
			level_name = t.name
			if i + 1 < len(GameData.LEVEL_THRESHOLDS):
				next_level_xp = GameData.LEVEL_THRESHOLDS[i + 1].xp
			else:
				next_level_xp = t.xp

	var xp_in_level := xp - level_xp
	var xp_for_level := maxi(next_level_xp - level_xp, 1)
	var progress_pct: int = mini(roundi(float(xp_in_level) / float(xp_for_level) * 100.0), 100) if level < 10 else 100

	return {
		"total": xp,
		"level": level,
		"level_name": level_name,
		"next_level_xp": next_level_xp,
		"xp_in_level": xp_in_level,
		"xp_for_level": xp_for_level,
		"progress_pct": progress_pct,
	}


# ── Streak ────────────────────────────────────────────────────────

func _update_streak(day: int) -> void:
	if day == current_day:
		streak_current += 1
		streak_best = maxi(streak_best, streak_current)
		_invalidate_xp()
		streak_updated.emit(streak_current, streak_best)


# ── Achievements ──────────────────────────────────────────────────

func _check_achievements(day: int, slot_id: String) -> void:
	var total_reactions := get_weekly_score()

	# first_reaction
	if total_reactions == 1 and "first_reaction" not in achievements_earned:
		_earn_achievement("first_reaction")

	# day_complete
	if get_daily_score(day) >= GameData.TOTAL_CARDS_PER_DAY and "day_complete" not in achievements_earned:
		_earn_achievement("day_complete")

	# perfect_week
	if get_weekly_score() >= 112 and "perfect_week" not in achievements_earned:
		_earn_achievement("perfect_week")

	# streak_3
	if streak_current >= 3 and "streak_3" not in achievements_earned:
		_earn_achievement("streak_3")

	# streak_7
	if streak_current >= 7 and "streak_7" not in achievements_earned:
		_earn_achievement("streak_7")

	# early_bird: activity before 06:00 game time
	var card := GameData.get_card(day, slot_id)
	if card and GameData.time_to_minutes(card.time) < 360.0 and "early_bird" not in achievements_earned:
		_earn_achievement("early_bird")

	# night_owl: evening practice
	if slot_id == "ep" and "night_owl" not in achievements_earned:
		_earn_achievement("night_owl")

	# speed_demon: first activity completed quickly (always true in game since accelerated)
	if "speed_demon" not in achievements_earned and total_reactions >= 3:
		_earn_achievement("speed_demon")


func _earn_achievement(key: String) -> void:
	achievements_earned.append(key)
	_invalidate_xp()
	for a in GameData.ACHIEVEMENTS:
		if a.key == key:
			achievement_earned.emit(a)
			xp_gained.emit(GameData.XP_PER_ACHIEVEMENT, "achievement")
			break


# ── Internal ──────────────────────────────────────────────────────

var _prev_level: int = 1
var _cached_xp: Dictionary = {}
var _xp_dirty: bool = true

func _get_level_before_last() -> int:
	return _prev_level


func _invalidate_xp() -> void:
	_xp_dirty = true


func get_cached_xp() -> Dictionary:
	if _xp_dirty:
		_cached_xp = calculate_xp()
		_xp_dirty = false
	return _cached_xp


# ── HOPA completion ─────────────────────────────────────────────

func complete_hopa_level(scene_id: String, time_seconds: float, objects_found: int, hints_used: int) -> void:
	hopa_progress[scene_id] = {
		"completed": true,
		"time_seconds": time_seconds,
		"objects_found": objects_found,
		"hints_used": hints_used,
	}
	_invalidate_xp()
	# Award XP per object found
	var xp_amount := objects_found * GameData.XP_PER_REACTION
	xp_gained.emit(xp_amount, "hopa_level")
	_check_hopa_achievements(scene_id, time_seconds, hints_used)
	hopa_level_completed.emit(scene_id, hopa_progress[scene_id])


func _check_hopa_achievements(scene_id: String, time_seconds: float, hints_used: int) -> void:
	# First HOPA level
	if hopa_progress.size() == 1 and "hopa_first_level" not in achievements_earned:
		_earn_achievement("hopa_first_level")
	# No hints
	if hints_used == 0 and "hopa_no_hints" not in achievements_earned:
		_earn_achievement("hopa_no_hints")
	# Speed run (under 60s)
	if time_seconds < 60.0 and "hopa_speed_run" not in achievements_earned:
		_earn_achievement("hopa_speed_run")
	# All 7 levels
	if hopa_progress.size() >= 7 and "hopa_all_levels" not in achievements_earned:
		_earn_achievement("hopa_all_levels")


# ── Day progression ──────────────────────────────────────────────

func advance_day() -> bool:
	if current_day >= 7:
		game_finished = true
		return false
	current_day += 1
	energy = 1.0
	water_glasses = 0
	energy_changed.emit(energy)
	return true


func start_game() -> void:
	reset()
	current_mode = "vertical"
	game_started = true


func is_activity_completed(day: int, slot_id: String) -> bool:
	return slot_id in completed_activities.get(day, [])


func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, 0.5, 2.0)
	ui_scale_changed.emit(ui_scale)


func vibrate(duration_ms: int = 50) -> void:
	if haptic_enabled:
		Input.vibrate_handheld(duration_ms)


# ── Hero appearance presets ──────────────────────────────────────
# Skin: modulate tint applied to skin elements (SVG base is peach #fce4cc)
const SKIN_PRESETS := [
	{"name": "Светлая", "tint": Color(1.0, 1.0, 1.0)},       # default peach
	{"name": "Тёплая", "tint": Color(1.0, 0.92, 0.82)},      # warm tan
	{"name": "Оливковая", "tint": Color(0.90, 0.85, 0.72)},   # olive
	{"name": "Смуглая", "tint": Color(0.78, 0.65, 0.50)},     # brown
	{"name": "Тёмная", "tint": Color(0.55, 0.42, 0.32)},      # dark
]

# Hair: modulate tint applied to hair elements (SVG base is auburn #a0784e)
const HAIR_PRESETS := [
	{"name": "Каштан", "tint": Color(1.0, 1.0, 1.0)},         # default auburn
	{"name": "Блонд", "tint": Color(1.45, 1.35, 0.95)},       # blonde (brighten)
	{"name": "Чёрный", "tint": Color(0.4, 0.35, 0.3)},        # black
	{"name": "Рыжий", "tint": Color(1.3, 0.75, 0.45)},        # red/ginger
	{"name": "Русый", "tint": Color(0.85, 0.75, 0.60)},       # light brown
]


func get_skin_tint() -> Color:
	return SKIN_PRESETS[clampi(hero_skin_idx, 0, SKIN_PRESETS.size() - 1)].tint

func get_hair_tint() -> Color:
	return HAIR_PRESETS[clampi(hero_hair_idx, 0, HAIR_PRESETS.size() - 1)].tint

# Hair style/type presets — suffix maps to SVG filename
const HAIR_STYLE_PRESETS_F := [
	{"name": "Длинные", "suffix": ""},           # default long
	{"name": "Короткие", "suffix": "_short"},    # short bob
	{"name": "Хвост", "suffix": "_ponytail"},    # ponytail
	{"name": "Косы", "suffix": "_braided"},      # braided
]
const HAIR_STYLE_PRESETS_M := [
	{"name": "Короткие", "suffix": ""},          # default short
	{"name": "Ёжик", "suffix": "_buzz"},         # buzz
	{"name": "Торчком", "suffix": "_spiky"},     # spiky
	{"name": "Набок", "suffix": "_swept"},       # swept side
]

func get_hair_style_presets() -> Array:
	if gender == "male":
		return HAIR_STYLE_PRESETS_M
	return HAIR_STYLE_PRESETS_F

func get_hair_style_suffix() -> String:
	var presets := get_hair_style_presets()
	var idx := clampi(hero_hair_style_idx, 0, presets.size() - 1)
	return presets[idx].suffix

func get_hair_style_name() -> String:
	var presets := get_hair_style_presets()
	var idx := clampi(hero_hair_style_idx, 0, presets.size() - 1)
	return presets[idx].name
