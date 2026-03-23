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
		await process_frame
		quit(1)
		return

	_suite_game_data(GD)
	_suite_game_state(GS, GD)
	_suite_time_system(GS, TS)
	_suite_save_manager(GS, SM, GD)
	_suite_time_blocking(GS, TS, GD)
	_suite_gender_and_settings(GS, SM)
	_suite_activity_states(GS, TS, GD)
	_suite_hopa_data()
	_suite_hopa_save(GS, SM)
	_suite_dialogue_data(GD)
	_suite_dialogue_integrity(GD)
	_suite_dialogue_save(GS, SM)
	_suite_color_utils()
	_suite_touch_utils()
	_suite_xp_cache(GS, GD)

	# Summary
	print("\n══════════════════════════════════════════════")
	if _fail_count == 0:
		print("  ALL %d TESTS PASSED ✓" % _test_count)
	else:
		print("  %d passed, %d FAILED out of %d tests" % [_pass_count, _fail_count, _test_count])
	print("══════════════════════════════════════════════\n")

	# Process frames so all queue_free() calls complete before exit
	await process_frame
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

	_assert_eq(GD.ACHIEVEMENTS.size(), 12, "12 achievements defined")


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
	_assert_eq(version, 6, "Save version is 6")

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


# ── HOPA Data Tests ─────────────────────────────────────────────

func _suite_hopa_data() -> void:
	_suite("HOPA Data")

	_assert_eq(HopaData.LEVEL_ORDER.size(), 7, "7 HOPA levels defined")

	for level_id in HopaData.LEVEL_ORDER:
		_assert(level_id in HopaData.LEVEL_TITLES, "Title exists for '%s'" % level_id)
		_assert(level_id in HopaData.STORY_TEXT, "Story exists for '%s'" % level_id)
		_assert(level_id in HopaData.LEVEL_OBJECTS, "Objects exist for '%s'" % level_id)
		_assert(level_id in HopaData.LEVEL_PUZZLES, "Puzzle exists for '%s'" % level_id)

	_assert_eq(HopaData.get_level_for_day(1), "garden_morning", "Day 1 = garden_morning")
	_assert_eq(HopaData.get_level_for_day(7), "sacred_garden", "Day 7 = sacred_garden")
	_assert_eq(HopaData.get_level_for_day(0), "", "Day 0 = empty")
	_assert_eq(HopaData.get_level_for_day(8), "", "Day 8 = empty")

	_assert_eq(HopaData.get_next_level("garden_morning"), "kitchen_pantry",
		"Next after garden_morning is kitchen_pantry")
	_assert_eq(HopaData.get_next_level("sacred_garden"), "",
		"No next after sacred_garden")

	_assert_eq(HopaData.get_day_number("garden_morning"), 1, "garden_morning is day 1")
	_assert_eq(HopaData.get_day_number("sacred_garden"), 7, "sacred_garden is day 7")
	_assert_eq(HopaData.get_day_number("nonexistent"), 0, "Unknown scene returns 0")

	var objects: Array = HopaData.get_objects("garden_morning")
	_assert(objects.size() >= 5, "garden_morning has 5+ objects")
	for obj in objects:
		_assert("id" in obj, "Object has 'id' field")
		_assert("name" in obj, "Object has 'name' field")
		_assert("is_key_item" in obj, "Object has 'is_key_item' field")

	var puzzle: Dictionary = HopaData.get_puzzle("garden_morning")
	_assert("type" in puzzle, "Puzzle has 'type'")
	_assert(puzzle.type in HopaData.PUZZLE_SCENES, "Puzzle type has scene mapping")

	# Level loader — test JSON file
	var test_data := HopaLevelLoader.load_level("res://tests/test_hopa_level.json")
	_assert(test_data.size() > 0, "Test JSON loads successfully")
	_assert_eq(test_data.get("scene_id", ""), "test_level", "Test JSON scene_id correct")
	_assert_eq(test_data.get("day", 0), 1, "Test JSON day correct")

	var test_objects: Array = test_data.get("objects", [])
	_assert_eq(test_objects.size(), 2, "Test JSON has 2 objects")
	if test_objects.size() >= 2:
		_assert_eq(test_objects[0].get("id", ""), "test_obj_1", "First object id correct")
		var pos: Vector2 = test_objects[0].get("position", Vector2.ZERO)
		_assert_eq(pos, Vector2(540, 960), "Object position parsed correctly")
		_assert_eq(test_objects[1].get("is_key_item", false), true, "Key item flag parsed")

	# Missing file
	var missing := HopaLevelLoader.load_level("res://nonexistent.json")
	_assert_eq(missing.size(), 0, "Missing file returns empty dict")


