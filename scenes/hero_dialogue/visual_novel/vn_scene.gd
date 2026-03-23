extends Control
## Visual Novel mode — hero portrait + branching dialogue + mini-interactions.
## Progresses through 16 daily cards as conversation with the hero.

var _current_day: int = 1
var _cards: Array[Dictionary] = []
var _card_idx: int = 0
var _api_sync: Node = null
var _dialog: Node = null
var _bg: ColorRect
var _day_label: Label
var _progress_bar: ProgressBar
var _sky_material: ShaderMaterial = null
var _anim_time: float = 0.0


func _ready() -> void:
	_current_day = GameState.current_day
	_cards = GameData.get_all_cards_for_day(_current_day)
	_card_idx = _get_resume_index()
	_build_scene()
	ThemeManager.apply_ui_scale_to_tree(self)
	_start_card_dialogue()


func _process(delta: float) -> void:
	_anim_time += delta
	if _sky_material:
		var tf := TimeSystem.get_time_of_day_factor() if TimeSystem else fmod(_anim_time * 0.01, 1.0)
		var colors: Array = ThemeManager.get_sky_colors(tf)
		_sky_material.set_shader_parameter("color_top", colors[0])
		_sky_material.set_shader_parameter("color_bottom", colors[1])


func _build_scene() -> void:
	# Sky background
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.z_index = -2
	var shader := load("res://shaders/sky_gradient.gdshader") as Shader
	if shader:
		_sky_material = ShaderMaterial.new()
		_sky_material.shader = shader
		_sky_material.set_shader_parameter("color_top", Color("#87CEEB"))
		_sky_material.set_shader_parameter("color_bottom", Color("#f5e6b8"))
		_sky_material.set_shader_parameter("star_density", 0.0)
		_bg.material = _sky_material
	else:
		_bg.color = ThemeManager.BG_CREAM
	add_child(_bg)

	# Hero portrait — large, centered above the dialog box
	var portrait := _create_hero_portrait()
	if portrait:
		add_child(portrait)

	# Top HUD bar
	var hud := HBoxContainer.new()
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_top = 40
	hud.offset_left = 30
	hud.offset_right = -30
	hud.offset_bottom = 100
	hud.add_theme_constant_override("separation", 16)
	add_child(hud)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "←"
	back_btn.custom_minimum_size = Vector2(60, 60)
	back_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(24))
	ThemeManager.style_button(back_btn, Color(0.15, 0.15, 0.1, 0.7), 12, false)
	back_btn.pressed.connect(_on_back)
	ThemeManager.apply_button_juice(back_btn)
	hud.add_child(back_btn)

	# Day label
	_day_label = Label.new()
	_day_label.text = "День %d" % _current_day
	_day_label.add_theme_font_size_override("font_size", ThemeManager.font_size(20))
	_day_label.add_theme_color_override("font_color", Color.WHITE)
	_day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud.add_child(_day_label)

	# Card counter
	var counter := Label.new()
	counter.name = "Counter"
	counter.add_theme_font_size_override("font_size", ThemeManager.font_size(16))
	counter.add_theme_color_override("font_color", ThemeManager.LIGHT_GOLD)
	counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud.add_child(counter)

	# Progress bar
	_progress_bar = ProgressBar.new()
	_progress_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_progress_bar.offset_top = 110
	_progress_bar.offset_left = 30
	_progress_bar.offset_right = -30
	_progress_bar.offset_bottom = 120
	_progress_bar.max_value = _cards.size()
	_progress_bar.value = _card_idx
	_progress_bar.show_percentage = false
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = ThemeManager.SAGE_GREEN
	bar_style.corner_radius_top_left = 4
	bar_style.corner_radius_top_right = 4
	bar_style.corner_radius_bottom_left = 4
	bar_style.corner_radius_bottom_right = 4
	_progress_bar.add_theme_stylebox_override("fill", bar_style)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0, 0, 0, 0.2)
	bar_bg.corner_radius_top_left = 4
	bar_bg.corner_radius_top_right = 4
	bar_bg.corner_radius_bottom_left = 4
	bar_bg.corner_radius_bottom_right = 4
	_progress_bar.add_theme_stylebox_override("background", bar_bg)
	add_child(_progress_bar)

	# API sync
	var api_sync_script := load("res://scenes/hero_dialogue/shared/api_sync.gd")
	if api_sync_script:
		_api_sync = Node.new()
		_api_sync.set_script(api_sync_script)
		add_child(_api_sync)

	# Branching dialog
	var dialog_scene := load("res://scenes/hero_dialogue/shared/branching_dialog.tscn")
	if dialog_scene:
		_dialog = dialog_scene.instantiate()
		add_child(_dialog)
		_dialog.dialog_finished.connect(_on_dialog_finished)
		_dialog.choice_made.connect(_on_choice_made)
		_dialog.action_requested.connect(_on_action_requested)
		# Set hero portrait in dialog box
		var portrait_tex := _load_hero_texture()
		if portrait_tex:
			_dialog.set_portrait_texture(portrait_tex)
			_dialog.set_portrait_visible(true)

	_update_counter()


