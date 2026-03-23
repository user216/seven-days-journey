extends Node2D
## Vertical climb level — platforms from dawn (bottom) to night (top).
## Enhanced visual: sky shader, parallax, particles, vignette, platform glow,
## completion sparkles, screen shake, squash & stretch.

var platforms: Array[Dictionary] = []
var _hero: Node2D = null
var _activity_popup = null
var _day_summary = null
var _pause_menu = null
var _stats_page = null
var _day_cards: Array[Dictionary] = []
var _current_platform: int = 0
var _anim_time: float = 0.0
var _camera: Camera2D = null

# Post-activity VN dialogue
var _branching_dialog: Node = null
var _pending_dialogue_slot: String = ""
var _pending_effects_platform_idx: int = -1

# Dead-zone camera — camera stays still while hero is within center band
const DEAD_ZONE_HALF := 0.15  # 30% of viewport height = ±15% from center
var _camera_target_y: float = 0.0
var _camera_lerp_speed: float = 3.5

const PLATFORM_HEIGHT := 300.0
const PLATFORM_WIDTH := 280.0
const PLATFORM_TEX_HEIGHT := 40.0

# Cloud drift tracking
var _cloud_sprites: Array[Sprite2D] = []

var _vine_tex: Texture2D = preload("res://assets/environment/vine_segment.svg")
var _platform_tex: Texture2D = preload("res://assets/environment/platform.svg")
var _flower_textures := [
	preload("res://assets/nature/flower_5petal.svg"),
	preload("res://assets/nature/flower_4petal.svg"),
	preload("res://assets/nature/flower_tulip.svg"),
]
var _tree_textures := [
	preload("res://assets/nature/tree_tall_01.svg"),
	preload("res://assets/nature/tree_tall_02.svg"),
	preload("res://assets/nature/tree_medium_01.svg"),
	preload("res://assets/nature/tree_medium_02.svg"),
]
var _bush_textures := [
	preload("res://assets/nature/bush_01.svg"),
	preload("res://assets/nature/bush_02.svg"),
	preload("res://assets/nature/bush_flowering.svg"),
]
var _cloud_textures := [
	preload("res://assets/nature/cloud_large.svg"),
	preload("res://assets/nature/cloud_medium.svg"),
	preload("res://assets/nature/cloud_small.svg"),
]

# Sky shader
var _sky_rect: ColorRect = null
var _sky_material: ShaderMaterial = null

# Vignette overlay
var _vignette: ColorRect = null
var _vignette_material: ShaderMaterial = null

# Parallax layers
var _parallax_bg: ParallaxBackground = null
var _far_layer: ParallaxLayer = null
var _mid_layer: ParallaxLayer = null
var _near_layer: ParallaxLayer = null

# Particles
var _leaf_particles: CPUParticles2D = null
var _firefly_particles: CPUParticles2D = null

# Screen shake — trauma-based with perlin noise (Squirrel Eiserloh pattern)
var _trauma: float = 0.0
var _trauma_decay: float = 3.0
var _shake_noise := FastNoiseLite.new()
var _shake_noise_y: int = 0
const MAX_SHAKE_OFFSET := Vector2(16.0, 10.0)
const MAX_SHAKE_ROTATION := 0.04  # radians

# Completion sparkle particles (reusable)
var _sparkle_particles: CPUParticles2D = null


func _ready() -> void:
	_shake_noise.seed = randi()
	_shake_noise.frequency = 2.0
	_setup_sky()
	_setup_parallax()
	_setup_particles()
	_setup_sparkles()
	_build_level()
	_setup_vignette()
	TimeSystem.activity_time_reached.connect(_on_activity_time)
	TimeSystem.time_changed.connect(_on_time_changed)
	TimeSystem.day_ended.connect(_on_day_ended)
	TimeSystem.start_day(GameState.current_day)
	_refresh_platform_states()
	AudioManager.play_music("climb_theme")


