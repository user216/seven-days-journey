extends Control
## Mode selection screen — 3 interaction modes for A/B testing.
## Visual Novel, RPG Companion, Godogen-generated.


func _ready() -> void:
	_build_ui()
	ThemeManager.apply_ui_scale_to_tree(self)
	_animate_entrance()


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.color = ThemeManager.BG_CREAM
	bg.z_index = -1
	add_child(bg)

	# Main container
	var vbox := VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.anchors_preset = Control.PRESET_CENTER
	vbox.offset_left = -420
	vbox.offset_right = 420
	vbox.offset_top = -500
	vbox.offset_bottom = 500
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
	var card := PanelContainer.new()
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
	card.add_theme_stylebox_override("panel", card_style)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", ThemeManager.font_size(20))
	title.add_theme_color_override("font_color", accent_color.darkened(0.2))
	inner.add_child(title)

	var desc := Label.new()
	desc.text = desc_text
	desc.add_theme_font_size_override("font_size", ThemeManager.font_size(14))
	desc.add_theme_color_override("font_color", ThemeManager.HINT_KHAKI)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	inner.add_child(desc)

	card.add_child(inner)

	# Make the whole card clickable
	var btn := Button.new()
	btn.flat = true
	btn.anchors_preset = Control.PRESET_FULL_RECT
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func(): _on_mode_selected(mode_key))
	ThemeManager.apply_button_juice(btn)
	card.add_child(btn)

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
