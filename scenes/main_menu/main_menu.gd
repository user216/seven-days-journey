extends Control
## Main menu — animated background with sky gradient, particles, entrance animations.
## Procedural drawing is delegated to DrawLayer child (mouse_filter=IGNORE).
##
## Diagnostic switches (visible on screen):
##   Audio ON/OFF — music, ambient, SFX
##   Shaders ON/OFF — shader warmup + sky gradient
##   Rendering ON/OFF — DrawLayer + particles
## Changes take effect on next app restart. Flags persisted to user://diag_flags.txt.

@onready var title_label: Label = $Scroll/VBox/TitleLabel
@onready var subtitle_label: Label = $Scroll/VBox/SubtitleLabel
@onready var continue_btn: Button = $Scroll/VBox/ContinueBtn
@onready var new_game_btn: Button = $Scroll/VBox/NewGameBtn
@onready var draw_layer: Control = $DrawLayer
@onready var vbox: VBoxContainer = $Scroll/VBox

var _title_tap_count: int = 0
var _title_tap_timer: float = 0.0
var _anim_time: float = 0.0
var _sky_material: ShaderMaterial = null
var _heartbeat_counter: int = 0

# Diagnostic flags (loaded from disk at startup)
var _diag_audio: bool = true
var _diag_shaders: bool = true
var _diag_rendering: bool = true

const DIAG_FLAGS_PATH := "user://diag_flags.txt"


func _ready() -> void:
	_load_diag_flags()
	CrashLogger.breadcrumb("MainMenu._ready (audio=%s, shaders=%s, rendering=%s)" % [
		str(_diag_audio), str(_diag_shaders), str(_diag_rendering)])
	continue_btn.visible = SaveManager.has_save()
	continue_btn.pressed.connect(_on_continue)
	new_game_btn.pressed.connect(_on_new_game)
	title_label.gui_input.connect(_on_title_input)
	_create_hopa_button()
	_create_dialogue_button()
	_create_send_logs_button()
	_update_dev_indicator()
	if _diag_rendering:
		_setup_background()
	else:
		$Background.color = Color(0.996, 0.988, 0.953)
		draw_layer.set_process(false)
		draw_layer.visible = false
	CrashLogger.breadcrumb("MainMenu.background_ready")
	ThemeManager.apply_ui_scale_to_tree(self)
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree(self))
	if _diag_rendering:
		_animate_entrance()
	if _diag_audio:
		AudioManager.play_music("menu_theme")
	_create_diag_switches()


func _setup_background() -> void:
	var bg := $Background
	if _diag_shaders:
		var shader := load("res://shaders/sky_gradient.gdshader") as Shader
		if shader:
			_sky_material = ShaderMaterial.new()
			_sky_material.shader = shader
			_sky_material.set_shader_parameter("color_top", Color("#87CEEB"))
			_sky_material.set_shader_parameter("color_bottom", Color("#f5e6b8"))
			_sky_material.set_shader_parameter("star_density", 0.0)
			bg.material = _sky_material
	else:
		bg.color = Color("#d4e8f0")

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

	# Leaf particles (CPUParticles2D — Mali-safe, no compute shaders)
	var leaf_p := CPUParticles2D.new()
	leaf_p.z_index = 1
	leaf_p.amount = 15
	leaf_p.lifetime = 10.0
	leaf_p.direction = Vector2(0.3, 1)
	leaf_p.spread = 35.0
	leaf_p.initial_velocity_min = 10.0
	leaf_p.initial_velocity_max = 30.0
	leaf_p.gravity = Vector2(0, 10)
	leaf_p.angular_velocity_min = -90.0
	leaf_p.angular_velocity_max = 90.0
	leaf_p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaf_p.emission_rect_extents = Vector2(600, 10)
	leaf_p.scale_amount_min = 0.6
	leaf_p.scale_amount_max = 1.8
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.45, 0.65, 0.25, 0.0))
	ramp.add_point(0.15, Color(0.5, 0.7, 0.3, 0.5))
	ramp.add_point(0.8, Color(0.55, 0.6, 0.2, 0.4))
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.5, 0.35, 0.1, 0.0))
	leaf_p.color_ramp = ramp
	leaf_p.texture = PlaceholderFactory.make_soft_circle(6, Color(0.5, 0.7, 0.3))
	add_child(leaf_p)

	# Golden sparkle particles (CPUParticles2D — Mali-safe)
	var sparkle_p := CPUParticles2D.new()
	sparkle_p.z_index = 2
	sparkle_p.amount = 12
	sparkle_p.lifetime = 6.0
	sparkle_p.direction = Vector2(0, -0.3)
	sparkle_p.spread = 180.0
	sparkle_p.initial_velocity_min = 5.0
	sparkle_p.initial_velocity_max = 15.0
	sparkle_p.gravity = Vector2(0, -2)
	sparkle_p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparkle_p.emission_rect_extents = Vector2(500, 600)
	sparkle_p.scale_amount_min = 0.5
	sparkle_p.scale_amount_max = 1.2
	var ff_ramp := Gradient.new()
	ff_ramp.set_offset(0, 0.0)
	ff_ramp.set_color(0, Color(0.95, 0.9, 0.5, 0.0))
	ff_ramp.add_point(0.25, Color(1.0, 0.95, 0.6, 0.7))
	ff_ramp.add_point(0.75, Color(0.95, 0.85, 0.4, 0.5))
	ff_ramp.set_offset(ff_ramp.get_point_count() - 1, 1.0)
	ff_ramp.set_color(ff_ramp.get_point_count() - 1, Color(0.85, 0.75, 0.3, 0.0))
	sparkle_p.color_ramp = ff_ramp
	sparkle_p.texture = PlaceholderFactory.make_soft_circle(5, Color(1.0, 0.95, 0.5))
	add_child(sparkle_p)


