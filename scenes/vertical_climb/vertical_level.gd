extends Node2D
## Vertical climb level — platforms from dawn (bottom) to night (top).
## Enhanced visual: sky shader, parallax, particles, vignette, platform glow,
## completion sparkles, screen shake, squash & stretch.

var platforms: Array[Dictionary] = []
var _hero: Node2D = null
var _activity_popup = null
var _day_summary = null
var _pause_menu = null
var _day_cards: Array[Dictionary] = []
var _current_platform: int = 0
var _anim_time: float = 0.0
var _camera: Camera2D = null

const PLATFORM_HEIGHT := 300.0
const PLATFORM_WIDTH := 280.0
const PLATFORM_TEX_HEIGHT := 40.0

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

# Parallax layers
var _parallax_bg: ParallaxBackground = null
var _far_layer: ParallaxLayer = null
var _mid_layer: ParallaxLayer = null
var _near_layer: ParallaxLayer = null

# Particles
var _leaf_particles: GPUParticles2D = null
var _firefly_particles: GPUParticles2D = null

# Screen shake
var _shake_amount: float = 0.0
var _shake_decay: float = 8.0

# Completion sparkle particles (reusable)
var _sparkle_particles: GPUParticles2D = null


func _ready() -> void:
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
	# Vignette is a CanvasLayer overlay so it stays fixed on screen
	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = 5
	add_child(vignette_layer)
	_vignette = ColorRect.new()
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vig_shader := load("res://shaders/vignette.gdshader") as Shader
	var vig_mat := ShaderMaterial.new()
	vig_mat.shader = vig_shader
	vig_mat.set_shader_parameter("intensity", 0.35)
	vig_mat.set_shader_parameter("softness", 0.8)
	_vignette.material = vig_mat
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


func _setup_parallax() -> void:
	_parallax_bg = ParallaxBackground.new()
	_parallax_bg.z_index = -5
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

	# Mountains in far layer (procedural)
	for i in range(4):
		var mx := rng.randf_range(-200, 800)
		var my := rng.randf_range(total_h * 0.3, total_h * 0.9)
		var mtn := Node2D.new()
		mtn.set_script(preload("res://scripts/utils/procedural_drawing.gd").get_class())
		_far_layer.add_child(mtn)
		# We'll draw mountains in _draw via far layer ref

	# Clouds
	for i in range(10):
		var cloud := Sprite2D.new()
		cloud.texture = _cloud_textures[rng.randi_range(0, _cloud_textures.size() - 1)]
		cloud.position = Vector2(rng.randf_range(-300, 1000), rng.randf_range(-800, total_h))
		cloud.scale = Vector2(rng.randf_range(2.0, 4.0), rng.randf_range(2.0, 4.0))
		cloud.modulate.a = 0.35
		_far_layer.add_child(cloud)

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
	_leaf_particles = GPUParticles2D.new()
	_leaf_particles.z_index = 4
	_leaf_particles.amount = 30
	_leaf_particles.lifetime = 8.0
	_leaf_particles.visibility_rect = Rect2(-600, -1500, 2200, 3500)
	_leaf_particles.process_material = _create_leaf_material()
	var leaf_tex := PlaceholderTexture2D.new()
	leaf_tex.size = Vector2(10, 6)
	_leaf_particles.texture = leaf_tex
	add_child(_leaf_particles)

	# Fireflies
	_firefly_particles = GPUParticles2D.new()
	_firefly_particles.z_index = 4
	_firefly_particles.amount = 25
	_firefly_particles.lifetime = 5.0
	_firefly_particles.visibility_rect = Rect2(-600, -1500, 2200, 3500)
	_firefly_particles.process_material = _create_firefly_material()
	var ff_tex := PlaceholderTexture2D.new()
	ff_tex.size = Vector2(6, 6)
	_firefly_particles.texture = ff_tex
	_firefly_particles.emitting = false
	add_child(_firefly_particles)


