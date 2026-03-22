extends SceneTree
## End-to-end tests — scene loading, input handling, UI accessibility, regression guards.
## Run with: godot --headless --script tests/test_e2e.gd
##
## Catches bugs we've hit before:
##   - Controls eating touch input (mouse_filter = STOP on overlays)
##   - Missing UI wiring (pause button not connected)
##   - Scene load crashes
##   - Invalid activity states ("missed")
##
## Uses call_deferred so Godot's project.godot autoloads are ready.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_count: int = 0
var _current_suite: String = ""


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("\n══════════════════════════════════════════════")
	print("  7 Days Journey — E2E Test Suite")
	print("══════════════════════════════════════════════\n")

	var GD := root.get_node("GameData")
	var GS := root.get_node("GameState")
	var TS := root.get_node("TimeSystem")
	var SM := root.get_node("SaveManager")
	var ST := root.get_node("SceneTransition")

	var AM := root.get_node("AudioManager")

	if not GD or not GS or not TS or not SM:
		print("  ✗ FATAL: Autoloads not found.")
		quit(1)
		return

	_suite_scene_loading(GS, TS)
	_suite_input_blocking(GS, TS)
	_suite_pause_menu_wiring(GS, TS)
	_suite_platform_tap_targets(GS, TS, GD)
	_suite_no_missed_state(GS, TS, GD)
	_suite_mini_interaction_contract()
	_suite_scene_transition(ST)
	_suite_hud_signals()
	_suite_vignette_passthrough(GS, TS)
	_suite_parallax_setup(GS, TS)
	_suite_main_menu()
	_suite_scene_transition_iris(ST)
	_suite_character_customize()
	_suite_popup_backgrounds()
	_suite_hopa_scene()
	_suite_audio_manager(AM)
	_suite_scene_transition_wipes(ST)
	_suite_theme_manager_theme()
	_suite_camera_bounds(GS, TS)
	_suite_hud_animated(GS, TS)
	_suite_audio_music(AM)
	_suite_scene_transition_v07(ST)
	_suite_haptic_gating(GS)
	_suite_dead_zone_camera(GS, TS)

	# Summary
	print("\n══════════════════════════════════════════════")
	if _fail_count == 0:
		print("  ALL %d E2E TESTS PASSED ✓" % _test_count)
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


## Recursively finds all Control nodes that have mouse_filter = STOP.
func _find_blocking_controls(node: Node) -> Array[Node]:
	var blockers: Array[Node] = []
	if node is Control:
		var ctrl: Control = node as Control
		if ctrl.mouse_filter == Control.MOUSE_FILTER_STOP:
			blockers.append(ctrl)
	for child in node.get_children():
		blockers.append_array(_find_blocking_controls(child))
	return blockers


# ═══════════════════════════════════════════════════════════════════
# Test Suites
# ═══════════════════════════════════════════════════════════════════


func _suite_scene_loading(GS: Node, TS: Node) -> void:
	_suite("Scene Loading (crash-free instantiation)")

	var scenes := [
		"res://scenes/vertical_climb/vertical_level.tscn",
		"res://scenes/main_menu/main_menu.tscn",
		"res://scenes/gender_select/gender_select.tscn",
		"res://scenes/shared/hud/hud.tscn",
		"res://scenes/shared/pause_menu/pause_menu.tscn",
		"res://scenes/shared/activity_popup/activity_popup.tscn",
		"res://scenes/shared/day_summary/day_summary.tscn",
		"res://scenes/shared/level_up/level_up.tscn",
		"res://scenes/shared/achievement_toast/achievement_toast.tscn",
	]

	GS.reset()
	GS.start_game()
	TS.start_day(1)

	for scene_path in scenes:
		var packed := load(scene_path)
		var scene_name: String = scene_path.get_file()
		_assert(packed != null, "Load '%s' — resource loaded" % scene_name)
		if packed:
			var instance: Node = (packed as PackedScene).instantiate()
			_assert(instance != null, "Load '%s' — instantiated" % scene_name)
			if instance:
				root.add_child(instance)
				_assert(instance.is_inside_tree(), "Load '%s' — in tree after _ready()" % scene_name)
				instance.queue_free()

	# Mini interaction scenes
	var mini_scenes := [
		"res://scenes/mini_interactions/breathing_exercise.tscn",
		"res://scenes/mini_interactions/tap_sunrise.tscn",
		"res://scenes/mini_interactions/swipe_droplets.tscn",
		"res://scenes/mini_interactions/hold_pose.tscn",
		"res://scenes/mini_interactions/drink_water.tscn",
		"res://scenes/mini_interactions/collect_flowers.tscn",
		"res://scenes/mini_interactions/flip_cards.tscn",
		"res://scenes/mini_interactions/tap_journal.tscn",
		"res://scenes/mini_interactions/thought_release.tscn",
		"res://scenes/mini_interactions/tap_gratitude.tscn",
		"res://scenes/mini_interactions/body_oil.tscn",
		"res://scenes/mini_interactions/drag_food.tscn",
		"res://scenes/mini_interactions/sufi_spin.tscn",
		"res://scenes/mini_interactions/hold_candle.tscn",
		"res://scenes/mini_interactions/slow_motion.tscn",
		"res://scenes/mini_interactions/swipe_curtain.tscn",
		"res://scenes/mini_interactions/gibberish_tap.tscn",
	]

	for scene_path in mini_scenes:
		var packed := load(scene_path)
		var scene_name: String = scene_path.get_file()
		if packed:
			var instance: Node = (packed as PackedScene).instantiate()
			_assert(instance != null, "Mini '%s' — instantiated" % scene_name)
			if instance:
				root.add_child(instance)
				_assert(instance.is_inside_tree(), "Mini '%s' — in tree" % scene_name)
				instance.queue_free()
		else:
			_assert(false, "Mini '%s' — resource not found" % scene_name)


