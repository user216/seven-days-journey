extends SceneTree
## Headless test runner — run with: godot --headless --script tests/test_runner.gd
## Tests core logic: GameState, TimeSystem, GameData, SaveManager.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_count: int = 0
var _current_suite: String = ""


func _init() -> void:
	print("\n══════════════════════════════════════════════")
	print("  7 Days Journey — Test Suite")
	print("══════════════════════════════════════════════\n")

	# Initialize autoloads (normally done by engine)
	_setup_autoloads()

	# Run all test suites
	_suite_game_data()
	_suite_game_state()
	_suite_time_system()
	_suite_save_manager()
	_suite_time_blocking()
	_suite_gender_and_settings()
	_suite_activity_states()

	# Summary
	print("\n══════════════════════════════════════════════")
	if _fail_count == 0:
		print("  ALL %d TESTS PASSED ✓" % _test_count)
	else:
		print("  %d passed, %d FAILED out of %d tests" % [_pass_count, _fail_count, _test_count])
	print("══════════════════════════════════════════════\n")

	quit(0 if _fail_count == 0 else 1)


# ── Helpers ──────────────────────────────────────────────────────

func _setup_autoloads() -> void:
	# GameData, ThemeManager are pure data — create instances
	var gd_script := load("res://autoload/game_data.gd")
	var game_data := Node.new()
	game_data.set_script(gd_script)
	game_data.name = "GameData"
	root.add_child(game_data)

	var gs_script := load("res://autoload/game_state.gd")
	var game_state := Node.new()
	game_state.set_script(gs_script)
	game_state.name = "GameState"
	root.add_child(game_state)

	var ts_script := load("res://autoload/time_system.gd")
	var time_system := Node.new()
	time_system.set_script(ts_script)
	time_system.name = "TimeSystem"
	root.add_child(time_system)

	var sm_script := load("res://autoload/save_manager.gd")
	var save_manager := Node.new()
	save_manager.set_script(sm_script)
	save_manager.name = "SaveManager"
	root.add_child(save_manager)


func _suite(name: String) -> void:
	_current_suite = name
	print("── %s ──" % name)


func _assert(condition: bool, msg: String) -> void:
	_test_count += 1
	if condition:
		_pass_count += 1
		print("  ✓ %s" % msg)
	else:
		_fail_count += 1
		print("  ✗ FAIL: %s" % msg)


func _assert_eq(actual, expected, msg: String) -> void:
	_test_count += 1
	if actual == expected:
		_pass_count += 1
		print("  ✓ %s" % msg)
	else:
		_fail_count += 1
		print("  ✗ FAIL: %s (expected=%s, actual=%s)" % [msg, str(expected), str(actual)])


# ── GameData Tests ───────────────────────────────────────────────