func _setup_sky() -> void:
	_sky_rect = ColorRect.new()
	_sky_rect.z_index = -10
	_sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_rect.size = Vector2(2000, 8000)
	_sky_rect.position = Vector2(-500, -1000)
	var shader := load("res://shaders/sky_gradient.gdshader") as Shader
	_sky_material = ShaderMaterial.new()
	_sky_material.shader = shader
	_sky_rect.material = _sky_material
	add_child(_sky_rect)
	_update_sky_colors()


func _setup_vignette() -> void:
	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = 5
	add_child(vignette_layer)
	_vignette = ColorRect.new()
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vig_shader := load("res://shaders/vignette.gdshader") as Shader
	_vignette_material = ShaderMaterial.new()
	_vignette_material.shader = vig_shader
	_vignette_material.set_shader_parameter("intensity", 0.35)
	_vignette_material.set_shader_parameter("softness", 0.8)
	_vignette_material.set_shader_parameter("time_factor", TimeSystem.get_time_of_day_factor())
	_vignette.material = _vignette_material
	vignette_layer.add_child(_vignette)


func _update_sky_colors() -> void:
	var tf: float = TimeSystem.get_time_of_day_factor()
	var colors: Array = ThemeManager.get_sky_colors(tf)
	_sky_material.set_shader_parameter("color_top", colors[0])
	_sky_material.set_shader_parameter("color_bottom", colors[1])
	var star_vis: float = 0.0
	if tf < 0.10:
		star_vis = 1.0 - tf / 0.10
	elif tf > 0.85:
		star_vis = (tf - 0.85) / 0.15
	_sky_material.set_shader_parameter("star_density", star_vis)
	# Sync vignette to time of day
	if _vignette_material:
		_vignette_material.set_shader_parameter("time_factor", tf)


func _setup_parallax() -> void:
	_parallax_bg = ParallaxBackground.new()
	_parallax_bg.layer = -5
	add_child(_parallax_bg)

	_far_layer = ParallaxLayer.new()
	_far_layer.motion_scale = Vector2(0.1, 0.2)
	_parallax_bg.add_child(_far_layer)

	_mid_layer = ParallaxLayer.new()
	_mid_layer.motion_scale = Vector2(0.2, 0.4)
	_parallax_bg.add_child(_mid_layer)

	_near_layer = ParallaxLayer.new()
	_near_layer.motion_scale = Vector2(0.3, 0.7)
	_parallax_bg.add_child(_near_layer)


