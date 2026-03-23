extends Node2D
## RPG Companion mode — horizontal side-scrolling garden with hero companion.
## 16 activity stations spread left-to-right, hero walks alongside player.

const STATION_SPACING := 320.0
const STATION_Y := 800.0
const GROUND_Y := 900.0
const CAMERA_SMOOTH := 5.0

var _current_day: int = 1
var _cards: Array[Dictionary] = []
var _stations: Array[Dictionary] = []  # {pos, card, state, node}
var _hero: Node2D = null
var _camera: Camera2D = null
var _active_station: int = -1
var _dialog: Node = null
var _sky_bg: ColorRect
var _sky_material: ShaderMaterial = null
var _anim_time: float = 0.0
var _touch_start: Vector2 = Vector2.ZERO
var _scrolling: bool = false


func _ready() -> void:
	_current_day = GameState.current_day
	_cards = GameData.get_all_cards_for_day(_current_day)
	_build_scene()
	ThemeManager.apply_ui_scale_to_tree(self)


func _build_scene() -> void:
	# Sky background (CanvasLayer behind everything)
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	add_child(sky_layer)

	# Sky bg needs explicit sizing — it's a child of CanvasLayer, not Control, so anchors won't resolve
	var sky_root := Control.new()
	sky_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky_layer.add_child(sky_root)
	sky_root.size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(func(): sky_root.size = get_viewport().get_visible_rect().size)

	_sky_bg = ColorRect.new()
	_sky_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := load("res://shaders/sky_gradient.gdshader") as Shader
	if shader:
		_sky_material = ShaderMaterial.new()
		_sky_material.shader = shader
		_sky_material.set_shader_parameter("color_top", Color("#87CEEB"))
		_sky_material.set_shader_parameter("color_bottom", Color("#f5e6b8"))
		_sky_material.set_shader_parameter("star_density", 0.0)
		_sky_bg.material = _sky_material
	else:
		_sky_bg.color = ThemeManager.BG_CREAM
	sky_root.add_child(_sky_bg)

	# Ground
	_draw_ground()

	# Decorations (flowers, bushes)
	_draw_decorations()

	# Stations
	_build_stations()

	# Path between stations
	_draw_path()

	# Hero
	var hero_script := load("res://scenes/hero_dialogue/rpg_companion/companion_hero.gd")
	_hero = Node2D.new()
	_hero.set_script(hero_script)
	_hero.position = Vector2(_stations[0].pos.x - 100, STATION_Y + 20)
	add_child(_hero)

	# Camera
	_camera = Camera2D.new()
	_camera.position = _hero.position
	_camera.zoom = Vector2(0.65, 0.65)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = CAMERA_SMOOTH
	_camera.limit_left = -200
	_camera.limit_right = int(_stations[-1].pos.x + 400)
	_camera.limit_top = 0
	_camera.limit_bottom = 1920
	add_child(_camera)
	_camera.make_current()

	# HUD overlay
	_build_hud()

	# Branching dialog — it's already a CanvasLayer (layer 50), add directly
	var dialog_scene := load("res://scenes/hero_dialogue/shared/branching_dialog.tscn")
	if dialog_scene:
		_dialog = dialog_scene.instantiate()
		add_child(_dialog)
		_dialog.dialog_finished.connect(_on_dialog_finished)
		_dialog.choice_made.connect(_on_choice_made)
		_dialog.action_requested.connect(_on_action_requested)
		# Set hero portrait in dialog box
		var gender_suffix := "_male" if GameState.gender == "male" else ""
		var hair_suffix := GameState.get_hair_style_suffix()
		var portrait_path := "res://assets/hero/climb/hero_climb_idle%s%s.svg" % [gender_suffix, hair_suffix]
		var portrait_tex := load(portrait_path) as Texture2D
		if portrait_tex:
			_dialog.set_portrait_texture(portrait_tex)
			_dialog.set_portrait_visible(true)


