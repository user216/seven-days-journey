extends SceneTree
## Headless test runner — run with: godot --headless --script tests/test_runner.gd
## Tests core logic: GameState, TimeSystem, GameData, SaveManager.
##
## NOTE: We use call_deferred + process frames so that Godot's own autoload
## system (from project.godot) has time to initialize all singletons.
## The _run_tests() starts after 2 idle frames — by then all autoloads are ready.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_count: int = 0
var _current_suite: String = ""


func _init() -> void:
	# Wait for autoloads to be ready by deferring
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("\n══════════════════════════════════════════════")
	print("  7 Days Journey — Test Suite")
	print("══════════════════════════════════════════════\n")

	var GD := root.get_node("GameData")
	var GS := root.get_node("GameState")
	var TS := root.get_node("TimeSystem")
	var SM := root.get_node("SaveManager")

	if not GD or not GS or not TS or not SM:
		print("  ✗ FATAL: Autoloads not found. Ensure project.godot has them registered.")
		print("    GameData=%s GameState=%s TimeSystem=%s SaveManager=%s" % [
			str(GD != null), str(GS != null), str(TS != null), str(SM != null)])
		quit(1)
		return

	_suite_game_data(GD)
	_suite_game_state(GS, GD)
	_suite_time_system(GS, TS)
	_suite_save_manager(GS, SM, GD)
	_suite_time_blocking(GS, TS, GD)
	_suite_gender_and_settings(GS, SM)
	_suite_activity_states(GS, TS, GD)

	# Summary
	print("\n══════════════════════════════════════════════")
	if _fail_count == 0:
		print("  ALL %d TESTS PASSED ✓" % _test_count)
	else:
		print("  %d passed, %d FAILED out of %d tests" % [_pass_count, _fail_count, _test_count])
	print("══════════════════════════════════════════════\n")

	quit(0 if _fail_count == 0 else 1)


# ── Helpers ──────────────────────────────────────────────────────

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

func _suite_game_data(GD: Node) -> void:
	_suite("GameData")

	var cards: Array = GD.get_all_cards_for_day(1)
	_assert_eq(cards.size(), GD.TOTAL_CARDS_PER_DAY, "Day 1 has 16 cards")

	for day in range(1, 8):
		var day_cards: Array = GD.get_all_cards_for_day(day)
		_assert_eq(day_cards.size(), 16, "Day %d has 16 cards" % day)

	for day in range(1, 8):
		var day_cards: Array = GD.get_all_cards_for_day(day)
		var sorted := true
		for i in range(day_cards.size() - 1):
			if day_cards[i].time > day_cards[i + 1].time:
				sorted = false
				break
		_assert(sorted, "Day %d cards are sorted by time" % day)

	_assert_eq(GD.time_to_minutes("04:30"), 270.0, "04:30 = 270 minutes")
	_assert_eq(GD.time_to_minutes("06:00"), 360.0, "06:00 = 360 minutes")
	_assert_eq(GD.time_to_minutes("13:00"), 780.0, "13:00 = 780 minutes")
	_assert_eq(GD.time_to_minutes("22:00"), 1320.0, "22:00 = 1320 minutes")
	_assert_eq(GD.time_to_minutes("00:00"), 0.0, "00:00 = 0 minutes")

	var card: Dictionary = GD.get_card(1, "wk")
	_assert(card.size() > 0, "get_card finds routine card 'wk' for day 1")
	_assert_eq(card.slot_id, "wk", "get_card returns correct slot_id")

	var day_card: Dictionary = GD.get_card(1, "ep")
	_assert(day_card.size() > 0, "get_card finds day-specific card 'ep' for day 1")

	var missing: Dictionary = GD.get_card(1, "nonexistent")
	_assert_eq(missing.size(), 0, "get_card returns empty for nonexistent slot")

	_assert(GD.get_interaction_scene("wk", 1).length() > 0, "wk has interaction scene")
	_assert(GD.get_interaction_scene("ep", 1).length() > 0, "ep day 1 has interaction scene")
	_assert(GD.get_interaction_scene("ep", 2).length() > 0, "ep day 2 has interaction scene")
	_assert(GD.get_interaction_scene("ep", 1) != GD.get_interaction_scene("ep", 2),
		"ep has day-specific interaction scenes")

	_assert(GD.SLOT_TITLES.size() > 0, "SLOT_TITLES populated")
	_assert("wk" in GD.SLOT_TITLES, "SLOT_TITLES contains 'wk'")

	var routine_slot_ids := []
	for card_r in GD.ROUTINE_CARDS:
		routine_slot_ids.append(card_r.slot_id)
	_assert_eq(routine_slot_ids.size(), 11, "11 routine cards defined")

	_assert_eq(GD.DAY_SLOT_IDS.size(), 5, "5 day-specific slot IDs defined")

	_assert_eq(GD.LEVEL_THRESHOLDS.size(), 10, "10 level thresholds defined")
	_assert_eq(GD.LEVEL_THRESHOLDS[0].level, 1, "First level is 1")
	_assert_eq(GD.LEVEL_THRESHOLDS[9].level, 10, "Last level is 10")

	_assert_eq(GD.ACHIEVEMENTS.size(), 8, "8 achievements defined")