func _setup_sparkles() -> void:
	_sparkle_particles = GPUParticles2D.new()
	_sparkle_particles.z_index = 8
	_sparkle_particles.amount = 20
	_sparkle_particles.lifetime = 1.0
	_sparkle_particles.one_shot = true
	_sparkle_particles.emitting = false
	_sparkle_particles.visibility_rect = Rect2(-200, -200, 400, 400)
	_sparkle_particles.process_material = _create_sparkle_material()
	var sp_tex := PlaceholderTexture2D.new()
	sp_tex.size = Vector2(6, 6)
	_sparkle_particles.texture = sp_tex
	add_child(_sparkle_particles)


func _create_leaf_material() -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.4, 1, 0)
	mat.spread = 40.0
	mat.initial_velocity_min = 15.0
	mat.initial_velocity_max = 40.0
	mat.gravity = Vector3(0, 12, 0)
	mat.angular_velocity_min = -120.0
	mat.angular_velocity_max = 120.0
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(900, 10, 0)
	mat.scale_min = 0.8
	mat.scale_max = 2.0
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.45, 0.65, 0.25, 0.0))
	ramp.add_point(0.1, Color(0.45, 0.65, 0.25, 0.65))
	ramp.add_point(0.5, Color(0.55, 0.6, 0.2, 0.55))
	ramp.add_point(0.85, Color(0.6, 0.45, 0.15, 0.4))
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.5, 0.35, 0.1, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	mat.color_ramp = tex
	return mat


func _create_firefly_material() -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -0.3, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 8.0
	mat.initial_velocity_max = 25.0
	mat.gravity = Vector3(0, -2, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(700, 900, 0)
	mat.scale_min = 0.6
	mat.scale_max = 1.5
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.95, 1.0, 0.5, 0.0))
	ramp.add_point(0.2, Color(0.95, 1.0, 0.5, 0.9))
	ramp.add_point(0.5, Color(0.9, 0.95, 0.4, 0.7))
	ramp.add_point(0.8, Color(0.85, 0.9, 0.35, 0.5))
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.8, 0.85, 0.3, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	mat.color_ramp = tex
	return mat


func _create_sparkle_material() -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 200.0
	mat.gravity = Vector3(0, 100, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 30.0
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(1.0, 0.95, 0.5, 1.0))
	ramp.add_point(0.4, Color(1.0, 0.85, 0.3, 0.8))
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.9, 0.6, 0.1, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	mat.color_ramp = tex
	return mat


func _emit_sparkles(pos: Vector2) -> void:
	_sparkle_particles.position = pos
	_sparkle_particles.restart()
	_sparkle_particles.emitting = true


func _shake_camera(amount: float) -> void:
	_shake_amount = amount


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

	# Camera
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 4.0
	_hero.add_child(_camera)
	_camera.make_current()

	# UI
	var hud_inst := preload("res://scenes/shared/hud/hud.tscn").instantiate()
	add_child(hud_inst)
	var hud_script = hud_inst.get_node("HUDScript")
	hud_script.pause_pressed.connect(_on_pause_pressed)

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

	# Pause menu
	var pause_inst := preload("res://scenes/shared/pause_menu/pause_menu.tscn").instantiate()
	add_child(pause_inst)
	_pause_menu = pause_inst.get_node("PauseScript")
	_pause_menu.main_menu_pressed.connect(func(): SceneTransition.change_scene("res://scenes/main_menu/main_menu.tscn"))

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


func _process(delta: float) -> void:
	_anim_time += delta
	_update_sky_colors()
	_update_particles()

	var cam_pos := _hero.position if _hero else Vector2.ZERO
	_sky_rect.position = Vector2(-500, cam_pos.y - 1500)
	_leaf_particles.position = Vector2(500, cam_pos.y - 500)
	_firefly_particles.position = Vector2(500, cam_pos.y - 300)

	# Screen shake decay
	if _shake_amount > 0.01:
		_shake_amount = lerpf(_shake_amount, 0.0, _shake_decay * delta)
		if _camera:
			_camera.offset = Vector2(
				randf_range(-_shake_amount, _shake_amount),
				randf_range(-_shake_amount, _shake_amount)
			)
	elif _camera and _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO

	queue_redraw()