# ── HOPA Save/Load Tests ────────────────────────────────────────

func _suite_hopa_save(GS: Node, SM: Node) -> void:
	_suite("HOPA Save/Load")

	GS.reset()
	GS.complete_hopa_level("garden_morning", 95.5, 7, 1)
	_assert("garden_morning" in GS.hopa_progress, "HOPA progress recorded")
	_assert_eq(GS.hopa_progress["garden_morning"]["completed"], true, "Level marked completed")
	_assert_eq(GS.hopa_progress["garden_morning"]["hints_used"], 1, "Hints count saved")
	_assert("hopa_first_level" in GS.achievements_earned, "hopa_first_level achievement earned")

	GS.hopa_current_level = "kitchen_pantry"
	GS.hopa_inventory.append("golden_key")
	GS.hopa_inventory.append("scroll")
	SM.save_game()

	GS.reset()
	_assert_eq(GS.hopa_progress.size(), 0, "Reset clears hopa_progress")
	_assert_eq(GS.hopa_inventory.size(), 0, "Reset clears hopa_inventory")

	SM.load_game()
	_assert("garden_morning" in GS.hopa_progress, "HOPA progress loaded")
	_assert_eq(GS.hopa_current_level, "kitchen_pantry", "Current level loaded")
	_assert_eq(GS.hopa_inventory.size(), 2, "Inventory loaded with 2 items")
	_assert("golden_key" in GS.hopa_inventory, "Inventory contains golden_key")

	SM.delete_save()
	GS.reset()


# ── Dialogue Data Tests ─────────────────────────────────────────

func _suite_dialogue_data(GD: Node) -> void:
	_suite("DialogueData")

	# Day 1 has full dialogues for all 16 cards
	var day1_cards: Array = GD.get_all_cards_for_day(1)
	for card in day1_cards:
		var key := "day1_%s" % card.slot_id
		var nodes: Array = DialogueData.get_dialogue(1, card.slot_id)
		_assert(nodes.size() > 0, "Dialogue exists for %s" % key)
		# First node should be a "say" type
		_assert_eq(nodes[0].get("type", ""), "say", "%s starts with say node" % key)

	# Days 2-7 have at least day-specific dialogues
	for day in range(2, 8):
		for slot_id in GD.DAY_SLOT_IDS:
			var nodes: Array = DialogueData.get_dialogue(day, slot_id)
			_assert(nodes.size() > 0, "Dialogue exists for day%d_%s" % [day, slot_id])

	# Fallback works for unknown slots
	var fallback: Array = DialogueData.get_dialogue(1, "nonexistent")
	_assert(fallback.size() > 0, "Fallback dialogue returned for unknown slot")

	# Branching dialogues exist
	var branching_keys := ["day1_wk_detail", "day1_mp_why", "day1_nc_why", "day1_ep_why",
		"day1_lc_energy", "day1_lc_water"]
	for bk in branching_keys:
		_assert(bk in DialogueData.DIALOGUES, "Branch key %s exists" % bk)

	# Choice nodes have valid structure
	for key in DialogueData.DIALOGUES:
		var nodes: Array = DialogueData.DIALOGUES[key]
		for node in nodes:
			if node.get("type", "") == "choice":
				var options: Array = node.get("options", [])
				_assert(options.size() >= 2, "Choice in %s has >= 2 options" % key)
				for opt in options:
					_assert(opt.has("text"), "Option in %s has text" % key)


# ── Dialogue Integrity Tests ──────────────────────────────────────