# ── GameState Tests ──────────────────────────────────────────────

func _suite_game_state(GS: Node, GD: Node) -> void:
	_suite("GameState")

	GS.reset()
	_assert_eq(GS.current_day, 1, "Reset sets day to 1")
	_assert_eq(GS.energy, 1.0, "Reset sets energy to 1.0")
	_assert_eq(GS.game_started, false, "Reset clears game_started")
	_assert_eq(GS.developer_mode, false, "Reset clears developer_mode")
	_assert_eq(GS.streak_current, 0, "Reset clears streak")
	_assert_eq(GS.water_glasses, 0, "Reset clears water_glasses")
	_assert_eq(GS.achievements_earned.size(), 0, "Reset clears achievements")

	for d in range(1, 8):
		_assert(d in GS.completed_activities, "Day %d in completed_activities" % d)
		_assert_eq(GS.completed_activities[d].size(), 0, "Day %d starts empty" % d)

	GS.start_game()
	_assert_eq(GS.game_started, true, "start_game sets game_started")
	_assert_eq(GS.current_mode, "vertical", "start_game sets vertical mode")

	GS.reset()
	GS.complete_activity(1, "wk")
	_assert(GS.is_activity_completed(1, "wk"), "wk marked as completed")
	_assert(!GS.is_activity_completed(1, "wp"), "wp not completed")
	_assert_eq(GS.get_daily_score(1), 1, "Daily score is 1 after one completion")

	GS.complete_activity(1, "wk")
	_assert_eq(GS.get_daily_score(1), 1, "Duplicate completion ignored")

	GS.complete_activity(1, "wp")
	GS.complete_activity(2, "wk")
	_assert_eq(GS.get_weekly_score(), 3, "Weekly score counts across days")

	GS.reset()
	var initial_energy: float = GS.energy
	GS.miss_activity(1, "wk")
	_assert(GS.energy < initial_energy, "miss_activity drains energy")
	_assert(GS.energy >= 0.0, "Energy stays non-negative")

	GS.reset()
	_assert_eq(GS.current_day, 1, "Starts at day 1")
	var advanced: bool = GS.advance_day()
	_assert(advanced, "advance_day returns true for day 1→2")
	_assert_eq(GS.current_day, 2, "Day advanced to 2")

	GS.current_day = 7
	var end_result: bool = GS.advance_day()
	_assert(!end_result, "advance_day returns false at day 7")
	_assert(GS.game_finished, "game_finished set at end of week")

	GS.reset()
	var xp0: Dictionary = GS.calculate_xp()
	_assert_eq(xp0.total, 0, "Zero XP with no activity")
	_assert_eq(xp0.level, 1, "Level 1 at zero XP")
	_assert_eq(xp0.level_name, "Новичок", "Level name 'Новичок' at start")

	GS.complete_activity(1, "wk")
	var xp1: Dictionary = GS.calculate_xp()
	# Completing 'wk' (04:30) earns: 1 reaction (10) + first_reaction (50) + early_bird (50) = 110
	_assert_eq(xp1.total, GD.XP_PER_REACTION + 2 * GD.XP_PER_ACHIEVEMENT,
		"XP includes reaction + first_reaction + early_bird achievements")

	GS.gender = "male"
	GS.reset()
	_assert_eq(GS.gender, "male", "Gender preserved across reset")
	GS.gender = "female"