# ── Dialogue Flow ────────────────────────────────────────────────

func _start_card_dialogue() -> void:
	if _card_idx >= _cards.size():
		_on_day_complete()
		return

	var card: Dictionary = _cards[_card_idx]
	var nodes: Array = DialogueData.get_dialogue(_current_day, card.slot_id)

	if _dialog:
		_dialog.show_dialogue("day%d_%s" % [_current_day, card.slot_id], nodes)


func _on_dialog_finished() -> void:
	# Mark card as discussed in dialogue progress
	if _current_day not in GameState.dialogue_progress:
		GameState.dialogue_progress[_current_day] = []
	var slot_id: String = _cards[_card_idx].slot_id if _card_idx < _cards.size() else ""
	if slot_id.length() > 0 and slot_id not in GameState.dialogue_progress[_current_day]:
		GameState.dialogue_progress[_current_day].append(slot_id)

	# Also complete the activity in main game state
	if slot_id.length() > 0:
		GameState.complete_activity(_current_day, slot_id)
		GameState.dialogue_node_completed.emit(_current_day, slot_id)

	# Advance to next card
	_card_idx += 1
	_progress_bar.value = _card_idx
	_update_counter()
	SaveManager.save_game()

	# Small delay before next dialogue
	var timer := get_tree().create_timer(0.5)
	timer.timeout.connect(_start_card_dialogue)


func _on_choice_made(choice_key: String) -> void:
	if choice_key.length() > 0:
		# Record choice
		var card: Dictionary = _cards[_card_idx] if _card_idx < _cards.size() else {}
		var dlg_key := "day%d_%s" % [_current_day, card.get("slot_id", "")]
		GameState.dialogue_choices[dlg_key] = choice_key

		# If branching to a different tree, show it
		var branch_nodes: Array = DialogueData.get_dialogue(_current_day, choice_key.split("_")[-1]) if "_" in choice_key else []
		if choice_key in DialogueData.DIALOGUES:
			branch_nodes = DialogueData.DIALOGUES[choice_key]
		if branch_nodes.size() > 0 and _dialog:
			_dialog.show_dialogue(choice_key, branch_nodes)


func _on_action_requested(action_id: String) -> void:
	# Load and run the mini-interaction for this slot
	var scene_path := GameData.get_interaction_scene(action_id, _current_day)
	if scene_path.is_empty():
		return

	var scene_res := load(scene_path)
	if not scene_res:
		return

	# Use activity popup pattern: instantiate the mini-interaction
	var interaction: Control = scene_res.instantiate()
	interaction.anchors_preset = Control.PRESET_CENTER
	interaction.offset_left = -300
	interaction.offset_right = 300
	interaction.offset_top = -200
	interaction.offset_bottom = 200
	add_child(interaction)

	# Connect signals
	if interaction.has_signal("completed"):
		interaction.completed.connect(func():
			interaction.queue_free()
			AudioManager.play("complete")
		)
	if interaction.has_signal("failed"):
		interaction.failed.connect(func():
			interaction.queue_free()
		)