func _build_stations() -> void:
	for i in range(_cards.size()):
		var card: Dictionary = _cards[i]
		var x := 200.0 + float(i) * STATION_SPACING
		var station_pos := Vector2(x, STATION_Y)

		# Determine state
		var state := "locked"
		if GameState.is_activity_completed(_current_day, card.slot_id):
			state = "completed"
		elif i == _get_first_available_index():
			state = "current"

		var station_node := _create_station_visual(station_pos, card, state, i)
		add_child(station_node)

		_stations.append({
			"pos": station_pos,
			"card": card,
			"state": state,
			"node": station_node,
			"index": i,
		})


func _create_station_visual(pos: Vector2, card: Dictionary, state: String, idx: int) -> Node2D:
	var node := Node2D.new()
	node.position = pos

	# Platform circle
	var platform := Node2D.new()
	platform.name = "Platform"
	node.add_child(platform)

	# Emoji label above
	var emoji := Label.new()
	emoji.text = card.get("emoji", "🌿")
	emoji.add_theme_font_size_override("font_size", ThemeManager.font_size(32))
	emoji.position = Vector2(-20, -80)
	node.add_child(emoji)

	# Title below
	var title := Label.new()
	title.text = card.get("title", "")
	title.add_theme_font_size_override("font_size", ThemeManager.font_size(12))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(120, 0)
	title.position = Vector2(-60, 50)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD

	match state:
		"completed":
			title.add_theme_color_override("font_color", ThemeManager.SAGE_GREEN)
		"current":
			title.add_theme_color_override("font_color", ThemeManager.GOLDEN_AMBER)
		_:
			title.add_theme_color_override("font_color", ThemeManager.HINT_KHAKI)
			title.modulate.a = 0.5
			emoji.modulate.a = 0.4

	node.add_child(title)

	# Click area
	var click_area := Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 50.0
	shape.shape = circle
	click_area.add_child(shape)
	click_area.input_event.connect(func(_vp, event, _idx):
		if event is InputEventMouseButton and event.pressed:
			_on_station_tapped(idx)
	)
	node.add_child(click_area)

	return node


func _draw_ground() -> void:
	# Simple green ground rect
	var total_width := 300.0 + float(_cards.size()) * STATION_SPACING
	var ground := ColorRect.new()
	ground.position = Vector2(-200, GROUND_Y)
	ground.size = Vector2(total_width, 1100)
	ground.color = ThemeManager.MINT_SAGE
	add_child(ground)

	# Grass line
	var grass := ColorRect.new()
	grass.position = Vector2(-200, GROUND_Y - 3)
	grass.size = Vector2(total_width, 6)
	grass.color = ThemeManager.SAGE_GREEN
	add_child(grass)


func _draw_decorations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _current_day * 42
	var flowers := ["🌸", "🌻", "🌺", "🌷", "🌼", "🌿", "🍃", "🦋"]
	var total_width := float(_cards.size()) * STATION_SPACING

	for i in range(25):
		var flower := Label.new()
		flower.text = flowers[rng.randi() % flowers.size()]
		flower.add_theme_font_size_override("font_size", ThemeManager.font_size(rng.randi_range(16, 28)))
		flower.position = Vector2(
			rng.randf_range(0, total_width),
			rng.randf_range(GROUND_Y + 20, GROUND_Y + 200)
		)
		flower.modulate.a = rng.randf_range(0.4, 0.8)
		add_child(flower)


func _draw_path() -> void:
	if _stations.size() < 2:
		return
	# Draw dotted path between stations
	for i in range(_stations.size() - 1):
		var from: Vector2 = _stations[i].pos
		var to: Vector2 = _stations[i + 1].pos
		var dots := 6
		for d in range(dots):
			var t := float(d + 1) / float(dots + 1)
			var dot_pos: Vector2 = from.lerp(to, t)
			var dot := ColorRect.new()
			dot.position = dot_pos - Vector2(3, 3)
			dot.size = Vector2(6, 6)
			dot.color = ThemeManager.EARTHY_BROWN
			dot.color.a = 0.4
			add_child(dot)