# ── TimeSystem Tests ─────────────────────────────────────────────

func _suite_time_system(GS: Node, TS: Node) -> void:
	_suite("TimeSystem")

	GS.reset()
	GS.developer_mode = false

	TS.start_day(1)
	_assert(TS._time_windows.size() > 0, "Time windows computed for day 1")
	_assert_eq(TS._current_day_cards.size(), 16, "16 cards loaded for day 1")

	for card in TS._current_day_cards:
		_assert(card.slot_id in TS._time_windows,
			"Time window exists for slot '%s'" % card.slot_id)

	for slot_id in TS._time_windows:
		var w: Dictionary = TS._time_windows[slot_id]
		_assert(w.has("start"), "Window has 'start' for %s" % slot_id)
		_assert(w.has("end"), "Window has 'end' for %s" % slot_id)
		_assert(w.end > w.start, "Window end > start for %s" % slot_id)
		_assert(w.end - w.start >= TS.MIN_WINDOW_MINUTES,
			"Window >= %d min for %s" % [int(TS.MIN_WINDOW_MINUTES), slot_id])

	var first_window: Dictionary = TS._time_windows.get("wk", {})
	_assert_eq(first_window.start, 270.0, "First activity (wk) window starts at 270 min (04:30)")

	var time_str: String = TS.get_time_string()
	_assert(time_str.length() == 5, "get_time_string returns HH:MM format (len=5)")
	_assert(time_str[2] == ":", "get_time_string has ':' separator")

	var phase: String = TS.get_current_phase()
	_assert(phase in ["night", "dawn", "morning", "day", "afternoon", "evening"],
		"get_current_phase returns valid phase: '%s'" % phase)

	var available: bool = TS.is_activity_available_now("wk")
	_assert(available is bool, "is_activity_available_now returns bool")

	TS.pause()
	_assert(TS.paused, "pause() sets paused=true")
	TS.resume()
	_assert(!TS.paused, "resume() sets paused=false")


# ── SaveManager Tests ────────────────────────────────────────────