func _on_day_complete() -> void:
	# Show day completion message
	if _dialog:
		var completion_nodes: Array = [
			{"type": "say", "speaker": "hero", "text": "Поздравляю! Вы завершили день %d! 🎉" % _current_day},
			{"type": "say", "speaker": "hero", "text": "Сегодня вы обсудили %d карточек. Прекрасная работа!" % _cards.size()},
		]

		if _current_day >= 7:
			completion_nodes.append({"type": "say", "speaker": "hero", "text": "Вы прошли весь практикум! Я горжусь вами! 🌟"})
			_dialog.dialog_finished.connect(_on_game_finished, CONNECT_ONE_SHOT)
		else:
			completion_nodes.append({"type": "choice", "prompt": "Что дальше?", "options": [
				{"text": "Перейти к следующему дню", "next": "next_day"},
				{"text": "Вернуться в меню", "next": "back"},
			]})
			_dialog.choice_made.connect(_on_day_end_choice, CONNECT_ONE_SHOT)

		_dialog.dialog_finished.disconnect(_on_dialog_finished)
		_dialog.show_dialogue("day_complete", completion_nodes)


func _on_day_end_choice(choice_key: String) -> void:
	if choice_key == "next_day":
		if GameState.advance_day():
			SaveManager.save_game()
			SceneTransition.reload_scene()
	else:
		SceneTransition.change_scene("res://scenes/hero_dialogue/mode_select.tscn")


func _on_game_finished() -> void:
	GameState.game_finished = true
	SaveManager.save_game()
	SceneTransition.change_scene("res://scenes/main_menu/main_menu.tscn")


# ── Helpers ──────────────────────────────────────────────────────

func _get_resume_index() -> int:
	var completed: Array = GameState.dialogue_progress.get(_current_day, [])
	if completed.is_empty():
		return 0
	# Find first uncompleted card
	for i in range(_cards.size()):
		if _cards[i].slot_id not in completed:
			return i
	return _cards.size()


func _update_counter() -> void:
	var counter := get_node_or_null("Counter") if false else null
	# Find counter in hud
	for child in get_children():
		if child is HBoxContainer:
			for c in child.get_children():
				if c.name == "Counter" and c is Label:
					counter = c
					break
	if counter:
		counter.text = "%d/%d" % [mini(_card_idx + 1, _cards.size()), _cards.size()]


func _on_back() -> void:
	SaveManager.save_game()
	SceneTransition.change_scene("res://scenes/hero_dialogue/mode_select.tscn")


func _load_hero_texture() -> Texture2D:
	## Load the hero idle SVG matching the player's gender and hairstyle.
	var suffix := GameState.get_hair_style_suffix()
	var gender_suffix := "_male" if GameState.gender == "male" else ""
	var path := "res://assets/hero/climb/hero_climb_idle%s%s.svg" % [gender_suffix, suffix]
	return load(path) as Texture2D


func _create_hero_portrait() -> TextureRect:
	## Create a large hero portrait centered in the upper part of the screen.
	var tex := _load_hero_texture()
	if not tex:
		return null
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.set_anchors_preset(Control.PRESET_CENTER)
	rect.offset_left = -150
	rect.offset_right = 150
	rect.offset_top = -280
	rect.offset_bottom = 220
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Apply hero_tint shader for skin/hair colors
	var tint_shader := load("res://shaders/hero_tint.gdshader") as Shader
	if tint_shader:
		var mat := ShaderMaterial.new()
		mat.shader = tint_shader
		mat.set_shader_parameter("skin_tint", GameState.get_skin_tint())
		mat.set_shader_parameter("hair_tint", GameState.get_hair_tint())
		mat.set_shader_parameter("dress_tint", Color.WHITE)
		mat.set_shader_parameter("glow_intensity", 0.0)
		rect.material = mat
	return rect