func _build_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 30
	add_child(hud_layer)

	# HUD root wrapper — CanvasLayer is not a Control, so anchors won't resolve
	var hud_root := Control.new()
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud_root)
	hud_root.size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(func(): hud_root.size = get_viewport().get_visible_rect().size)

	# Top bar
	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_top = 30
	top_bar.offset_left = 20
	top_bar.offset_right = -20
	top_bar.offset_bottom = 90
	top_bar.add_theme_constant_override("separation", 12)
	hud_root.add_child(top_bar)

	# Back
	var back_btn := Button.new()
	back_btn.text = "←"
	back_btn.custom_minimum_size = Vector2(60, 60)
	back_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(24))
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color(0, 0, 0, 0.3)
	back_style.corner_radius_top_left = 12
	back_style.corner_radius_top_right = 12
	back_style.corner_radius_bottom_left = 12
	back_style.corner_radius_bottom_right = 12
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", Color.WHITE)
	back_btn.pressed.connect(_on_back)
	ThemeManager.apply_button_juice(back_btn)
	top_bar.add_child(back_btn)

	# Day label
	var day_label := Label.new()
	day_label.text = "День %d" % _current_day
	day_label.add_theme_font_size_override("font_size", ThemeManager.font_size(20))
	day_label.add_theme_color_override("font_color", Color.WHITE)
	day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(day_label)

	# Score
	var score_label := Label.new()
	var completed_count := GameState.get_daily_score(_current_day)
	score_label.text = "%d/16" % completed_count
	score_label.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	score_label.add_theme_color_override("font_color", ThemeManager.LIGHT_GOLD)
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(score_label)


# ── Station Interaction ──────────────────────────────────────────

func _on_station_tapped(idx: int) -> void:
	if idx < 0 or idx >= _stations.size():
		return

	var station: Dictionary = _stations[idx]
	if station.state == "locked":
		# Shake the station
		var node: Node2D = station.node
		var orig_x := node.position.x
		var tw := create_tween()
		tw.tween_property(node, "position:x", orig_x + 10, 0.05)
		tw.tween_property(node, "position:x", orig_x - 10, 0.05)
		tw.tween_property(node, "position:x", orig_x, 0.05)
		return

	_active_station = idx

	# Walk hero to station
	_hero.walk_to(station.pos.x - 80)

	# Wait for hero to arrive, then show dialogue
	await get_tree().create_timer(maxf(absf(_hero.position.x - station.pos.x) / 200.0, 0.3)).timeout

	# Show speech bubble first, then full dialogue
	_hero.show_speech(station.card.get("title", ""), 2.0)
	await get_tree().create_timer(1.5).timeout

	# Start dialogue
	var nodes: Array = DialogueData.get_dialogue(_current_day, station.card.slot_id)
	if _dialog:
		_dialog.show_dialogue("day%d_%s" % [_current_day, station.card.slot_id], nodes)


func _on_dialog_finished() -> void:
	if _active_station < 0 or _active_station >= _stations.size():
		return

	var station: Dictionary = _stations[_active_station]
	var slot_id: String = station.card.slot_id

	# Mark completed
	GameState.complete_activity(_current_day, slot_id)
	GameState.dialogue_node_completed.emit(_current_day, slot_id)

	# Update station state
	_stations[_active_station].state = "completed"
	_refresh_station_visual(_active_station)

	# Unlock next station
	var next_idx := _active_station + 1
	if next_idx < _stations.size() and _stations[next_idx].state == "locked":
		_stations[next_idx].state = "current"
		_refresh_station_visual(next_idx)

	SaveManager.save_game()

	# Check day completion
	if GameState.get_daily_score(_current_day) >= GameData.TOTAL_CARDS_PER_DAY:
		_on_day_complete()

	_active_station = -1


func _on_choice_made(choice_key: String) -> void:
	if choice_key.length() > 0 and choice_key in DialogueData.DIALOGUES:
		if _dialog:
			_dialog.show_dialogue(choice_key, DialogueData.DIALOGUES[choice_key])


