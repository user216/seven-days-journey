extends Control
## Mode selection screen — 3 interaction modes for A/B testing.
## Visual Novel, RPG Companion, Godogen-generated.

var _sky_material: ShaderMaterial = null
var _anim_time: float = 0.0


func _ready() -> void:
	_build_ui()
	ThemeManager.apply_ui_scale_to_tree(self)
	_animate_entrance()


func _build_ui() -> void:
	# Background with sky gradient
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = ThemeManager.BG_CREAM
	bg.z_index = -1
	var shader := load("res://shaders/sky_gradient.gdshader") as Shader
	if shader:
		_sky_material = ShaderMaterial.new()
		_sky_material.shader = shader
		_sky_material.set_shader_parameter("color_top", Color("#b8cfe0"))
		_sky_material.set_shader_parameter("color_bottom", Color("#fefcf3"))
		_sky_material.set_shader_parameter("star_density", 0.0)
		bg.material = _sky_material
	add_child(bg)

	# Subtle sparkle particles
	var sparkle_p := CPUParticles2D.new()
	sparkle_p.z_index = 0
	sparkle_p.amount = 5
	sparkle_p.lifetime = 8.0
	sparkle_p.direction = Vector2(0, -0.2)
	sparkle_p.spread = 180.0
	sparkle_p.initial_velocity_min = 2.0
	sparkle_p.initial_velocity_max = 6.0
	sparkle_p.gravity = Vector2(0, -1)
	sparkle_p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparkle_p.emission_rect_extents = Vector2(500, 800)
	sparkle_p.scale_amount_min = 0.3
	sparkle_p.scale_amount_max = 0.7
	var ff_ramp := Gradient.new()
	ff_ramp.set_offset(0, 0.0)
	ff_ramp.set_color(0, Color(0.95, 0.9, 0.5, 0.0))
	ff_ramp.add_point(0.25, Color(1.0, 0.95, 0.6, 0.3))
	ff_ramp.add_point(0.75, Color(0.95, 0.85, 0.4, 0.2))
	ff_ramp.set_offset(ff_ramp.get_point_count() - 1, 1.0)
	ff_ramp.set_color(ff_ramp.get_point_count() - 1, Color(0.85, 0.75, 0.3, 0.0))
	sparkle_p.color_ramp = ff_ramp
	sparkle_p.texture = PlaceholderFactory.make_soft_circle(3, Color(1.0, 0.95, 0.5))
	add_child(sparkle_p)

	# Main container — use margins instead of fixed pixel offsets
	var vbox := VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 40
	vbox.offset_right = -40
	vbox.offset_top = 80
	vbox.offset_bottom = -40
	vbox.add_theme_constant_override("separation", 30)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Диалог с героем"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", ThemeManager.font_size(28))
	title.add_theme_color_override("font_color", ThemeManager.TEXT_BROWN)
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Выберите стиль взаимодействия"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", ThemeManager.font_size(16))
	subtitle.add_theme_color_override("font_color", ThemeManager.HINT_KHAKI)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(subtitle)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	# Mode cards
	_create_mode_card(vbox, "visual_novel",
		"📖 Визуальная новелла",
		"Диалог с героем лицом к лицу.\nПортрет, текст и выбор ответов.",
		ThemeManager.SAGE_GREEN)

	_create_mode_card(vbox, "rpg_companion",
		"🌿 Спутник по саду",
		"Герой гуляет с вами по саду.\nРечевые пузыри у каждой станции.",
		ThemeManager.SOFT_TEAL)

	_create_mode_card(vbox, "godogen",
		"✨ Новый мир",
		"Сгенерированный AI мир.\nУникальный опыт взаимодействия.",
		ThemeManager.GOLDEN_AMBER)

	# Back button
	var back_btn := Button.new()
	back_btn.name = "BackBtn"
	back_btn.text = "← Назад"
	back_btn.custom_minimum_size = Vector2(200, 60)
	back_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(16))
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = ThemeManager.EARTHY_BROWN
	back_style.corner_radius_top_left = 12
	back_style.corner_radius_top_right = 12
	back_style.corner_radius_bottom_left = 12
	back_style.corner_radius_bottom_right = 12
	back_style.content_margin_left = 16.0
	back_style.content_margin_right = 16.0
	back_style.content_margin_top = 8.0
	back_style.content_margin_bottom = 8.0
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_color_override("font_color", Color.WHITE)
	back_btn.pressed.connect(_on_back)
	ThemeManager.apply_button_juice(back_btn)
	vbox.add_child(back_btn)


func _create_mode_card(parent: VBoxContainer, mode_key: String, title_text: String, desc_text: String, accent_color: Color) -> void:
	# Use a Button as the card base for reliable click handling
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 140)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color.WHITE
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_left = 16
	card_style.corner_radius_bottom_right = 16
	card_style.border_color = accent_color
	card_style.border_width_left = 4
	card_style.content_margin_left = 24.0
	card_style.content_margin_right = 24.0
	card_style.content_margin_top = 16.0
	card_style.content_margin_bottom = 16.0
	# Subtle shadow
	card_style.shadow_color = Color(0, 0, 0, 0.1)
	card_style.shadow_size = 4
	card_style.shadow_offset = Vector2(0, 2)
	card.add_theme_stylebox_override("normal", card_style)

	var hover_style := card_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.97, 0.97, 0.97)
	card.add_theme_stylebox_override("hover", hover_style)
	card.add_theme_stylebox_override("pressed", hover_style)
	card.add_theme_stylebox_override("focus", card_style)

	# Remove default button text — we use custom layout
	card.text = ""
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Title + description as button text with BBCode-style line breaks
	# Since Button only supports single text, we'll set the text to title + newlines + desc
	card.text = title_text + "\n" + desc_text
	card.add_theme_font_size_override("font_size", ThemeManager.font_size(16))
	card.add_theme_color_override("font_color", accent_color.darkened(0.2))

	card.pressed.connect(func(): _on_mode_selected(mode_key))
	ThemeManager.apply_button_juice(card)

	parent.add_child(card)


func _animate_entrance() -> void:
	var main_vbox := get_node_or_null("MainVBox")
	if not main_vbox:
		return
	main_vbox.modulate.a = 0.0
	main_vbox.position.y += 40
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(main_vbox, "modulate:a", 1.0, 0.5).set_delay(0.1)
	tw.tween_property(main_vbox, "position:y", main_vbox.position.y - 40, 0.5).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


# ── Navigation ───────────────────────────────────────────────────

func _on_mode_selected(mode_key: String) -> void:
	GameState.dialogue_mode = mode_key
	SaveManager.save_game()

	match mode_key:
		"visual_novel":
			SceneTransition.change_scene("res://scenes/hero_dialogue/visual_novel/vn_scene.tscn")
		"rpg_companion":
			SceneTransition.change_scene("res://scenes/hero_dialogue/rpg_companion/garden_walk.tscn")
		"godogen":
			SceneTransition.change_scene("res://scenes/hero_dialogue/godogen_mode/godogen_scene.tscn")


func _on_back() -> void:
	SceneTransition.change_scene("res://scenes/main_menu/main_menu.tscn")


func _process(delta: float) -> void:
	_anim_time += delta
	if _sky_material:
		var cycle := sin(_anim_time * 0.08) * 0.5 + 0.5
		var top := Color("#b8cfe0").lerp(Color("#87CEEB"), cycle)
		var bottom := Color("#fefcf3").lerp(Color("#f5e6b8"), cycle)
		_sky_material.set_shader_parameter("color_top", top)
		_sky_material.set_shader_parameter("color_bottom", bottom)