func _populate_parallax(total_h: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345 + GameState.current_day

	# Clouds
	for i in range(10):
		var cloud := Sprite2D.new()
		cloud.texture = _cloud_textures[rng.randi_range(0, _cloud_textures.size() - 1)]
		cloud.position = Vector2(rng.randf_range(-300, 1000), rng.randf_range(-800, total_h))
		cloud.scale = Vector2(rng.randf_range(2.0, 4.0), rng.randf_range(2.0, 4.0))
		cloud.modulate.a = 0.35
		_far_layer.add_child(cloud)
		_cloud_sprites.append(cloud)

	# Trees along both edges
	for i in range(18):
		var tree := Sprite2D.new()
		tree.texture = _tree_textures[rng.randi_range(0, _tree_textures.size() - 1)]
		var side: float = rng.randf_range(-120, -20) if rng.randf() < 0.5 else rng.randf_range(980, 1100)
		tree.position = Vector2(side, rng.randf_range(-200, total_h + 200))
		tree.scale = Vector2(rng.randf_range(2.0, 3.5), rng.randf_range(2.0, 3.5))
		tree.modulate.a = rng.randf_range(0.4, 0.7)
		_mid_layer.add_child(tree)

	# Bushes, flowers, grass along edges
	for i in range(22):
		var bush := Sprite2D.new()
		bush.texture = _bush_textures[rng.randi_range(0, _bush_textures.size() - 1)]
		var side: float = rng.randf_range(-50, 60) if rng.randf() < 0.5 else rng.randf_range(940, 1050)
		bush.position = Vector2(side, rng.randf_range(-100, total_h + 100))
		bush.scale = Vector2(rng.randf_range(1.5, 2.5), rng.randf_range(1.5, 2.5))
		bush.modulate.a = rng.randf_range(0.5, 0.8)
		_near_layer.add_child(bush)

	for i in range(14):
		var flower := Sprite2D.new()
		flower.texture = _flower_textures[rng.randi_range(0, _flower_textures.size() - 1)]
		var side: float = rng.randf_range(20, 100) if rng.randf() < 0.5 else rng.randf_range(900, 980)
		flower.position = Vector2(side, rng.randf_range(0, total_h))
		flower.scale = Vector2(rng.randf_range(1.0, 1.8), rng.randf_range(1.0, 1.8))
		_near_layer.add_child(flower)



func _setup_particles() -> void:
	# Falling leaves
	_leaf_particles = CPUParticles2D.new()
	_leaf_particles.z_index = 4
	_leaf_particles.amount = 30
	_leaf_particles.lifetime = 8.0
	_apply_leaf_properties(_leaf_particles)
	_leaf_particles.texture = PlaceholderFactory.make_soft_circle(6, Color(0.5, 0.7, 0.3))
	add_child(_leaf_particles)

	# Fireflies
	_firefly_particles = CPUParticles2D.new()
	_firefly_particles.z_index = 4
	_firefly_particles.amount = 25
	_firefly_particles.lifetime = 5.0
	_apply_firefly_properties(_firefly_particles)
	_firefly_particles.texture = PlaceholderFactory.make_soft_circle(5, Color(0.95, 1.0, 0.5))
	_firefly_particles.emitting = false
	add_child(_firefly_particles)


func _setup_sparkles() -> void:
	_sparkle_particles = CPUParticles2D.new()
	_sparkle_particles.z_index = 8
	_sparkle_particles.amount = 20
	_sparkle_particles.lifetime = 1.0
	_sparkle_particles.one_shot = true
	_sparkle_particles.emitting = false
	_apply_sparkle_properties(_sparkle_particles)
	_sparkle_particles.texture = PlaceholderFactory.make_soft_circle(5, Color(1.0, 0.95, 0.5))
	add_child(_sparkle_particles)


func _apply_leaf_properties(p: CPUParticles2D) -> void:
	p.direction = Vector2(0.4, 1)
	p.spread = 40.0
	p.initial_velocity_min = 15.0
	p.initial_velocity_max = 40.0
	p.gravity = Vector2(0, 12)
	p.angular_velocity_min = -120.0
	p.angular_velocity_max = 120.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(900, 10)
	p.scale_amount_min = 0.8
	p.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.45, 0.65, 0.25, 0.0))
	ramp.add_point(0.1, Color(0.45, 0.65, 0.25, 0.65))
	ramp.add_point(0.5, Color(0.55, 0.6, 0.2, 0.55))
	ramp.add_point(0.85, Color(0.6, 0.45, 0.15, 0.4))
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.5, 0.35, 0.1, 0.0))
	p.color_ramp = ramp


func _apply_firefly_properties(p: CPUParticles2D) -> void:
	p.direction = Vector2(0, -0.3)
	p.spread = 180.0
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 25.0
	p.gravity = Vector2(0, -2)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700, 900)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.5
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.95, 1.0, 0.5, 0.0))
	ramp.add_point(0.2, Color(0.95, 1.0, 0.5, 0.9))
	ramp.add_point(0.5, Color(0.9, 0.95, 0.4, 0.7))
	ramp.add_point(0.8, Color(0.85, 0.9, 0.35, 0.5))
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.8, 0.85, 0.3, 0.0))
	p.color_ramp = ramp


