extends Control
## Main menu — animated background with sky gradient, particles, entrance animations.
## Procedural drawing is delegated to DrawLayer child (mouse_filter=IGNORE).

@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel
@onready var continue_btn: Button = $VBox/ContinueBtn
@onready var new_game_btn: Button = $VBox/NewGameBtn
@onready var draw_layer: Control = $DrawLayer

var _title_tap_count: int = 0
var _title_tap_timer: float = 0.0
var _anim_time: float = 0.0
var _sky_material: ShaderMaterial = null


func _ready() -> void:
	continue_btn.visible = SaveManager.has_save()
	continue_btn.pressed.connect(_on_continue)
	new_game_btn.pressed.connect(_on_new_game)
	title_label.gui_input.connect(_on_title_input)
	_create_hopa_button()
	_create_dialogue_button()
	_update_dev_indicator()
	_setup_background()
	ThemeManager.apply_ui_scale_to_tree(self)
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree(self))
	_animate_entrance()
	AudioManager.play_music("menu_theme")


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

	# Populate draw layer data
	var mtns: Array[Dictionary] = []
	mtns.append({"points": PackedVector2Array([Vector2(0, 1600), Vector2(200, 1100), Vector2(450, 1050), Vector2(700, 1200), Vector2(1080, 1600)]),
		 "color": Color("#a8c97a"), "alpha": 0.4})
	mtns.append({"points": PackedVector2Array([Vector2(0, 1600), Vector2(250, 1000), Vector2(540, 850), Vector2(750, 1050), Vector2(1080, 1600)]),
		 "color": Color("#5e8a3c"), "alpha": 0.7})
	draw_layer.mountains = mtns

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var clouds_data: Array[Dictionary] = []
	for i in range(5):
		clouds_data.append({
			"x": rng.randf_range(-200, 1200),
			"y": rng.randf_range(100, 500),
			"rx": rng.randf_range(60, 120),
			"ry": rng.randf_range(25, 40),
			"speed": rng.randf_range(6.0, 18.0),
			"alpha": rng.randf_range(0.25, 0.5),
		})
	draw_layer.clouds = clouds_data

	var trees_data: Array[Dictionary] = []
	for i in range(8):
		trees_data.append({
			"x": rng.randf_range(0, 1080),
			"y": rng.randf_range(1400, 1600),
			"height": rng.randf_range(80, 160),
			"width": rng.randf_range(40, 80),
			"dark": rng.randf() > 0.5,
		})
	draw_layer.trees = trees_data

	# Leaf particles
	var leaf_p := GPUParticles2D.new()
	leaf_p.z_index = 1
	leaf_p.amount = 15
	leaf_p.lifetime = 10.0
	leaf_p.visibility_rect = Rect2(-200, -200, 1480, 2120)
	var leaf_mat := ParticleProcessMaterial.new()
	leaf_mat.direction = Vector3(0.3, 1, 0)
	leaf_mat.spread = 35.0
	leaf_mat.initial_velocity_min = 10.0
	leaf_mat.initial_velocity_max = 30.0
	leaf_mat.gravity = Vector3(0, 10, 0)
	leaf_mat.angular_velocity_min = -90.0
	leaf_mat.angular_velocity_max = 90.0
	leaf_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	leaf_mat.emission_box_extents = Vector3(600, 10, 0)
	leaf_mat.scale_min = 0.6
	leaf_mat.scale_max = 1.8
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.45, 0.65, 0.25, 0.0))
	ramp.add_point(0.15, Color(0.5, 0.7, 0.3, 0.5))
	ramp.add_point(0.8, Color(0.55, 0.6, 0.2, 0.4))
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.5, 0.35, 0.1, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = ramp
	leaf_mat.color_ramp = grad_tex
	leaf_p.process_material = leaf_mat
	leaf_p.texture = _make_soft_circle(6, Color(0.5, 0.7, 0.3))
	add_child(leaf_p)

	# Golden sparkle particles
	var sparkle_p := GPUParticles2D.new()
	sparkle_p.z_index = 2
	sparkle_p.amount = 12
	sparkle_p.lifetime = 6.0
	sparkle_p.visibility_rect = Rect2(-200, -200, 1480, 2120)
	var ff_mat := ParticleProcessMaterial.new()
	ff_mat.direction = Vector3(0, -0.3, 0)
	ff_mat.spread = 180.0
	ff_mat.initial_velocity_min = 5.0
	ff_mat.initial_velocity_max = 15.0
	ff_mat.gravity = Vector3(0, -2, 0)
	ff_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ff_mat.emission_box_extents = Vector3(500, 600, 0)
	ff_mat.scale_min = 0.5
	ff_mat.scale_max = 1.2
	var ff_ramp := Gradient.new()
	ff_ramp.set_offset(0, 0.0)
	ff_ramp.set_color(0, Color(0.95, 0.9, 0.5, 0.0))
	ff_ramp.add_point(0.25, Color(1.0, 0.95, 0.6, 0.7))
	ff_ramp.add_point(0.75, Color(0.95, 0.85, 0.4, 0.5))
	ff_ramp.set_offset(ff_ramp.get_point_count() - 1, 1.0)
	ff_ramp.set_color(ff_ramp.get_point_count() - 1, Color(0.85, 0.75, 0.3, 0.0))
	var ff_tex := GradientTexture1D.new()
	ff_tex.gradient = ff_ramp
	ff_mat.color_ramp = ff_tex
	sparkle_p.process_material = ff_mat
	sparkle_p.texture = _make_soft_circle(5, Color(1.0, 0.95, 0.5))
	add_child(sparkle_p)