func _suite_save_manager(GS: Node, SM: Node, GD: Node) -> void:
	_suite("SaveManager")

	SM.delete_save()
	_assert(!SM.has_save(), "No save file after delete")

	_assert(!SM.load_game(), "load_game returns false when no save exists")

	GS.reset()
	GS.start_game()
	GS.gender = "male"
	GS.developer_mode = true
	GS.current_day = 3
	GS.complete_activity(1, "wk")
	GS.complete_activity(1, "wp")
	GS.streak_current = 2
	GS.streak_best = 2
	GS.water_glasses = 5
	GS.energy = 0.75
	SM.save_game()

	_assert(SM.has_save(), "Save file exists after save_game")

	GS.reset()
	_assert_eq(GS.current_day, 1, "After reset, day is 1")

	var loaded: bool = SM.load_game()
	_assert(loaded, "load_game returns true")
	_assert_eq(GS.current_day, 3, "Loaded day = 3")
	_assert_eq(GS.gender, "male", "Loaded gender = male")
	_assert_eq(GS.developer_mode, true, "Loaded developer_mode = true")
	_assert_eq(GS.game_started, true, "Loaded game_started = true")
	_assert(GS.is_activity_completed(1, "wk"), "Loaded completion: day 1 wk")
	_assert(GS.is_activity_completed(1, "wp"), "Loaded completion: day 1 wp")
	_assert(!GS.is_activity_completed(1, "tp"), "Loaded completion: day 1 tp not completed")
	_assert_eq(GS.streak_current, 2, "Loaded streak_current = 2")
	_assert_eq(GS.streak_best, 2, "Loaded streak_best = 2")
	_assert_eq(GS.water_glasses, 5, "Loaded water_glasses = 5")
	_assert_eq(GS.energy, 0.75, "Loaded energy = 0.75")

	var cfg := ConfigFile.new()
	cfg.load(SM.SAVE_PATH)
	var version: int = cfg.get_value("meta", "version", 0)
	_assert_eq(version, 2, "Save version is 2")

	cfg.set_value("meta", "version", 1)
	cfg.save(SM.SAVE_PATH)
	GS.reset()
	_assert(SM.load_game(), "v1 save loads successfully (compat)")

	cfg.set_value("meta", "version", 0)
	cfg.save(SM.SAVE_PATH)
	GS.reset()
	_assert(!SM.load_game(), "v0 save rejected")

	cfg.set_value("meta", "version", 99)
	cfg.save(SM.SAVE_PATH)
	GS.reset()
	_assert(!SM.load_game(), "v99 save rejected")

	SM.delete_save()
	_assert(!SM.has_save(), "Save deleted successfully")

	GS.gender = "female"
	GS.developer_mode = false


# ── Time-Blocking Tests ─────────────────────────────────────────

func _suite_time_blocking(GS: Node, TS: Node, GD: Node) -> void:
	_suite("Time-Blocking")

	GS.reset()
	GS.developer_mode = false
	TS.start_day(1)

	var now: float = TS.get_real_minutes()

	var past_slot: String = ""
	var current_slot: String = ""
	var future_slot: String = ""

	for card in TS._current_day_cards:
		var w: Dictionary = TS._time_windows.get(card.slot_id, {})
		if w:
			if now >= w.end and past_slot == "":
				past_slot = card.slot_id
			elif now >= w.start and now < w.end and current_slot == "":
				current_slot = card.slot_id
			elif now < w.start and future_slot == "":
				future_slot = card.slot_id

	if past_slot != "":
		var state: String = TS.get_activity_state(past_slot)
		_assert_eq(state, "available_late",
			"Past-window slot '%s' is 'available_late' (not missed)" % past_slot)
		_assert(TS.is_activity_available_now(past_slot),
			"Past-window slot '%s' is available (tappable)" % past_slot)

	if current_slot != "":
		var state: String = TS.get_activity_state(current_slot)
		_assert_eq(state, "current",
			"In-window slot '%s' is 'current'" % current_slot)
		_assert(TS.is_activity_available_now(current_slot),
			"In-window slot '%s' is available (tappable)" % current_slot)

	if future_slot != "":
		var state: String = TS.get_activity_state(future_slot)
		_assert_eq(state, "locked",
			"Future slot '%s' is 'locked'" % future_slot)
		_assert(!TS.is_activity_available_now(future_slot),
			"Future slot '%s' is NOT available" % future_slot)

	if past_slot != "":
		GS.complete_activity(1, past_slot)
		_assert_eq(TS.get_activity_state(past_slot), "completed",
			"Completed activity returns 'completed' regardless of time")

	GS.reset()
	GS.developer_mode = true
	TS.start_day(1)

	if past_slot != "":
		var state: String = TS.get_activity_state(past_slot)
		_assert_eq(state, "current",
			"Dev mode: past slot '%s' is 'current' (not available_late)" % past_slot)

	if future_slot != "":
		var state: String = TS.get_activity_state(future_slot)
		_assert_eq(state, "locked",
			"Dev mode: future slot '%s' still 'locked'" % future_slot)

	var all_states: Array[String] = []
	for card in TS._current_day_cards:
		var s: String = TS.get_activity_state(card.slot_id)
		if s not in all_states:
			all_states.append(s)
	_assert("missed" not in all_states,
		"No 'missed' state in any activity (states: %s)" % str(all_states))

	GS.reset()
	GS.developer_mode = false
	TS.start_day(1)
	var tappable_count := 0
	for card in TS._current_day_cards:
		if TS.is_activity_available_now(card.slot_id):
			tappable_count += 1
	_assert(tappable_count > 0 or now < 270.0,
		"At least one tappable platform (count=%d, time=%.0f min)" % [tappable_count, now])

	GS.developer_mode = false


