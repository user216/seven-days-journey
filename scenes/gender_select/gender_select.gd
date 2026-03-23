extends Control
## Gender selection screen — animated background, entrance animations, styled buttons.

@onready var female_btn: Button = $VBox/HBox/FemaleBox/FemaleBtn
@onready var male_btn: Button = $VBox/HBox/MaleBox/MaleBtn
@onready var female_preview: TextureRect = $VBox/HBox/FemaleBox/FemalePreview
@onready var male_preview: TextureRect = $VBox/HBox/MaleBox/MalePreview
@onready var emoji_label: Label = $VBox/EmojiLabel
@onready var title_label: Label = $VBox/TitleLabel

var _sky_material: ShaderMaterial = null
var _anim_time: float = 0.0


func _ready() -> void:
	female_btn.pressed.connect(func(): _select("female"))
	male_btn.pressed.connect(func(): _select("male"))
	_setup_background()
	_style_buttons()
	ThemeManager.apply_ui_scale_to_tree(self)
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree(self))
	_animate_entrance()


func _setup_background() -> void:
	var bg := $Background
	var shader := load("res://shaders/sky_gradient.gdshader") as Shader
	if shader:
		_sky_material = ShaderMaterial.new()
		_sky_material.shader = shader
		_sky_material.set_shader_parameter("color_top", Color("#87CEEB"))
		_sky_material.set_shader_parameter("color_bottom", Color("#f5e6b8"))
		_sky_material.set_shader_parameter("star_density", 0.0)
		bg.material = _sky_material

	# Leaf particles
	var leaf_p := CPUParticles2D.new()
	leaf_p.z_index = 1
	leaf_p.amount = 8
	leaf_p.lifetime = 12.0
	leaf_p.direction = Vector2(0.3, 1)
	leaf_p.spread = 35.0
	leaf_p.initial_velocity_min = 8.0
	leaf_p.initial_velocity_max = 20.0
	leaf_p.gravity = Vector2(0, 8)
	leaf_p.angular_velocity_min = -60.0
	leaf_p.angular_velocity_max = 60.0
	leaf_p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaf_p.emission_rect_extents = Vector2(600, 10)
	leaf_p.scale_amount_min = 0.5
	leaf_p.scale_amount_max = 1.5
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.45, 0.65, 0.25, 0.0))
	ramp.add_point(0.15, Color(0.5, 0.7, 0.3, 0.4))
	ramp.add_point(0.8, Color(0.55, 0.6, 0.2, 0.3))
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.5, 0.35, 0.1, 0.0))
	leaf_p.color_ramp = ramp
	leaf_p.texture = PlaceholderFactory.make_soft_circle(5, Color(0.5, 0.7, 0.3))
	add_child(leaf_p)

	# Golden sparkle particles
	var sparkle_p := CPUParticles2D.new()
	sparkle_p.z_index = 2
	sparkle_p.amount = 6
	sparkle_p.lifetime = 8.0
	sparkle_p.direction = Vector2(0, -0.3)
	sparkle_p.spread = 180.0
	sparkle_p.initial_velocity_min = 3.0
	sparkle_p.initial_velocity_max = 10.0
	sparkle_p.gravity = Vector2(0, -2)
	sparkle_p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparkle_p.emission_rect_extents = Vector2(500, 800)
	sparkle_p.scale_amount_min = 0.4
	sparkle_p.scale_amount_max = 1.0
	var ff_ramp := Gradient.new()
	ff_ramp.set_offset(0, 0.0)
	ff_ramp.set_color(0, Color(0.95, 0.9, 0.5, 0.0))
	ff_ramp.add_point(0.25, Color(1.0, 0.95, 0.6, 0.5))
	ff_ramp.add_point(0.75, Color(0.95, 0.85, 0.4, 0.3))
	ff_ramp.set_offset(ff_ramp.get_point_count() - 1, 1.0)
	ff_ramp.set_color(ff_ramp.get_point_count() - 1, Color(0.85, 0.75, 0.3, 0.0))
	sparkle_p.color_ramp = ff_ramp
	sparkle_p.texture = PlaceholderFactory.make_soft_circle(4, Color(1.0, 0.95, 0.5))
	add_child(sparkle_p)


func _style_buttons() -> void:
	for btn in [female_btn, male_btn]:
		var style := StyleBoxFlat.new()
		style.bg_color = ThemeManager.SAGE_GREEN.darkened(0.05)
		style.bg_color.a = 0.95
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_left = 16
		style.corner_radius_bottom_right = 16
		style.content_margin_left = 20.0
		style.content_margin_right = 20.0
		style.content_margin_top = 14.0
		style.content_margin_bottom = 14.0
		style.shadow_color = Color(0, 0, 0, 0.15)
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 2)
		btn.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate() as StyleBoxFlat
		hover.bg_color = ThemeManager.SAGE_GREEN
		btn.add_theme_stylebox_override("hover", hover)
		var pressed := style.duplicate() as StyleBoxFlat
		pressed.bg_color = ThemeManager.SAGE_GREEN.darkened(0.2)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", ThemeManager.LIGHT_GOLD)
		ThemeManager.apply_button_juice(btn)


func _animate_entrance() -> void:
	# Emoji floats in from top
	emoji_label.modulate.a = 0.0
	var t1 := create_tween()
	t1.tween_property(emoji_label, "modulate:a", 1.0, 0.5).set_delay(0.2)

	# Title slides in
	title_label.modulate.a = 0.0
	var orig_y := title_label.position.y
	title_label.position.y = orig_y - 30
	var t2 := create_tween()
	t2.set_parallel(true)
	t2.tween_property(title_label, "modulate:a", 1.0, 0.5).set_delay(0.3)
	t2.tween_property(title_label, "position:y", orig_y, 0.5).set_delay(0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Female preview + button slide in from left
	female_preview.modulate.a = 0.0
	female_btn.modulate.a = 0.0
	var fp_x := female_preview.position.x
	female_preview.position.x = fp_x - 80
	var t3 := create_tween()
	t3.set_parallel(true)
	t3.tween_property(female_preview, "modulate:a", 1.0, 0.4).set_delay(0.6)
	t3.tween_property(female_preview, "position:x", fp_x, 0.5).set_delay(0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t3.tween_property(female_btn, "modulate:a", 1.0, 0.3).set_delay(0.8)

	# Male preview + button slide in from right
	male_preview.modulate.a = 0.0
	male_btn.modulate.a = 0.0
	var mp_x := male_preview.position.x
	male_preview.position.x = mp_x + 80
	var t4 := create_tween()
	t4.set_parallel(true)
	t4.tween_property(male_preview, "modulate:a", 1.0, 0.4).set_delay(0.6)
	t4.tween_property(male_preview, "position:x", mp_x, 0.5).set_delay(0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t4.tween_property(male_btn, "modulate:a", 1.0, 0.3).set_delay(0.8)


func _process(delta: float) -> void:
	_anim_time += delta
	if _sky_material:
		var cycle := sin(_anim_time * 0.1) * 0.5 + 0.5
		var top := Color("#87CEEB").lerp(Color("#b8cfe0"), cycle)
		var bottom := Color("#f5e6b8").lerp(Color("#fefcf3"), cycle)
		_sky_material.set_shader_parameter("color_top", top)
		_sky_material.set_shader_parameter("color_bottom", bottom)


func _select(chosen_gender: String) -> void:
	GameState.gender = chosen_gender
	GameState.hero_hair_style_idx = 0
	SceneTransition.change_scene("res://scenes/character_customize/character_customize.tscn")