func _create_hopa_button() -> void:
	var hopa_btn := Button.new()
	hopa_btn.name = "HopaBtn"
	hopa_btn.text = "Сад Тайн"
	hopa_btn.custom_minimum_size = Vector2(400, 80)
	hopa_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(20))

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeManager.SOFT_TEAL
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	hopa_btn.add_theme_stylebox_override("normal", style)
	hopa_btn.add_theme_color_override("font_color", Color.WHITE)

	hopa_btn.pressed.connect(_on_hopa)
	$VBox.add_child(hopa_btn)


func _create_dialogue_button() -> void:
	var dlg_btn := Button.new()
	dlg_btn.name = "DialogueBtn"
	dlg_btn.text = "Диалог с героем"
	dlg_btn.custom_minimum_size = Vector2(400, 80)
	dlg_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(20))

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeManager.GOLDEN_AMBER
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	dlg_btn.add_theme_stylebox_override("normal", style)
	dlg_btn.add_theme_color_override("font_color", Color.WHITE)

	dlg_btn.pressed.connect(_on_dialogue)
	$VBox.add_child(dlg_btn)


func _animate_entrance() -> void:
	var orig_y := title_label.position.y
	title_label.modulate.a = 0.0
	title_label.position.y = orig_y - 60
	var t1 := create_tween()
	t1.set_parallel(true)
	t1.tween_property(title_label, "modulate:a", 1.0, 0.6).set_delay(0.3)
	t1.tween_property(title_label, "position:y", orig_y, 0.6).set_delay(0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	subtitle_label.modulate.a = 0.0
	var t2 := create_tween()
	t2.tween_property(subtitle_label, "modulate:a", 1.0, 0.5).set_delay(0.7)

	for btn in [continue_btn, new_game_btn]:
		if btn.visible:
			var btn_y: float = btn.position.y
			btn.modulate.a = 0.0
			btn.position.y = btn_y + 40
			var tb := create_tween()
			tb.set_parallel(true)
			tb.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(1.0)
			tb.tween_property(btn, "position:y", btn_y, 0.5).set_delay(1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	_anim_time += delta

	if _title_tap_timer > 0.0:
		_title_tap_timer -= delta
		if _title_tap_timer <= 0.0:
			_title_tap_count = 0

	if _sky_material:
		var cycle := sin(_anim_time * 0.08) * 0.5 + 0.5
		var top := Color("#87CEEB").lerp(Color("#b8cfe0"), cycle)
		var bottom := Color("#f5e6b8").lerp(Color("#fefcf3"), cycle)
		_sky_material.set_shader_parameter("color_top", top)
		_sky_material.set_shader_parameter("color_bottom", bottom)


func _on_continue() -> void:
	if SaveManager.load_game():
		SceneTransition.change_scene("res://scenes/vertical_climb/vertical_level.tscn")


func _on_new_game() -> void:
	SceneTransition.change_scene_iris("res://scenes/gender_select/gender_select.tscn")


func _on_hopa() -> void:
	GameState.hopa_current_level = HopaData.LEVEL_ORDER[0]
	SceneTransition.change_scene_iris("res://scenes/hopa/hopa_scene_base.tscn")


func _on_dialogue() -> void:
	SceneTransition.change_scene_iris("res://scenes/hero_dialogue/mode_select.tscn")


func _on_title_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_title_tap_count += 1
		_title_tap_timer = 3.0
		if _title_tap_count >= 5:
			GameState.developer_mode = not GameState.developer_mode
			SaveManager.save_game()
			_title_tap_count = 0
			_update_dev_indicator()


func _update_dev_indicator() -> void:
	if GameState.developer_mode:
		subtitle_label.text = "🔧 Режим разработчика"
	else:
		subtitle_label.text = "Путь гармонии и осознанности"


static func _make_soft_circle(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)
	for y in range(size):
		for x in range(size):
			var dist := Vector2(x, y).distance_to(center)
			var alpha := clampf(1.0 - dist / float(radius), 0.0, 1.0)
			alpha *= alpha
			img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	return ImageTexture.create_from_image(img)