func _apply_sparkle_properties(p: CPUParticles2D) -> void:
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 200.0
	p.gravity = Vector2(0, 100)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 30.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.5
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(1.0, 0.95, 0.5, 1.0))
	ramp.add_point(0.4, Color(1.0, 0.85, 0.3, 0.8))
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.9, 0.6, 0.1, 0.0))
	p.color_ramp = ramp


func _emit_sparkles(pos: Vector2) -> void:
	_sparkle_particles.position = pos
	_sparkle_particles.restart()
	_sparkle_particles.emitting = true


func _shake_camera(trauma_amount: float) -> void:
	_trauma = minf(_trauma + trauma_amount, 1.0)


func _build_level() -> void:
	_day_cards = GameData.get_all_cards_for_day(GameState.current_day)

	var total_height: float = _day_cards.size() * PLATFORM_HEIGHT
	for i in range(_day_cards.size()):
		var card := _day_cards[i]
		var y := total_height - i * PLATFORM_HEIGHT
		var x := 180.0 + (i % 3) * 230.0  # zigzag
		platforms.append({
			"pos": Vector2(x, y),
			"card": card,
			"state": "locked",
			"bridge_visible": false,
		})

	_populate_parallax(total_height)

	_sky_rect.size = Vector2(2000, total_height + 2000)
	_sky_rect.position = Vector2(-500, -1000)

	# Hero
	_hero = Node2D.new()
	_hero.set_script(preload("res://scenes/vertical_climb/hero/climb_hero.gd"))
	if platforms.size() > 0:
		_hero.position = platforms[0].pos + Vector2(PLATFORM_WIDTH * 0.5, -40)
	add_child(_hero)

	# Camera — standalone with dead-zone following
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = false  # we handle smoothing manually
	_camera.limit_left = -200
	_camera.limit_right = 1280
	_camera.limit_bottom = int(total_height + 500)
	_camera.limit_top = -800
	add_child(_camera)
	_camera.position = _hero.position
	_camera_target_y = _hero.position.y
	_camera.make_current()

	# UI
	var hud_inst := preload("res://scenes/shared/hud/hud.tscn").instantiate()
	add_child(hud_inst)
	var hud_script = hud_inst.get_node("HUDScript")
	hud_script.pause_pressed.connect(_on_pause_pressed)
	hud_script.stats_pressed.connect(_on_stats_pressed)

	var popup_inst := preload("res://scenes/shared/activity_popup/activity_popup.tscn").instantiate()
	add_child(popup_inst)
	_activity_popup = popup_inst.get_node("PopupScript")
	_activity_popup.activity_done.connect(_on_activity_done)

	var sum_inst := preload("res://scenes/shared/day_summary/day_summary.tscn").instantiate()
	add_child(sum_inst)
	_day_summary = sum_inst.get_node("SummaryScript")
	_day_summary.next_day_pressed.connect(func(): GameState.advance_day(); SceneTransition.reload_scene())
	_day_summary.game_finished.connect(func(): SceneTransition.change_scene("res://scenes/main_menu/main_menu.tscn"))

	add_child(preload("res://scenes/shared/level_up/level_up.tscn").instantiate())
	add_child(preload("res://scenes/shared/achievement_toast/achievement_toast.tscn").instantiate())

	# Branching dialogue overlay for post-activity VN conversation
	var dialog_scene := load("res://scenes/hero_dialogue/shared/branching_dialog.tscn")
	if dialog_scene:
		_branching_dialog = dialog_scene.instantiate()
		_branching_dialog.skip_actions = true
		add_child(_branching_dialog)
		_branching_dialog.dialog_finished.connect(_on_climb_dialogue_finished)
		_branching_dialog.choice_made.connect(_on_climb_choice_made)
		var portrait_tex := _load_hero_portrait_texture()
		if portrait_tex:
			_branching_dialog.set_portrait_texture(portrait_tex)
			_branching_dialog.set_portrait_visible(true)

	# Pause menu
	var pause_inst := preload("res://scenes/shared/pause_menu/pause_menu.tscn").instantiate()
	add_child(pause_inst)
	_pause_menu = pause_inst.get_node("PauseScript")
	_pause_menu.main_menu_pressed.connect(func(): SceneTransition.change_scene("res://scenes/main_menu/main_menu.tscn"))

	# Stats page
	var stats_inst := preload("res://scenes/shared/stats_page/stats_page.tscn").instantiate()
	add_child(stats_inst)
	_stats_page = stats_inst.get_node("StatsScript")

	# Side vines (decorative)
	var total_h: float = _day_cards.size() * PLATFORM_HEIGHT
	for i in range(int(total_h / 180)):
		var vy := float(i) * 180.0
		for side_x in [40, 960]:
			var vine := Sprite2D.new()
			vine.texture = _vine_tex
			vine.position = Vector2(side_x, vy + 90)
			vine.z_index = -1
			add_child(vine)


