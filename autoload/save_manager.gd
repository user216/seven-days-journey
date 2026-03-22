extends Node
## Save/load game state via ConfigFile to user://save_data.cfg.

const SAVE_PATH := "user://save_data.cfg"
const SAVE_VERSION := 6

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("meta", "version", SAVE_VERSION)
	cfg.set_value("meta", "last_saved", Time.get_datetime_string_from_system())

	cfg.set_value("progress", "current_day", GameState.current_day)
	cfg.set_value("progress", "preferred_mode", GameState.current_mode)
	cfg.set_value("progress", "game_started", GameState.game_started)
	cfg.set_value("progress", "game_finished", GameState.game_finished)

	# Serialize completed activities as JSON
	var activities_json := {}
	for day in GameState.completed_activities:
		activities_json[str(day)] = GameState.completed_activities[day]
	cfg.set_value("progress", "completed_activities", JSON.stringify(activities_json))

	cfg.set_value("streak", "current", GameState.streak_current)
	cfg.set_value("streak", "best", GameState.streak_best)

	cfg.set_value("achievements", "earned", ",".join(GameState.achievements_earned))

	cfg.set_value("wellness", "water_glasses", GameState.water_glasses)
	cfg.set_value("wellness", "breathing_sessions", GameState.breathing_sessions)
	cfg.set_value("wellness", "breathing_minutes", GameState.breathing_minutes)

	cfg.set_value("state", "energy", GameState.energy)

	cfg.set_value("settings", "gender", GameState.gender)
	cfg.set_value("settings", "developer_mode", GameState.developer_mode)
	cfg.set_value("settings", "ui_scale", GameState.ui_scale)
	cfg.set_value("settings", "hero_skin_idx", GameState.hero_skin_idx)
	cfg.set_value("settings", "hero_hair_idx", GameState.hero_hair_idx)
	cfg.set_value("settings", "hero_hair_style_idx", GameState.hero_hair_style_idx)
	cfg.set_value("settings", "audio_volume", AudioManager.get_master_volume())
	cfg.set_value("settings", "ambient_enabled", AudioManager._ambient_enabled)
	cfg.set_value("settings", "sfx_enabled", AudioManager.get_sfx_enabled())
	cfg.set_value("settings", "haptic_enabled", GameState.haptic_enabled)

	# HOPA progress (v3)
	cfg.set_value("hopa", "progress", JSON.stringify(GameState.hopa_progress))
	cfg.set_value("hopa", "inventory", ",".join(GameState.hopa_inventory))
	cfg.set_value("hopa", "current_level", GameState.hopa_current_level)

	# Dialogue progress (v6)
	cfg.set_value("dialogue", "mode", GameState.dialogue_mode)
	cfg.set_value("dialogue", "progress", JSON.stringify(GameState.dialogue_progress))
	cfg.set_value("dialogue", "choices", JSON.stringify(GameState.dialogue_choices))

	cfg.save(SAVE_PATH)


func load_game() -> bool:
	if not has_save():
		return false

	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return false

	var version: int = cfg.get_value("meta", "version", 0)
	if version < 1 or version > SAVE_VERSION:
		return false

	GameState.reset()
	GameState.current_day = cfg.get_value("progress", "current_day", 1)
	GameState.current_mode = cfg.get_value("progress", "preferred_mode", "vertical")
	GameState.game_started = cfg.get_value("progress", "game_started", false)
	GameState.game_finished = cfg.get_value("progress", "game_finished", false)

	var activities_str: String = cfg.get_value("progress", "completed_activities", "{}")
	var activities_parsed = JSON.parse_string(activities_str)
	if activities_parsed is Dictionary:
		for day_str in activities_parsed:
			var day_num := int(day_str)
			GameState.completed_activities[day_num] = []
			for slot in activities_parsed[day_str]:
				GameState.completed_activities[day_num].append(str(slot))

	GameState.streak_current = cfg.get_value("streak", "current", 0)
	GameState.streak_best = cfg.get_value("streak", "best", 0)

	var earned_str: String = cfg.get_value("achievements", "earned", "")
	if earned_str.length() > 0:
		GameState.achievements_earned.assign(earned_str.split(","))
	else:
		GameState.achievements_earned = []

	GameState.water_glasses = cfg.get_value("wellness", "water_glasses", 0)
	GameState.breathing_sessions = cfg.get_value("wellness", "breathing_sessions", 0)
	GameState.breathing_minutes = cfg.get_value("wellness", "breathing_minutes", 0)
	GameState.energy = cfg.get_value("state", "energy", 1.0)

	GameState.gender = cfg.get_value("settings", "gender", "female")
	GameState.developer_mode = cfg.get_value("settings", "developer_mode", false)
	GameState.ui_scale = cfg.get_value("settings", "ui_scale", 1.0)
	GameState.hero_skin_idx = cfg.get_value("settings", "hero_skin_idx", 0)
	GameState.hero_hair_idx = cfg.get_value("settings", "hero_hair_idx", 0)
	GameState.hero_hair_style_idx = cfg.get_value("settings", "hero_hair_style_idx", 0)

	# Audio settings (v4+)
	AudioManager.set_master_volume(cfg.get_value("settings", "audio_volume", 0.7))
	AudioManager.set_ambient_enabled(cfg.get_value("settings", "ambient_enabled", true))
	AudioManager.set_sfx_enabled(cfg.get_value("settings", "sfx_enabled", true))
	GameState.haptic_enabled = cfg.get_value("settings", "haptic_enabled", true)

	# HOPA progress (v3 — missing keys default to empty)
	var hopa_str: String = cfg.get_value("hopa", "progress", "{}")
	var hopa_parsed = JSON.parse_string(hopa_str)
	if hopa_parsed is Dictionary:
		GameState.hopa_progress = hopa_parsed
	var hopa_inv_str: String = cfg.get_value("hopa", "inventory", "")
	if hopa_inv_str.length() > 0:
		GameState.hopa_inventory.assign(hopa_inv_str.split(","))
	else:
		GameState.hopa_inventory = []
	GameState.hopa_current_level = cfg.get_value("hopa", "current_level", "")

	# Dialogue progress (v6 — missing keys default to empty)
	GameState.dialogue_mode = cfg.get_value("dialogue", "mode", "")
	var dlg_prog_str: String = cfg.get_value("dialogue", "progress", "{}")
	var dlg_prog_parsed = JSON.parse_string(dlg_prog_str)
	if dlg_prog_parsed is Dictionary:
		GameState.dialogue_progress = {}
		for day_str in dlg_prog_parsed:
			var day_num := int(day_str)
			GameState.dialogue_progress[day_num] = []
			for slot in dlg_prog_parsed[day_str]:
				GameState.dialogue_progress[day_num].append(str(slot))
	var dlg_choices_str: String = cfg.get_value("dialogue", "choices", "{}")
	var dlg_choices_parsed = JSON.parse_string(dlg_choices_str)
	if dlg_choices_parsed is Dictionary:
		GameState.dialogue_choices = dlg_choices_parsed

	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