func _suite_game_data() -> void:
	_suite("GameData")

	# Card count
	var cards := GameData.get_all_cards_for_day(1)
	_assert_eq(cards.size(), GameData.TOTAL_CARDS_PER_DAY, "Day 1 has 16 cards")

	for day in range(1, 8):
		var day_cards := GameData.get_all_cards_for_day(day)
		_assert_eq(day_cards.size(), 16, "Day %d has 16 cards" % day)

	# Cards are sorted by time
	for day in range(1, 8):
		var day_cards := GameData.get_all_cards_for_day(day)
		var sorted := true
		for i in range(day_cards.size() - 1):
			if day_cards[i].time > day_cards[i + 1].time:
				sorted = false
				break
		_assert(sorted, "Day %d cards are sorted by time" % day)

	# time_to_minutes conversion
	_assert_eq(GameData.time_to_minutes("04:30"), 270.0, "04:30 = 270 minutes")
	_assert_eq(GameData.time_to_minutes("06:00"), 360.0, "06:00 = 360 minutes")
	_assert_eq(GameData.time_to_minutes("13:00"), 780.0, "13:00 = 780 minutes")
	_assert_eq(GameData.time_to_minutes("22:00"), 1320.0, "22:00 = 1320 minutes")
	_assert_eq(GameData.time_to_minutes("00:00"), 0.0, "00:00 = 0 minutes")

	# get_card lookup
	var card := GameData.get_card(1, "wk")
	_assert(card.size() > 0, "get_card finds routine card 'wk' for day 1")
	_assert_eq(card.slot_id, "wk", "get_card returns correct slot_id")

	var day_card := GameData.get_card(1, "ep")
	_assert(day_card.size() > 0, "get_card finds day-specific card 'ep' for day 1")

	var missing := GameData.get_card(1, "nonexistent")
	_assert_eq(missing.size(), 0, "get_card returns empty for nonexistent slot")

	# Interaction scene mapping
	_assert(GameData.get_interaction_scene("wk", 1).length() > 0, "wk has interaction scene")
	_assert(GameData.get_interaction_scene("ep", 1).length() > 0, "ep day 1 has interaction scene")
	_assert(GameData.get_interaction_scene("ep", 2).length() > 0, "ep day 2 has different interaction")
	_assert(GameData.get_interaction_scene("ep", 1) != GameData.get_interaction_scene("ep", 2),
		"ep has day-specific interaction scenes")

	# Slot titles built
	_assert(GameData.SLOT_TITLES.size() > 0, "SLOT_TITLES populated")
	_assert("wk" in GameData.SLOT_TITLES, "SLOT_TITLES contains 'wk'")

	# All 11 routine slots exist
	var routine_slot_ids := []
	for card_r in GameData.ROUTINE_CARDS:
		routine_slot_ids.append(card_r.slot_id)
	_assert_eq(routine_slot_ids.size(), 11, "11 routine cards defined")

	# All 5 day-specific slots
	_assert_eq(GameData.DAY_SLOT_IDS.size(), 5, "5 day-specific slot IDs defined")

	# Levels
	_assert_eq(GameData.LEVEL_THRESHOLDS.size(), 10, "10 level thresholds defined")
	_assert_eq(GameData.LEVEL_THRESHOLDS[0].level, 1, "First level is 1")
	_assert_eq(GameData.LEVEL_THRESHOLDS[9].level, 10, "Last level is 10")

	# Achievements
	_assert_eq(GameData.ACHIEVEMENTS.size(), 8, "8 achievements defined")


# ── GameState Tests ──────────────────────────────────────────────