func _on_pause_pressed() -> void:
	if _pause_menu:
		_pause_menu.show_menu()


func _on_stats_pressed() -> void:
	if _stats_page:
		_stats_page.show_page()


func _process(delta: float) -> void:
	_anim_time += delta
	_update_sky_colors()
	_update_particles()

	var hero_pos := _hero.position if _hero else Vector2.ZERO

	# Dead-zone camera: only update target when hero leaves center band
	if _camera and _hero:
		var vp_h: float = get_viewport_rect().size.y / _camera.zoom.y
		var dead_zone_px: float = vp_h * DEAD_ZONE_HALF
		var diff_y: float = hero_pos.y - _camera_target_y
		if abs(diff_y) > dead_zone_px:
			_camera_target_y = hero_pos.y - sign(diff_y) * dead_zone_px
		_camera.position.x = lerpf(_camera.position.x, hero_pos.x, _camera_lerp_speed * delta)
		_camera.position.y = lerpf(_camera.position.y, _camera_target_y, _camera_lerp_speed * delta)

	_sky_rect.position = Vector2(-500, hero_pos.y - 1500)
	_leaf_particles.position = Vector2(500, hero_pos.y - 500)
	_firefly_particles.position = Vector2(500, hero_pos.y - 300)

	# Cloud drift
	for cloud in _cloud_sprites:
		cloud.position.x += 8.0 * delta
		if cloud.position.x > 1300.0:
			cloud.position.x = -400.0

	# Screen shake — trauma-based with perlin noise
	if _trauma > 0.001 and _camera:
		_trauma = maxf(_trauma - _trauma_decay * delta, 0.0)
		var intensity := _trauma * _trauma  # quadratic falloff
		_shake_noise_y += 1
		_camera.offset = Vector2(
			MAX_SHAKE_OFFSET.x * intensity * _shake_noise.get_noise_2d(float(_shake_noise.seed), float(_shake_noise_y)),
			MAX_SHAKE_OFFSET.y * intensity * _shake_noise.get_noise_2d(float(_shake_noise.seed + 100), float(_shake_noise_y))
		)
		_camera.rotation = MAX_SHAKE_ROTATION * intensity * _shake_noise.get_noise_2d(float(_shake_noise.seed + 200), float(_shake_noise_y))
	elif _camera:
		if _camera.offset != Vector2.ZERO:
			_camera.offset = Vector2.ZERO
		if _camera.rotation != 0.0:
			_camera.rotation = 0.0

	queue_redraw()


func _update_particles() -> void:
	var tf: float = TimeSystem.get_time_of_day_factor()
	_firefly_particles.emitting = tf < 0.08 or tf > 0.88
	# Switch to night music when dark
	if tf > 0.85 and AudioManager.get_current_music_key() == "climb_theme":
		AudioManager.play_music("night_theme")
	elif tf <= 0.85 and AudioManager.get_current_music_key() == "night_theme":
		AudioManager.play_music("climb_theme")


