extends CanvasLayer
## Level completion overlay — stats, confetti, next-level buttons.

signal next_level_pressed
signal menu_pressed

# ── Nodes ────────────────────────────────────────────────────────

var _panel: PanelContainer
var _confetti: CPUParticles2D


func _ready() -> void:
	layer = 60
	_build_ui()
	_spawn_confetti()
	_animate_entrance()


func setup(stats: Dictionary) -> void:
	## Call after adding to tree. stats = {scene_id, time_seconds, objects_found, hints_used}
	# Stats are displayed in _build_ui defaults; call this to update with real data
	pass


# ── UI Construction ──────────────────────────────────────────────

func _build_ui() -> void:
	# Dimmer
	var dimmer := ColorRect.new()
	dimmer.anchors_preset = Control.PRESET_FULL_RECT
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	# Main panel
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.1
	_panel.anchor_right = 0.9
	_panel.anchor_top = 0.25
	_panel.anchor_bottom = 0.75

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeManager.BG_CREAM
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_color = ThemeManager.GOLDEN_AMBER
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.content_margin_left = 30.0
	style.content_margin_right = 30.0
	style.content_margin_top = 30.0
	style.content_margin_bottom = 30.0
	_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)

	# Title
	var title := Label.new()
	title.text = "Уровень пройден!"
	title.add_theme_font_size_override("font_size", ThemeManager.font_size(28))
	title.add_theme_color_override("font_color", ThemeManager.GOLDEN_AMBER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Stats will be updated via setup()
	var stats_label := Label.new()
	stats_label.name = "StatsLabel"
	stats_label.text = "Отлично!"
	stats_label.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	stats_label.add_theme_color_override("font_color", ThemeManager.TEXT_BROWN)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(stats_label)

	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)

	var menu_btn := Button.new()
	menu_btn.text = "Меню"
	menu_btn.custom_minimum_size = Vector2(160, 80)
	menu_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	menu_btn.pressed.connect(func(): menu_pressed.emit())
	btn_container.add_child(menu_btn)

	var next_btn := Button.new()
	next_btn.text = "Далее"
	next_btn.custom_minimum_size = Vector2(200, 80)
	next_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(20))
	next_btn.pressed.connect(func(): next_level_pressed.emit())
	btn_container.add_child(next_btn)

	vbox.add_child(btn_container)
	_panel.add_child(vbox)

	# Start invisible for entrance animation
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.8, 0.8)
	_panel.pivot_offset = Vector2(540, 960)
	add_child(_panel)


func _animate_entrance() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _spawn_confetti() -> void:
	_confetti = CPUParticles2D.new()
	_confetti.one_shot = true
	_confetti.emitting = true
	_confetti.amount = 80
	_confetti.lifetime = 2.5
	_confetti.position = Vector2(540, 200)

	_confetti.direction = Vector2(0, 1)
	_confetti.spread = 60.0
	_confetti.initial_velocity_min = 150.0
	_confetti.initial_velocity_max = 350.0
	_confetti.gravity = Vector2(0, 400)
	_confetti.scale_amount_min = 0.4
	_confetti.scale_amount_max = 1.5
	_confetti.angular_velocity_min = -180.0
	_confetti.angular_velocity_max = 180.0
	_confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_confetti.emission_rect_extents = Vector2(400, 10)

	# Multi-color: gold, sage, cream
	_confetti.color = ThemeManager.GOLDEN_AMBER

	_confetti.texture = PlaceholderFactory.make_soft_circle(6, Color.WHITE)
	add_child(_confetti)