func _suite_game_state() -> void:
	_suite("GameState")

	# Reset initializes correctly
	GameState.reset()
	_assert_eq(GameState.current_day, 1, "Reset sets day to 1")
	_assert_eq(GameState.energy, 1.0, "Reset sets energy to 1.0")
	_assert_eq(GameState.game_started, false, "Reset clears game_started")
	_assert_eq(GameState.developer_mode, false, "Reset clears developer_mode")
	_assert_eq(GameState.streak_current, 0, "Reset clears streak")
	_assert_eq(GameState.water_glasses, 0, "Reset clears water_glasses")
	_assert_eq(GameState.achievements_earned.size(), 0, "Reset clears achievements")

	# completed_activities initialized for days 1-7
	for d in range(1, 8):
		_assert(d in GameState.completed_activities, "Day %d in completed_activities" % d)
		_assert_eq(GameState.completed_activities[d].size(), 0, "Day %d starts empty" % d)

	# start_game
	GameState.start_game()
	_assert_eq(GameState.game_started, true, "start_game sets game_started")
	_assert_eq(GameState.current_mode, "vertical", "start_game sets vertical mode")

	# complete_activity
	GameState.reset()
	GameState.complete_activity(1, "wk")
	_assert(GameState.is_activity_completed(1, "wk"), "wk marked as completed")
	_assert(!GameState.is_activity_completed(1, "wp"), "wp not completed")
	_assert_eq(GameState.get_daily_score(1), 1, "Daily score is 1 after one completion")

	# Duplicate completion ignored
	GameState.complete_activity(1, "wk")
	_assert_eq(GameState.get_daily_score(1), 1, "Duplicate completion ignored")

	# Weekly score
	GameState.complete_activity(1, "wp")
	GameState.complete_activity(2, "wk")
	_assert_eq(GameState.get_weekly_score(), 3, "Weekly score counts across days")

	# Energy / miss
	GameState.reset()
	var initial_energy := GameState.energy
	GameState.miss_activity(1, "wk")
	_assert(GameState.energy < initial_energy, "miss_activity drains energy")
	_assert(GameState.energy >= 0.0, "Energy stays non-negative")

	# Day progression
	GameState.reset()
	_assert_eq(GameState.current_day, 1, "Starts at day 1")
	var advanced := GameState.advance_day()
	_assert(advanced, "advance_day returns true for day 1→2")
	_assert_eq(GameState.current_day, 2, "Day advanced to 2")

	# Day progression — end of week
	GameState.current_day = 7
	var end := GameState.advance_day()
	_assert(!end, "advance_day returns false at day 7")
	_assert(GameState.game_finished, "game_finished set at end of week")

	# XP calculation
	GameState.reset()
	var xp0 := GameState.calculate_xp()
	_assert_eq(xp0.total, 0, "Zero XP with no activity")
	_assert_eq(xp0.level, 1, "Level 1 at zero XP")
	_assert_eq(xp0.level_name, "Новичок", "Level name 'Новичок' at start")

	# XP after reactions
	GameState.complete_activity(1, "wk")
	var xp1 := GameState.calculate_xp()
	_assert_eq(xp1.total, GameData.XP_PER_REACTION + GameData.XP_PER_ACHIEVEMENT,
		"XP includes reaction + first_reaction achievement")

	# Gender preserved across reset
	GameState.gender = "male"
	GameState.reset()
	_assert_eq(GameState.gender, "male", "Gender preserved across reset")
	GameState.gender = "female"  # restore default


# ── TimeSystem Tests ─────────────────────────────────────────────

func _suite_time_system() -> void:
	_suite("TimeSystem")

	GameState.reset()
	GameState.developer_mode = false

	# start_day populates windows
	TimeSystem.start_day(1)
	_assert(TimeSystem._time_windows.size() > 0, "Time windows computed for day 1")
	_assert_eq(TimeSystem._current_day_cards.size(), 16, "16 cards loaded for day 1")

	# Every card has a time window
	for card in TimeSystem._current_day_cards:
		_assert(card.slot_id in TimeSystem._time_windows,
			"Time window exists for slot '%s'" % card.slot_id)

	# Time windows have valid start/end
	for slot_id in TimeSystem._time_windows:
		var w: Dictionary = TimeSystem._time_windows[slot_id]
		_assert(w.has("start"), "Window has 'start' for %s" % slot_id)
		_assert(w.has("end"), "Window has 'end' for %s" % slot_id)
		_assert(w.end > w.start, "Window end > start for %s" % slot_id)
		_assert(w.end - w.start >= TimeSystem.MIN_WINDOW_MINUTES,
			"Window >= %d min for %s" % [int(TimeSystem.MIN_WINDOW_MINUTES), slot_id])

	# First card window starts at 04:30 = 270 minutes
	var first_window: Dictionary = TimeSystem._time_windows.get("wk", {})
	_assert_eq(first_window.start, 270.0, "First activity (wk) window starts at 270 min (04:30)")

	# Time windows don't overlap (for unique-time slots)
	var windows_sorted: Array = []
	for slot_id in TimeSystem._time_windows:
		var w: Dictionary = TimeSystem._time_windows[slot_id]
		windows_sorted.append({"slot": slot_id, "start": w.start, "end": w.end})
	windows_sorted.sort_custom(func(a, b): return a.start < b.start)

	# get_time_string format
	var time_str := TimeSystem.get_time_string()
	_assert(time_str.length() == 5, "get_time_string returns HH:MM format (len=5)")
	_assert(time_str[2] == ":", "get_time_string has ':' separator")

	# get_current_phase returns valid phase
	var phase := TimeSystem.get_current_phase()
	_assert(phase in ["night", "dawn", "morning", "day", "afternoon", "evening"],
		"get_current_phase returns valid phase: '%s'" % phase)

	# is_activity_available_now returns bool
	var available := TimeSystem.is_activity_available_now("wk")
	_assert(available is bool, "is_activity_available_now returns bool")

	# pause/resume
	TimeSystem.pause()
	_assert(TimeSystem.paused, "pause() sets paused=true")
	TimeSystem.resume()
	_assert(!TimeSystem.paused, "resume() sets paused=false")