func _refresh_platform_states() -> void:
	for i in range(platforms.size()):
		var p: Dictionary = platforms[i]
		p.state = TimeSystem.get_activity_state(p.card.slot_id)


func _draw() -> void:
	# Celestial body (sun/moon) — tracks camera view
	var tf: float = TimeSystem.get_time_of_day_factor()
	var cam_y: float = _camera.position.y if _camera else 0.0
	if tf > 0.10 and tf < 0.80:
		# Daytime: sun arcs across sky
		var sun_t := (tf - 0.10) / 0.70
		var sun_x := lerpf(200.0, 880.0, sun_t)
		var sun_y := cam_y - 700.0 - sin(sun_t * PI) * 150.0
		var sun_alpha := minf(1.0, minf((tf - 0.10) / 0.05, (0.80 - tf) / 0.08))
		ProceduralDrawing.draw_sun(self, Vector2(sun_x, sun_y), 45.0,
			Color(1.0, 0.95, 0.75, sun_alpha))
	elif tf < 0.10 or tf > 0.85:
		# Night: moon
		ProceduralDrawing.draw_moon(self, Vector2(750.0, cam_y - 650.0), 35.0)

	var font := ThemeDB.fallback_font
	for i in range(platforms.size()):
		var p: Dictionary = platforms[i]
		var pos: Vector2 = p.pos
		var card: Dictionary = p.card

		var platform_modulate := Color.WHITE
		var draw_glow := false
		var glow_color := ThemeManager.GOLDEN_AMBER
		match p.state:
			"locked":
				platform_modulate = Color(0.45, 0.45, 0.45, 0.45)
			"available_late":
				platform_modulate = Color(0.9, 0.75, 0.45, 0.9)
				glow_color = ThemeManager.GOLDEN_AMBER.darkened(0.2)
				draw_glow = true
			"current":
				var pulse: float = 0.85 + sin(_anim_time * 3.0) * 0.15
				platform_modulate = Color(1.15, 1.05, 0.85, pulse)
				draw_glow = true
			"completed":
				platform_modulate = Color(0.55, 0.9, 0.45, 1.0)
				glow_color = ThemeManager.DEEP_LEAF

		# Glow aura behind platform — soft elliptical layers
		if draw_glow:
			var glow_pulse: float = 0.12 + sin(_anim_time * 2.0) * 0.08
			var center := pos + Vector2(PLATFORM_WIDTH * 0.5, PLATFORM_TEX_HEIGHT * 0.5)
			# Draw concentric ellipses (outer to inner) for soft gradient
			var layers := 6
			for l in range(layers):
				var t := float(l) / float(layers)
				var rx := (PLATFORM_WIDTH * 0.5 + 40.0) * (1.0 - t * 0.5)
				var ry := 55.0 * (1.0 - t * 0.4)
				var alpha := glow_pulse * (0.15 + t * 0.6)
				var c := Color(glow_color.r, glow_color.g, glow_color.b, alpha)
				# Approximate ellipse with polygon
				var pts := PackedVector2Array()
				var segs := 24
				for s in range(segs + 1):
					var angle := float(s) / float(segs) * TAU
					pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
				draw_colored_polygon(pts, c)

		# Platform SVG texture
		draw_texture_rect(
			_platform_tex,
			Rect2(pos.x, pos.y, PLATFORM_WIDTH, PLATFORM_TEX_HEIGHT),
			false,
			platform_modulate
		)

		# Activity marker
		var emoji_text: String = card.get("emoji", "")
		var title_text: String = card.get("title", "")
		if title_text.length() > 18:
			title_text = title_text.substr(0, 18) + "…"

		if p.state == "locked":
			draw_string(font, pos + Vector2(12, PLATFORM_TEX_HEIGHT + 22), "🔒",
				HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(22))
			draw_string(font, pos + Vector2(52, PLATFORM_TEX_HEIGHT + 22), title_text,
				HORIZONTAL_ALIGNMENT_LEFT, 160, ThemeManager.font_size(15), Color(0.5, 0.5, 0.5, 0.55))
			var time_str: String = card.get("time", "")
			draw_string(font, pos + Vector2(PLATFORM_WIDTH - 65, PLATFORM_TEX_HEIGHT + 22), time_str,
				HORIZONTAL_ALIGNMENT_RIGHT, 65, ThemeManager.font_size(13), Color(0.5, 0.5, 0.5, 0.7))
		else:
			draw_string(font, pos + Vector2(12, PLATFORM_TEX_HEIGHT + 22), emoji_text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(26))
			var title_color: Color = ThemeManager.TEXT_BROWN
			if p.state == "completed":
				title_color = Color(1, 1, 1, 0.9)
			elif p.state == "available_late":
				title_color = ThemeManager.TEXT_BROWN.darkened(0.15)
			draw_string(font, pos + Vector2(52, PLATFORM_TEX_HEIGHT + 22), title_text,
				HORIZONTAL_ALIGNMENT_LEFT, 260, ThemeManager.font_size(15), title_color)
			if p.state == "completed":
				draw_string(font, pos + Vector2(PLATFORM_WIDTH - 35, PLATFORM_TEX_HEIGHT + 22), "✅",
					HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(18))
			elif p.state == "available_late":
				draw_string(font, pos + Vector2(PLATFORM_WIDTH - 35, PLATFORM_TEX_HEIGHT + 22), "⏰",
					HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(16))

		# Bridge to next platform — wavy vine with leaves
		if p.bridge_visible and i + 1 < platforms.size():
			var next_pos: Vector2 = platforms[i + 1].pos
			var bridge_start := pos + Vector2(PLATFORM_WIDTH * 0.5, 0)
			var bridge_end := next_pos + Vector2(PLATFORM_WIDTH * 0.5, PLATFORM_TEX_HEIGHT)
			var steps := 12
			var prev_pt := bridge_start
			for s in range(1, steps + 1):
				var t := float(s) / float(steps)
				var pt := bridge_start.lerp(bridge_end, t)
				pt.x += sin(t * PI * 3.0) * 18.0
				# Thicker vine
				draw_line(prev_pt, pt, ThemeManager.SAGE_GREEN.darkened(0.1), 5.0)
				draw_line(prev_pt, pt, ThemeManager.SAGE_GREEN, 3.0)
				# Leaf pairs along vine
				if s % 2 == 0:
					var leaf_off := Vector2(8, -4) if s % 4 == 0 else Vector2(-8, -4)
					draw_circle(pt + leaf_off, 5.0, ThemeManager.DEEP_LEAF)
					draw_circle(pt + leaf_off * 0.5, 3.0, ThemeManager.LIGHT_SAGE)
				prev_pt = pt


