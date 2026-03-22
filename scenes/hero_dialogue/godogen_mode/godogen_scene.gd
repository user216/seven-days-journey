extends Control
## Godogen mode — placeholder + instructions for AI-generated game.
## When godogen has been run and output integrated, this scene loads the generated content.
## Until then, shows instructions for running the godogen pipeline.

var _generated_scene_path := "res://scenes/hero_dialogue/godogen_mode/generated/main.tscn"


func _ready() -> void:
	# Check if generated content exists
	if ResourceLoader.exists(_generated_scene_path):
		_load_generated()
	else:
		_show_placeholder()
	ThemeManager.apply_ui_scale_to_tree(self)


func _load_generated() -> void:
	var scene := load(_generated_scene_path)
	if scene:
		var instance := scene.instantiate()
		add_child(instance)
	else:
		_show_placeholder()


func _show_placeholder() -> void:
	# Background
	var bg := ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.color = ThemeManager.BG_CREAM
	add_child(bg)

	# Main container
	var scroll := ScrollContainer.new()
	scroll.anchors_preset = Control.PRESET_FULL_RECT
	scroll.offset_top = 40
	scroll.offset_left = 40
	scroll.offset_right = -40
	scroll.offset_bottom = -40
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "✨ Новый мир"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", ThemeManager.font_size(28))
	title.add_theme_color_override("font_color", ThemeManager.GOLDEN_AMBER)
	vbox.add_child(title)

	# Description
	var desc := RichTextLabel.new()
	desc.bbcode_enabled = false
	desc.fit_content = true
	desc.custom_minimum_size = Vector2(0, 400)
	desc.add_theme_font_size_override("normal_font_size", ThemeManager.font_size(15))
	desc.add_theme_color_override("default_color", ThemeManager.TEXT_BROWN)
	desc.text = """Этот режим использует AI (godogen) для создания уникального игрового мира, в котором вы взаимодействуете с героем.

Для генерации нужно:

1. Установить godogen:
   git clone https://github.com/htdt/godogen /tmp/godogen

2. Создать проект:
   cd /tmp/godogen
   ./publish.sh /tmp/hero_world

3. Задать описание игры в Claude Code:
   Откройте /tmp/hero_world и опишите мир

4. Дождаться генерации (1-3 часа)

5. Скопировать результат:
   cp -r /tmp/hero_world/scenes/* \
     seven_days_game/scenes/hero_dialogue/godogen_mode/generated/

Необходимые API ключи:
• GOOGLE_API_KEY — для генерации арта (Gemini)
• Опционально: TRIPO3D_API_KEY — для 3D моделей

После интеграции перезапустите игру — этот экран заменится сгенерированным миром."""
	vbox.add_child(desc)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "← Назад к выбору режима"
	back_btn.custom_minimum_size = Vector2(400, 70)
	back_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeManager.EARTHY_BROWN
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	back_btn.add_theme_stylebox_override("normal", style)
	back_btn.add_theme_color_override("font_color", Color.WHITE)
	back_btn.pressed.connect(_on_back)
	ThemeManager.apply_button_juice(back_btn)
	vbox.add_child(back_btn)


func _on_back() -> void:
	SceneTransition.change_scene("res://scenes/hero_dialogue/mode_select.tscn")