func _suite_dialogue_integrity(GD: Node) -> void:
	_suite("Dialogue Integrity")

	# Helper methods produce correct node types
	var say_node := DialogueData.say("hello", "hero")
	_assert_eq(say_node.type, "say", "say() produces say type")
	_assert_eq(say_node.speaker, "hero", "say() sets speaker")
	_assert_eq(say_node.text, "hello", "say() sets text")

	var say_player := DialogueData.say("yes", "player")
	_assert_eq(say_player.speaker, "player", "say() accepts player speaker")

	var choice_node := DialogueData.choice("Pick one", [
		DialogueData.opt("A", "branch_a"),
		DialogueData.opt("B"),
	])
	_assert_eq(choice_node.type, "choice", "choice() produces choice type")
	_assert_eq(choice_node.prompt, "Pick one", "choice() sets prompt")
	_assert_eq(choice_node.options.size(), 2, "choice() has 2 options")
	_assert_eq(choice_node.options[0].text, "A", "opt() text set")
	_assert_eq(choice_node.options[0].next, "branch_a", "opt() next set")
	_assert_eq(choice_node.options[1].next, "", "opt() next defaults empty")

	var action_node := DialogueData.action("breathe")
	_assert_eq(action_node.type, "action", "action() produces action type")
	_assert_eq(action_node.action, "breathe", "action() sets action_id")

	# All nodes in DIALOGUES have valid types
	var valid_types := ["say", "choice", "action"]
	for key in DialogueData.DIALOGUES:
		var nodes: Array = DialogueData.DIALOGUES[key]
		for node in nodes:
			var t: String = node.get("type", "")
			_assert(t in valid_types, "Node type '%s' valid in %s" % [t, key])

	# say nodes have non-empty text
	for key in DialogueData.DIALOGUES:
		var nodes: Array = DialogueData.DIALOGUES[key]
		for node in nodes:
			if node.get("type", "") == "say":
				_assert(node.get("text", "").length() > 0, "Say node in %s has text" % key)

	# action nodes have non-empty action id
	for key in DialogueData.DIALOGUES:
		var nodes: Array = DialogueData.DIALOGUES[key]
		for node in nodes:
			if node.get("type", "") == "action":
				_assert(node.get("action", "").length() > 0, "Action in %s has id" % key)

	# Choice "next" keys that are non-empty should reference existing dialogues
	for key in DialogueData.DIALOGUES:
		var nodes: Array = DialogueData.DIALOGUES[key]
		for node in nodes:
			if node.get("type", "") == "choice":
				for o in node.get("options", []):
					var nxt: String = o.get("next", "")
					if nxt.length() > 0:
						_assert(nxt in DialogueData.DIALOGUES, "Choice next '%s' in %s exists" % [nxt, key])

	# Day 1 routine slot IDs all have dialogues (wk, wp, mp, etc.)
	var day1_routine: Array = GD.ROUTINE_SLOT_IDS if "ROUTINE_SLOT_IDS" in GD else []
	for sid in day1_routine:
		_assert("day1_%s" % sid in DialogueData.DIALOGUES, "Day 1 routine slot %s has dialogue" % sid)

	# Days 2-7 day-specific slots have dialogues
	for day in range(2, 8):
		for sid in GD.DAY_SLOT_IDS:
			var k := "day%d_%s" % [day, sid]
			_assert(k in DialogueData.DIALOGUES or DialogueData.get_dialogue(day, sid).size() > 0,
				"Day %d slot %s has dialogue or fallback" % [day, sid])

	# Fallback for totally unknown slot returns non-empty
	var fb := DialogueData.get_dialogue(99, "zzz")
	_assert(fb.size() > 0, "Fallback for unknown day/slot returns nodes")
	_assert_eq(fb[0].get("type", ""), "say", "Fallback starts with say node")

	# Multi-day save round-trip
	var GS := root.get_node("GameState")
	var SM := root.get_node("SaveManager")
	GS.reset()
	GS.dialogue_mode = "rpg_companion"
	GS.dialogue_progress = {1: ["wk", "wp"], 3: ["mp", "nc", "dc"], 7: ["ep"]}
	GS.dialogue_choices = {"day1_wk": "day1_wk_detail", "day3_mp": "day3_mp_why"}
	SM.save_game()
	GS.reset()
	SM.load_game()
	_assert_eq(GS.dialogue_mode, "rpg_companion", "RPG mode persisted")
	_assert(1 in GS.dialogue_progress, "Day 1 progress loaded")
	_assert(3 in GS.dialogue_progress, "Day 3 progress loaded")
	_assert(7 in GS.dialogue_progress, "Day 7 progress loaded")
	_assert_eq(GS.dialogue_progress[3].size(), 3, "Day 3 has 3 slots")
	_assert_eq(GS.dialogue_choices.size(), 2, "2 choices persisted")

	# Empty progress round-trip
	GS.reset()
	GS.dialogue_mode = "visual_novel"
	GS.dialogue_progress = {}
	GS.dialogue_choices = {}
	SM.save_game()
	GS.reset()
	SM.load_game()
	_assert_eq(GS.dialogue_mode, "visual_novel", "VN mode with empty progress")
	_assert_eq(GS.dialogue_progress.size(), 0, "Empty progress stays empty")
	_assert_eq(GS.dialogue_choices.size(), 0, "Empty choices stays empty")

	SM.delete_save()
	GS.reset()