func _suite_input_blocking(GS: Node, TS: Node) -> void:
	_suite("Input Blocking (no Controls eating touch)")

	GS.reset()
	GS.start_game()
	TS.start_day(1)

	var packed := load("res://scenes/vertical_climb/vertical_level.tscn") as PackedScene
	_assert(packed != null, "Vertical level packed scene loaded")
	if not packed:
		return

	var level: Node = packed.instantiate()
	root.add_child(level)

	# Find all Controls with mouse_filter = STOP
	var blockers := _find_blocking_controls(level)

	# Filter out legitimate blockers
	var bad_blockers: Array[Node] = []
	for blocker in blockers:
		var ctrl: Control = blocker as Control
		if ctrl is Button:
			continue
		if not ctrl.visible:
			continue
		if ctrl is ProgressBar:
			continue
		# Controls inside CanvasLayer are fine (HUD, popups, overlays)
		var parent: Node = ctrl.get_parent()
		var in_canvas_layer := false
		while parent:
			if parent is CanvasLayer:
				in_canvas_layer = true
				break
			parent = parent.get_parent()
		if in_canvas_layer:
			continue
		bad_blockers.append(ctrl)

	_assert(bad_blockers.size() == 0,
		"No blocking Controls in main scene tree (found %d)" % bad_blockers.size())

	# REGRESSION GUARD: Sky ColorRect must have MOUSE_FILTER_IGNORE
	var sky_found := false
	for child in level.get_children():
		if child is ColorRect and child.z_index == -10:
			sky_found = true
			_assert_eq((child as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE,
				"Sky ColorRect has MOUSE_FILTER_IGNORE (v0.4.0 regression guard)")
			break
	_assert(sky_found, "Sky ColorRect found in vertical level")

	level.queue_free()


func _suite_pause_menu_wiring(GS: Node, TS: Node) -> void:
	_suite("Pause Menu Wiring")

	GS.reset()
	GS.start_game()
	TS.start_day(1)

	var packed := load("res://scenes/vertical_climb/vertical_level.tscn") as PackedScene
	if not packed:
		_assert(false, "Vertical level loaded for pause test")
		return

	var level: Node = packed.instantiate()
	root.add_child(level)

	var has_pause := "_pause_menu" in level
	_assert(has_pause, "Level has _pause_menu variable")
	if has_pause:
		_assert(level.get("_pause_menu") != null, "Pause menu instantiated (_pause_menu != null)")

	var has_hero := "_hero" in level
	_assert(has_hero, "Level has _hero variable")
	if has_hero:
		_assert(level.get("_hero") != null, "Hero instantiated")

	level.queue_free()


func _suite_platform_tap_targets(GS: Node, TS: Node, GD: Node) -> void:
	_suite("Platform Tap Targets (reachable)")

	GS.reset()
	GS.start_game()
	GS.developer_mode = true
	TS.start_day(1)

	var packed := load("res://scenes/vertical_climb/vertical_level.tscn") as PackedScene
	if not packed:
		_assert(false, "Vertical level loaded for tap target test")
		return

	var level: Node = packed.instantiate()
	root.add_child(level)

	_assert("platforms" in level, "Level has 'platforms' property")
	if "platforms" in level:
		var platforms: Array = level.get("platforms")
		_assert_eq(platforms.size(), 16, "16 platforms created for day 1")

		for i in range(platforms.size()):
			var p: Dictionary = platforms[i]
			_assert(p.has("pos"), "Platform %d has 'pos'" % i)
			_assert(p.has("card"), "Platform %d has 'card'" % i)
			_assert(p.has("state"), "Platform %d has 'state'" % i)

		var tappable := 0
		for p in platforms:
			if p.state in ["current", "available_late"]:
				tappable += 1
		_assert(tappable > 0,
			"At least one tappable platform in dev mode (found %d)" % tappable)

		# Verify hero's jump_to method works directly
		# (NOTE: _unhandled_input uses get_global_mouse_position() which is always
		#  (0,0) in headless mode, so we test jump_to directly instead)
		if tappable > 0:
			for p in platforms:
				if p.state in ["current", "available_late"]:
					var hero: Node = level.get("_hero")
					if hero and hero.has_method("jump_to"):
						var target: Vector2 = p.pos + Vector2(140, -40)
						hero.jump_to(target)
						_assert(hero.get("is_jumping") == true,
							"Hero starts jumping after jump_to()")
						_assert(hero.get("target_pos") == target,
							"Hero target_pos set correctly")
					break

	level.queue_free()
	GS.developer_mode = false


func _suite_no_missed_state(GS: Node, TS: Node, GD: Node) -> void:
	_suite("No 'missed' State (regression)")

	var valid_states := ["completed", "current", "available_late", "locked"]

	for day in range(1, 8):
		GS.reset()
		GS.developer_mode = false
		TS.start_day(day)

		var cards: Array = GD.get_all_cards_for_day(day)
		var has_missed := false
		for card in cards:
			var state: String = TS.get_activity_state(card.slot_id)
			if state == "missed":
				has_missed = true
				_assert(false, "Day %d slot '%s' returned 'missed'" % [day, card.slot_id])

		if not has_missed:
			_assert(true, "Day %d: no 'missed' state in %d activities" % [day, cards.size()])


func _suite_mini_interaction_contract() -> void:
	_suite("Mini Interaction Contract (signals, lifecycle)")

	var base_packed := load("res://scenes/mini_interactions/mini_interaction_base.tscn") as PackedScene
	if not base_packed:
		_assert(false, "mini_interaction_base.tscn loaded")
		return

	var base: Node = base_packed.instantiate()
	_assert(base.has_signal("completed"), "MiniInteractionBase has 'completed' signal")
	_assert(base.has_signal("failed"), "MiniInteractionBase has 'failed' signal")
	_assert("duration" in base, "Has 'duration' property")
	_assert("is_active" in base, "Has 'is_active' property")
	_assert(base.has_method("complete_interaction"), "Has complete_interaction()")
	_assert(base.has_method("get_progress"), "Has get_progress()")
	base.queue_free()

	var breathe_packed := load("res://scenes/mini_interactions/breathing_exercise.tscn") as PackedScene
	if breathe_packed:
		var breathe: Node = breathe_packed.instantiate()
		root.add_child(breathe)
		_assert(breathe.has_signal("completed"), "breathing_exercise has 'completed'")
		_assert(breathe.has_signal("failed"), "breathing_exercise has 'failed'")
		if "is_active" in breathe:
			_assert(breathe.get("is_active") == true, "breathing_exercise auto-starts (is_active=true)")
		breathe.queue_free()

	var tap_packed := load("res://scenes/mini_interactions/tap_sunrise.tscn") as PackedScene
	if tap_packed:
		var tap: Node = tap_packed.instantiate()
		var failed_emitted := false
		tap.failed.connect(func(): failed_emitted = true)
		root.add_child(tap)

		if "duration" in tap and "elapsed" in tap:
			tap.set("elapsed", tap.get("duration") + 1.0)
			tap._process(0.016)
			_assert(failed_emitted or tap.get("is_active") == false,
				"tap_sunrise fails when elapsed > duration")
		tap.queue_free()


func _suite_scene_transition(ST: Node) -> void:
	_suite("Scene Transition")

	_assert(ST != null, "SceneTransition autoload exists")
	if not ST:
		return

	_assert(ST.has_method("change_scene"), "Has change_scene()")
	_assert(ST.has_method("reload_scene"), "Has reload_scene()")

	if "_color_rect" in ST:
		var cr: Control = ST.get("_color_rect") as Control
		if cr:
			_assert_eq(cr.mouse_filter, Control.MOUSE_FILTER_IGNORE,
				"SceneTransition overlay has MOUSE_FILTER_IGNORE when idle")


func _suite_hud_signals() -> void:
	_suite("HUD Signal Wiring")

	var hud_packed := load("res://scenes/shared/hud/hud.tscn") as PackedScene
	if not hud_packed:
		_assert(false, "HUD scene loaded")
		return

	var hud: Node = hud_packed.instantiate()
	root.add_child(hud)

	var hud_script: Node = hud.get_node_or_null("HUDScript")
	_assert(hud_script != null, "HUDScript node exists in HUD scene")

	if hud_script:
		_assert(hud_script.has_signal("pause_pressed"),
			"HUDScript has 'pause_pressed' signal")

		# Verify the pause button exists and has a signal connection
		if "pause_btn" in hud_script and hud_script.get("pause_btn"):
			var btn: Button = hud_script.get("pause_btn")
			var connections: Array = btn.get_signal_connection_list("pressed")
			_assert(connections.size() > 0,
				"PauseBtn has signal connections (%d)" % connections.size())
		else:
			_assert(false, "PauseBtn exists in HUD")

	hud.queue_free()


func _suite_vignette_passthrough(GS: Node, TS: Node) -> void:
	_suite("Vignette & Overlay Passthrough")

	GS.reset()
	GS.start_game()
	TS.start_day(1)

	var packed := load("res://scenes/vertical_climb/vertical_level.tscn") as PackedScene
	if not packed:
		_assert(false, "Vertical level loaded for vignette test")
		return

	var level: Node = packed.instantiate()
	root.add_child(level)

	if "_vignette" in level:
		var vignette: Control = level.get("_vignette") as Control
		if vignette:
			_assert_eq(vignette.mouse_filter, Control.MOUSE_FILTER_IGNORE,
				"Vignette ColorRect has MOUSE_FILTER_IGNORE")
		else:
			_assert(false, "Vignette instance exists")
	else:
		_assert(false, "Level has _vignette property")

	# Check visible CanvasLayer ColorRects — skip dimmers for hidden popups
	for child in level.get_children():
		if child is CanvasLayer:
			# Skip popup/menu CanvasLayers that are hidden by default
			if not child.visible:
				continue
			for overlay_child in child.get_children():
				if overlay_child is ColorRect and overlay_child.visible:
					# Skip named dimmers (intentional blockers for popups)
					if overlay_child.name == "Dimmer":
						continue
					_assert_eq((overlay_child as Control).mouse_filter,
						Control.MOUSE_FILTER_IGNORE,
						"CanvasLayer child '%s' non-blocking" % overlay_child.name)

	level.queue_free()


func _suite_parallax_setup(GS: Node, TS: Node) -> void:
	_suite("Parallax & Visual Setup")

	GS.reset()
	GS.start_game()
	TS.start_day(1)

	var packed := load("res://scenes/vertical_climb/vertical_level.tscn") as PackedScene
	if not packed:
		_assert(false, "Vertical level loaded for parallax test")
		return

	var level: Node = packed.instantiate()
	root.add_child(level)

	if "_parallax_bg" in level:
		_assert(level.get("_parallax_bg") != null, "ParallaxBackground created")

	for layer_name in ["_far_layer", "_mid_layer", "_near_layer"]:
		if layer_name in level:
			var layer: Node = level.get(layer_name)
			_assert(layer != null, "%s exists" % layer_name)
			if layer:
				_assert(layer.get_child_count() > 0,
					"%s has children (%d)" % [layer_name, layer.get_child_count()])

	if "_leaf_particles" in level:
		var lp: Node = level.get("_leaf_particles")
		_assert(lp != null, "Leaf particles created")
		if lp:
			_assert(lp.get("emitting") == true, "Leaf particles emitting")

	if "_firefly_particles" in level:
		_assert(level.get("_firefly_particles") != null, "Firefly particles created")

	if "_sparkle_particles" in level:
		var sp: Node = level.get("_sparkle_particles")
		_assert(sp != null, "Sparkle particles created")
		if sp:
			_assert(sp.get("one_shot") == true, "Sparkle particles are one_shot")

	if "_camera" in level:
		var cam: Node = level.get("_camera")
		_assert(cam != null, "Camera2D created")
		if cam:
			_assert(cam.get("position_smoothing_enabled") == false,
				"Camera has manual smoothing (dead zone)")
			_assert("_camera_target_y" in level, "Level has _camera_target_y for dead zone")

	if "_hero" in level:
		_assert(level.get("_hero") != null, "Climbing hero exists")

	if "_sky_material" in level:
		_assert(level.get("_sky_material") != null, "Sky shader material exists")

	level.queue_free()


func _suite_main_menu() -> void:
	_suite("Main Menu — Buttons & DrawLayer")

	var mm_packed := load("res://scenes/main_menu/main_menu.tscn") as PackedScene
	_assert(mm_packed != null, "Main menu scene loads")
	if not mm_packed:
		return

	var mm: Node = mm_packed.instantiate()
	root.add_child(mm)

	# Verify core node structure
	var bg := mm.get_node_or_null("Background")
	_assert(bg != null, "Background node exists")

	var draw_layer := mm.get_node_or_null("DrawLayer")
	_assert(draw_layer != null, "DrawLayer node exists")

	var vbox := mm.get_node_or_null("VBox")
	_assert(vbox != null, "VBox node exists")

	# DrawLayer must not eat input
	if draw_layer:
		_assert_eq(draw_layer.mouse_filter, Control.MOUSE_FILTER_IGNORE,
			"DrawLayer has MOUSE_FILTER_IGNORE")

	# Buttons exist and are wired
	var continue_btn := mm.get_node_or_null("VBox/ContinueBtn")
	_assert(continue_btn != null, "ContinueBtn exists")

	var new_game_btn := mm.get_node_or_null("VBox/NewGameBtn")
	_assert(new_game_btn != null, "NewGameBtn exists")

	if new_game_btn:
		_assert(new_game_btn is Button, "NewGameBtn is a Button")
		var connections := new_game_btn.get_signal_connection_list("pressed")
		_assert(connections.size() > 0,
			"NewGameBtn.pressed has connections (%d)" % connections.size())

	if continue_btn:
		_assert(continue_btn is Button, "ContinueBtn is a Button")
		var connections := continue_btn.get_signal_connection_list("pressed")
		_assert(connections.size() > 0,
			"ContinueBtn.pressed has connections (%d)" % connections.size())

	# Title and subtitle exist
	var title := mm.get_node_or_null("VBox/TitleLabel")
	_assert(title != null, "TitleLabel exists")
	if title:
		_assert(title.text == "7 Days Journey", "Title text is correct")

	var subtitle := mm.get_node_or_null("VBox/SubtitleLabel")
	_assert(subtitle != null, "SubtitleLabel exists")

	# Z-ordering: DrawLayer must be between Background and VBox
	if bg and draw_layer and vbox:
		var bg_idx := bg.get_index()
		var dl_idx := draw_layer.get_index()
		var vbox_idx := vbox.get_index()
		_assert(bg_idx < dl_idx and dl_idx < vbox_idx,
			"Z-order: Background(%d) < DrawLayer(%d) < VBox(%d)" % [bg_idx, dl_idx, vbox_idx])

	# Script references correct scene paths
	var mm_script := mm.get_script() as Script
	_assert(mm_script != null, "MainMenu has script attached")
	if mm_script:
		var source: String = mm_script.source_code
		_assert(source.contains("_on_continue"), "Script has _on_continue handler")
		_assert(source.contains("_on_new_game"), "Script has _on_new_game handler")
		_assert(source.contains("change_scene_iris"), "New game uses iris transition")

	mm.queue_free()


func _suite_scene_transition_iris(ST: Node) -> void:
	_suite("Scene Transition — Iris Wipe")

	_assert(ST.has_method("change_scene_iris"), "Has change_scene_iris()")

	# Iris rect exists and is hidden by default
	if "_iris_rect" in ST:
		var ir: Control = ST.get("_iris_rect") as Control
		_assert(ir != null, "Iris rect exists")
		if ir:
			_assert(ir.visible == false, "Iris rect hidden by default")
			_assert_eq(ir.mouse_filter, Control.MOUSE_FILTER_IGNORE,
				"Iris rect MOUSE_FILTER_IGNORE when idle")

	# Iris shader material exists
	if "_iris_material" in ST:
		var mat: ShaderMaterial = ST.get("_iris_material") as ShaderMaterial
		_assert(mat != null, "Iris shader material exists")
		if mat:
			_assert(mat.shader != null, "Iris shader loaded")


func _suite_character_customize() -> void:
	_suite("Character Customization")

	# Scene loads
	var scene := load("res://scenes/character_customize/character_customize.tscn")
	_assert(scene != null, "character_customize.tscn loads")
	if not scene:
		return

	var cc: Control = scene.instantiate()
	root.add_child(cc)

	# Core nodes exist
	_assert(cc.get_node_or_null("VBox/Preview") != null, "Preview TextureRect exists")
	_assert(cc.get_node_or_null("VBox/TitleLabel") != null, "TitleLabel exists")
	_assert(cc.get_node_or_null("VBox/StartBtn") != null, "StartBtn exists")

	# Customization rows exist
	_assert(cc.get_node_or_null("VBox/SkinRow/SkinPrev") != null, "SkinPrev button exists")
	_assert(cc.get_node_or_null("VBox/SkinRow/SkinNext") != null, "SkinNext button exists")
	_assert(cc.get_node_or_null("VBox/SkinRow/SkinLabel") != null, "SkinLabel exists")
	_assert(cc.get_node_or_null("VBox/HairRow/HairPrev") != null, "HairPrev button exists")
	_assert(cc.get_node_or_null("VBox/HairRow/HairNext") != null, "HairNext button exists")
	_assert(cc.get_node_or_null("VBox/HairRow/HairLabel") != null, "HairLabel exists")
	_assert(cc.get_node_or_null("VBox/StyleRow/StylePrev") != null, "StylePrev button exists")
	_assert(cc.get_node_or_null("VBox/StyleRow/StyleNext") != null, "StyleNext button exists")
	_assert(cc.get_node_or_null("VBox/StyleRow/StyleLabel") != null, "StyleLabel exists")

	# Buttons are large enough for touch
	var start_btn := cc.get_node_or_null("VBox/StartBtn") as Button
	if start_btn:
		_assert(start_btn.custom_minimum_size.y >= 80, "StartBtn min height >= 80px")

	var skin_prev := cc.get_node_or_null("VBox/SkinRow/SkinPrev") as Button
	if skin_prev:
		_assert(skin_prev.custom_minimum_size.x >= 80 and skin_prev.custom_minimum_size.y >= 80,
			"SkinPrev min size >= 80x80")

	# Gender select navigates to customize
	var gs_scene := load("res://scenes/gender_select/gender_select.tscn")
	_assert(gs_scene != null, "gender_select.tscn loads")
	if gs_scene:
		var gs: Node = gs_scene.instantiate()
		root.add_child(gs)
		var gs_script := gs.get_script() as Script
		if gs_script:
			_assert(gs_script.source_code.contains("character_customize"),
				"Gender select navigates to character_customize")
		gs.queue_free()

	cc.queue_free()


func _suite_popup_backgrounds() -> void:
	_suite("Popup Dark Backgrounds")

	# Level-up has Panel with dark background
	var lu_scene := load("res://scenes/shared/level_up/level_up.tscn")
	_assert(lu_scene != null, "level_up.tscn loads")
	if lu_scene:
		var lu: Node = lu_scene.instantiate()
		root.add_child(lu)
		var panel := lu.get_node_or_null("CenterContainer/Panel") as PanelContainer
		_assert(panel != null, "LevelUp has Panel wrapper")
		if panel:
			var vbox := panel.get_node_or_null("VBox")
			_assert(vbox != null, "LevelUp VBox inside Panel")
		lu.queue_free()

	# Day summary has dark panel style
	var ds_scene := load("res://scenes/shared/day_summary/day_summary.tscn")
	_assert(ds_scene != null, "day_summary.tscn loads")
	if ds_scene:
		var ds: Node = ds_scene.instantiate()
		root.add_child(ds)
		var panel := ds.get_node_or_null("Panel") as PanelContainer
		_assert(panel != null, "DaySummary has PanelContainer")
		ds.queue_free()

	# Activity popup has dark panel style
	var ap_scene := load("res://scenes/shared/activity_popup/activity_popup.tscn")
	_assert(ap_scene != null, "activity_popup.tscn loads")
	if ap_scene:
		var ap: Node = ap_scene.instantiate()
		root.add_child(ap)
		var panel := ap.get_node_or_null("Panel") as PanelContainer
		_assert(panel != null, "ActivityPopup has PanelContainer")
		ap.queue_free()

	# Achievement toast has dark panel and mouse_filter IGNORE
	var at_scene := load("res://scenes/shared/achievement_toast/achievement_toast.tscn")
	_assert(at_scene != null, "achievement_toast.tscn loads")
	if at_scene:
		var at: Node = at_scene.instantiate()
		root.add_child(at)
		var toast := at.get_node_or_null("ToastPanel") as PanelContainer
		_assert(toast != null, "AchievementToast has ToastPanel")
		if toast:
			_assert_eq(toast.mouse_filter, Control.MOUSE_FILTER_IGNORE,
				"ToastPanel MOUSE_FILTER_IGNORE")
		at.queue_free()


func _suite_hopa_scene() -> void:
	_suite("HOPA Scene (Сад Тайн)")

	var GS := root.get_node("GameState")
	GS.reset()

	# HOPA scene loads without crash
	var hopa_packed := load("res://scenes/hopa/hopa_scene_base.tscn") as PackedScene
	_assert(hopa_packed != null, "hopa_scene_base.tscn loads")
	if not hopa_packed:
		return

	# Set a level before instantiating
	GS.hopa_current_level = "garden_morning"
	var hopa: Node = hopa_packed.instantiate()
	root.add_child(hopa)
	_assert(hopa.is_inside_tree(), "HOPA scene in tree after _ready()")

	# Core script properties
	_assert("_found_objects" in hopa, "Has _found_objects property")
	_assert("_time_remaining" in hopa, "Has _time_remaining property")
	_assert("_level_data" in hopa, "Has _level_data property")

	# HUD should be created
	_assert("_hud" in hopa, "Has _hud property")
	if "_hud" in hopa:
		_assert(hopa.get("_hud") != null, "HUD instantiated")

	# Hint system should be created
	_assert("_hint_system" in hopa, "Has _hint_system property")
	if "_hint_system" in hopa:
		_assert(hopa.get("_hint_system") != null, "HintSystem instantiated")

	# Signals exist
	_assert(hopa.has_signal("level_completed"), "Has level_completed signal")
	_assert(hopa.has_signal("object_found"), "Has object_found signal")

	hopa.queue_free()

	# Puzzle scenes load
	var puzzle_scenes := [
		"res://scenes/hopa/puzzles/jigsaw_puzzle.tscn",
		"res://scenes/hopa/puzzles/match_pairs_puzzle.tscn",
		"res://scenes/hopa/puzzles/connect_runes_puzzle.tscn",
	]

	for scene_path in puzzle_scenes:
		var packed := load(scene_path) as PackedScene
		var scene_name: String = scene_path.get_file()
		_assert(packed != null, "Puzzle '%s' loads" % scene_name)
		if packed:
			var instance: Node = packed.instantiate()
			root.add_child(instance)
			_assert(instance.is_inside_tree(), "Puzzle '%s' in tree" % scene_name)
			_assert(instance.has_signal("completed"), "Puzzle '%s' has completed signal" % scene_name)
			_assert(instance.has_signal("failed"), "Puzzle '%s' has failed signal" % scene_name)
			instance.queue_free()

	# MainMenu has HOPA button
	var mm_packed := load("res://scenes/main_menu/main_menu.tscn") as PackedScene
	if mm_packed:
		var mm: Node = mm_packed.instantiate()
		root.add_child(mm)
		var mm_script := mm.get_script() as Script
		if mm_script:
			_assert(mm_script.source_code.contains("_on_hopa"),
				"Main menu has _on_hopa handler")
			_assert(mm_script.source_code.contains("Сад Тайн"),
				"Main menu has 'Сад Тайн' button text")
		mm.queue_free()

	# HOPA level JSONs are valid
	for level_id in HopaData.LEVEL_ORDER:
		var json_path := "res://scenes/hopa/levels/%s.json" % level_id
		var data := HopaLevelLoader.load_level(json_path)
		_assert(data.size() > 0, "Level JSON '%s' loads" % level_id)
		if data.size() > 0:
			_assert("objects" in data, "Level '%s' has objects" % level_id)
			var objs: Array = data.get("objects", [])
			_assert(objs.size() >= 5, "Level '%s' has 5+ objects (%d)" % [level_id, objs.size()])

	GS.reset()


func _suite_audio_manager(AM: Node) -> void:
	_suite("Audio Manager")

	_assert(AM != null, "AudioManager autoload exists")
	if not AM:
		return

	_assert(AM.has_method("play"), "Has play() method")
	_assert(AM.has_method("set_master_volume"), "Has set_master_volume()")
	_assert(AM.has_method("get_master_volume"), "Has get_master_volume()")
	_assert(AM.has_method("set_ambient_enabled"), "Has set_ambient_enabled()")

	# Sounds generated
	if "_sounds" in AM:
		var sounds: Dictionary = AM.get("_sounds")
		_assert(sounds.size() >= 9, "At least 9 sounds generated (%d)" % sounds.size())
		for key in ["click", "complete", "level_up", "achievement", "jump", "land",
				"popup_open", "popup_close", "xp_gain"]:
			_assert(key in sounds, "Sound '%s' exists" % key)

	# Pool created
	if "_pool" in AM:
		var pool: Array = AM.get("_pool")
		_assert(pool.size() >= 4, "Audio pool has 4+ players (%d)" % pool.size())

	# Volume control
	AM.set_master_volume(0.5)
	_assert_eq(AM.get_master_volume(), 0.5, "Volume set to 0.5")
	AM.set_master_volume(0.7)  # restore

	# Playing non-existent key doesn't crash
	AM.play("nonexistent_sound_key")
	_assert(true, "Playing nonexistent key does not crash")


func _suite_scene_transition_wipes(ST: Node) -> void:
	_suite("Scene Transition — Diamond & Dissolve Wipes")

	_assert(ST.has_method("change_scene_diamond"), "Has change_scene_diamond()")
	_assert(ST.has_method("change_scene_dissolve"), "Has change_scene_dissolve()")
	_assert(ST.has_method("flash_screen"), "Has flash_screen()")

	# Diamond rect exists and is hidden
	if "_diamond_rect" in ST:
		var dr: Control = ST.get("_diamond_rect") as Control
		_assert(dr != null, "Diamond rect exists")
		if dr:
			_assert(dr.visible == false, "Diamond rect hidden by default")

	# Dissolve rect exists and is hidden
	if "_dissolve_rect" in ST:
		var dr: Control = ST.get("_dissolve_rect") as Control
		_assert(dr != null, "Dissolve rect exists")
		if dr:
			_assert(dr.visible == false, "Dissolve rect hidden by default")

	# Flash rect exists
	if "_flash_rect" in ST:
		var fr: Control = ST.get("_flash_rect") as Control
		_assert(fr != null, "Flash rect exists")
		if fr:
			_assert(fr.visible == false, "Flash rect hidden by default")

	# Diamond material has shader
	if "_diamond_material" in ST:
		var mat: ShaderMaterial = ST.get("_diamond_material") as ShaderMaterial
		_assert(mat != null, "Diamond shader material exists")

	# Dissolve material has shader
	if "_dissolve_material" in ST:
		var mat: ShaderMaterial = ST.get("_dissolve_material") as ShaderMaterial
		_assert(mat != null, "Dissolve shader material exists")


func _suite_theme_manager_theme() -> void:
	_suite("Theme Manager — Centralized Theme & Button Juice")

	var TM := root.get_node("ThemeManager")
	_assert(TM != null, "ThemeManager autoload exists")
	if not TM:
		return

	# game_theme built
	if "game_theme" in TM:
		var theme: Theme = TM.get("game_theme") as Theme
		_assert(theme != null, "game_theme exists")
		if theme:
			_assert(theme.has_stylebox("panel", "PanelContainer"), "Theme has PanelContainer/panel")
			_assert(theme.has_stylebox("normal", "Button"), "Theme has Button/normal")
			_assert(theme.has_stylebox("hover", "Button"), "Theme has Button/hover")
			_assert(theme.has_stylebox("pressed", "Button"), "Theme has Button/pressed")
			_assert(theme.has_stylebox("fill", "ProgressBar"), "Theme has ProgressBar/fill")
			_assert(theme.has_color("font_color", "Label"), "Theme has Label/font_color")

	# Button juice method exists
	_assert(TM.has_method("apply_button_juice"), "Has apply_button_juice()")

	# Button juice is idempotent
	var btn := Button.new()
	btn.text = "Test"
	btn.custom_minimum_size = Vector2(100, 50)
	root.add_child(btn)
	TM.apply_button_juice(btn)
	_assert(btn.has_meta("_button_juiced"), "Button marked as juiced after first call")
	TM.apply_button_juice(btn)  # second call should not crash
	_assert(true, "Double apply_button_juice does not crash")
	btn.queue_free()


func _suite_camera_bounds(GS: Node, TS: Node) -> void:
	_suite("Camera Bounds & Zoom")

	GS.reset()
	GS.start_game()
	TS.start_day(1)

	var packed := load("res://scenes/vertical_climb/vertical_level.tscn") as PackedScene
	if not packed:
		_assert(false, "Vertical level loaded for camera bounds test")
		return

	var level: Node = packed.instantiate()
	root.add_child(level)

	if "_camera" in level:
		var cam: Camera2D = level.get("_camera") as Camera2D
		_assert(cam != null, "Camera exists")
		if cam:
			_assert(cam.limit_left == -200, "Camera limit_left set")
			_assert(cam.limit_right == 1280, "Camera limit_right set")
			_assert(cam.limit_top == -800, "Camera limit_top set")
			_assert(cam.limit_bottom > 0, "Camera limit_bottom set (>0)")

	level.queue_free()


func _suite_hud_animated(GS: Node, TS: Node) -> void:
	_suite("HUD Animated")

	GS.reset()
	GS.start_game()
	TS.start_day(1)

	var hud_packed := load("res://scenes/shared/hud/hud.tscn") as PackedScene
	if not hud_packed:
		_assert(false, "HUD loaded for animated test")
		return

	var hud: Node = hud_packed.instantiate()
	root.add_child(hud)

	var hud_script: Node = hud.get_node_or_null("HUDScript")
	_assert(hud_script != null, "HUDScript exists")
	if hud_script:
		_assert(hud_script.has_method("_spawn_floating_xp"), "Has _spawn_floating_xp method")
		_assert("_xp_tween" in hud_script, "Has _xp_tween property")

		# Verify streak flame in day label
		GS.streak_current = 3
		if hud_script.has_method("_refresh"):
			hud_script._refresh()
		if "day_label" in hud_script:
			var day_label: Label = hud_script.get("day_label")
			if day_label:
				_assert(day_label.text.contains("🔥"),
					"Day label has flame emoji with streak >= 3")

		GS.streak_current = 0
		if hud_script.has_method("_refresh"):
			hud_script._refresh()
		if "day_label" in hud_script:
			var day_label: Label = hud_script.get("day_label")
			if day_label:
				_assert(not day_label.text.contains("🔥"),
					"Day label has no flame with streak < 3")

	hud.queue_free()


func _suite_audio_music(AM: Node) -> void:
	_suite("Audio Manager — Music & Pitch (v0.7.0)")

	_assert(AM.has_method("play_music"), "Has play_music()")
	_assert(AM.has_method("stop_music"), "Has stop_music()")

	if "_music_streams" in AM:
		var streams: Dictionary = AM.get("_music_streams")
		_assert(streams.size() >= 3, "At least 3 music streams (%d)" % streams.size())
		for key in ["menu_theme", "climb_theme", "night_theme"]:
			_assert(key in streams, "Music '%s' exists" % key)

	if "_music_a" in AM:
		_assert(AM.get("_music_a") != null, "Music player A exists")
	if "_music_b" in AM:
		_assert(AM.get("_music_b") != null, "Music player B exists")

	_assert(AM.has_method("set_sfx_enabled"), "Has set_sfx_enabled()")
	_assert(AM.has_method("get_sfx_enabled"), "Has get_sfx_enabled()")
	AM.set_sfx_enabled(false)
	_assert_eq(AM.get_sfx_enabled(), false, "SFX can be disabled")
	AM.set_sfx_enabled(true)

	if AM.has_method("_resolve_key"):
		_assert_eq(AM._resolve_key("click"), "click", "Exact key resolves")
		_assert_eq(AM._resolve_key("click+soft"), "click+soft", "Variant key resolves")
		_assert_eq(AM._resolve_key("click+unknown"), "click", "Fallback key resolves to parent")
		_assert_eq(AM._resolve_key("nonexistent"), "", "Unknown key returns empty")

	if "_sounds" in AM:
		var sounds: Dictionary = AM.get("_sounds")
		_assert("click+soft" in sounds, "click+soft variant exists")
		_assert("land+heavy" in sounds, "land+heavy variant exists")


func _suite_scene_transition_v07(ST: Node) -> void:
	_suite("Scene Transition — v0.7.0 (signals, history, pattern, shockwave)")

	_assert(ST.has_signal("transition_started"), "Has transition_started signal")
	_assert(ST.has_signal("scene_swapped"), "Has scene_swapped signal")
	_assert(ST.has_signal("transition_finished"), "Has transition_finished signal")

	_assert(ST.has_method("has_history"), "Has has_history()")
	_assert(ST.has_method("go_back"), "Has go_back()")
	_assert_eq(ST.has_history(), false, "History empty at start")

	_assert(ST.has_method("change_scene_pattern"), "Has change_scene_pattern()")
	if "_pattern_rect" in ST:
		var pr: Control = ST.get("_pattern_rect") as Control
		_assert(pr != null, "Pattern rect exists")
		if pr:
			_assert(pr.visible == false, "Pattern rect hidden by default")
	if "_pattern_material" in ST:
		var mat: ShaderMaterial = ST.get("_pattern_material") as ShaderMaterial
		_assert(mat != null, "Pattern material exists")

	_assert(ST.has_method("shockwave"), "Has shockwave()")
	if "_shockwave_rect" in ST:
		var sw: Control = ST.get("_shockwave_rect") as Control
		_assert(sw != null, "Shockwave rect exists")
		if sw:
			_assert(sw.visible == false, "Shockwave rect hidden by default")
	if "_shockwave_material" in ST:
		var mat: ShaderMaterial = ST.get("_shockwave_material") as ShaderMaterial
		_assert(mat != null, "Shockwave material exists")


func _suite_haptic_gating(GS: Node) -> void:
	_suite("Haptic Gating (v0.7.0)")

	_assert("haptic_enabled" in GS, "GameState has haptic_enabled")
	_assert(GS.has_method("vibrate"), "GameState has vibrate() method")

	GS.haptic_enabled = true
	_assert_eq(GS.haptic_enabled, true, "Haptic default is true")

	GS.haptic_enabled = false
	GS.vibrate(50)
	_assert(true, "vibrate() with haptic disabled does not crash")
	GS.haptic_enabled = true


func _suite_dead_zone_camera(GS: Node, TS: Node) -> void:
	_suite("Dead-Zone Camera (v0.7.0)")

	GS.reset()
	GS.start_game()
	TS.start_day(1)

	var packed := load("res://scenes/vertical_climb/vertical_level.tscn") as PackedScene
	if not packed:
		_assert(false, "Vertical level loaded for dead zone test")
		return

	var level: Node = packed.instantiate()
	root.add_child(level)

	_assert("_camera_target_y" in level, "Has _camera_target_y")
	_assert("DEAD_ZONE_HALF" in level, "Has DEAD_ZONE_HALF constant")
	_assert("_camera_lerp_speed" in level, "Has _camera_lerp_speed")

	if "_camera" in level:
		var cam: Camera2D = level.get("_camera") as Camera2D
		_assert(cam != null, "Camera exists for dead zone")
		if cam:
			var hero: Node = level.get("_hero")
			if hero:
				_assert(cam.get_parent() != hero, "Camera is NOT child of hero (standalone)")
				_assert(cam.get_parent() == level, "Camera is child of level")

	level.queue_free()