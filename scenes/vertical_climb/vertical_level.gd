extends Node2D
## Vertical climb level — platforms from dawn (bottom) to night (top).
## Time-blocking: platforms locked until real time matches scheduled time.

var platforms: Array[Dictionary] = []
var _hero: Node2D = null
var _activity_popup = null
var _day_summary = null
var _day_cards: Array[Dictionary] = []
var _current_platform: int = 0
var _anim_time: float = 0.0

const PLATFORM_HEIGHT := 300.0
const PLATFORM_WIDTH := 250.0

var _vine_tex: Texture2D = preload("res://assets/environment/vine_segment.svg")
var _platform_tex: Texture2D = preload("res://assets/environment/platform.svg")
var _flower_textures := [
	preload("res://assets/nature/flower_5petal.svg"),
	preload("res://assets/nature/flower_4petal.svg"),
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

# Parallax layers
var _parallax_bg: ParallaxBackground = null
var _far_layer: ParallaxLayer = null   # mountains/clouds — slow
var _mid_layer: ParallaxLayer = null   # trees — medium
var _near_layer: ParallaxLayer = null  # bushes/flowers — fast

# Particles
var _leaf_particles: GPUParticles2D = null
var _firefly_particles: GPUParticles2D = null


func _ready() -> void:
	_setup_sky()
	_setup_parallax()
	_setup_particles()
	_build_level()
	TimeSystem.activity_time_reached.connect(_on_activity_time)
	TimeSystem.time_changed.connect(_on_time_changed)
	TimeSystem.day_ended.connect(_on_day_ended)
	TimeSystem.start_day(GameState.current_day)


func _setup_sky() -> void:
	# Full-screen ColorRect with gradient shader — sits behind everything
	_sky_rect = ColorRect.new()
	_sky_rect.z_index = -10
	_sky_rect.size = Vector2(2000, 8000)
	_sky_rect.position = Vector2(-500, -1000)
	var shader := load("res://shaders/sky_gradient.gdshader") as Shader
	_sky_material = ShaderMaterial.new()
	_sky_material.shader = shader
	_sky_rect.material = _sky_material
	add_child(_sky_rect)
	_update_sky_colors()


func _update_sky_colors() -> void:
	var tf: float = TimeSystem.get_time_of_day_factor()
	var colors: Array = ThemeManager.get_sky_colors(tf)
	_sky_material.set_shader_parameter("color_top", colors[0])
	_sky_material.set_shader_parameter("color_bottom", colors[1])
	# Stars visible at night (tf < 0.1 or tf > 0.85)
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

	# Far layer — clouds, mountains (moves 20% of camera)
	_far_layer = ParallaxLayer.new()
	_far_layer.motion_scale = Vector2(0.1, 0.2)
	_parallax_bg.add_child(_far_layer)

	# Mid layer — trees (moves 40% of camera)
	_mid_layer = ParallaxLayer.new()
	_mid_layer.motion_scale = Vector2(0.2, 0.4)
	_parallax_bg.add_child(_mid_layer)

	# Near layer — bushes, flowers (moves 70% of camera)
	_near_layer = ParallaxLayer.new()
	_near_layer.motion_scale = Vector2(0.3, 0.7)
	_parallax_bg.add_child(_near_layer)


func _populate_parallax(total_h: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345 + GameState.current_day

	# Clouds in far layer
	for i in range(8):
		var cloud := Sprite2D.new()
		cloud.texture = _cloud_textures[rng.randi_range(0, _cloud_textures.size() - 1)]
		cloud.position = Vector2(rng.randf_range(-200, 900), rng.randf_range(-500, total_h))
		cloud.scale = Vector2(rng.randf_range(1.5, 3.0), rng.randf_range(1.5, 3.0))
		cloud.modulate.a = 0.4
		_far_layer.add_child(cloud)

	# Trees in mid layer
	for i in range(12):
		var tree := Sprite2D.new()
		tree.texture = _tree_textures[rng.randi_range(0, _tree_textures.size() - 1)]
		var side: float = -80.0 if rng.randf() < 0.5 else 1000.0
		tree.position = Vector2(side + rng.randf_range(-30, 30), rng.randf_range(0, total_h))
		tree.scale = Vector2(2.0, 2.0)
		tree.modulate.a = 0.5
		_mid_layer.add_child(tree)

	# Bushes and flowers in near layer
	for i in range(16):
		var bush := Sprite2D.new()
		bush.texture = _bush_textures[rng.randi_range(0, _bush_textures.size() - 1)]
		var side: float = -40.0 if rng.randf() < 0.5 else 1020.0
		bush.position = Vector2(side + rng.randf_range(-20, 20), rng.randf_range(0, total_h))
		bush.scale = Vector2(1.5, 1.5)
		bush.modulate.a = 0.6
		_near_layer.add_child(bush)

	for i in range(10):
		var flower := Sprite2D.new()
		flower.texture = _flower_textures[rng.randi_range(0, _flower_textures.size() - 1)]
		var side: float = 30.0 if rng.randf() < 0.5 else 970.0
		flower.position = Vector2(side + rng.randf_range(-20, 20), rng.randf_range(0, total_h))
		flower.scale = Vector2(1.2, 1.2)
		_near_layer.add_child(flower)


func _setup_particles() -> void:
	# Falling leaves — always visible, gentle drift
	_leaf_particles = GPUParticles2D.new()
	_leaf_particles.z_index = 5
	_leaf_particles.amount = 20
	_leaf_particles.lifetime = 6.0
	_leaf_particles.visibility_rect = Rect2(-600, -1200, 2200, 3000)
	_leaf_particles.process_material = _create_leaf_material()
	# Texture: small colored quad via a tiny CanvasTexture approach
	# Use a simple PlaceholderTexture2D — the particle material handles color
	var leaf_tex := PlaceholderTexture2D.new()
	leaf_tex.size = Vector2(8, 5)
	_leaf_particles.texture = leaf_tex
	add_child(_leaf_particles)

	# Fireflies — visible only at night
	_firefly_particles = GPUParticles2D.new()
	_firefly_particles.z_index = 5
	_firefly_particles.amount = 15
	_firefly_particles.lifetime = 4.0
	_firefly_particles.visibility_rect = Rect2(-600, -1200, 2200, 3000)
	_firefly_particles.process_material = _create_firefly_material()
	var ff_tex := PlaceholderTexture2D.new()
	ff_tex.size = Vector2(4, 4)
	_firefly_particles.texture = ff_tex
	_firefly_particles.emitting = false
	add_child(_firefly_particles)


func _create_leaf_material() -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.3, 1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 50.0
	mat.gravity = Vector3(0, 15, 0)
	mat.angular_velocity_min = -90.0
	mat.angular_velocity_max = 90.0
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(800, 10, 0)
	mat.scale_min = 0.8
	mat.scale_max = 1.5
	# Leaf green/brown colors
	mat.color = Color(0.5, 0.7, 0.3, 0.7)
	var color_ramp := Gradient.new()
	color_ramp.set_offset(0, 0.0)
	color_ramp.set_color(0, Color(0.5, 0.7, 0.3, 0.0))
	color_ramp.add_point(0.15, Color(0.5, 0.7, 0.3, 0.7))
	color_ramp.add_point(0.8, Color(0.6, 0.5, 0.2, 0.6))
	color_ramp.set_offset(color_ramp.get_point_count() - 1, 1.0)
	color_ramp.set_color(color_ramp.get_point_count() - 1, Color(0.4, 0.3, 0.1, 0.0))
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_ramp
	mat.color_ramp = color_tex
	return mat


func _create_firefly_material() -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -0.5, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 20.0
	mat.gravity = Vector3(0, -3, 0)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(600, 800, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.2
	# Warm yellow-green glow
	var color_ramp := Gradient.new()
	color_ramp.set_offset(0, 0.0)
	color_ramp.set_color(0, Color(0.9, 1.0, 0.4, 0.0))
	color_ramp.add_point(0.3, Color(0.9, 1.0, 0.4, 0.8))
	color_ramp.add_point(0.7, Color(0.8, 0.9, 0.3, 0.6))
	color_ramp.set_offset(color_ramp.get_point_count() - 1, 1.0)
	color_ramp.set_color(color_ramp.get_point_count() - 1, Color(0.7, 0.8, 0.2, 0.0))
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_ramp
	mat.color_ramp = color_tex
	return mat


func _build_level() -> void:
	_day_cards = GameData.get_all_cards_for_day(GameState.current_day)

	# Build platforms bottom to top (first card at bottom)
	var total_height: float = _day_cards.size() * PLATFORM_HEIGHT
	for i in range(_day_cards.size()):
		var card := _day_cards[i]
		var y := total_height - i * PLATFORM_HEIGHT
		var x := 200.0 + (i % 3) * 250.0  # zigzag
		platforms.append({
			"pos": Vector2(x, y),
			"card": card,
			"state": "locked",  # locked, available_late, current, completed
			"bridge_visible": false,
		})

	# Populate parallax with nature sprites
	_populate_parallax(total_height)

	# Position sky rect to cover entire level
	_sky_rect.size = Vector2(2000, total_height + 2000)
	_sky_rect.position = Vector2(-500, -1000)

	# Hero starts on bottom platform
	_hero = Node2D.new()
	_hero.set_script(preload("res://scenes/vertical_climb/hero/climb_hero.gd"))
	if platforms.size() > 0:
		_hero.position = platforms[0].pos + Vector2(PLATFORM_WIDTH * 0.5, -30)
	add_child(_hero)

	# Camera follows hero vertically
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 4.0
	_hero.add_child(cam)
	cam.make_current()

	# UI
	add_child(preload("res://scenes/shared/hud/hud.tscn").instantiate())

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

	# Side vine sprites
	var total_h: float = _day_cards.size() * PLATFORM_HEIGHT
	for i in range(int(total_h / 200)):
		var vy := float(i) * 200.0
		# Left vine
		var lv := Sprite2D.new()
		lv.texture = _vine_tex
		lv.position = Vector2(50, vy + 100)
		lv.scale = Vector2(1.0, 1.0)
		lv.z_index = -1
		add_child(lv)
		# Right vine
		var rv := Sprite2D.new()
		rv.texture = _vine_tex
		rv.position = Vector2(950, vy + 100)
		rv.scale = Vector2(1.0, 1.0)
		rv.z_index = -1
		add_child(rv)


func _process(delta: float) -> void:
	_anim_time += delta
	_update_sky_colors()
	_update_particles()
	# Keep sky rect following camera
	var cam_pos := _hero.position if _hero else Vector2.ZERO
	_sky_rect.position = Vector2(-500, cam_pos.y - 1500)
	# Keep particles emitting near camera
	_leaf_particles.position = Vector2(500, cam_pos.y - 400)
	_firefly_particles.position = Vector2(500, cam_pos.y - 200)
	queue_redraw()


func _update_particles() -> void:
	var tf: float = TimeSystem.get_time_of_day_factor()
	# Fireflies only at night
	var is_night := tf < 0.08 or tf > 0.88
	_firefly_particles.emitting = is_night


func _refresh_platform_states() -> void:
	for i in range(platforms.size()):
		var p: Dictionary = platforms[i]
		var sid: String = p.card.slot_id
		p.state = TimeSystem.get_activity_state(sid)


func _draw() -> void:
	# Platforms (using SVG sprite texture now)
	var font := ThemeDB.fallback_font
	for i in range(platforms.size()):
		var p: Dictionary = platforms[i]
		var pos: Vector2 = p.pos
		var card: Dictionary = p.card

		# Platform rendering based on state
		var platform_modulate := Color.WHITE
		var draw_glow := false
		match p.state:
			"locked":
				platform_modulate = Color(0.5, 0.5, 0.5, 0.5)
			"available_late":
				platform_modulate = Color(0.85, 0.7, 0.4, 0.85)
			"current":
				# Pulse glow effect
				var pulse: float = 0.8 + sin(_anim_time * 3.0) * 0.2
				platform_modulate = Color(
					1.2, 1.0, 0.7, pulse
				)
				draw_glow = true
			"completed":
				platform_modulate = Color(0.5, 0.85, 0.4, 1.0)

		# Glow ring behind current platform
		if draw_glow:
			var glow_alpha: float = 0.15 + sin(_anim_time * 2.0) * 0.1
			draw_rect(
				Rect2(pos.x - 15, pos.y - 45, PLATFORM_WIDTH + 30, 80),
				Color(ThemeManager.GOLDEN_AMBER.r, ThemeManager.GOLDEN_AMBER.g,
					ThemeManager.GOLDEN_AMBER.b, glow_alpha)
			)

		# Draw platform SVG sprite
		draw_texture_rect(
			_platform_tex,
			Rect2(pos.x, pos.y, PLATFORM_WIDTH, 25),
			false,
			platform_modulate
		)

		# Activity marker text
		var emoji_text: String = card.get("emoji", "")
		var title_text: String = card.get("title", "")
		if title_text.length() > 15:
			title_text = title_text.substr(0, 15) + "…"

		if p.state == "locked":
			# Lock icon and dimmed text
			draw_string(font, pos + Vector2(10, -10), "🔒",
				HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(24))
			draw_string(font, pos + Vector2(50, -10), title_text,
				HORIZONTAL_ALIGNMENT_LEFT, 200, ThemeManager.font_size(16), Color(0.5, 0.5, 0.5, 0.6))
			# Time label
			var time_str: String = card.get("time", "")
			draw_string(font, pos + Vector2(PLATFORM_WIDTH - 60, -10), time_str,
				HORIZONTAL_ALIGNMENT_RIGHT, 60, ThemeManager.font_size(14), Color(0.5, 0.5, 0.5, 0.8))
		else:
			draw_string(font, pos + Vector2(10, -10), emoji_text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(28))
			var title_color: Color = ThemeManager.TEXT_BROWN
			if p.state == "completed":
				title_color = Color(1, 1, 1, 0.9)
			elif p.state == "available_late":
				title_color = ThemeManager.TEXT_BROWN.darkened(0.2)
			draw_string(font, pos + Vector2(50, -10), title_text,
				HORIZONTAL_ALIGNMENT_LEFT, 200, ThemeManager.font_size(16), title_color)
			# Checkmark for completed
			if p.state == "completed":
				draw_string(font, pos + Vector2(PLATFORM_WIDTH - 30, -10), "✅",
					HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(20))
			# Late indicator
			elif p.state == "available_late":
				draw_string(font, pos + Vector2(PLATFORM_WIDTH - 30, -10), "⏰",
					HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(18))

		# Bridge/vine to next platform
		if p.bridge_visible and i + 1 < platforms.size():
			var next_pos: Vector2 = platforms[i + 1].pos
			var bridge_start := pos + Vector2(PLATFORM_WIDTH * 0.5, 0)
			var bridge_end := next_pos + Vector2(PLATFORM_WIDTH * 0.5, 25)
			# Draw a leafy vine bridge instead of plain line
			var steps := 8
			var prev_pt := bridge_start
			for s in range(1, steps + 1):
				var t := float(s) / float(steps)
				var pt := bridge_start.lerp(bridge_end, t)
				pt.x += sin(t * PI * 2.0) * 15.0  # wave
				draw_line(prev_pt, pt, ThemeManager.SAGE_GREEN, 4.0)
				# Small leaf dots along vine
				if s % 2 == 0:
					draw_circle(pt + Vector2(6, 0), 4.0, ThemeManager.DEEP_LEAF)
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
				var rect := Rect2(p.pos.x, p.pos.y - 50, PLATFORM_WIDTH, 75)
				if rect.has_point(world_pos):
					# Move hero to platform
					_hero.jump_to(p.pos + Vector2(PLATFORM_WIDTH * 0.5, -30))
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
			break

	_refresh_platform_states()
	SaveManager.save_game()
	queue_redraw()


func _on_day_ended() -> void:
	_day_summary.show_summary(GameState.current_day)