# ── Dialogue Save/Load Tests ────────────────────────────────────

func _suite_dialogue_save(GS: Node, SM: Node) -> void:
	_suite("Dialogue Save/Load")

	GS.reset()
	GS.dialogue_mode = "visual_novel"
	GS.dialogue_progress = {1: ["wk", "wp", "mp"]}
	GS.dialogue_choices = {"day1_wk": "day1_wk_detail"}
	SM.save_game()

	GS.reset()
	_assert_eq(GS.dialogue_mode, "", "Reset clears dialogue_mode")
	_assert_eq(GS.dialogue_progress.size(), 0, "Reset clears dialogue_progress")

	SM.load_game()
	_assert_eq(GS.dialogue_mode, "visual_novel", "dialogue_mode loaded")
	_assert(1 in GS.dialogue_progress, "dialogue_progress day 1 loaded")
	_assert_eq(GS.dialogue_progress[1].size(), 3, "3 slots in dialogue_progress day 1")
	_assert("day1_wk" in GS.dialogue_choices, "dialogue_choices loaded")
	_assert_eq(GS.dialogue_choices["day1_wk"], "day1_wk_detail", "Choice value correct")

	SM.delete_save()
	GS.reset()


# ── ColorUtils Tests ────────────────────────────────────────────

func _suite_color_utils() -> void:
	_suite("ColorUtils")

	# Empty array returns white
	var empty_result: Color = ColorUtils.lerp_color_array([], 0.5)
	_assert_eq(empty_result, Color.WHITE, "Empty array returns WHITE")

	# Single color returns that color
	var single: Color = ColorUtils.lerp_color_array([Color.RED], 0.5)
	_assert_eq(single, Color.RED, "Single color returns that color")

	# Two colors at extremes
	var at_zero: Color = ColorUtils.lerp_color_array([Color.RED, Color.BLUE], 0.0)
	_assert(absf(at_zero.r - 1.0) < 0.01, "t=0 returns first color (red)")

	var at_one: Color = ColorUtils.lerp_color_array([Color.RED, Color.BLUE], 0.99)
	_assert(absf(at_one.b - 0.99) < 0.05, "t=0.99 near last color (blue)")

	# Midpoint
	var mid: Color = ColorUtils.lerp_color_array([Color.RED, Color.BLUE], 0.5)
	_assert(absf(mid.r - 0.5) < 0.05, "t=0.5 red component ~0.5")
	_assert(absf(mid.b - 0.5) < 0.05, "t=0.5 blue component ~0.5")

	# Three colors
	var three_mid: Color = ColorUtils.lerp_color_array(
		[Color.RED, Color.GREEN, Color.BLUE], 0.5)
	_assert(absf(three_mid.g - 1.0) < 0.01, "3 colors t=0.5 = middle color (green)")

	# hex_to_color
	var red_hex: Color = ColorUtils.hex_to_color("#ff0000")
	_assert(absf(red_hex.r - 1.0) < 0.01, "hex #ff0000 red channel = 1")
	_assert(absf(red_hex.g) < 0.01, "hex #ff0000 green channel = 0")