func _on_activity_time(_slot_id: String, _card: Dictionary) -> void:
	_refresh_platform_states()
	queue_redraw()


func _on_time_changed(_real_time_minutes: float) -> void:
	_refresh_platform_states()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _branching_dialog and _branching_dialog.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		var world_pos := get_global_mouse_position()
		for i in range(platforms.size()):
			var p: Dictionary = platforms[i]
			if p.state in ["current", "available_late"]:
				var rect := Rect2(p.pos.x, p.pos.y - 50, PLATFORM_WIDTH, 90)
				if rect.has_point(world_pos):
					_hero.jump_to(p.pos + Vector2(PLATFORM_WIDTH * 0.5, -40))
					AudioManager.play("jump")
					_current_platform = i
					await get_tree().create_timer(0.3).timeout
					AudioManager.play("land")
					GameState.vibrate(30)
					_activity_popup.show_popup(p.card, GameState.current_day)
					return


func _on_activity_done(slot_id: String, completed: bool) -> void:
	if completed:
		GameState.complete_activity(GameState.current_day, slot_id)
		AudioManager.play("complete")
		GameState.vibrate(50)

		# Store slot and platform index for deferred visual effects
		_pending_dialogue_slot = slot_id
		_pending_effects_platform_idx = -1
		for i in range(platforms.size()):
			if platforms[i].card.slot_id == slot_id:
				_pending_effects_platform_idx = i
				break

		# Keep time paused during dialogue
		TimeSystem.pause()
		_start_climb_dialogue(slot_id)
	else:
		GameState.miss_activity(GameState.current_day, slot_id)
		_refresh_platform_states()
		SaveManager.save_game()
		queue_redraw()