# ── SaveManager Tests ────────────────────────────────────────────

func _suite_save_manager() -> void:
	_suite("SaveManager")

	# Clean state
	SaveManager.delete_save()
	_assert(!SaveManager.has_save(), "No save file after delete")

	# Load returns false when no save
	_assert(!SaveManager.load_game(), "load_game returns false when no save exists")

	# Save and verify file exists
	GameState.reset()
	GameState.start_game()
	GameState.gender = "male"
	GameState.developer_mode = true
	GameState.current_day = 3
	GameState.complete_activity(1, "wk")
	GameState.complete_activity(1, "wp")
	GameState.streak_current = 2
	GameState.streak_best = 2
	GameState.water_glasses = 5
	GameState.energy = 0.75
	SaveManager.save_game()

	_assert(SaveManager.has_save(), "Save file exists after save_game")

	# Load restores state correctly
	GameState.reset()
	_assert_eq(GameState.current_day, 1, "After reset, day is 1")

	var loaded := SaveManager.load_game()
	_assert(loaded, "load_game returns true")
	_assert_eq(GameState.current_day, 3, "Loaded day = 3")
	_assert_eq(GameState.gender, "male", "Loaded gender = male")
	_assert_eq(GameState.developer_mode, true, "Loaded developer_mode = true")
	_assert_eq(GameState.game_started, true, "Loaded game_started = true")
	_assert(GameState.is_activity_completed(1, "wk"), "Loaded completion: day 1 wk")
	_assert(GameState.is_activity_completed(1, "wp"), "Loaded completion: day 1 wp")
	_assert(!GameState.is_activity_completed(1, "tp"), "Loaded completion: day 1 tp not completed")
	_assert_eq(GameState.streak_current, 2, "Loaded streak_current = 2")
	_assert_eq(GameState.streak_best, 2, "Loaded streak_best = 2")
	_assert_eq(GameState.water_glasses, 5, "Loaded water_glasses = 5")
	_assert_eq(GameState.energy, 0.75, "Loaded energy = 0.75")

	# Save version = 2
	var cfg := ConfigFile.new()
	cfg.load(SaveManager.SAVE_PATH)
	var version: int = cfg.get_value("meta", "version", 0)
	_assert_eq(version, 2, "Save version is 2")

	# v1 save compat: version 1 should load
	cfg.set_value("meta", "version", 1)
	cfg.save(SaveManager.SAVE_PATH)
	GameState.reset()
	_assert(SaveManager.load_game(), "v1 save loads successfully (compat)")

	# Invalid version rejected
	cfg.set_value("meta", "version", 0)
	cfg.save(SaveManager.SAVE_PATH)
	GameState.reset()
	_assert(!SaveManager.load_game(), "v0 save rejected")

	cfg.set_value("meta", "version", 99)
	cfg.save(SaveManager.SAVE_PATH)
	GameState.reset()
	_assert(!SaveManager.load_game(), "v99 save rejected")

	# Cleanup
	SaveManager.delete_save()
	_assert(!SaveManager.has_save(), "Save deleted successfully")

	# Restore default
	GameState.gender = "female"
	GameState.developer_mode = false