# ── TouchUtils Tests ────────────────────────────────────────────

func _suite_touch_utils() -> void:
	_suite("TouchUtils")

	var tu := TouchUtils.new()

	# TAP: short distance, short time
	tu.on_touch_start(Vector2(100, 100), 0.0)
	var tap_result: int = tu.on_touch_end(Vector2(105, 105), 0.1)
	_assert_eq(tap_result, TouchUtils.GestureType.TAP, "Short touch = TAP")

	# SWIPE_RIGHT
	tu.on_touch_start(Vector2(100, 100), 0.0)
	var swipe_r: int = tu.on_touch_end(Vector2(200, 110), 0.2)
	_assert_eq(swipe_r, TouchUtils.GestureType.SWIPE_RIGHT, "Right swipe detected")

	# SWIPE_LEFT
	tu.on_touch_start(Vector2(200, 100), 0.0)
	var swipe_l: int = tu.on_touch_end(Vector2(50, 105), 0.2)
	_assert_eq(swipe_l, TouchUtils.GestureType.SWIPE_LEFT, "Left swipe detected")

	# SWIPE_DOWN
	tu.on_touch_start(Vector2(100, 100), 0.0)
	var swipe_d: int = tu.on_touch_end(Vector2(110, 250), 0.2)
	_assert_eq(swipe_d, TouchUtils.GestureType.SWIPE_DOWN, "Down swipe detected")

	# SWIPE_UP
	tu.on_touch_start(Vector2(100, 250), 0.0)
	var swipe_u: int = tu.on_touch_end(Vector2(110, 100), 0.2)
	_assert_eq(swipe_u, TouchUtils.GestureType.SWIPE_UP, "Up swipe detected")

	# HOLD: same position, long time
	tu.on_touch_start(Vector2(100, 100), 0.0)
	var hold: int = tu.on_touch_end(Vector2(105, 105), 0.5)
	_assert_eq(hold, TouchUtils.GestureType.HOLD, "Long hold detected")

	# get_hold_duration
	tu.on_touch_start(Vector2(100, 100), 1.0)
	var dur: float = tu.get_hold_duration(2.5)
	_assert(absf(dur - 1.5) < 0.01, "Hold duration = 1.5s")

	# get_swipe_velocity
	tu.on_touch_start(Vector2(0, 0), 0.0)
	var vel: Vector2 = tu.get_swipe_velocity(Vector2(100, 0), 0.5)
	_assert(absf(vel.x - 200.0) < 0.1, "Swipe velocity x = 200 px/s")

	# Constants exist
	_assert_eq(TouchUtils.SWIPE_MIN_DISTANCE, 50.0, "SWIPE_MIN_DISTANCE = 50")
	_assert_eq(TouchUtils.HOLD_MIN_DURATION, 0.3, "HOLD_MIN_DURATION = 0.3")


# ── XP Cache Tests ───────────────────────────────────────────────

func _suite_xp_cache(GS: Node, GD: Node) -> void:
	_suite("XP Cache")

	GS.reset()
	# After reset, cache should be dirty
	var xp0: Dictionary = GS.get_cached_xp()
	_assert_eq(xp0.total, 0, "Cached XP starts at 0")
	_assert_eq(xp0.level, 1, "Cached level starts at 1")

	# Complete activity should invalidate and return updated XP
	GS.complete_activity(1, "wk")
	var xp1: Dictionary = GS.get_cached_xp()
	_assert(xp1.total > 0, "Cached XP > 0 after activity completion")

	# Calling get_cached_xp again should return same result (cached)
	var xp2: Dictionary = GS.get_cached_xp()
	_assert_eq(xp1.total, xp2.total, "Second call returns cached value")

	# calculate_xp and get_cached_xp should agree
	var xp_direct: Dictionary = GS.calculate_xp()
	_assert_eq(xp_direct.total, xp2.total, "Cached matches direct calculation")

	GS.reset()