func _on_action_requested(action_id: String) -> void:
	# Same pattern as VN mode — load mini-interaction
	var scene_path := GameData.get_interaction_scene(action_id, _current_day)
	if scene_path.is_empty():
		return
	var scene_res := load(scene_path)
	if not scene_res:
		return

	var interaction: Control = scene_res.instantiate()
	# Add to a CanvasLayer so it overlays properly
	var overlay := CanvasLayer.new()
	overlay.layer = 45
	add_child(overlay)
	interaction.anchors_preset = Control.PRESET_CENTER
	interaction.offset_left = -300
	interaction.offset_right = 300
	interaction.offset_top = -200
	interaction.offset_bottom = 200
	overlay.add_child(interaction)

	if interaction.has_signal("completed"):
		interaction.completed.connect(func():
			overlay.queue_free()
			AudioManager.play("complete")
		)
	if interaction.has_signal("failed"):
		interaction.failed.connect(func():
			overlay.queue_free()
		)


func _refresh_station_visual(idx: int) -> void:
	var station: Dictionary = _stations[idx]
	var node: Node2D = station.node
	# Update emoji and title colors based on new state
	for child in node.get_children():
		if child is Label:
			if child.get_theme_font_size("font_size") > ThemeManager.font_size(20):
				# Emoji
				child.modulate.a = 1.0 if station.state != "locked" else 0.4
			else:
				# Title
				match station.state:
					"completed":
						child.add_theme_color_override("font_color", ThemeManager.SAGE_GREEN)
						child.modulate.a = 1.0
					"current":
						child.add_theme_color_override("font_color", ThemeManager.GOLDEN_AMBER)
						child.modulate.a = 1.0
					_:
						child.add_theme_color_override("font_color", ThemeManager.HINT_KHAKI)
						child.modulate.a = 0.5


func _on_day_complete() -> void:
	if _dialog:
		var nodes: Array = [
			{"type": "say", "speaker": "hero", "text": "Мы прошли весь сегодняшний путь вместе! 🎉"},
		]
		if _current_day >= 7:
			nodes.append({"type": "say", "speaker": "hero", "text": "Практикум завершён! Вы прекрасны! 🌟"})
			_dialog.dialog_finished.connect(func():
				GameState.game_finished = true
				SaveManager.save_game()
				SceneTransition.change_scene("res://scenes/main_menu/main_menu.tscn")
			, CONNECT_ONE_SHOT)
		else:
			nodes.append({"type": "choice", "prompt": "Продолжим завтра?", "options": [
				{"text": "Да, следующий день!", "next": "next_day"},
				{"text": "Вернуться в меню", "next": "back"},
			]})
			_dialog.choice_made.connect(func(choice):
				if choice == "next_day":
					if GameState.advance_day():
						SaveManager.save_game()
						SceneTransition.reload_scene()
				else:
					SceneTransition.change_scene("res://scenes/hero_dialogue/mode_select.tscn")
			, CONNECT_ONE_SHOT)
		_dialog.show_dialogue("day_complete", nodes)


func _get_first_available_index() -> int:
	for i in range(_cards.size()):
		if not GameState.is_activity_completed(_current_day, _cards[i].slot_id):
			return i
	return _cards.size()


func _process(delta: float) -> void:
	_anim_time += delta
	# Camera follows hero
	if _camera and _hero:
		_camera.position = _camera.position.lerp(
			Vector2(_hero.position.x + 100, STATION_Y - 100),
			CAMERA_SMOOTH * delta
		)
	# Sky animation
	if _sky_material:
		var tf := TimeSystem.get_time_of_day_factor() if TimeSystem else fmod(_anim_time * 0.01, 1.0)
		var colors: Array = ThemeManager.get_sky_colors(tf)
		_sky_material.set_shader_parameter("color_top", colors[0])
		_sky_material.set_shader_parameter("color_bottom", colors[1])


func _on_back() -> void:
	SaveManager.save_game()
	SceneTransition.change_scene("res://scenes/hero_dialogue/mode_select.tscn")