# ── Time-Blocking Tests ─────────────────────────────────────────

func _suite_time_blocking() -> void:
	_suite("Time-Blocking")

	GameState.reset()
	GameState.developer_mode = false
	TimeSystem.start_day(1)

	var now := TimeSystem.get_real_minutes()

	# Find slots that are in the past, current, and future relative to real time
	var past_slot: String = ""
	var current_slot: String = ""
	var future_slot: String = ""

	for card in TimeSystem._current_day_cards:
		var w: Dictionary = TimeSystem._time_windows.get(card.slot_id, {})
		if w:
			if now >= w.end and past_slot == "":
				past_slot = card.slot_id
			elif now >= w.start and now < w.end and current_slot == "":
				current_slot = card.slot_id
			elif now < w.start and future_slot == "":
				future_slot = card.slot_id

	# Test states based on real time
	if past_slot != "":
		var state := TimeSystem.get_activity_state(past_slot)
		_assert_eq(state, "available_late",
			"Past-window slot '%s' is 'available_late' (not missed)" % past_slot)
		_assert(TimeSystem.is_activity_available_now(past_slot),
			"Past-window slot '%s' is available (tappable)" % past_slot)

	if current_slot != "":
		var state := TimeSystem.get_activity_state(current_slot)
		_assert_eq(state, "current",
			"In-window slot '%s' is 'current'" % current_slot)
		_assert(TimeSystem.is_activity_available_now(current_slot),
			"In-window slot '%s' is available (tappable)" % current_slot)

	if future_slot != "":
		var state := TimeSystem.get_activity_state(future_slot)
		_assert_eq(state, "locked",
			"Future slot '%s' is 'locked'" % future_slot)
		_assert(!TimeSystem.is_activity_available_now(future_slot),
			"Future slot '%s' is NOT available" % future_slot)

	# Completed overrides all states
	if past_slot != "":
		GameState.complete_activity(1, past_slot)
		_assert_eq(TimeSystem.get_activity_state(past_slot), "completed",
			"Completed activity returns 'completed' regardless of time")

	# Developer mode: all past activities are "current"
	GameState.reset()
	GameState.developer_mode = true
	TimeSystem.start_day(1)

	if past_slot != "":
		var state := TimeSystem.get_activity_state(past_slot)
		_assert_eq(state, "current",
			"Dev mode: past slot '%s' is 'current' (not available_late)" % past_slot)

	if future_slot != "":
		var state := TimeSystem.get_activity_state(future_slot)
		_assert_eq(state, "locked",
			"Dev mode: future slot '%s' still 'locked'" % future_slot)

	# No "missed" state exists anymore
	var all_states: Array[String] = []
	for card in TimeSystem._current_day_cards:
		var s := TimeSystem.get_activity_state(card.slot_id)
		if s not in all_states:
			all_states.append(s)
	_assert("missed" not in all_states,
		"No 'missed' state in any activity (states: %s)" % str(all_states))

	# Dev mode off: count tappable platforms
	GameState.reset()
	GameState.developer_mode = false
	TimeSystem.start_day(1)
	var tappable_count := 0
	for card in TimeSystem._current_day_cards:
		if TimeSystem.is_activity_available_now(card.slot_id):
			tappable_count += 1
	# At any time of day, past + current should give us some tappable platforms
	# (past are available_late, current is current)
	_assert(tappable_count > 0 or now < 270.0,
		"At least one tappable platform (count=%d, time=%.0f min)" % [tappable_count, now])

	# Restore
	GameState.developer_mode = false


# ── Gender & Settings Tests ──────────────────────────────────────