# ── Gender & Settings Tests ──────────────────────────────────────

func _suite_gender_and_settings(GS: Node, SM: Node) -> void:
	_suite("Gender & Settings")

	GS.reset()
	_assert_eq(GS.gender, "female", "Default gender is female")

	GS.gender = "male"
	GS.reset()
	_assert_eq(GS.gender, "male", "Gender preserved after reset()")

	GS.developer_mode = true
	GS.reset()
	_assert_eq(GS.developer_mode, false, "Developer mode cleared after reset()")

	GS.developer_mode = true
	GS.start_game()
	_assert_eq(GS.developer_mode, false, "Developer mode cleared after start_game()")

	GS.gender = "male"
	SM.save_game()
	GS.gender = "female"
	SM.load_game()
	_assert_eq(GS.gender, "male", "Gender round-trips through save/load")

	GS.developer_mode = true
	SM.save_game()
	GS.developer_mode = false
	SM.load_game()
	_assert_eq(GS.developer_mode, true, "Developer mode round-trips through save/load")

	GS.start_game()
	_assert_eq(GS.current_mode, "vertical", "Mode is always 'vertical'")

	SM.delete_save()
	GS.gender = "female"
	GS.developer_mode = false


# ── Activity State Transitions ───────────────────────────────────

func _suite_activity_states(GS: Node, TS: Node, GD: Node) -> void:
	_suite("Activity State Transitions")

	GS.reset()
	GS.developer_mode = false
	TS.start_day(1)

	var valid_states := ["completed", "current", "available_late", "locked"]
	for card in TS._current_day_cards:
		var state: String = TS.get_activity_state(card.slot_id)
		_assert(state in valid_states,
			"Slot '%s' state '%s' is valid" % [card.slot_id, state])

	var test_slot: String = TS._current_day_cards[0].slot_id
	var state_before: String = TS.get_activity_state(test_slot)
	_assert(state_before != "completed", "Slot '%s' not completed initially" % test_slot)

	GS.complete_activity(1, test_slot)
	var state_after: String = TS.get_activity_state(test_slot)
	_assert_eq(state_after, "completed", "Slot '%s' becomes completed after complete_activity" % test_slot)

	_assert("first_reaction" in GS.achievements_earned,
		"first_reaction achievement earned after first completion")

	GS.reset()
	for card in GD.get_all_cards_for_day(1):
		GS.complete_activity(1, card.slot_id)
	_assert_eq(GS.get_daily_score(1), 16, "Perfect day: all 16 activities completed")
	_assert_eq(GS.get_perfect_days(), 1, "1 perfect day counted")
	_assert("day_complete" in GS.achievements_earned, "day_complete achievement earned")

	GS.reset()
	_assert_eq(GS.energy, 1.0, "Energy starts at 1.0")
	for i in range(16):
		GS.miss_activity(1, "slot_%d" % i)
	_assert_eq(GS.energy, 0.0, "Energy reaches 0 after 16 misses")

	var factor: float = TS.get_time_of_day_factor()
	_assert(factor >= 0.0, "Time of day factor >= 0")
	_assert(factor <= 1.0, "Time of day factor <= 1")

	var next: Dictionary = TS.get_next_activity()
	_assert(next is Dictionary, "get_next_activity returns Dictionary")
	if next.size() > 0:
		_assert("slot_id" in next, "Next activity has slot_id")
		_assert("time" in next, "Next activity has time")

	GS.reset()