func _create_hopa_button() -> void:
	var hopa_btn := Button.new()
	hopa_btn.name = "HopaBtn"
	hopa_btn.text = "Сад Тайн"
	hopa_btn.custom_minimum_size = Vector2(400, 80)
	hopa_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(20))

	ThemeManager.style_button(hopa_btn, ThemeManager.DEEP_LEAF, 12)

	hopa_btn.pressed.connect(_on_hopa)
	vbox.add_child(hopa_btn)


func _create_dialogue_button() -> void:
	var dlg_btn := Button.new()
	dlg_btn.name = "DialogueBtn"
	dlg_btn.text = "Диалог с героем"
	dlg_btn.custom_minimum_size = Vector2(400, 80)
	dlg_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(20))

	ThemeManager.style_button(dlg_btn, ThemeManager.GOLDEN_AMBER, 12)

	dlg_btn.pressed.connect(_on_dialogue)
	vbox.add_child(dlg_btn)


func _create_send_logs_button() -> void:
	var log_btn := Button.new()
	log_btn.name = "SendLogsBtn"
	log_btn.text = "Отправить логи"
	log_btn.custom_minimum_size = Vector2(400, 64)
	log_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(16))

	ThemeManager.style_button(log_btn, ThemeManager.HINT_KHAKI, 12)

	log_btn.pressed.connect(_on_send_logs)
	vbox.add_child(log_btn)


func _create_diag_switches() -> void:
	## Visible diagnostic toggle switches at the bottom of the menu.
	## Changes are saved immediately but take full effect on next restart.
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var header := Label.new()
	header.text = "Диагностика (перезапустите после изменений)"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", ThemeManager.font_size(14))
	header.add_theme_color_override("font_color", Color(0.49, 0.45, 0.34, 0.7))
	vbox.add_child(header)

	var grid := HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 24)
	vbox.add_child(grid)

	_add_switch(grid, "Звук", _diag_audio, func(on: bool):
		_diag_audio = on
		_save_diag_flags()
		CrashLogger.breadcrumb("Diag: audio=%s" % str(on))
	)
	_add_switch(grid, "Шейдеры", _diag_shaders, func(on: bool):
		_diag_shaders = on
		_save_diag_flags()
		CrashLogger.breadcrumb("Diag: shaders=%s" % str(on))
	)
	_add_switch(grid, "Рендер", _diag_rendering, func(on: bool):
		_diag_rendering = on
		_save_diag_flags()
		CrashLogger.breadcrumb("Diag: rendering=%s" % str(on))
	)

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(bottom_spacer)


func _add_switch(parent: Control, label_text: String, initial: bool, callback: Callable) -> void:
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", ThemeManager.font_size(14))
	lbl.add_theme_color_override("font_color", Color(0.35, 0.32, 0.25, 0.85))
	vb.add_child(lbl)

	var toggle := CheckButton.new()
	toggle.button_pressed = initial
	toggle.custom_minimum_size = Vector2(80, 50)
	toggle.toggled.connect(callback)
	vb.add_child(toggle)

	parent.add_child(vb)


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

	# Heartbeat breadcrumb every 1 second for crash diagnosis
	var sec := int(_anim_time)
	if sec > _heartbeat_counter:
		_heartbeat_counter = sec
		CrashLogger.breadcrumb("MainMenu.heartbeat %ds" % sec)

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


func _on_send_logs() -> void:
	CrashLogger.send_logs_via_email()


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


# -- Diagnostic flag persistence --

func _load_diag_flags() -> void:
	if not FileAccess.file_exists(DIAG_FLAGS_PATH):
		return  # defaults: all true
	var f := FileAccess.open(DIAG_FLAGS_PATH, FileAccess.READ)
	if not f:
		return
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("audio="):
			_diag_audio = line.get_slice("=", 1) == "1"
		elif line.begins_with("shaders="):
			_diag_shaders = line.get_slice("=", 1) == "1"
		elif line.begins_with("rendering="):
			_diag_rendering = line.get_slice("=", 1) == "1"
	f.close()


func _save_diag_flags() -> void:
	var f := FileAccess.open(DIAG_FLAGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string("audio=%s\n" % ("1" if _diag_audio else "0"))
		f.store_string("shaders=%s\n" % ("1" if _diag_shaders else "0"))
		f.store_string("rendering=%s\n" % ("1" if _diag_rendering else "0"))
		f.close()
