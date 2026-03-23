extends Control
## Character customization screen — sky gradient, styled arrows, entrance animations.

@onready var preview: TextureRect = $VBox/Preview
@onready var skin_label: Label = $VBox/SkinRow/SkinLabel
@onready var hair_label: Label = $VBox/HairRow/HairLabel
@onready var style_label: Label = $VBox/StyleRow/StyleLabel
@onready var start_btn: Button = $VBox/StartBtn
@onready var title_label: Label = $VBox/TitleLabel

var _preview_shader: ShaderMaterial = null
var _sky_material: ShaderMaterial = null
var _anim_time: float = 0.0
var _arrow_buttons: Array[Button] = []


func _ready() -> void:
	$VBox/SkinRow/SkinPrev.pressed.connect(_on_skin_prev)
	$VBox/SkinRow/SkinNext.pressed.connect(_on_skin_next)
	$VBox/HairRow/HairPrev.pressed.connect(_on_hair_prev)
	$VBox/HairRow/HairNext.pressed.connect(_on_hair_next)
	$VBox/StyleRow/StylePrev.pressed.connect(_on_style_prev)
	$VBox/StyleRow/StyleNext.pressed.connect(_on_style_next)
	start_btn.pressed.connect(_on_start)
	# Setup tint shader for preview
	_preview_shader = ShaderMaterial.new()
	_preview_shader.shader = load("res://shaders/hero_tint.gdshader")
	preview.material = _preview_shader
	_setup_background()
	_style_arrow_buttons()
	_update_all()
	ThemeManager.apply_ui_scale_to_tree(self)
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree(self))
	_animate_entrance()


func _setup_background() -> void:
	var bg := $Background
	var shader := load("res://shaders/sky_gradient.gdshader") as Shader
	if shader:
		_sky_material = ShaderMaterial.new()
		_sky_material.shader = shader
		_sky_material.set_shader_parameter("color_top", Color("#b8cfe0"))
		_sky_material.set_shader_parameter("color_bottom", Color("#fefcf3"))
		_sky_material.set_shader_parameter("star_density", 0.0)
		bg.material = _sky_material

	# Subtle sparkle particles
	var sparkle_p := CPUParticles2D.new()
	sparkle_p.z_index = 1
	sparkle_p.amount = 6
	sparkle_p.lifetime = 8.0
	sparkle_p.direction = Vector2(0, -0.2)
	sparkle_p.spread = 180.0
	sparkle_p.initial_velocity_min = 3.0
	sparkle_p.initial_velocity_max = 8.0
	sparkle_p.gravity = Vector2(0, -1)
	sparkle_p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparkle_p.emission_rect_extents = Vector2(500, 800)
	sparkle_p.scale_amount_min = 0.3
	sparkle_p.scale_amount_max = 0.8
	var ff_ramp := Gradient.new()
	ff_ramp.set_offset(0, 0.0)
	ff_ramp.set_color(0, Color(0.95, 0.9, 0.5, 0.0))
	ff_ramp.add_point(0.25, Color(1.0, 0.95, 0.6, 0.4))
	ff_ramp.add_point(0.75, Color(0.95, 0.85, 0.4, 0.25))
	ff_ramp.set_offset(ff_ramp.get_point_count() - 1, 1.0)
	ff_ramp.set_color(ff_ramp.get_point_count() - 1, Color(0.85, 0.75, 0.3, 0.0))
	sparkle_p.color_ramp = ff_ramp
	sparkle_p.texture = PlaceholderFactory.make_soft_circle(4, Color(1.0, 0.95, 0.5))
	add_child(sparkle_p)


func _style_arrow_buttons() -> void:
	_arrow_buttons = [
		$VBox/SkinRow/SkinPrev, $VBox/SkinRow/SkinNext,
		$VBox/HairRow/HairPrev, $VBox/HairRow/HairNext,
		$VBox/StyleRow/StylePrev, $VBox/StyleRow/StyleNext,
	]
	for btn in _arrow_buttons:
		var style := StyleBoxFlat.new()
		style.bg_color = ThemeManager.EARTHY_BROWN
		style.bg_color.a = 0.85
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_left = 14
		style.corner_radius_bottom_right = 14
		style.content_margin_left = 8.0
		style.content_margin_right = 8.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate() as StyleBoxFlat
		hover.bg_color = ThemeManager.EARTHY_BROWN
		btn.add_theme_stylebox_override("hover", hover)
		var pressed := style.duplicate() as StyleBoxFlat
		pressed.bg_color = ThemeManager.EARTHY_BROWN.darkened(0.2)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", ThemeManager.LIGHT_GOLD)
		ThemeManager.apply_button_juice(btn)
	# Also style the start button
	ThemeManager.apply_button_juice(start_btn)


