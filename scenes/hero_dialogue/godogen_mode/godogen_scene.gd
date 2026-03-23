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
	var scene: PackedScene = load(_generated_scene_path) as PackedScene
	if scene:
		var instance: Node = scene.instantiate()
		add_child(instance)
	else:
		_show_placeholder()


func _show_placeholder() -> void:
	# Background with sky gradient shader
	var bg := ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.color = ThemeManager.BG_CREAM
	var shader := load("res://shaders/sky_gradient.gdshader") as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("color_top", Color("#87CEEB"))
		mat.set_shader_parameter("color_bottom", Color("#f5e6b8"))
		mat.set_shader_parameter("star_density", 0.0)
		bg.material = mat
	add_child(bg)

	# Golden sparkle particles
	var sparkle := CPUParticles2D.new()
	sparkle.z_index = 2
	sparkle.amount = 6
	sparkle.lifetime = 8.0
	sparkle.direction = Vector2(0, -0.3)
	sparkle.spread = 180.0
	sparkle.initial_velocity_min = 3.0
	sparkle.initial_velocity_max = 10.0
	sparkle.gravity = Vector2(0, -2)
	sparkle.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparkle.emission_rect_extents = Vector2(500, 800)
	sparkle.scale_amount_min = 0.4
	sparkle.scale_amount_max = 1.0
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.95, 0.9, 0.5, 0.0))
	ramp.add_point(0.25, Color(0.95, 0.88, 0.45, 0.5))
	ramp.add_point(0.75, Color(0.95, 0.85, 0.4, 0.3))
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.85, 0.75, 0.3, 0.0))
	sparkle.color_ramp = ramp
	sparkle.texture = PlaceholderFactory.make_soft_circle(4, Color(1.0, 0.95, 0.5))
	add_child(sparkle)

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
	ThemeManager.style_button(back_btn, ThemeManager.EARTHY_BROWN, 12)
	back_btn.pressed.connect(_on_back)
	ThemeManager.apply_button_juice(back_btn)
	vbox.add_child(back_btn)


func _on_back() -> void:
	SceneTransition.change_scene("res://scenes/hero_dialogue/mode_select.tscn")