func _update_particles() -> void:
	var tf: float = TimeSystem.get_time_of_day_factor()
	_firefly_particles.emitting = tf < 0.08 or tf > 0.88


func _refresh_platform_states() -> void:
	for i in range(platforms.size()):
		var p: Dictionary = platforms[i]
		p.state = TimeSystem.get_activity_state(p.card.slot_id)


func _draw() -> void:
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

		# Glow aura behind platform
		if draw_glow:
			var glow_pulse: float = 0.12 + sin(_anim_time * 2.0) * 0.08
			# Outer soft glow
			draw_rect(
				Rect2(pos.x - 25, pos.y - 55, PLATFORM_WIDTH + 50, 100),
				Color(glow_color.r, glow_color.g, glow_color.b, glow_pulse * 0.5)
			)
			# Inner bright glow
			draw_rect(
				Rect2(pos.x - 10, pos.y - 35, PLATFORM_WIDTH + 20, 65),
				Color(glow_color.r, glow_color.g, glow_color.b, glow_pulse)
			)

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
		if title_text.length() > 14:
			title_text = title_text.substr(0, 14) + "…"

		if p.state == "locked":
			draw_string(font, pos + Vector2(12, -12), "🔒",
				HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(22))
			draw_string(font, pos + Vector2(52, -12), title_text,
				HORIZONTAL_ALIGNMENT_LEFT, 200, ThemeManager.font_size(15), Color(0.5, 0.5, 0.5, 0.55))
			var time_str: String = card.get("time", "")
			draw_string(font, pos + Vector2(PLATFORM_WIDTH - 65, -12), time_str,
				HORIZONTAL_ALIGNMENT_RIGHT, 65, ThemeManager.font_size(13), Color(0.5, 0.5, 0.5, 0.7))
		else:
			draw_string(font, pos + Vector2(12, -12), emoji_text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(26))
			var title_color: Color = ThemeManager.TEXT_BROWN
			if p.state == "completed":
				title_color = Color(1, 1, 1, 0.9)
			elif p.state == "available_late":
				title_color = ThemeManager.TEXT_BROWN.darkened(0.15)
			draw_string(font, pos + Vector2(52, -12), title_text,
				HORIZONTAL_ALIGNMENT_LEFT, 220, ThemeManager.font_size(15), title_color)
			if p.state == "completed":
				draw_string(font, pos + Vector2(PLATFORM_WIDTH - 35, -12), "✅",
					HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(18))
			elif p.state == "available_late":
				draw_string(font, pos + Vector2(PLATFORM_WIDTH - 35, -12), "⏰",
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
	if event is InputEventMouseButton and event.pressed:
		var world_pos := get_global_mouse_position()
		for i in range(platforms.size()):
			var p: Dictionary = platforms[i]
			if p.state in ["current", "available_late"]:
				var rect := Rect2(p.pos.x, p.pos.y - 50, PLATFORM_WIDTH, 90)
				if rect.has_point(world_pos):
					_hero.jump_to(p.pos + Vector2(PLATFORM_WIDTH * 0.5, -40))
					_current_platform = i
					await get_tree().create_timer(0.3).timeout
					_activity_popup.show_popup(p.card, GameState.current_day)
					return


func _on_activity_done(slot_id: String, completed: bool) -> void:
	if completed:
		GameState.complete_activity(GameState.current_day, slot_id)
	else:
		GameState.miss_activity(GameState.current_day, slot_id)

	for i in range(platforms.size()):
		if platforms[i].card.slot_id == slot_id:
			if completed:
				platforms[i].bridge_visible = true
				# Sparkle effect + screen shake on completion
				_emit_sparkles(platforms[i].pos + Vector2(PLATFORM_WIDTH * 0.5, 0))
				_shake_camera(8.0)
			break

	_refresh_platform_states()
	SaveManager.save_game()
	queue_redraw()


func _on_day_ended() -> void:
	_day_summary.show_summary(GameState.current_day)