func _start_climb_dialogue(slot_id: String) -> void:
	if not _branching_dialog:
		_play_completion_effects()
		return

	var nodes: Array = DialogueData.get_dialogue(GameState.current_day, slot_id)
	if nodes.is_empty():
		_play_completion_effects()
		return

	var key := "day%d_%s" % [GameState.current_day, slot_id]
	_branching_dialog.show_dialogue(key, nodes)


func _on_climb_dialogue_finished() -> void:
	# Record dialogue progress
	var day := GameState.current_day
	if day not in GameState.dialogue_progress:
		GameState.dialogue_progress[day] = []
	if _pending_dialogue_slot.length() > 0 and _pending_dialogue_slot not in GameState.dialogue_progress[day]:
		GameState.dialogue_progress[day].append(_pending_dialogue_slot)

	GameState.dialogue_node_completed.emit(day, _pending_dialogue_slot)
	_play_completion_effects()


func _on_climb_choice_made(choice_key: String) -> void:
	if choice_key.length() > 0:
		var dlg_key := "day%d_%s" % [GameState.current_day, _pending_dialogue_slot]
		GameState.dialogue_choices[dlg_key] = choice_key

		# Branch to a different dialogue tree if it exists
		var branch_nodes: Array = []
		if choice_key in DialogueData.DIALOGUES:
			branch_nodes = DialogueData.DIALOGUES[choice_key]
		if branch_nodes.size() > 0 and _branching_dialog:
			_branching_dialog.show_dialogue(choice_key, branch_nodes)


func _play_completion_effects() -> void:
	TimeSystem.resume()
	_pending_dialogue_slot = ""

	SceneTransition.flash_screen(Color(0.49, 0.64, 0.27, 1.0), 0.2)
	SceneTransition.shockwave(Vector2(0.5, 0.5), 0.5)

	if _pending_effects_platform_idx >= 0 and _pending_effects_platform_idx < platforms.size():
		var i := _pending_effects_platform_idx
		platforms[i].bridge_visible = true
		_emit_sparkles(platforms[i].pos + Vector2(PLATFORM_WIDTH * 0.5, 0))
		_shake_camera(0.3)
		if _camera:
			var zw := create_tween()
			zw.tween_property(_camera, "zoom", Vector2(1.08, 1.08), 0.15).set_ease(Tween.EASE_OUT)
			zw.tween_property(_camera, "zoom", Vector2.ONE, 0.3).set_ease(Tween.EASE_IN_OUT)

	_pending_effects_platform_idx = -1
	_refresh_platform_states()
	SaveManager.save_game()
	queue_redraw()


func _on_day_ended() -> void:
	if _branching_dialog and _branching_dialog.visible:
		return
	if _day_summary and not _day_summary.summary_layer.visible:
		_day_summary.show_summary(GameState.current_day)


func _load_hero_portrait_texture() -> Texture2D:
	var suffix := GameState.get_hair_style_suffix()
	var gender_suffix := "_male" if GameState.gender == "male" else ""
	var path := "res://assets/hero/climb/hero_climb_idle%s%s.svg" % [gender_suffix, suffix]
	return load(path) as Texture2D