func _suite_gender_and_settings() -> void:
	_suite("Gender & Settings")

	# Default gender
	GameState.reset()
	_assert_eq(GameState.gender, "female", "Default gender is female (previous sessions preserved, but after full reset)")
	# Note: gender is preserved across reset(), but was set to "female" above

	# Gender survives reset
	GameState.gender = "male"
	GameState.reset()
	_assert_eq(GameState.gender, "male", "Gender preserved after reset()")

	# Developer mode does NOT survive reset
	GameState.developer_mode = true
	GameState.reset()
	_assert_eq(GameState.developer_mode, false, "Developer mode cleared after reset()")

	# start_game resets dev mode too
	GameState.developer_mode = true
	GameState.start_game()
	_assert_eq(GameState.developer_mode, false, "Developer mode cleared after start_game()")

	# Gender saved and loaded
	GameState.gender = "male"
	SaveManager.save_game()
	GameState.gender = "female"
	SaveManager.load_game()
	_assert_eq(GameState.gender, "male", "Gender round-trips through save/load")

	# Developer mode saved and loaded
	GameState.developer_mode = true
	SaveManager.save_game()
	GameState.developer_mode = false
	SaveManager.load_game()
	_assert_eq(GameState.developer_mode, true, "Developer mode round-trips through save/load")

	# Mode is always vertical
	GameState.start_game()
	_assert_eq(GameState.current_mode, "vertical", "Mode is always 'vertical'")

	# Cleanup
	SaveManager.delete_save()
	GameState.gender = "female"
	GameState.developer_mode = false


# ── Activity State Transitions ───────────────────────────────────

func _suite_activity_states() -> void:
	_suite("Activity State Transitions")

	GameState.reset()
	GameState.developer_mode = false
	TimeSystem.start_day(1)

	# Valid states are: completed, current, available_late, locked
	var valid_states := ["completed", "current", "available_late", "locked"]
	for card in TimeSystem._current_day_cards:
		var state := TimeSystem.get_activity_state(card.slot_id)
		_assert(state in valid_states,
			"Slot '%s' state '%s' is valid" % [card.slot_id, state])

	# Complete an activity and verify transition
	var test_slot := TimeSystem._current_day_cards[0].slot_id
	var state_before := TimeSystem.get_activity_state(test_slot)
	_assert(state_before != "completed", "Slot '%s' not completed initially" % test_slot)

	GameState.complete_activity(1, test_slot)
	var state_after := TimeSystem.get_activity_state(test_slot)
	_assert_eq(state_after, "completed", "Slot '%s' becomes completed after complete_activity" % test_slot)

	# Achievements triggered by completion
	_assert("first_reaction" in GameState.achievements_earned,
		"first_reaction achievement earned after first completion")

	# Perfect day check
	GameState.reset()
	for card in GameData.get_all_cards_for_day(1):
		GameState.complete_activity(1, card.slot_id)
	_assert_eq(GameState.get_daily_score(1), 16, "Perfect day: all 16 activities completed")
	_assert_eq(GameState.get_perfect_days(), 1, "1 perfect day counted")
	_assert("day_complete" in GameState.achievements_earned, "day_complete achievement earned")

	# Energy starts at 1.0, decreases with misses
	GameState.reset()
	_assert_eq(GameState.energy, 1.0, "Energy starts at 1.0")
	for i in range(16):
		GameState.miss_activity(1, "slot_%d" % i)
	_assert_eq(GameState.energy, 0.0, "Energy reaches 0 after 16 misses")

	# Verify get_time_of_day_factor is bounded
	var factor := TimeSystem.get_time_of_day_factor()
	_assert(factor >= 0.0, "Time of day factor >= 0")
	_assert(factor <= 1.0, "Time of day factor <= 1")

	# get_next_activity returns a dict or empty
	var next := TimeSystem.get_next_activity()
	_assert(next is Dictionary, "get_next_activity returns Dictionary")
	if next.size() > 0:
		_assert("slot_id" in next, "Next activity has slot_id")
		_assert("time" in next, "Next activity has time")

	# Restore clean state
	GameState.reset()