func _animate_entrance() -> void:
	# Title fades in
	title_label.modulate.a = 0.0
	var t1 := create_tween()
	t1.tween_property(title_label, "modulate:a", 1.0, 0.4).set_delay(0.2)

	# Preview scales in with spring
	preview.modulate.a = 0.0
	preview.pivot_offset = preview.size * 0.5
	preview.scale = Vector2(0.7, 0.7)
	var t2 := create_tween()
	t2.set_parallel(true)
	t2.tween_property(preview, "modulate:a", 1.0, 0.4).set_delay(0.3)
	t2.tween_property(preview, "scale", Vector2.ONE, 0.5).set_delay(0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Rows slide in staggered
	var rows: Array[Node] = [$VBox/SkinRow, $VBox/HairRow, $VBox/StyleRow]
	for i in range(rows.size()):
		var row: Node = rows[i]
		if row is Control:
			var ctrl := row as Control
			ctrl.modulate.a = 0.0
			var orig_x := ctrl.position.x
			ctrl.position.x = orig_x + 60
			var t := create_tween()
			t.set_parallel(true)
			t.tween_property(ctrl, "modulate:a", 1.0, 0.3).set_delay(0.5 + i * 0.15)
			t.tween_property(ctrl, "position:x", orig_x, 0.4).set_delay(0.5 + i * 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Start button slides up
	start_btn.modulate.a = 0.0
	var btn_y := start_btn.position.y
	start_btn.position.y = btn_y + 30
	var t3 := create_tween()
	t3.set_parallel(true)
	t3.tween_property(start_btn, "modulate:a", 1.0, 0.3).set_delay(1.0)
	t3.tween_property(start_btn, "position:y", btn_y, 0.4).set_delay(1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	_anim_time += delta
	if _sky_material:
		var cycle := sin(_anim_time * 0.08) * 0.5 + 0.5
		var top := Color("#b8cfe0").lerp(Color("#87CEEB"), cycle)
		var bottom := Color("#fefcf3").lerp(Color("#f5e6b8"), cycle)
		_sky_material.set_shader_parameter("color_top", top)
		_sky_material.set_shader_parameter("color_bottom", bottom)


func _update_all() -> void:
	_update_skin_label()
	_update_hair_label()
	_update_style_label()
	_update_preview()


func _update_preview() -> void:
	var suffix := GameState.get_hair_style_suffix()
	var gender_suffix := ""
	if GameState.gender == "male":
		gender_suffix = "_male"
	var path := "res://assets/hero/climb/hero_climb_idle%s%s.svg" % [gender_suffix, suffix]
	var tex := load(path) as Texture2D
	if tex:
		preview.texture = tex
		preview.modulate = Color.WHITE
	if _preview_shader:
		_preview_shader.set_shader_parameter("skin_tint", GameState.get_skin_tint())
		_preview_shader.set_shader_parameter("hair_tint", GameState.get_hair_tint())
		_preview_shader.set_shader_parameter("dress_tint", Color.WHITE)
		_preview_shader.set_shader_parameter("glow_intensity", 0.0)


func _update_skin_label() -> void:
	skin_label.text = GameState.SKIN_PRESETS[GameState.hero_skin_idx].name


func _update_hair_label() -> void:
	hair_label.text = GameState.HAIR_PRESETS[GameState.hero_hair_idx].name


func _update_style_label() -> void:
	style_label.text = GameState.get_hair_style_name()


func _on_skin_prev() -> void:
	GameState.hero_skin_idx = wrapi(GameState.hero_skin_idx - 1, 0, GameState.SKIN_PRESETS.size())
	_update_all()

func _on_skin_next() -> void:
	GameState.hero_skin_idx = wrapi(GameState.hero_skin_idx + 1, 0, GameState.SKIN_PRESETS.size())
	_update_all()

func _on_hair_prev() -> void:
	GameState.hero_hair_idx = wrapi(GameState.hero_hair_idx - 1, 0, GameState.HAIR_PRESETS.size())
	_update_all()

func _on_hair_next() -> void:
	GameState.hero_hair_idx = wrapi(GameState.hero_hair_idx + 1, 0, GameState.HAIR_PRESETS.size())
	_update_all()

func _on_style_prev() -> void:
	var presets := GameState.get_hair_style_presets()
	GameState.hero_hair_style_idx = wrapi(GameState.hero_hair_style_idx - 1, 0, presets.size())
	_update_all()

func _on_style_next() -> void:
	var presets := GameState.get_hair_style_presets()
	GameState.hero_hair_style_idx = wrapi(GameState.hero_hair_style_idx + 1, 0, presets.size())
	_update_all()

func _on_start() -> void:
	GameState.start_game()
	SaveManager.save_game()
	SceneTransition.change_scene("res://scenes/vertical_climb/vertical_level.tscn")
